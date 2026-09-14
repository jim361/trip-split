import { initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteApp, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, signInAnonymously } from "firebase/auth";
import {
  collection,
  connectFirestoreEmulator,
  deleteDoc,
  deleteField,
  doc,
  getDocFromServer,
  getDocsFromServer,
  getFirestore,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
  increment,
  type DocumentReference,
  type Transaction,
} from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { afterAll, afterEach, beforeAll, beforeEach, expect, it } from "vitest";

let environment: RulesTestEnvironment;
const apps: FirebaseApp[] = [];

// 공용 테스트는 export가 없으므로 기존 SDK 초기화 패턴을 이 담당 파일 안에서 유지한다.
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
  const user = anonymous ? (await signInAnonymously(auth)).user : null;
  const call = async <T = Record<string, unknown>>(name: string, input: unknown): Promise<T> =>
    (await httpsCallable<unknown, T>(functions, name)(input)).data;
  return { db, uid: user?.uid ?? "", call };
}

type Client = Awaited<ReturnType<typeof client>>;
async function create(owner: Client) {
  return owner.call<{ tripId: string; shareCode: string }>("createTrip", {
    title: "IMB-03 참조 여행",
    startDate: "2026-11-25",
    endDate: "2026-11-27",
    countryCode: "JP",
    timeZone: "Asia/Tokyo",
    mapProvider: "google",
    defaultCurrency: "JPY",
    participantNames: ["하나", "둘"],
  });
}

async function setup() {
  const owner = await client("owner");
  const guest = await client("guest");
  const { tripId, shareCode } = await create(owner);
  await guest.call("joinTrip", { shareCode });
  const participants = await getDocsFromServer(
    collection(owner.db, "trips", tripId, "participants"),
  );
  const ref = (name: string, id: string, member = owner) =>
    doc(member.db, "trips", tripId, name, id);
  return { owner, guest, tripId, ref, participantId: participants.docs[0].id };
}

const updated = (uid: string) => ({ updatedAt: serverTimestamp(), updatedBy: uid });
const audit = (uid: string) => ({ createdAt: serverTimestamp(), createdBy: uid, ...updated(uid) });
const itinerary = (uid: string) => ({
  title: "장소 없는 일정",
  date: "2026-11-25",
  planId: "A",
  order: 0,
  ...updated(uid),
});
const place = (uid: string) => ({
  name: "수동 장소",
  provider: "manual",
  source: "manual",
  addedBy: uid,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});
const reservation = (uid: string) => ({
  title: "숙소 예약",
  type: "stay",
  status: "booked",
  ...audit(uid),
});
const checklist = (uid: string) => ({
  title: "여권",
  scope: "personal",
  isDone: false,
  ...audit(uid),
});

function response(result: PromiseSettledResult<unknown>) {
  return result.status === "fulfilled"
    ? { status: result.status, value: result.value }
    : { status: result.status, code: result.reason.code, details: result.reason.details };
}

async function state(ref: DocumentReference) {
  const snapshot = await getDocFromServer(ref);
  return snapshot.exists() ? snapshot.data() : null;
}

async function referenceWrite(source: DocumentReference, write: (tx: Transaction) => void) {
  const trip = source.parent.parent!;
  await runTransaction(source.firestore, async (tx) => {
    const snapshot = await tx.get(trip);
    tx.update(trip, {
      referenceVersion: (snapshot.get("referenceVersion") ?? 0) + 1,
      updatedAt: serverTimestamp(),
    });
    write(tx);
  });
}

async function removeTarget(member: Client, target: DocumentReference) {
  const field = target.parent.id === "places" ? "placeId" : "itineraryItemId";
  return member.call(target.parent.id === "places" ? "deletePlace" : "deleteItineraryItem", {
    tripId: target.parent.parent!.id,
    [field]: target.id,
  });
}

// 참조 중 삭제 거부를 적용한 뒤에도 각 응답과 최종 상태를 모두 확인한다.
async function expectIntegrity(
  label: string,
  results: PromiseSettledResult<unknown>[],
  source: DocumentReference,
  target: DocumentReference,
  field: string,
) {
  const [saved, linked] = await Promise.all([state(source), state(target)]);
  console.info(
    "IMB-D03",
    JSON.stringify({ label, responses: results.map(response), saved, linked }),
  );
  for (const result of results) {
    if (result.status === "rejected") {
      expect
        .soft(["permission-denied", "functions/failed-precondition"])
        .toContain(result.reason.code);
    }
  }
  expect
    .soft(saved?.[field] !== target.id || linked !== null, "삭제된 대상을 가리키는 참조")
    .toBe(true);
  return { saved, linked };
}

beforeAll(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-trip-split",
    firestore: { host: "127.0.0.1", port: 8080 },
  });
});

it.each(["itinerary", "reservations"] as const)(
  "기존 고아 %s는 일반 수정 거부 뒤 명시적 참조 해제로 복구한다",
  async (name) => {
    const { owner, ref } = await setup();
    const source = ref(name, "legacy");
    const field = name === "itinerary" ? "placeId" : "itineraryItemId";
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), source.path), {
        ...(name === "itinerary" ? itinerary(owner.uid) : reservation(owner.uid)),
        [field]: "missing",
      });
    });
    const before = await state(source);
    await expect(
      updateDoc(source, { title: "무관한 수정", ...updated(owner.uid) }),
    ).rejects.toMatchObject({ code: "permission-denied" });
    expect(await state(source)).toEqual(before);
    await referenceWrite(source, (tx) =>
      tx.update(source, { [field]: deleteField(), ...updated(owner.uid) }),
    );
    expect(await state(source)).not.toHaveProperty(field);
    await updateDoc(source, { title: "복구 완료", ...updated(owner.uid) });
    expect(await state(source)).toMatchObject({ title: "복구 완료" });
  },
);

it("서버도 손상되거나 소진된 참조 버전에서 대상을 삭제하지 않는다", async () => {
  const { owner, tripId, ref } = await setup();
  const target = ref("places", "target");
  await setDoc(target, place(owner.uid));
  const before = await state(target);
  for (const referenceVersion of [null, -1, "bad", 1.5, Number.MAX_SAFE_INTEGER]) {
    await environment.withSecurityRulesDisabled(async (context) => {
      await updateDoc(doc(context.firestore(), "trips", tripId), { referenceVersion });
    });
    await expect(removeTarget(owner, target)).rejects.toMatchObject({
      code: "functions/failed-precondition",
    });
    expect(await state(target)).toEqual(before);
  }
});

it("구형 여행의 참조 버전 0부터 연결하고 직접 연결·삭제·버전 변조를 거부한다", async () => {
  const { owner, guest, tripId, ref } = await setup();
  const trip = doc(owner.db, "trips", tripId);
  await environment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), trip.path), { referenceVersion: deleteField() });
  });
  const target = ref("places", "target");
  const source = ref("itinerary", "source");
  await setDoc(target, place(owner.uid));
  await setDoc(source, itinerary(owner.uid));
  await expect(
    updateDoc(source, { placeId: "target", ...updated(owner.uid) }),
  ).rejects.toMatchObject({ code: "permission-denied" });
  expect(await state(source)).not.toHaveProperty("placeId");
  await referenceWrite(source, (tx) =>
    tx.update(source, { placeId: "target", ...updated(owner.uid) }),
  );
  expect(await state(trip)).toHaveProperty("referenceVersion", 1);
  for (const referenceVersion of [-1, 0, 1.5, 12, deleteField()]) {
    await expect(
      updateDoc(trip, { referenceVersion, updatedAt: serverTimestamp() }),
    ).rejects.toMatchObject({ code: "permission-denied" });
    expect(await state(trip)).toHaveProperty("referenceVersion", 1);
  }
  await expect(deleteDoc(target)).rejects.toMatchObject({ code: "permission-denied" });
  await expect(deleteDoc(source)).rejects.toMatchObject({ code: "permission-denied" });
  await expect(removeTarget(guest, target)).rejects.toMatchObject({
    code: "functions/failed-precondition",
  });
  await removeTarget(guest, source);
  await removeTarget(guest, target);
  expect(await state(source)).toBeNull();
  expect(await state(target)).toBeNull();
});

it.each(["places", "itinerary"] as const)(
  "%s 삭제 Callable의 인증·멤버·ID·멱등성을 확인한다",
  async (name) => {
    const { owner, guest, tripId, ref } = await setup();
    const target = ref(name, "target");
    await setDoc(target, name === "places" ? place(owner.uid) : itinerary(owner.uid));
    const outsider = await client("outsider");
    const unauthenticated = await client("unauthenticated", false);
    for (const [member, code] of [
      [outsider, "permission-denied"],
      [unauthenticated, "unauthenticated"],
    ] as const) {
      await expect(removeTarget(member, target)).rejects.toMatchObject({
        code: `functions/${code}`,
      });
      expect(await state(target)).not.toBeNull();
    }
    const callable = name === "places" ? "deletePlace" : "deleteItineraryItem";
    const field = name === "places" ? "placeId" : "itineraryItemId";
    await expect(owner.call(callable, { tripId, [field]: "bad/id" })).rejects.toMatchObject({
      code: "functions/invalid-argument",
    });
    await expect(
      owner.call(callable, { tripId: "missing-trip", [field]: target.id }),
    ).rejects.toMatchObject({ code: "functions/permission-denied" });
    await expect(removeTarget(guest, target)).resolves.toEqual({ [field]: target.id });
    await expect(removeTarget(guest, target)).resolves.toEqual({ [field]: target.id });
    expect(await state(target)).toBeNull();
  },
);

it("연결된 예약 삭제·참조 교체는 이전 대상 삭제를 허용하고 새 대상을 계속 보호한다", async () => {
  const { owner, guest, ref } = await setup();
  const oldTarget = ref("itinerary", "old");
  const newTarget = ref("itinerary", "new");
  const source = ref("reservations", "reservation");
  await setDoc(oldTarget, itinerary(owner.uid));
  await setDoc(newTarget, itinerary(owner.uid));
  await referenceWrite(source, (tx) =>
    tx.set(source, { ...reservation(owner.uid), itineraryItemId: "old" }),
  );
  const auditBefore = await state(source);
  await referenceWrite(source, (tx) =>
    tx.update(source, { itineraryItemId: "new", ...updated(owner.uid) }),
  );
  expect((await state(source))?.createdAt).toEqual(auditBefore?.createdAt);
  await removeTarget(guest, oldTarget);
  await expect(removeTarget(guest, newTarget)).rejects.toMatchObject({
    code: "functions/failed-precondition",
  });
  await expect(deleteDoc(source)).rejects.toMatchObject({ code: "permission-denied" });
  await referenceWrite(source, (tx) => tx.delete(source));
  await removeTarget(guest, newTarget);
  expect(await state(source)).toBeNull();
  expect(await state(oldTarget)).toBeNull();
  expect(await state(newTarget)).toBeNull();
});

it.each(["placeId", "itineraryItemId"] as const)(
  "정산 %s 생성↔삭제 경합과 원장 삭제 후 대상 해제를 확인한다",
  async (field) => {
    const { owner, guest, tripId, ref, participantId } = await setup();
    const target = ref(field === "placeId" ? "places" : "itinerary", "race");
    await setDoc(target, field === "placeId" ? place(owner.uid) : itinerary(owner.uid));
    const draft = {
      title: "동시 저장",
      category: "food",
      expenseDate: "2026-11-25",
      totalAmount: 1000,
      currency: "JPY",
      payer: { participantId, amount: 1000 },
      consumers: [participantId],
      allocationMethod: "equal",
      allocatedAmounts: [{ participantId, amount: 1000 }],
      receiptItems: [],
      source: "manual",
      [field]: target.id,
    };
    const results = await Promise.allSettled([
      owner.call<{ expense: { id: string } }>("createExpense", { tripId, draft }),
      removeTarget(guest, target),
    ]);
    const rows = await getDocsFromServer(collection(owner.db, "trips", tripId, "expenses"));
    const targetState = await state(target);
    console.info(
      "IMB-D03 expense race",
      JSON.stringify({
        field,
        responses: results.map(response),
        targetState,
        expenses: rows.docs.map((row) => row.data()),
      }),
    );
    if (results[0].status === "fulfilled") {
      expect(results[1]).toMatchObject({
        status: "rejected",
        reason: { code: "functions/failed-precondition" },
      });
      expect(rows.size).toBe(1);
      expect(rows.docs[0].data()).toMatchObject(draft);
      expect(targetState).not.toBeNull();
      await owner.call("deleteExpense", { tripId, expenseId: results[0].value.expense.id });
      await removeTarget(guest, target);
    } else {
      expect(results[0].reason).toMatchObject({
        code: "functions/invalid-argument",
        details: { field },
      });
      expect(results[1]).toMatchObject({ status: "fulfilled" });
      expect(rows.empty).toBe(true);
      expect(targetState).toBeNull();
    }
    expect((await getDocsFromServer(collection(owner.db, "trips", tripId, "expenses"))).empty).toBe(
      true,
    );
    expect(await state(target)).toBeNull();
  },
);
beforeEach(async () => {
  await environment.clearFirestore();
});
afterEach(async () => {
  await Promise.all(apps.splice(0).map(deleteApp));
});
afterAll(async () => {
  await environment.cleanup();
});

it("장소 없는 일정과 같은 여행 장소 연결·해제를 상대 멤버의 서버 조회로 확인한다", async () => {
  const { owner, guest, ref } = await setup();
  const item = ref("itinerary", "item");
  await setDoc(item, itinerary(owner.uid));
  expect(await state(ref("itinerary", "item", guest))).not.toHaveProperty("placeId");
  await setDoc(ref("places", "place"), place(owner.uid));
  await referenceWrite(item, (tx) => tx.update(item, { placeId: "place", ...updated(owner.uid) }));
  expect(await state(ref("itinerary", "item", guest))).toMatchObject({ placeId: "place" });
  await referenceWrite(item, (tx) =>
    tx.update(item, { placeId: deleteField(), ...updated(owner.uid) }),
  );
  expect(await state(ref("itinerary", "item", guest))).not.toHaveProperty("placeId");
  await expect(removeTarget(guest, ref("places", "place"))).resolves.toEqual({ placeId: "place" });
  await expect(removeTarget(guest, item)).resolves.toEqual({ itineraryItemId: "item" });
  expect(await state(item)).toBeNull();
  expect(await state(ref("places", "place"))).toBeNull();
});

it.each([
  ["create", "missing"],
  ["update", "missing"],
  ["create", "foreign"],
  ["update", "foreign"],
] as const)("없는/타 여행 장소를 거부한다: %s %s", async (operation, targetId) => {
  const { owner, guest, ref } = await setup();
  if (targetId === "foreign") {
    const foreign = await create(owner);
    await setDoc(doc(owner.db, "trips", foreign.tripId, "places", targetId), place(owner.uid));
  }
  const item = ref("itinerary", "item");
  if (operation === "update") await setDoc(item, itinerary(owner.uid));
  const before = await state(item);
  const [result] = await Promise.allSettled([
    referenceWrite(item, (tx) => {
      if (operation === "create") tx.set(item, { ...itinerary(owner.uid), placeId: targetId });
      else tx.update(item, { placeId: targetId, ...updated(owner.uid) });
    }),
  ]);
  const saved = await state(ref("itinerary", "item", guest));
  console.info(
    "IMB-D03",
    JSON.stringify({ operation, targetId, response: response(result), saved }),
  );
  expect.soft(result).toMatchObject({ status: "rejected", reason: { code: "permission-denied" } });
  expect.soft(saved).toEqual(before);
  expect(await state(ref("places", targetId))).toBeNull();
});

it.each(["reservations", "checklistItems"] as const)(
  "%s는 미연결·연결·해제를 허용하고 없는/타 여행/UID 참조의 생성·수정을 거부한다",
  async (name) => {
    const { owner, guest, ref, participantId } = await setup();
    const field = name === "reservations" ? "itineraryItemId" : "assigneeParticipantId";
    const targetCollection = name === "reservations" ? "itinerary" : "participants";
    const validId = name === "reservations" ? "item" : participantId;
    const draft = name === "reservations" ? reservation(owner.uid) : checklist(owner.uid);
    await setDoc(ref("itinerary", "item"), itinerary(owner.uid));
    const foreign = await create(owner);
    await setDoc(
      doc(owner.db, "trips", foreign.tripId, targetCollection, "foreign"),
      name === "reservations"
        ? itinerary(owner.uid)
        : {
            name: "외부 참여자",
            isActive: true,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
          },
    );
    const source = ref(name, "source");
    await setDoc(source, draft);
    await referenceWrite(source, (tx) =>
      tx.update(source, { [field]: validId, ...updated(owner.uid) }),
    );
    expect(await state(ref(name, "source", guest))).toMatchObject({ [field]: validId });
    const before = await state(source);
    for (const id of ["missing", "foreign", owner.uid]) {
      for (const operation of ["create", "update"]) {
        const failed = operation === "create" ? ref(name, "bad") : source;
        await expect(
          referenceWrite(failed, (tx) => {
            if (operation === "create") tx.set(failed, { ...draft, [field]: id });
            else tx.update(failed, { [field]: id, ...updated(owner.uid) });
          }),
        ).rejects.toMatchObject({ code: "permission-denied" });
        expect(await state(failed)).toEqual(operation === "create" ? null : before);
      }
    }
    await referenceWrite(source, (tx) =>
      tx.update(source, { [field]: deleteField(), ...updated(owner.uid) }),
    );
    expect(await state(ref(name, "source", guest))).not.toHaveProperty(field);
  },
);

for (const kind of ["place", "reservation"] as const) {
  it.each(["link-first", "delete-first", "parallel", "batch"] as const)(
    `IMB-D03 ${kind} 연결↔삭제 뒤 고아 참조가 없어야 한다: %s`,
    async (schedule) => {
      const { owner, guest, ref } = await setup();
      const isPlace = kind === "place";
      const target = ref(isPlace ? "places" : "itinerary", "target");
      const source = ref(isPlace ? "itinerary" : "reservations", "source");
      const field = isPlace ? "placeId" : "itineraryItemId";
      await setDoc(target, isPlace ? place(owner.uid) : itinerary(owner.uid));
      await setDoc(source, isPlace ? itinerary(owner.uid) : reservation(owner.uid));
      const peerTarget = doc(guest.db, target.path);
      const link = () =>
        referenceWrite(source, (tx) =>
          tx.update(source, { [field]: target.id, ...updated(owner.uid) }),
        );
      const remove = () => removeTarget(guest, peerTarget);
      let results: PromiseSettledResult<unknown>[];
      if (schedule === "batch") {
        const batch = writeBatch(owner.db);
        batch.update(source.parent.parent!, {
          referenceVersion: increment(1),
          updatedAt: serverTimestamp(),
        });
        batch.update(source, { [field]: target.id, ...updated(owner.uid) });
        batch.delete(target);
        results = await Promise.allSettled([batch.commit()]);
        expect(results[0]).toMatchObject({
          status: "rejected",
          reason: { code: "permission-denied" },
        });
      } else if (schedule === "parallel") {
        results = await Promise.allSettled([link(), remove()]);
        expect(results.filter((result) => result.status === "fulfilled")).toHaveLength(1);
      } else {
        const first = schedule === "link-first" ? link : remove;
        const second = schedule === "link-first" ? remove : link;
        results = [
          ...(await Promise.allSettled([first()])),
          ...(await Promise.allSettled([second()])),
        ];
      }
      const { saved, linked } = await expectIntegrity(
        `${kind}/${schedule}`,
        results,
        doc(guest.db, source.path),
        peerTarget,
        field,
      );
      // 응답과 최종 상태의 대응을 확인한다. 경합의 승자 자체는 고정하지 않는다.
      const linkResult = results[schedule === "delete-first" ? 1 : 0];
      const deleteResult = results[schedule === "link-first" ? 1 : schedule === "parallel" ? 1 : 0];
      if (deleteResult.status === "fulfilled") expect.soft(linked).toBeNull();
      if (linkResult.status === "rejected") expect.soft(saved).not.toHaveProperty(field);
      if (linked !== null && linkResult.status === "fulfilled") {
        expect.soft(saved?.[field]).toBe(target.id);
      }
      expect.soft(saved).toMatchObject({ title: isPlace ? "장소 없는 일정" : "숙소 예약" });
      if (schedule === "link-first") {
        expect(results[0]).toMatchObject({ status: "fulfilled" });
        expect(results[1]).toMatchObject({
          status: "rejected",
          reason: {
            code: "functions/failed-precondition",
            details: {
              appCode: "conflict",
              retryable: false,
              field: isPlace ? "placeId" : "itineraryItemId",
            },
          },
        });
      }
      if (schedule === "delete-first") {
        expect(results[0]).toMatchObject({ status: "fulfilled" });
        expect(results[1]).toMatchObject({
          status: "rejected",
          reason: { code: "permission-denied" },
        });
      }
    },
  );
}

it("참여자 물리 삭제는 연결 전·후·동시·batch에서 거부하고 personal은 다른 멤버도 읽고 수정한다", async () => {
  const { owner, guest, ref, participantId } = await setup();
  const target = ref("participants", participantId, guest);
  const source = ref("checklistItems", "passport");
  await expect(deleteDoc(target)).rejects.toMatchObject({ code: "permission-denied" });
  const results = await Promise.allSettled([
    setDoc(source, { ...checklist(owner.uid), assigneeParticipantId: participantId }),
    deleteDoc(target),
  ]);
  await expectIntegrity(
    "checklist/delete-parallel",
    results,
    source,
    target,
    "assigneeParticipantId",
  );
  expect(results[0]).toMatchObject({ status: "fulfilled" });
  expect(results[1]).toMatchObject({ status: "rejected", reason: { code: "permission-denied" } });
  await expect(deleteDoc(target)).rejects.toMatchObject({ code: "permission-denied" });
  const before = await state(source);
  const batch = writeBatch(owner.db);
  batch.update(source, { isDone: true, ...updated(owner.uid) });
  batch.delete(ref("participants", participantId));
  await expect(batch.commit()).rejects.toMatchObject({ code: "permission-denied" });
  expect(await state(source)).toEqual(before);
  const changes = await Promise.allSettled([
    updateDoc(target, { name: "새 이름", isActive: false, updatedAt: serverTimestamp() }),
    updateDoc(ref("checklistItems", "passport", guest), { isDone: true, ...updated(guest.uid) }),
  ]);
  expect(changes.map(response)).toEqual([
    { status: "fulfilled", value: undefined },
    { status: "fulfilled", value: undefined },
  ]);
  expect(await state(target)).toMatchObject({ name: "새 이름", isActive: false });
  expect(await state(source)).toMatchObject({
    scope: "personal",
    isDone: true,
    assigneeParticipantId: participantId,
    createdBy: owner.uid,
    updatedBy: guest.uid,
  });
  // 존재하는 비활성 참여자는 현재 준비 계약에서 유효하다. 신규 지출의 활성 제약과 다르다.
  await setDoc(ref("checklistItems", "inactive"), {
    ...checklist(owner.uid),
    assigneeParticipantId: participantId,
  });
  expect(await state(ref("checklistItems", "inactive", guest))).toMatchObject({
    assigneeParticipantId: participantId,
  });
  const outsider = await client("outsider");
  await expect(getDocFromServer(doc(outsider.db, source.path))).rejects.toMatchObject({
    code: "permission-denied",
  });
});

it.each(["add", "delete", "date", "plan", "incoming-date", "incoming-plan"] as const)(
  "JS 읽기 집합 모사(실제 Dart 아님): 재정렬 도중 %s의 응답·최종 상태를 확인한다",
  async (change) => {
    const { owner, guest, ref } = await setup();
    const a = ref("itinerary", "a");
    const b = ref("itinerary", "b");
    const c = ref("itinerary", "c");
    await setDoc(a, { ...itinerary(owner.uid), title: "a", order: 10 });
    await setDoc(b, { ...itinerary(owner.uid), title: "b", order: 20 });
    if (change.startsWith("incoming")) {
      await setDoc(c, {
        ...itinerary(owner.uid),
        title: "c",
        order: 0,
        date: change === "incoming-date" ? "2026-11-26" : "2026-11-25",
        planId: change === "incoming-plan" ? "B" : "A",
      });
    }
    const beforeA = await state(a);
    const read = Promise.withResolvers<void>();
    const resume = Promise.withResolvers<void>();
    let attempts = 0;
    // FirestoreTripRepositories.reorderItineraryItems의 문서 읽기/검사/쓰기 범위만 모사한다.
    // ponytail: Dart SDK·오프라인·UI 동작은 모사하지 않으며 실제 Flutter 통합 검사로 보완한다.
    const reorder = runTransaction(owner.db, async (transaction) => {
      attempts += 1;
      const references = [b, a];
      for (const reference of references) {
        const snapshot = await transaction.get(reference);
        if (!snapshot.exists())
          throw Object.assign(new Error("삭제된 일정"), { code: "not-found" });
        const data = snapshot.data();
        if (data.date !== "2026-11-25" || (data.planId ?? "A") !== "A") {
          throw Object.assign(new Error("이동된 일정"), { code: "conflict" });
        }
      }
      if (attempts === 1) {
        read.resolve();
        await resume.promise;
      }
      references.forEach((reference, order) => {
        transaction.update(reference, { order, ...updated(owner.uid) });
      });
    });
    const resultPromise = Promise.allSettled([reorder]);
    // 첫 읽기 전에 오류가 나면 무기한 gate를 기다리지 않고 원인을 보고한다.
    await Promise.race([read.promise, reorder]);
    let mutation: PromiseSettledResult<unknown>[];
    try {
      const peer = doc(guest.db, (change.startsWith("incoming") || change === "add" ? c : b).path);
      mutation = await Promise.allSettled([
        change === "add"
          ? setDoc(peer, { ...itinerary(guest.uid), title: "c", order: 0 })
          : change === "delete"
            ? removeTarget(guest, peer)
            : updateDoc(peer, {
                ...(change === "date"
                  ? { date: "2026-11-26" }
                  : change === "plan"
                    ? { planId: "B" }
                    : { date: "2026-11-25", planId: "A" }),
                ...updated(guest.uid),
              }),
      ]);
    } finally {
      resume.resolve();
    }
    const [result] = await resultPromise;
    const [savedA, savedB, savedC] = await Promise.all([state(a), state(b), state(c)]);
    console.info(
      "IMB-D03 reorder",
      JSON.stringify({
        change,
        attempts,
        mutation: mutation.map(response),
        result: response(result),
        savedA,
        savedB,
        savedC,
      }),
    );
    expect(mutation[0]).toMatchObject({ status: "fulfilled" });
    if (["delete", "date", "plan"].includes(change)) {
      expect(result).toMatchObject({
        status: "rejected",
        // Raw JS SDK의 오류이며 Dart repository의 notFound 변환은 Flutter에서 별도 검증한다.
        reason: { code: change === "delete" ? "permission-denied" : "conflict" },
      });
      if (change === "delete") expect(attempts).toBe(1);
      else expect(attempts).toBeGreaterThanOrEqual(2);
      expect(savedA).toEqual(beforeA);
      if (change === "delete") expect(savedB).toBeNull();
      else
        expect(savedB).toMatchObject({
          order: 20,
          updatedBy: guest.uid,
          ...(change === "date" ? { date: "2026-11-26" } : { planId: "B" }),
        });
      expect(savedC).toBeNull();
    } else {
      expect(result).toMatchObject({ status: "fulfilled" });
      expect(savedA).toMatchObject({ title: "a", date: "2026-11-25", planId: "A", order: 1 });
      expect(savedB).toMatchObject({ title: "b", date: "2026-11-25", planId: "A", order: 0 });
      expect(savedC).toMatchObject({
        title: "c",
        date: "2026-11-25",
        planId: "A",
        order: 0,
        updatedBy: guest.uid,
      });
    }
  },
);

it.each(["placeId", "itineraryItemId"] as const)(
  "IMB-D03 정산 %s 저장 후 대상 삭제에도 참조 무결성이 유지되어야 한다",
  async (field) => {
    const { owner, guest, tripId, ref, participantId } = await setup();
    const target = ref(field === "placeId" ? "places" : "itinerary", "target");
    await setDoc(target, field === "placeId" ? place(owner.uid) : itinerary(owner.uid));
    const draft = {
      title: "점심",
      category: "food",
      expenseDate: "2026-11-25",
      totalAmount: 1000,
      currency: "JPY",
      payer: { participantId, amount: 1000 },
      consumers: [participantId],
      allocationMethod: "equal",
      allocatedAmounts: [{ participantId, amount: 1000 }],
      receiptItems: [],
      source: "manual",
      [field]: target.id,
    };
    const saved = await owner.call<{ expense: { id: string } }>("createExpense", { tripId, draft });
    const expense = ref("expenses", saved.expense.id);
    expect(await state(expense)).toMatchObject(draft);
    const results = await Promise.allSettled([removeTarget(guest, target)]);
    const final = await expectIntegrity(`expense/${field}`, results, expense, target, field);
    expect(results[0]).toMatchObject({
      status: "rejected",
      reason: {
        code: "functions/failed-precondition",
        details: { field, appCode: "conflict", retryable: false },
      },
    });
    expect(final.saved).toMatchObject(draft);
    expect(final.linked).not.toBeNull();
    const detached = { ...draft };
    delete detached[field];
    await owner.call("updateExpense", { tripId, expenseId: saved.expense.id, draft: detached });
    expect(await state(expense)).not.toHaveProperty(field);
    await expect(removeTarget(guest, target)).resolves.toEqual({ [field]: target.id });
    expect(await state(target)).toBeNull();
    const afterDetach = await state(expense);
    {
      await expect(
        owner.call("updateExpense", { tripId, expenseId: saved.expense.id, draft }),
      ).rejects.toMatchObject({
        code: "functions/invalid-argument",
        details: { field, retryable: false },
      });
      expect(await state(expense)).toEqual(afterDetach);
      await expect(owner.call("createExpense", { tripId, draft })).rejects.toMatchObject({
        code: "functions/invalid-argument",
        details: { field, retryable: false },
      });
      expect(
        (await getDocsFromServer(collection(owner.db, "trips", tripId, "expenses"))).size,
      ).toBe(1);
    }
  },
);
