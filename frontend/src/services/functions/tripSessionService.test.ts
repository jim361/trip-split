import { describe, expect, it } from "vitest";

import { mockTripRepositorySeed } from "../../test/fixtures/mockTripSeed";
import { TOKYO_TRIP_ID } from "../../test/fixtures/tokyoTrip";
import { createInMemoryTripRepositories } from "../mock";
import { MockTripSessionService, toFirebaseCreateTripPayload } from "./tripSessionService";

describe("MockTripSessionService", () => {
  it("adds legacy aliases only at the Firebase write boundary", () => {
    expect(
      toFirebaseCreateTripPayload({
        title: "도쿄 여행",
        startDate: "2026-11-25",
        endDate: "2026-12-01",
        countryCode: "JP",
        timeZone: "Asia/Tokyo",
        mapProvider: "google",
        defaultCurrency: "JPY",
      }),
    ).toMatchObject({
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
      regionType: "international",
      currency: "JPY",
    });
  });

  it("종료일이 시작일보다 빠른 여행을 거부한다", async () => {
    const service = new MockTripSessionService();

    await expect(
      service.createTrip({
        title: "잘못된 여행",
        startDate: "2026-12-02",
        endDate: "2026-12-01",
        countryCode: "JP",
        timeZone: "Asia/Tokyo",
        mapProvider: "google",
        defaultCurrency: "JPY",
      }),
    ).rejects.toMatchObject({ code: "invalid-argument", field: "endDate" });
  });

  it("도쿄 template 일정을 입력한 시작일로 옮기고 여행 기간 안에 유지한다", async () => {
    const repositories = createInMemoryTripRepositories(mockTripRepositorySeed, {
      getActorUid: () => "user-owner",
    });
    const service = new MockTripSessionService(repositories);

    await service.createTrip({
      title: "새해 도쿄 여행",
      startDate: "2027-01-03",
      endDate: "2027-01-03",
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
      participantCount: 2,
    });

    const snapshot = repositories.snapshot();
    const trip = snapshot.trips.find((item) => item.id === TOKYO_TRIP_ID);
    const itinerary = snapshot.itinerary.filter((item) => item.tripId === TOKYO_TRIP_ID);
    const activeParticipants = snapshot.participants.filter(
      (participant) => participant.tripId === TOKYO_TRIP_ID && participant.isActive,
    );

    expect(trip).toMatchObject({
      title: "새해 도쿄 여행",
      countryCode: "JP",
      timeZone: "Asia/Tokyo",
      mapProvider: "google",
      defaultCurrency: "JPY",
      startDate: "2027-01-03",
      endDate: "2027-01-03",
    });
    expect(new Set(itinerary.map((item) => item.date))).toEqual(new Set(["2027-01-03"]));
    expect(itinerary.map((item) => item.order)).toEqual([0, 1, 2, 3, 4, 5]);
    expect(activeParticipants).toHaveLength(2);
  });
});
