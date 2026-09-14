import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { initializeApp, deleteApp, type FirebaseApp } from "firebase/app";
import { getAuth, connectAuthEmulator, signInAnonymously } from "firebase/auth";
import {
  getFirestore,
  connectFirestoreEmulator,
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  onSnapshot,
} from "firebase/firestore";
import { getFunctions, connectFunctionsEmulator, httpsCallable } from "firebase/functions";
import { beforeAll, beforeEach, afterEach, afterAll, it, expect } from "vitest";

let environment: RulesTestEnvironment;
const apps: FirebaseApp[] = [];
async function client(label: string, anonymous = true) {
  const app = initializeApp(
    { projectId: "demo-trip-split", apiKey: "demo-api-key", authDomain: "localhost" },
    `${label}-${crypto.randomUUID()}`,
  );
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, "127.0.0.1", 8080);
  const functions = getFunctions(app, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  if (anonymous) await signInAnonymously(auth);
  const call = async <T = Record<string, unknown>>(name: string, input: unknown): Promise<T> =>
    (await httpsCallable<unknown, T>(functions, name)(input)).data;
  return { auth, db, call };
}
type Client = Awaited<ReturnType<typeof client>>;
async function create(owner: Client) {
  return owner.call<{ tripId: string; shareCode: string }>("createTrip", {
    title: "도메인 통합 여행",
    startDate: "2026-11-25",
    endDate: "2026-11-27",
    countryCode: "JP",
    timeZone: "Asia/Tokyo",
    mapProvider: "google",
    defaultCurrency: "JPY",
    participantNames: ["하나", "둘", "셋"],
  });
}
async function setup() {
  const owner = await client("owner"),
    guest = await client("guest"),
    outsider = await client("outsider");
  const trip = await create(owner);
  await guest.call("joinTrip", { shareCode: trip.shareCode });
  const participants = await getDocs(collection(owner.db, "trips", trip.tripId, "participants"));
  return { owner, guest, outsider, ...trip, ids: participants.docs.map((d) => d.id) };
}
function draft(ids: string[]) {
  return {
    title: "점심",
    category: "food",
    expenseDate: "2026-11-25",
    totalAmount: 3000,
    currency: "JPY",
    payer: { participantId: ids[0], amount: 3000 },
    consumers: ids,
    allocationMethod: "equal",
    allocatedAmounts: ids.map((participantId) => ({ participantId, amount: 1000 })),
    receiptItems: [],
    source: "manual",
  };
}
const audit = (uid: string) => ({
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  createdBy: uid,
  updatedBy: uid,
});
beforeAll(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-trip-split",
    firestore: { host: "127.0.0.1", port: 8080 },
  });
});
beforeEach(async () => {
  await environment.clearFirestore();
});
afterEach(async () => {
  await Promise.all(apps.splice(0).map(deleteApp));
});
afterAll(async () => {
  await environment.cleanup();
});

it("두 인증 클라이언트의 구독에 장소·일정·준비·설정과 지출 CRUD가 반영된다", async () => {
  const { owner, guest, tripId, ids } = await setup();
  const seen = new Map<string, Record<string, unknown>[]>();
  const errors: unknown[] = [];
  const stops = [
    "places",
    "itinerary",
    "reservations",
    "checklistItems",
    "expenses",
    "participants",
  ].map((name) =>
    onSnapshot(
      collection(guest.db, "trips", tripId, name),
      (snapshot) => {
        seen.set(
          name,
          snapshot.docs.map((d) => ({ id: d.id, ...d.data() })),
        );
      },
      (error) => errors.push(error),
    ),
  );
  stops.push(
    onSnapshot(
      doc(guest.db, "trips", tripId),
      (snapshot) => {
        seen.set("trip", [snapshot.data() ?? {}]);
      },
      (error) => errors.push(error),
    ),
  );
  const uid = owner.auth.currentUser!.uid;
  const reference = (name: string, id: string) => doc(owner.db, "trips", tripId, name, id);
  try {
    await expect.poll(() => seen.size).toBe(7);
    expect(guest.auth.currentUser!.uid).not.toBe(uid);
    await setDoc(reference("places", "sync-place"), {
      name: "동기화 장소",
      provider: "manual",
      source: "manual",
      lat: 35.7,
      lng: 139.7,
      addedBy: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(reference("itinerary", "sync-item"), {
      date: "2026-11-25",
      planId: "B",
      category: "activity",
      title: "시간 미정 일정",
      order: 0,
      placeId: "sync-place",
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });
    await setDoc(reference("reservations", "sync-reservation"), {
      title: "식당 예약",
      type: "other",
      status: "planned",
      ...audit(uid),
    });
    await setDoc(reference("checklistItems", "sync-checklist"), {
      title: "여권",
      scope: "personal",
      isDone: false,
      ...audit(uid),
    });
    await owner.call("linkMyParticipant", { tripId, participantId: ids[0] });
    await updateDoc(doc(owner.db, "trips", tripId), {
      title: "갱신된 여행",
      updatedAt: serverTimestamp(),
    });
    await expect.poll(() => seen.get("places")?.[0]?.name).toBe("동기화 장소");
    await expect.poll(() => seen.get("itinerary")?.[0]?.planId).toBe("B");
    await expect.poll(() => seen.get("reservations")?.[0]?.title).toBe("식당 예약");
    await expect.poll(() => seen.get("checklistItems")?.[0]?.scope).toBe("personal");
    await expect
      .poll(() => seen.get("participants")?.find((p) => p.id === ids[0])?.linkedUid)
      .toBe(uid);
    await expect.poll(() => seen.get("trip")?.[0]?.title).toBe("갱신된 여행");
    const saved = await owner.call<{ expense: { id: string } }>("createExpense", {
      tripId,
      draft: draft(ids),
    });
    await expect.poll(() => seen.get("expenses")?.[0]?.totalAmount).toBe(3000);
    await owner.call("updateExpense", {
      tripId,
      expenseId: saved.expense.id,
      draft: { ...draft(ids), title: "변경된 점심" },
    });
    await expect.poll(() => seen.get("expenses")?.[0]?.title).toBe("변경된 점심");
    await owner.call("deleteExpense", { tripId, expenseId: saved.expense.id });
    await expect.poll(() => seen.get("expenses")?.length).toBe(0);
    await updateDoc(reference("checklistItems", "sync-checklist"), {
      isDone: true,
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });
    await expect.poll(() => seen.get("checklistItems")?.[0]?.isDone).toBe(true);
    expect(errors).toEqual([]);
  } finally {
    stops.forEach((stop) => stop());
  }
});

it("내 여행 목록은 인증 UID만 사용하고 참여 전후 목록과 기존 멤버 UID 보정을 반영한다", async () => {
  const { owner, guest, outsider, tripId, shareCode } = await setup();
  expect(await outsider.call("listMyTrips", {})).toEqual({ trips: [] });
  const result = await guest.call<{ trips: { id: string; updatedAt: number }[] }>(
    "listMyTrips",
    {},
  );
  expect(result.trips.map((t) => t.id)).toEqual([tripId]);
  expect(typeof result.trips[0].updatedAt).toBe("number");
  await expect(
    outsider.call("listMyTrips", { uid: owner.auth.currentUser!.uid }),
  ).rejects.toMatchObject({ code: "functions/invalid-argument" });
  const member = doc(owner.db, "trips", tripId, "members", guest.auth.currentUser!.uid);
  await assertFails(updateDoc(member, { uid: owner.auth.currentUser!.uid }));
  await environment.withSecurityRulesDisabled(async (c) => {
    const ref = doc(c.firestore(), member.path);
    const data = (await getDoc(ref)).data()!;
    delete data.uid;
    await setDoc(ref, data);
  });
  await guest.call("joinTrip", { shareCode });
  expect((await getDoc(member)).data()?.uid).toBe(guest.auth.currentUser!.uid);
  const unauthenticated = await client("no-auth", false);
  await expect(unauthenticated.call("listMyTrips", {})).rejects.toMatchObject({
    code: "functions/unauthenticated",
  });
});

it("내 참여자 연결은 동시 경쟁에서도 하나의 계정만 소유하고 해제·재연결은 원자적이다", async () => {
  const { owner, guest, outsider, tripId, ids } = await setup();
  await owner.call("linkMyParticipant", { tripId, participantId: null });
  const results = await Promise.allSettled(
    [owner, guest].map((c) => c.call("linkMyParticipant", { tripId, participantId: ids[1] })),
  );
  expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
  const linked = (await getDoc(doc(owner.db, "trips", tripId, "participants", ids[1]))).data()!
    .linkedUid;
  const winner = linked === owner.auth.currentUser!.uid ? owner : guest;
  await winner.call("linkMyParticipant", { tripId, participantId: ids[2] });
  const rows = await getDocs(collection(owner.db, "trips", tripId, "participants"));
  expect(rows.docs.filter((d) => d.data().linkedUid === linked).map((d) => d.id)).toEqual([ids[2]]);
  await assertFails(
    updateDoc(doc(owner.db, "trips", tripId, "participants", ids[0]), {
      linkedUid: linked,
      updatedAt: serverTimestamp(),
    }),
  );
  await expect(
    outsider.call("linkMyParticipant", { tripId, participantId: ids[0] }),
  ).rejects.toMatchObject({ code: "functions/permission-denied" });
  await expect(
    winner.call("linkMyParticipant", { tripId, participantId: ids[0], uid: "another" }),
  ).rejects.toMatchObject({ code: "functions/invalid-argument" });
  await winner.call("linkMyParticipant", { tripId, participantId: null });
  expect(
    (await getDoc(doc(owner.db, "trips", tripId, "participants", ids[2]))).data(),
  ).not.toHaveProperty("linkedUid");
});

it("장소 검색·링크 후보는 멤버에게만 반환하고 임의 URL과 provider 불일치를 차단한다", async () => {
  const { owner, outsider, tripId } = await setup();
  const result = await owner.call<{ name: string; source: string }[]>("searchPlaces", {
    tripId,
    query: "우에노",
  });
  expect(result.length).toBeGreaterThan(0);
  expect(result.every((p) => p.source === "googleSearch")).toBe(true);
  expect(await owner.call("searchPlaces", { tripId, query: "존재하지않는후보" })).toEqual([]);
  expect(
    await owner.call("parsePlaceLink", {
      tripId,
      url: "https://www.google.com/maps/search/?api=1&query=우에노",
    }),
  ).toMatchObject({ source: "googleMapsUrl" });
  await expect(
    owner.call("parsePlaceLink", { tripId, url: "http://127.0.0.1/private" }),
  ).rejects.toMatchObject({ code: "functions/invalid-argument" });
  await expect(outsider.call("searchPlaces", { tripId, query: "우에노" })).rejects.toMatchObject({
    code: "functions/permission-denied",
  });
  await environment.withSecurityRulesDisabled(async (c) => {
    await updateDoc(doc(c.firestore(), "trips", tripId), { mapProvider: "naver" });
  });
  await expect(owner.call("searchPlaces", { tripId, query: "우에노" })).rejects.toMatchObject({
    code: "functions/invalid-argument",
  });
});

it("예약·체크리스트 Rules가 감사 정보·참조·권한을 검사하고 공동/개인 항목을 멤버에게 동기화한다", async () => {
  const { owner, guest, outsider, tripId, ids } = await setup();
  const uid = owner.auth.currentUser!.uid,
    guestUid = guest.auth.currentUser!.uid;
  const ref = doc(owner.db, "trips", tripId, "reservations", "hotel");
  await assertSucceeds(
    setDoc(ref, {
      title: "호텔 예약",
      type: "stay",
      status: "booked",
      url: "https://example.com/booking",
      ...audit(uid),
    }),
  );
  const original = (await getDoc(ref)).data()!;
  await assertSucceeds(
    updateDoc(doc(guest.db, ref.path), {
      status: "cancelled",
      updatedAt: serverTimestamp(),
      updatedBy: guestUid,
    }),
  );
  expect((await getDoc(ref)).data()?.createdAt).toEqual(original.createdAt);
  await assertFails(
    updateDoc(ref, { createdBy: guestUid, updatedBy: uid, updatedAt: serverTimestamp() }),
  );
  await assertFails(
    updateDoc(ref, { url: "javascript:alert(1)", updatedBy: uid, updatedAt: serverTimestamp() }),
  );
  await assertFails(
    updateDoc(ref, { itineraryItemId: "missing", updatedBy: uid, updatedAt: serverTimestamp() }),
  );
  await assertFails(getDoc(doc(outsider.db, ref.path)));
  await assertFails(deleteDoc(doc(outsider.db, ref.path)));
  const check = doc(owner.db, "trips", tripId, "checklistItems", "passport");
  await assertSucceeds(
    setDoc(check, {
      title: "여권 챙기기",
      scope: "personal",
      isDone: false,
      assigneeParticipantId: ids[1],
      ...audit(uid),
    }),
  );
  await assertSucceeds(getDoc(doc(guest.db, check.path)));
  await assertSucceeds(
    updateDoc(doc(guest.db, check.path), {
      isDone: true,
      updatedBy: guestUid,
      updatedAt: serverTimestamp(),
    }),
  );
  expect((await getDoc(check)).data()?.isDone).toBe(true);
  await assertFails(
    updateDoc(check, {
      assigneeParticipantId: "missing",
      updatedBy: uid,
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(owner.db, "trips", tripId, "checklistItems", "bad"), {
      title: "",
      scope: "shared",
      isDone: false,
      ...audit(uid),
    }),
  );
  await assertSucceeds(deleteDoc(ref));
  await assertSucceeds(deleteDoc(check));
});

it("지출 Callable 생성·편집·삭제가 두 멤버에게 보이고 직접 쓰기와 다른 여행 접근을 거부한다", async () => {
  const { owner, guest, outsider, tripId, ids } = await setup();
  const saved = await owner.call<{ expense: { id: string; createdAt: number; createdBy: string } }>(
    "createExpense",
    { tripId, draft: draft(ids) },
  );
  const ref = doc(guest.db, "trips", tripId, "expenses", saved.expense.id);
  expect(saved.expense.createdBy).toBe(owner.auth.currentUser!.uid);
  expect(typeof saved.expense.createdAt).toBe("number");
  expect((await getDoc(ref)).data()?.totalAmount).toBe(3000);
  await assertFails(updateDoc(ref, { totalAmount: 1 }));
  await assertFails(deleteDoc(ref));
  await assertFails(setDoc(doc(owner.db, "trips", tripId, "expenses", "direct"), draft(ids)));
  await expect(outsider.call("createExpense", { tripId, draft: draft(ids) })).rejects.toMatchObject(
    { code: "functions/permission-denied" },
  );
  await guest.call("updateExpense", {
    tripId,
    expenseId: saved.expense.id,
    draft: { ...draft(ids), title: "수정한 점심" },
  });
  expect((await getDoc(ref)).data()).toMatchObject({
    title: "수정한 점심",
    createdBy: owner.auth.currentUser!.uid,
    updatedBy: guest.auth.currentUser!.uid,
  });
  await guest.call("deleteExpense", { tripId, expenseId: saved.expense.id });
  await guest.call("deleteExpense", { tripId, expenseId: saved.expense.id });
  expect((await getDoc(ref)).exists()).toBe(false);
  await expect(
    guest.call("updateExpense", { tripId, expenseId: saved.expense.id, draft: draft(ids) }),
  ).rejects.toMatchObject({ code: "functions/not-found" });
});

it("기존 비활성 참여자 이력은 편집할 수 있고 새 지출·타 여행 참조·잘못된 배분은 저장하지 않는다", async () => {
  const { owner, tripId, ids } = await setup();
  const saved = await owner.call<{ expense: { id: string } }>("createExpense", {
    tripId,
    draft: draft(ids),
  });
  await updateDoc(doc(owner.db, "trips", tripId, "participants", ids[1]), {
    isActive: false,
    updatedAt: serverTimestamp(),
  });
  await owner.call("updateExpense", {
    tripId,
    expenseId: saved.expense.id,
    draft: { ...draft(ids), memo: "과거 이력 유지" },
  });
  await expect(owner.call("createExpense", { tripId, draft: draft(ids) })).rejects.toMatchObject({
    code: "functions/invalid-argument",
  });
  const other = await create(owner);
  await setDoc(doc(owner.db, "trips", other.tripId, "places", "foreign"), {
    name: "다른 여행 장소",
    provider: "manual",
    source: "manual",
    addedBy: owner.auth.currentUser!.uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  for (const patch of [
    { placeId: "foreign" },
    { itineraryItemId: "missing" },
    { allocatedAmounts: [{ participantId: ids[0], amount: 3000 }] },
    { createdBy: "spoof" },
  ]) {
    await expect(
      owner.call("updateExpense", {
        tripId,
        expenseId: saved.expense.id,
        draft: { ...draft(ids), ...patch },
      }),
    ).rejects.toMatchObject({ code: "functions/invalid-argument" });
  }
  const rows = await getDocs(collection(owner.db, "trips", tripId, "expenses"));
  expect(rows.size).toBe(1);
  expect(rows.docs[0].data()).toMatchObject({ memo: "과거 이력 유지", totalAmount: 3000 });
});

it("OCR는 검토 후보만 반환하고 항목별 합계 확인 후에만 지출에 반영한다", async () => {
  const { owner, outsider, tripId, ids } = await setup();
  const imageBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a1ioAAAAASUVORK5CYII=";
  const image = { tripId, imageBase64, mimeType: "image/png" };
  const parsed = await owner.call<{ items: unknown[]; warnings: string[] }>("parseReceipt", image);
  expect(parsed.items).toHaveLength(2);
  expect(parsed.warnings.join()).toContain("샘플");
  expect((await getDocs(collection(owner.db, "trips", tripId, "expenses"))).size).toBe(0);
  await expect(outsider.call("parseReceipt", image)).rejects.toMatchObject({
    code: "functions/permission-denied",
  });
  await expect(
    owner.call("parseReceipt", { ...image, mimeType: "image/jpeg" }),
  ).rejects.toMatchObject({ code: "functions/invalid-argument" });
  const receiptItems = [
    { id: "food", kind: "item", name: "식사", amount: 3300 },
    { id: "discount", kind: "discount", name: "할인", amount: -600 },
    { id: "service", kind: "serviceFee", name: "봉사료", amount: 300 },
  ].map((r, index) => ({
    ...r,
    consumers: ids,
    allocatedAmounts: ids.map((participantId) => ({ participantId, amount: r.amount / 3 })),
    allocationMethod: "equal",
    source: "ocr",
    sortOrder: index,
  }));
  const itemized = { ...draft(ids), allocationMethod: "itemized", source: "ocr", receiptItems };
  const saved = await owner.call<{ expense: { id: string; receiptItems: unknown[] } }>(
    "createExpense",
    { tripId, draft: itemized },
  );
  expect(saved.expense.receiptItems).toHaveLength(3);
  await expect(
    owner.call("updateExpense", {
      tripId,
      expenseId: saved.expense.id,
      draft: {
        ...itemized,
        receiptItems: [{ ...receiptItems[0], amount: 3200 }, ...receiptItems.slice(1)],
      },
    }),
  ).rejects.toMatchObject({ code: "functions/invalid-argument" });
  expect(
    (await getDoc(doc(owner.db, "trips", tripId, "expenses", saved.expense.id))).data()
      ?.totalAmount,
  ).toBe(3000);
});
