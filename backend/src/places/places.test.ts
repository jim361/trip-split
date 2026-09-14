import { getFirestore, type Firestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { googleLinkQuery, parsePlaceLink, searchDemoPlaces, searchPlaces } from "./places";

vi.mock("firebase-admin/firestore", () => ({ getFirestore: vi.fn() }));

const station = {
  name: "우에노역",
  address: "Ueno, Taito City, Tokyo",
  lat: 35.7138,
  lng: 139.7773,
  provider: "google",
  source: "googleSearch",
};

function failure(code: string, field?: string) {
  return expect.objectContaining({
    code,
    details: { appCode: code, retryable: false, ...(field === undefined ? {} : { field }) },
  });
}

describe("Google 검색 후보", () => {
  it("이름·주소 검색은 공백과 대소문자를 정규화하고 정확한 후보를 반환한다", () => {
    expect(searchDemoPlaces("  우에노  ")).toEqual([
      station,
      {
        name: "우에노 숙소",
        address: "Taito City, Tokyo",
        lat: 35.711,
        lng: 139.779,
        provider: "google",
        source: "googleSearch",
      },
    ]);
    expect(searchDemoPlaces("  UENO  ")).toEqual([station]);
    expect(searchDemoPlaces("우에노역")).toEqual([station]);
    expect(searchDemoPlaces("없는 장소")).toEqual([]);
  });
});

describe("Google 링크 해석", () => {
  it.each([
    "https://maps.google.com/?q=",
    "https://maps.google.com/?query=",
    "https://google.com/maps?q=",
    "https://google.com/maps?query=",
    "https://www.google.com/maps/search/?api=1&q=",
    "https://www.google.com/maps/search/?api=1&query=",
    "https://maps.google.com:443/?q=",
    "https://www.google.com:443/maps?query=",
  ])("지원 호스트·경로·표준 HTTPS 포트에서 UTF-8 검색어를 해석한다: %s", (prefix) => {
    expect(googleLinkQuery(`${prefix}%20%EC%9A%B0%EC%97%90%EB%85%B8%20`)).toBe("우에노");
  });

  it.each([
    ["Ueno+Station", "Ueno Station"],
    ["Ueno%20Station", "Ueno Station"],
    ["%E4%B8%8A%E9%87%8E%E9%A7%85", "上野駅"],
    ["%2B%26%3D%23", "+&=#"],
    ["%2520", "%20"],
    ["우에노", "우에노"],
  ])("검색어를 한 번 디코딩한다: %s", (encoded, decoded) => {
    expect(googleLinkQuery(`https://maps.google.com/?q=${encoded}`)).toBe(decoded);
  });

  it("query가 있으면 q보다 우선하고 fragment는 검색어에 섞지 않는다", () => {
    expect(googleLinkQuery("https://google.com/maps?q=Narita&query=Ueno#ignored")).toBe("Ueno");
  });

  it.each([
    "not a URL",
    "https://maps.google.com/",
    "https://maps.google.com/?q=",
    "https://maps.google.com/?query=",
    "https://maps.google.com/?q=+%20%09",
    "https://maps.google.com/?query=%20&q=Ueno",
    "https://maps.google.com/#q=Ueno",
    "http://maps.google.com/?q=a",
    "http://maps.google.com:443/?q=a",
    "https://maps.google.com.evil.test/?q=a",
    "https://evilgoogle.com/maps?q=a",
    "https://127.0.0.1/?q=a",
    "https://[::1]/?q=a",
    "https://user@maps.google.com/?q=a",
    "https://user:password@maps.google.com/?q=a",
    "https://:password@maps.google.com/?q=a",
    "https://maps.google.com@evil.test/?q=a",
    "https://maps.app.goo.gl/short",
    "https://goo.gl/maps/short",
    "https://www.google.com/search?q=a",
    "https://google.com/maps-evil?q=a",
    "https://google.com/?q=a",
    "https://www.google.com/maps/place/Ueno",
    "https://maps.google.com:8080/?q=a",
    "https://google.com:80/maps?q=a",
    "https://www.google.com:444/maps?q=a",
  ])("미지원·빈 검색어·위장 URL은 sourceUrl 오류로 거부한다: %s", (url) => {
    expect(() => googleLinkQuery(url)).toThrowError(failure("invalid-argument", "sourceUrl"));
  });

  it("잘못된 링크의 원문·사용자 정보·검색어를 오류에 노출하지 않는다", () => {
    const url = "https://private-user:private-password@evil.test/?q=private-query";
    try {
      googleLinkQuery(url);
      expect.fail("잘못된 URL이 성공했다");
    } catch (error) {
      expect(error).toEqual(failure("invalid-argument", "sourceUrl"));
      const message = `${String(error)} ${JSON.stringify(error)}`;
      for (const value of [url, "private-user", "private-password", "private-query"])
        expect(message).not.toContain(value);
    }
  });
});

function request(data: unknown): CallableRequest<unknown> {
  return { data, auth: { uid: "member-a", token: {} } } as CallableRequest<unknown>;
}

describe.each([
  { name: "searchPlaces", handler: searchPlaces, input: { query: "우에노역" }, field: "query" },
  {
    name: "parsePlaceLink",
    handler: parsePlaceLink,
    input: { url: "https://maps.google.com/?q=%EC%9A%B0%EC%97%90%EB%85%B8%EC%97%AD" },
    field: "url",
  },
])("$name Callable 경계", ({ handler, input, field }) => {
  const memberGet = vi.fn();
  const tripGet = vi.fn();
  const doc = vi.fn();
  const externalFetch = vi.fn();
  const data = { tripId: "trip-a", ...input };

  beforeEach(() => {
    memberGet.mockReset().mockResolvedValue({ exists: true });
    tripGet.mockReset().mockResolvedValue({ data: () => ({ mapProvider: "google" }) });
    doc.mockReset().mockImplementation((path: string) => {
      if (path === "trips/trip-a/members/member-a") return { get: memberGet };
      if (path === "trips/trip-a") return { get: tripGet };
      throw new Error(`예상하지 않은 Firestore 경로: ${path}`);
    });
    vi.mocked(getFirestore).mockReturnValue({ doc } as unknown as Firestore);
    vi.stubEnv("FUNCTIONS_EMULATOR", "true");
    externalFetch.mockReset().mockRejectedValue(new Error("외부 연결은 IMB-02 범위 밖이다"));
    vi.stubGlobal("fetch", externalFetch);
  });

  afterEach(() => {
    try {
      expect(externalFetch).not.toHaveBeenCalled();
    } finally {
      vi.unstubAllEnvs();
      vi.unstubAllGlobals();
    }
  });

  it("실제 handler가 멤버 확인 뒤 기존 후보 wire를 반환한다", async () => {
    await expect(handler.run(request(data))).resolves.toEqual(
      field === "query" ? [station] : { ...station, source: "googleMapsUrl", sourceUrl: input.url },
    );
    expect(doc.mock.calls).toEqual([["trips/trip-a/members/member-a"], ["trips/trip-a"]]);
  });

  it("최대 길이는 trim 후 적용하고 한 글자 초과는 입력 필드 오류로 거부한다", async () => {
    const limit = field === "query" ? 160 : 2048;
    const value = field === "query" ? "x".repeat(limit) : `${input.url}#`.padEnd(limit, "x");
    expect(value).toHaveLength(limit);
    await expect(handler.run(request({ ...data, [field]: ` \t${value}\n ` }))).resolves.toEqual(
      field === "query" ? [] : { ...station, source: "googleMapsUrl", sourceUrl: value },
    );
    tripGet.mockClear();
    await expect(handler.run(request({ ...data, [field]: `${value}x` }))).rejects.toEqual(
      failure("invalid-argument", field),
    );
    expect(tripGet).not.toHaveBeenCalled();
  });

  it("최소 길이 1의 검색어를 허용하고 길이 1의 비URL은 해석 오류로 거부한다", async () => {
    if (field === "query") {
      await expect(handler.run(request({ ...data, query: "역" }))).resolves.toEqual([station]);
    } else {
      await expect(handler.run(request({ ...data, url: "x" }))).rejects.toEqual(
        failure("invalid-argument", "sourceUrl"),
      );
      expect(tripGet).not.toHaveBeenCalled();
    }
  });

  it.each([undefined, null, false, 42, "문자열 요청", []])(
    "객체가 아닌 요청을 거부한다: %j",
    async (value) => {
      await expect(handler.run(request(value))).rejects.toEqual(failure("invalid-argument"));
      expect(doc).not.toHaveBeenCalled();
    },
  );

  it.each([undefined, null, 1, [], {}, "", " \t "])(
    "문자열이 아닌 값과 빈 입력을 거부한다: %j",
    async (value) => {
      await expect(handler.run(request({ ...data, [field]: value }))).rejects.toEqual(
        failure("invalid-argument", field),
      );
      expect(tripGet).not.toHaveBeenCalled();
    },
  );

  it("미인증 요청은 저장소를 읽기 전에 거부한다", async () => {
    await expect(handler.run({ data } as CallableRequest<unknown>)).rejects.toEqual(
      failure("unauthenticated"),
    );
    expect(doc).not.toHaveBeenCalled();
  });

  it("비멤버는 provider를 확인하기 전에 거부한다", async () => {
    memberGet.mockResolvedValue({ exists: false });
    await expect(handler.run(request(data))).rejects.toEqual(failure("permission-denied"));
    expect(doc.mock.calls).toEqual([["trips/trip-a/members/member-a"]]);
    expect(tripGet).not.toHaveBeenCalled();
  });

  it.each(["naver", undefined])(
    "Google이 아닌 여행 provider를 거부한다: %s",
    async (mapProvider) => {
      tripGet.mockResolvedValue({ data: () => ({ mapProvider }) });
      await expect(handler.run(request(data))).rejects.toEqual(failure("invalid-argument"));
    },
  );

  it.each([undefined, "false", "TRUE", "1"])(
    "Emulator 밖에서는 후보 대신 재시도 불가 unavailable을 반환한다: %s",
    async (emulator) => {
      vi.stubEnv("FUNCTIONS_EMULATOR", emulator);
      await expect(handler.run(request(data))).rejects.toEqual(failure("unavailable"));
      expect(doc.mock.calls).toEqual([["trips/trip-a/members/member-a"], ["trips/trip-a"]]);
    },
  );
});
