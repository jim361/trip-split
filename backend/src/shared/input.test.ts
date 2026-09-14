import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";

import { requireDocumentId, requireLocalDate } from "./input";

describe("requireLocalDate", () => {
  it("실제로 존재하는 날짜만 허용한다", () => {
    expect(requireLocalDate({ startDate: "2028-02-29" }, "startDate")).toBe("2028-02-29");
  });

  it.each(["2026-02-29", "2026-02-30", "2026-13-01", "2026-00-10"])(
    "잘못된 달력 날짜 %s를 거부한다",
    (value) => {
      expect(() => requireLocalDate({ startDate: value }, "startDate")).toThrow(HttpsError);
    },
  );
});

describe("requireDocumentId", () => {
  it("공백을 제거한 단일 Firestore 문서 ID를 반환한다", () => {
    expect(requireDocumentId({ tripId: " trip-a " }, "tripId")).toBe("trip-a");
  });

  it("하위 경로로 해석될 수 있는 값을 거부한다", () => {
    expect(() => requireDocumentId({ tripId: "trip/a" }, "tripId")).toThrowError(
      expect.objectContaining({
        code: "invalid-argument",
        details: expect.objectContaining({ field: "tripId" }),
      }),
    );
  });
});
