import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";

import { requireLocalDate } from "./input";

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
