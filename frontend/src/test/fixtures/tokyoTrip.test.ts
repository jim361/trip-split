import { describe, expect, it } from "vitest";

import { TOKYO_TRIP_ID, tokyoFixtureIds, tokyoFlutterIdMap, tokyoTripFixture } from "./tokyoTrip";

describe("tokyoTripFixture", () => {
  it("uses the canonical trip contract without changing stable React IDs", () => {
    expect(tokyoTripFixture.trip).toMatchObject({
      id: TOKYO_TRIP_ID,
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
    });
    expect(tokyoTripFixture.trip).not.toHaveProperty("regionType");
    expect(tokyoTripFixture.trip).not.toHaveProperty("currency");
    expect(tokyoFlutterIdMap.ownerUid.react).toBe(tokyoFixtureIds.ownerUid);
    expect(tokyoFlutterIdMap.itinerary.arrival.react).toBe(tokyoFixtureIds.itinerary.flight);
    expect(tokyoFlutterIdMap.places.sensoji.react).toBe(tokyoFixtureIds.places.asakusa);
  });

  it("contains the Flutter-equivalent core places and itinerary values", () => {
    expect(tokyoTripFixture.places.map((place) => place.id)).toEqual(
      expect.arrayContaining([
        tokyoFixtureIds.places.narita,
        tokyoFixtureIds.places.ueno,
        tokyoFixtureIds.places.hotel,
        tokyoFixtureIds.places.asakusa,
      ]),
    );
    expect(tokyoTripFixture.itinerary).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: tokyoFixtureIds.itinerary.flight,
          startTime: "13:40",
          endTime: "14:30",
          title: "나리타 공항 도착",
        }),
        expect.objectContaining({
          id: tokyoFixtureIds.itinerary.ueno,
          startTime: "15:10",
          endTime: "16:00",
        }),
        expect.objectContaining({
          id: tokyoFixtureIds.itinerary.checkIn,
          startTime: "17:00",
          endTime: "17:30",
        }),
        expect.objectContaining({
          id: tokyoFixtureIds.itinerary.asakusa,
          startTime: "09:30",
          endTime: "11:30",
        }),
      ]),
    );
  });

  it("includes the conserved JPY dinner expense", () => {
    const [expense] = tokyoTripFixture.expenses;
    expect(expense).toMatchObject({
      id: tokyoFixtureIds.expenses.dinner,
      totalAmount: 4_500,
      currency: "JPY",
      allocationMethod: "equal",
    });
    expect(
      expense.allocatedAmounts.reduce((total, allocation) => total + allocation.amount, 0),
    ).toBe(expense.totalAmount);
  });
});
