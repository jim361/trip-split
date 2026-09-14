import { initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteApp, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, signInAnonymously } from "firebase/auth";
import { connectFirestoreEmulator, doc, getFirestore, updateDoc } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { afterAll, afterEach, beforeAll, beforeEach, expect, it } from "vitest";

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
  return { call, db };
}

type Client = Awaited<ReturnType<typeof client>>;

async function create(owner: Client) {
  return owner.call<{ tripId: string }>("createTrip", {
    title: "장소 Emulator 여행",
    startDate: "2026-11-25",
    endDate: "2026-11-27",
    countryCode: "JP",
    timeZone: "Asia/Tokyo",
    mapProvider: "google",
    defaultCurrency: "JPY",
    participantNames: ["하나"],
  });
}

async function expectError(
  promise: Promise<unknown>,
  code: string,
  field?: "query" | "url" | "tripId" | "sourceUrl",
) {
  await expect(promise).rejects.toMatchObject({
    code: `functions/${code}`,
    details: { appCode: code, retryable: false, ...(field ? { field } : {}) },
  });
}

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

it("실제 Callable SDK로 검색 배열과 링크 단일 후보를 정확한 fixture로 반환한다", async () => {
  const owner = await client("owner");
  const { tripId } = await create(owner);

  await expect(owner.call("searchPlaces", { tripId, query: "우에노" })).resolves.toEqual([
    {
      name: "우에노역",
      address: "Ueno, Taito City, Tokyo",
      lat: 35.7138,
      lng: 139.7773,
      provider: "google",
      source: "googleSearch",
    },
    {
      name: "우에노 숙소",
      address: "Taito City, Tokyo",
      lat: 35.711,
      lng: 139.779,
      provider: "google",
      source: "googleSearch",
    },
  ]);
  const url = "https://maps.google.com:443/?q=%EC%9A%B0%EC%97%90%EB%85%B8";
  await expect(owner.call("parsePlaceLink", { tripId, url })).resolves.toEqual({
    name: "우에노역",
    address: "Ueno, Taito City, Tokyo",
    lat: 35.7138,
    lng: 139.7773,
    provider: "google",
    source: "googleMapsUrl",
    sourceUrl: url,
  });
});

it("빈 검색과 링크 not-found를 구분하고 sourceUrl 오류 필드를 보존한다", async () => {
  const owner = await client("owner");
  const { tripId } = await create(owner);

  await expect(owner.call("searchPlaces", { tripId, query: "존재하지않는후보" })).resolves.toEqual(
    [],
  );
  await expectError(
    owner.call("parsePlaceLink", {
      tripId,
      url: "https://www.google.com/maps/search/?api=1&query=%EC%A1%B4%EC%9E%AC%ED%95%98%EC%A7%80%EC%95%8A%EB%8A%94%ED%9B%84%EB%B3%B4",
    }),
    "not-found",
    "sourceUrl",
  );
});

it("미인증과 비멤버는 두 Callable 모두 retryable=false으로 거부한다", async () => {
  const owner = await client("owner");
  const outsider = await client("outsider");
  const unauthenticated = await client("unauthenticated", false);
  const { tripId } = await create(owner);

  for (const member of [
    { client: unauthenticated, code: "unauthenticated" },
    { client: outsider, code: "permission-denied" },
  ]) {
    await expectError(member.client.call("searchPlaces", { tripId, query: "우에노" }), member.code);
    await expectError(
      member.client.call("parsePlaceLink", {
        tripId,
        url: "https://maps.google.com/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
      }),
      member.code,
    );
  }
});

it("요청 형식·필드 타입과 검색·링크 길이 경계를 Callable 오류 details로 반환한다", async () => {
  const owner = await client("owner");
  const { tripId } = await create(owner);
  const url2048 = "https://maps.google.com/?q=".padEnd(2048, "x");
  const url2049 = `${url2048}x`;

  await expectError(owner.call("searchPlaces", null), "invalid-argument");
  await expectError(owner.call("parsePlaceLink", []), "invalid-argument");
  await expectError(
    owner.call("searchPlaces", { tripId: 1, query: "우에노" }),
    "invalid-argument",
    "tripId",
  );
  await expectError(
    owner.call("parsePlaceLink", { tripId: "bad/id", url: "https://maps.google.com/?q=a" }),
    "invalid-argument",
    "tripId",
  );
  await expectError(owner.call("searchPlaces", { tripId, query: 1 }), "invalid-argument", "query");
  await expectError(owner.call("parsePlaceLink", { tripId, url: 1 }), "invalid-argument", "url");
  await expect(owner.call("searchPlaces", { tripId, query: "우" })).resolves.toHaveLength(2);
  await expect(owner.call("searchPlaces", { tripId, query: "x".repeat(160) })).resolves.toEqual([]);
  await expectError(
    owner.call("searchPlaces", { tripId, query: "x".repeat(161) }),
    "invalid-argument",
    "query",
  );
  expect(url2048).toHaveLength(2048);
  expect(url2049).toHaveLength(2049);
  await expectError(
    owner.call("parsePlaceLink", { tripId, url: url2048 }),
    "not-found",
    "sourceUrl",
  );
  await expectError(
    owner.call("parsePlaceLink", { tripId, url: url2049 }),
    "invalid-argument",
    "url",
  );
});

it("지원 Google q/query 인코딩과 표준 HTTPS 포트를 허용하고 비표준 URL을 차단한다", async () => {
  const owner = await client("owner");
  const { tripId } = await create(owner);
  const supportedUrls = [
    "https://maps.google.com/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://www.google.com/maps/search/?query=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://google.com/maps?query=%EC%9A%B0%EC%97%90%EB%85%B8",
  ];

  for (const url of supportedUrls) {
    await expect(
      owner.call<{ name: string; sourceUrl: string }>("parsePlaceLink", { tripId, url }),
    ).resolves.toMatchObject({
      name: "우에노역",
      source: "googleMapsUrl",
      sourceUrl: url,
    });
  }
  for (const url of [
    "http://maps.google.com/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://maps.google.com:8080/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://maps.google.com.evil.test/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://maps.app.goo.gl/short",
    "https://user@maps.google.com/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://www.google.com/search?query=%EC%9A%B0%EC%97%90%EB%85%B8",
    "https://maps.google.com/?q=",
  ]) {
    await expectError(
      owner.call("parsePlaceLink", { tripId, url }),
      "invalid-argument",
      "sourceUrl",
    );
  }
});

it("Google provider가 아닌 여행에서는 두 Callable 모두 입력 오류로 거부한다", async () => {
  const owner = await client("owner");
  const { tripId } = await create(owner);
  await environment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), "trips", tripId), { mapProvider: "naver" });
  });

  await expectError(owner.call("searchPlaces", { tripId, query: "우에노" }), "invalid-argument");
  await expectError(
    owner.call("parsePlaceLink", {
      tripId,
      url: "https://maps.google.com/?q=%EC%9A%B0%EC%97%90%EB%85%B8",
    }),
    "invalid-argument",
  );
});
