import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";

import { normalizeCreateTripInput } from "./tripInput";

const dates = {
  title: "도쿄 가을 여행",
  startDate: "2026-11-01",
  endDate: "2026-11-05",
};

describe("normalizeCreateTripInput", () => {
  it("Flutter canonical 입력을 정규화한다", () => {
    expect(
      normalizeCreateTripInput(
        {
          ...dates,
          countryCode: "jp",
          timeZone: "Asia/Tokyo",
          mapProvider: "google",
          defaultCurrency: "jpy",
          participantNames: [" 지민 ", "서연"],
        },
        "지민",
      ),
    ).toEqual({
      ...dates,
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
      participantNames: ["지민", "서연"],
    });
  });

  it("React legacy 입력을 canonical 기본값과 참여자 이름으로 바꾼다", () => {
    expect(
      normalizeCreateTripInput(
        {
          ...dates,
          regionType: "international",
          currency: "JPY",
          participantCount: 3,
        },
        "지민",
      ),
    ).toMatchObject({
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
      participantNames: ["지민", "동행 2", "동행 3"],
    });
  });

  it.each([
    [{ ...dates, countryCode: "JPN" }, "countryCode"],
    [{ ...dates, countryCode: "US" }, "timeZone"],
    [{ ...dates, timeZone: "Mars/Olympus" }, "timeZone"],
    [{ ...dates, mapProvider: "unknown" }, "mapProvider"],
    [{ ...dates, defaultCurrency: "YEN".repeat(30) }, "defaultCurrency"],
    [{ ...dates, participantNames: [] }, "participantNames"],
    [{ ...dates, participantNames: [" "] }, "participantNames"],
  ])("잘못된 canonical 입력의 %s 필드를 거부한다", (input, field) => {
    try {
      normalizeCreateTripInput(input, "지민");
      throw new Error("오류가 발생해야 합니다.");
    } catch (error) {
      expect(error).toBeInstanceOf(HttpsError);
      expect((error as HttpsError).details).toMatchObject({ field });
    }
  });
});
