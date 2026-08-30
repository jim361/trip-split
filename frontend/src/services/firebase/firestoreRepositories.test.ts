import { deleteField, type Firestore } from "firebase/firestore";
import { describe, expect, it } from "vitest";

import type { ItineraryCategory, ItineraryPlanId } from "../../shared/types";
import { readItineraryPlanFields } from "../repositories/itineraryFields";
import {
  createFirestoreTripRepositories,
  readTripContractFields,
  toFirestoreAppError,
  toFirestoreItineraryUpdateData,
} from "./firestoreRepositories";

describe("toFirestoreAppError", () => {
  it("normalizes Firebase errors without exposing their raw message", () => {
    expect(
      toFirestoreAppError({
        code: "firestore/permission-denied",
        message: "sensitive backend detail",
      }),
    ).toEqual({
      code: "permission-denied",
      message: "이 여행 데이터에 접근할 권한이 없습니다.",
      retryable: false,
    });
  });

  it("marks temporary service failures as retryable", () => {
    expect(toFirestoreAppError({ code: "unavailable" })).toMatchObject({
      code: "unavailable",
      retryable: true,
    });
  });
});

describe("readTripContractFields", () => {
  it("reads canonical trip metadata", () => {
    expect(
      readTripContractFields({
        countryCode: "JP",
        timeZone: "Asia/Tokyo",
        mapProvider: "google",
        defaultCurrency: "JPY",
      }),
    ).toEqual({
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
    });
  });

  it("normalizes legacy trip metadata at the Firestore boundary", () => {
    expect(readTripContractFields({ regionType: "domestic", currency: "KRW" })).toEqual({
      countryCode: "KR",
      timeZone: "Asia/Seoul",
      mapProvider: "naver",
      defaultCurrency: "KRW",
    });
  });
});

describe("toFirestoreItineraryUpdateData", () => {
  it("preserves valid plan/category changes without assigning omitted fields", () => {
    expect(toFirestoreItineraryUpdateData({ planId: "B", category: "meal" })).toEqual({
      planId: "B",
      category: "meal",
    });
    expect(toFirestoreItineraryUpdateData({ title: "제목만 수정" })).toEqual({
      title: "제목만 수정",
    });
  });

  it("maps nullable itinerary fields to Firestore delete sentinels", () => {
    const data = toFirestoreItineraryUpdateData({
      title: "수정된 일정",
      startTime: null,
      endTime: null,
      placeId: null,
      memo: null,
    });

    expect(data.title).toBe("수정된 일정");
    expect(data.startTime).toEqual(deleteField());
    expect(data.endTime).toEqual(deleteField());
    expect(data.placeId).toEqual(deleteField());
    expect(data.memo).toEqual(deleteField());
  });
});

describe("itinerary plan/category boundary", () => {
  it("defaults only absent legacy fields to A/other", () => {
    expect(readItineraryPlanFields({})).toEqual({ planId: "A", category: "other" });
    expect(readItineraryPlanFields({ planId: "B", category: "flight" })).toEqual({
      planId: "B",
      category: "flight",
    });
    expect(() => readItineraryPlanFields({ planId: null })).toThrow();
    expect(() => readItineraryPlanFields({ category: "unknown" })).toThrow();
  });

  it("rejects invalid create/update values before contacting Firestore", async () => {
    const repositories = createFirestoreTripRepositories({} as Firestore, {
      getActorUid: () => "member",
    });
    for (const fields of [
      { planId: "C" as ItineraryPlanId },
      { category: "unknown" as ItineraryCategory },
    ]) {
      await expect(
        repositories.itinerary.createItineraryItem("trip", {
          date: "2026-11-25",
          title: "잘못된 입력",
          order: 0,
          ...fields,
        }),
      ).rejects.toMatchObject({ code: "invalid-argument", field: Object.keys(fields)[0] });
      await expect(
        repositories.itinerary.updateItineraryItem("trip", "item", fields),
      ).rejects.toMatchObject({ code: "invalid-argument", field: Object.keys(fields)[0] });
    }
  });
});
