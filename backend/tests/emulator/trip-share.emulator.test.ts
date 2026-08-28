import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteApp, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, signInAnonymously, type Auth } from "firebase/auth";
import {
  collection,
  connectFirestoreEmulator,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  serverTimestamp,
  setDoc,
  updateDoc,
  type Firestore,
} from "firebase/firestore";
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
  type Functions,
} from "firebase/functions";
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "vitest";

const PROJECT_ID = "demo-trip-split";
const FIRESTORE_PORT = 8080;
const AUTH_PORT = 9099;
const FUNCTIONS_PORT = 5001;
const FUNCTIONS_REGION = "asia-northeast3";

type TestClient = {
  app: FirebaseApp;
  auth: Auth;
  firestore: Firestore;
  functions: Functions;
};

type CreateTripResult = { tripId: string; shareCode: string };
type JoinTripResult = { tripId: string; title: string; shareCode: string };

let rulesEnvironment: RulesTestEnvironment;
const apps: FirebaseApp[] = [];

function createClient(label: string): TestClient {
  const app = initializeApp(
    { projectId: PROJECT_ID, apiKey: "demo-api-key", authDomain: "localhost" },
    `${label}-${crypto.randomUUID()}`,
  );
  apps.push(app);

  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://127.0.0.1:${AUTH_PORT}`, { disableWarnings: true });

  const firestore = getFirestore(app);
  connectFirestoreEmulator(firestore, "127.0.0.1", FIRESTORE_PORT);

  const functions = getFunctions(app, FUNCTIONS_REGION);
  connectFunctionsEmulator(functions, "127.0.0.1", FUNCTIONS_PORT);

  return { app, auth, firestore, functions };
}

beforeAll(async () => {
  rulesEnvironment = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { host: "127.0.0.1", port: FIRESTORE_PORT },
  });
});

beforeEach(async () => {
  await rulesEnvironment.clearFirestore();
});

afterEach(async () => {
  await Promise.all(apps.splice(0).map((app) => deleteApp(app)));
});

afterAll(async () => {
  await rulesEnvironment.cleanup();
});

describe("trip share callable functions", () => {
  it("익명 사용자 두 명을 같은 여행의 editor member로 등록한다", async () => {
    const owner = createClient("owner");
    const guest = createClient("guest");
    const ownerCredential = await signInAnonymously(owner.auth);
    const createTrip = httpsCallable<
      {
        title: string;
        startDate: string;
        endDate: string;
        countryCode: string;
        timeZone: string;
        mapProvider: "google";
        defaultCurrency: string;
        participantNames: string[];
      },
      CreateTripResult
    >(owner.functions, "createTrip");

    const created = await createTrip({
      title: "도쿄 가을 여행",
      startDate: "2026-08-01",
      endDate: "2026-08-03",
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
      participantNames: ["지민", "서연", "민수"],
    });

    await rulesEnvironment.withSecurityRulesDisabled(async (context) => {
      const code = await getDoc(doc(context.firestore(), "shareCodes", created.data.shareCode));
      expect(code.data()).toMatchObject({
        tripId: created.data.tripId,
        isActive: true,
        useCount: 0,
      });
      expect(code.data()).not.toHaveProperty("expiresAt");
      expect(code.data()).not.toHaveProperty("maxUses");
    });

    await signInAnonymously(guest.auth);
    const joinTrip = httpsCallable<{ shareCode: string }, JoinTripResult>(
      guest.functions,
      "joinTrip",
    );
    const joined = await joinTrip({ shareCode: created.data.shareCode });
    await joinTrip({ shareCode: created.data.shareCode });

    expect(joined.data.tripId).toBe(created.data.tripId);
    expect(joined.data.title).toBe("도쿄 가을 여행");

    const ownerMember = await getDoc(
      doc(owner.firestore, "trips", created.data.tripId, "members", ownerCredential.user.uid),
    );
    const guestMember = await getDoc(
      doc(guest.firestore, "trips", created.data.tripId, "members", guest.auth.currentUser!.uid),
    );

    expect(ownerMember.data()?.role).toBe("editor");
    expect(guestMember.data()?.role).toBe("editor");

    await rulesEnvironment.withSecurityRulesDisabled(async (context) => {
      const firestore = context.firestore();
      const members = await getDocs(collection(firestore, "trips", created.data.tripId, "members"));
      const participants = await getDocs(
        collection(firestore, "trips", created.data.tripId, "participants"),
      );
      const trip = await getDoc(doc(firestore, "trips", created.data.tripId));
      const code = await getDoc(doc(firestore, "shareCodes", created.data.shareCode));
      const participantData = participants.docs.map((snapshot) => snapshot.data());
      expect(members.size).toBe(2);
      expect(participants.size).toBe(3);
      expect(trip.data()).toMatchObject({
        countryCode: "JP",
        timeZone: "Asia/Tokyo",
        mapProvider: "google",
        defaultCurrency: "JPY",
        regionType: "international",
        currency: "JPY",
      });
      expect(participantData).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            linkedUid: ownerCredential.user.uid,
            isActive: true,
          }),
        ]),
      );
      expect(participantData.filter((participant) => participant.isActive)).toHaveLength(3);
      expect(participantData.filter((participant) => participant.linkedUid)).toHaveLength(1);
      expect(participantData.map((participant) => participant.name)).toEqual(
        expect.arrayContaining(["지민", "서연", "민수"]),
      );
      expect(code.data()?.useCount).toBe(1);
    });
  });

  it("공유 코드를 재생성하면 이전 코드를 사용할 수 없다", async () => {
    const owner = createClient("owner-regenerate");
    await signInAnonymously(owner.auth);
    const createTrip = httpsCallable<
      { title: string; startDate: string; endDate: string },
      CreateTripResult
    >(owner.functions, "createTrip");
    const regenerate = httpsCallable<{ tripId: string }, CreateTripResult>(
      owner.functions,
      "createShareCode",
    );
    const created = await createTrip({
      title: "강릉 여행",
      startDate: "2026-08-01",
      endDate: "2026-08-02",
    });
    const nextCode = await regenerate({ tripId: created.data.tripId });

    expect(nextCode.data.shareCode).not.toBe(created.data.shareCode);

    await rulesEnvironment.withSecurityRulesDisabled(async (context) => {
      const firestore = context.firestore();
      const [oldCode, activeCode, trip] = await Promise.all([
        getDoc(doc(firestore, "shareCodes", created.data.shareCode)),
        getDoc(doc(firestore, "shareCodes", nextCode.data.shareCode)),
        getDoc(doc(firestore, "trips", created.data.tripId)),
      ]);
      expect(oldCode.data()?.isActive).toBe(false);
      expect(activeCode.data()).toMatchObject({ isActive: true, useCount: 0 });
      expect(activeCode.data()).not.toHaveProperty("expiresAt");
      expect(activeCode.data()).not.toHaveProperty("maxUses");
      expect(trip.data()?.shareCode).toBe(nextCode.data.shareCode);
    });

    const guest = createClient("guest-old-code");
    await signInAnonymously(guest.auth);
    const joinTrip = httpsCallable<{ shareCode: string }, JoinTripResult>(
      guest.functions,
      "joinTrip",
    );
    await expect(joinTrip({ shareCode: created.data.shareCode })).rejects.toMatchObject({
      code: "functions/not-found",
    });
    const guestRegenerate = httpsCallable<{ tripId: string }, CreateTripResult>(
      guest.functions,
      "createShareCode",
    );
    await expect(guestRegenerate({ tripId: created.data.tripId })).rejects.toMatchObject({
      code: "functions/permission-denied",
    });
  });

  it("인증하지 않은 사용자의 여행 생성과 참여를 거부한다", async () => {
    const client = createClient("unauthenticated");
    const createTrip = httpsCallable(client.functions, "createTrip");
    const joinTrip = httpsCallable(client.functions, "joinTrip");

    await expect(
      createTrip({ title: "거부", startDate: "2026-08-01", endDate: "2026-08-02" }),
    ).rejects.toMatchObject({ code: "functions/unauthenticated" });
    await expect(joinTrip({ shareCode: "ABCDEFGH" })).rejects.toMatchObject({
      code: "functions/unauthenticated",
    });
  });
});

describe("members based firestore rules", () => {
  const tripId = "rules-trip";
  const memberUid = "member-user";
  const outsiderUid = "outsider-user";

  beforeEach(async () => {
    await rulesEnvironment.withSecurityRulesDisabled(async (context) => {
      const firestore = context.firestore();
      const timestamp = new Date("2026-07-01T00:00:00.000Z");
      await setDoc(doc(firestore, "trips", tripId), {
        title: "규칙 테스트 해외여행",
        ownerUid: memberUid,
        countryCode: "JP",
        timeZone: "Asia/Tokyo",
        mapProvider: "google",
        defaultCurrency: "JPY",
        regionType: "international",
        currency: "JPY",
        shareCode: "RULES123",
        startDate: "2026-07-01",
        endDate: "2026-07-02",
        createdAt: timestamp,
        updatedAt: timestamp,
      });
      await setDoc(doc(firestore, "trips", tripId, "members", memberUid), {
        displayName: "멤버",
        role: "editor",
        joinedAt: timestamp,
        lastActiveAt: timestamp,
      });
      await setDoc(doc(firestore, "trips", tripId, "participants", "participant-1"), {
        name: "멤버",
        linkedUid: memberUid,
        isActive: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      });
      await setDoc(doc(firestore, "shareCodes", "RULES123"), {
        tripId,
        isActive: true,
      });
    });
  });

  it("멤버만 여행과 하위 도메인 데이터를 읽고 쓸 수 있다", async () => {
    const memberDb = rulesEnvironment.authenticatedContext(memberUid).firestore();
    const outsiderDb = rulesEnvironment.authenticatedContext(outsiderUid).firestore();

    await assertSucceeds(getDoc(doc(memberDb, "trips", tripId)));
    await assertSucceeds(
      setDoc(doc(memberDb, "trips", tripId, "places", "place-1"), {
        name: "센소지",
        address: "2 Chome-3-1 Asakusa, Tokyo",
        lat: 35.7148,
        lng: 139.7967,
        provider: "google",
        source: "googleSearch",
        addedBy: memberUid,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(getDoc(doc(outsiderDb, "trips", tripId)));

    for (const collectionName of ["participants", "places", "itinerary", "expenses"]) {
      await assertFails(getDoc(doc(outsiderDb, "trips", tripId, collectionName, "item")));
    }
  });

  it("장소 좌표와 provider/source 조합을 검증한다", async () => {
    const memberDb = rulesEnvironment.authenticatedContext(memberUid).firestore();
    const basePlace = {
      name: "도쿄 타워",
      provider: "google",
      source: "googleSearch",
      addedBy: memberUid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    await assertFails(
      setDoc(doc(memberDb, "trips", tripId, "places", "missing-lng"), {
        ...basePlace,
        lat: 35.6586,
      }),
    );
    await assertFails(
      setDoc(doc(memberDb, "trips", tripId, "places", "invalid-lat"), {
        ...basePlace,
        lat: 91,
        lng: 139.7454,
      }),
    );
    await assertFails(
      setDoc(doc(memberDb, "trips", tripId, "places", "mismatched-source"), {
        ...basePlace,
        provider: "manual",
      }),
    );
    await assertSucceeds(
      setDoc(doc(memberDb, "trips", tripId, "places", "manual-place"), {
        ...basePlace,
        provider: "manual",
        source: "manual",
      }),
    );
  });

  it("일정 시간과 선택적 장소 ID 형식을 검증한다", async () => {
    const memberDb = rulesEnvironment.authenticatedContext(memberUid).firestore();
    const baseItem = {
      date: "2026-11-25",
      title: "나리타 도착",
      order: 0,
      updatedBy: memberUid,
      updatedAt: serverTimestamp(),
    };

    await assertFails(
      setDoc(doc(memberDb, "trips", tripId, "itinerary", "invalid-time"), {
        ...baseItem,
        startTime: "9:30",
      }),
    );
    await assertFails(
      setDoc(doc(memberDb, "trips", tripId, "itinerary", "empty-place"), {
        ...baseItem,
        placeId: "",
      }),
    );
    await assertSucceeds(
      setDoc(doc(memberDb, "trips", tripId, "itinerary", "valid-item"), {
        ...baseItem,
        startTime: "09:30",
      }),
    );
  });

  it("canonical 필드와 감사 필드가 올바른 지출만 허용한다", async () => {
    const memberDb = rulesEnvironment.authenticatedContext(memberUid).firestore();
    const expenseRef = doc(memberDb, "trips", tripId, "expenses", "expense-1");

    await assertFails(setDoc(expenseRef, { totalAmount: 12_000 }));
    await assertFails(
      setDoc(expenseRef, {
        title: "점심",
        category: "식비",
        expenseDate: "2026-07-01",
        totalAmount: 12_000,
        currency: "JPY",
        payer: { participantId: "participant-1", amount: 12_000 },
        consumers: ["participant-1"],
        allocationMethod: "equal",
        allocatedAmounts: [{ participantId: "participant-1", amount: 12_000 }],
        receiptItems: [],
        source: "manual",
        createdBy: outsiderUid,
        updatedBy: outsiderUid,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      setDoc(expenseRef, {
        title: "점심",
        category: "식비",
        expenseDate: "2026-07-01",
        totalAmount: 12_000,
        currency: "JPY",
        payer: { participantId: "participant-1", amount: 12_000 },
        consumers: ["participant-1"],
        allocationMethod: "equal",
        allocatedAmounts: [{ participantId: "participant-1", amount: 12_000 }],
        receiptItems: [],
        source: "manual",
        createdBy: memberUid,
        updatedBy: memberUid,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("trip 불변 필드와 member role을 클라이언트에서 바꿀 수 없다", async () => {
    const memberDb = rulesEnvironment.authenticatedContext(memberUid).firestore();
    const tripRef = doc(memberDb, "trips", tripId);
    const memberRef = doc(memberDb, "trips", tripId, "members", memberUid);

    await assertSucceeds(
      updateDoc(tripRef, { title: "수정한 제목", updatedAt: serverTimestamp() }),
    );
    await assertFails(updateDoc(tripRef, { ownerUid: outsiderUid, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(tripRef, { countryCode: "KR", updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(memberRef, { role: "owner", lastActiveAt: serverTimestamp() }));
    await assertFails(
      setDoc(doc(memberDb, "trips", tripId, "members", "new-member"), {
        displayName: "직접 추가",
        role: "editor",
        joinedAt: serverTimestamp(),
        lastActiveAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(memberRef));
    await assertFails(deleteDoc(doc(memberDb, "trips", tripId, "participants", "participant-1")));
  });

  it("사용자는 자기 프로필만 canonical 형식으로 쓸 수 있다", async () => {
    const memberDb = rulesEnvironment
      .authenticatedContext(memberUid, {
        firebase: { sign_in_provider: "anonymous" },
      })
      .firestore();
    const profileRef = doc(memberDb, "users", memberUid);

    await assertSucceeds(
      setDoc(profileRef, {
        displayName: "멤버",
        authProvider: "anonymous",
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(memberDb, "users", outsiderUid), {
        displayName: "다른 사용자",
        authProvider: "anonymous",
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(profileRef, {
        authProvider: "google",
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("공유 코드 문서는 클라이언트에서 직접 읽을 수 없다", async () => {
    const memberDb = rulesEnvironment.authenticatedContext(memberUid).firestore();

    await assertFails(getDoc(doc(memberDb, "shareCodes", "RULES123")));
  });
});
