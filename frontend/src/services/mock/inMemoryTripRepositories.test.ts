import { describe, expect, it, vi } from "vitest";

import type { ItineraryCategory, ItineraryPlanId } from "../../shared/types";
import {
  GANGNEUNG_TRIP_ID,
  gangneungFixtureIds,
  gangneungTripRepositorySeed,
} from "../../test/fixtures/gangneungTrip";
import { createInMemoryTripRepositories } from "./inMemoryTripRepositories";

describe("InMemoryTripRepositories", () => {
  it("reads legacy items as A/other and preserves independent plan/category values", async () => {
    const seed = structuredClone(gangneungTripRepositorySeed);
    delete seed.itinerary[0].planId;
    delete seed.itinerary[0].category;
    const repositories = createInMemoryTripRepositories(seed, {
      getActorUid: () => gangneungFixtureIds.users.owner,
      idFactory: () => "new-plan-b",
    });
    const onData = vi.fn();
    const onError = vi.fn();
    const unsubscribe = repositories.itinerary.subscribeItinerary(
      GANGNEUNG_TRIP_ID,
      onData,
      onError,
    );
    expect(onData.mock.calls[0][0][0]).toMatchObject({ planId: "A", category: "other" });
    expect(repositories.snapshot()).toEqual(seed);

    const created = await repositories.itinerary.createItineraryItem(GANGNEUNG_TRIP_ID, {
      date: "2026-07-03",
      title: "비 오는 날 실내 일정",
      order: 0,
      planId: "B",
      category: "activity",
    });
    expect(created).toMatchObject({ planId: "B", category: "activity" });
    await repositories.itinerary.updateItineraryItem(GANGNEUNG_TRIP_ID, created.id, {
      title: "B안 카페",
      category: "meal",
    });
    expect(onData.mock.calls.at(-1)?.[0]).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ id: created.id, planId: "B", category: "meal" }),
        expect.objectContaining({ id: seed.itinerary[0].id, planId: "A", category: "other" }),
      ]),
    );
    expect(onError).not.toHaveBeenCalled();
    unsubscribe();
  });

  it("rejects invalid plan/category creates and updates without mutating the itinerary", async () => {
    const repositories = createInMemoryTripRepositories(gangneungTripRepositorySeed);
    const before = repositories.snapshot();
    for (const fields of [
      { planId: "C" as ItineraryPlanId },
      { category: "unknown" as ItineraryCategory },
    ]) {
      await expect(
        repositories.itinerary.createItineraryItem(GANGNEUNG_TRIP_ID, {
          date: "2026-07-03",
          title: "잘못된 입력",
          order: 0,
          ...fields,
        }),
      ).rejects.toMatchObject({ code: "invalid-argument", field: Object.keys(fields)[0] });
      await expect(
        repositories.itinerary.updateItineraryItem(
          GANGNEUNG_TRIP_ID,
          gangneungFixtureIds.itinerary.depart,
          fields,
        ),
      ).rejects.toMatchObject({ code: "invalid-argument", field: Object.keys(fields)[0] });
    }
    expect(repositories.snapshot()).toEqual(before);
  });

  it("publishes CRUD changes through the same realtime repository contract", async () => {
    const originalSeed = structuredClone(gangneungTripRepositorySeed);
    const onData = vi.fn();
    const onError = vi.fn();
    const repositories = createInMemoryTripRepositories(gangneungTripRepositorySeed, {
      getActorUid: () => gangneungFixtureIds.users.owner,
      now: () => 123_456,
      idFactory: () => "place-new",
    });

    const unsubscribe = repositories.places.subscribePlaces(GANGNEUNG_TRIP_ID, onData, onError);
    expect(onData).toHaveBeenCalledTimes(1);
    expect(onData.mock.calls[0][0]).toHaveLength(6);

    const created = await repositories.places.createPlace(GANGNEUNG_TRIP_ID, {
      name: "새 장소",
      provider: "manual",
      source: "manual",
      memo: "mock에서 추가",
    });
    expect(created).toMatchObject({
      id: "place-new",
      tripId: GANGNEUNG_TRIP_ID,
      addedBy: gangneungFixtureIds.users.owner,
      createdAt: 123_456,
      updatedAt: 123_456,
    });
    expect(onData.mock.calls.at(-1)?.[0]).toHaveLength(7);

    await repositories.places.updatePlace(GANGNEUNG_TRIP_ID, created.id, { memo: "수정됨" });
    expect(
      onData.mock.calls.at(-1)?.[0].find((place: { id: string }) => place.id === created.id),
    ).toMatchObject({ memo: "수정됨" });

    await repositories.places.deletePlace(GANGNEUNG_TRIP_ID, created.id);
    expect(onData.mock.calls.at(-1)?.[0]).toHaveLength(6);
    expect(onError).not.toHaveBeenCalled();

    unsubscribe();
    expect(repositories.snapshot()).toEqual(originalSeed);
  });

  it("blocks deleting a participant referenced by the expense ledger", async () => {
    const repositories = createInMemoryTripRepositories(gangneungTripRepositorySeed, {
      getActorUid: () => gangneungFixtureIds.users.owner,
    });

    await expect(
      repositories.participants.deleteParticipant(
        GANGNEUNG_TRIP_ID,
        gangneungFixtureIds.participants.me,
      ),
    ).rejects.toMatchObject({ code: "conflict", retryable: false });
  });

  it("injects the authenticated uid into newly created expenses", async () => {
    const repositories = createInMemoryTripRepositories(gangneungTripRepositorySeed, {
      getActorUid: () => gangneungFixtureIds.users.owner,
      now: () => 987_654,
      idFactory: () => "expense-new",
    });

    const expense = await repositories.expenses.createExpense(GANGNEUNG_TRIP_ID, {
      title: "주차비",
      category: "교통",
      expenseDate: "2026-07-04",
      totalAmount: 4_000,
      currency: "KRW",
      payer: {
        participantId: gangneungFixtureIds.participants.me,
        amount: 4_000,
      },
      consumers: [gangneungFixtureIds.participants.me],
      allocationMethod: "equal",
      allocatedAmounts: [
        {
          participantId: gangneungFixtureIds.participants.me,
          amount: 4_000,
        },
      ],
      receiptItems: [],
      source: "manual",
    });

    expect(expense).toMatchObject({
      id: "expense-new",
      createdBy: gangneungFixtureIds.users.owner,
      updatedBy: gangneungFixtureIds.users.owner,
      createdAt: 987_654,
      updatedAt: 987_654,
    });
  });

  it("deletes nullable itinerary fields instead of storing null", async () => {
    const repositories = createInMemoryTripRepositories(gangneungTripRepositorySeed, {
      getActorUid: () => gangneungFixtureIds.users.owner,
      now: () => 123_456,
    });

    await repositories.itinerary.updateItineraryItem(
      GANGNEUNG_TRIP_ID,
      gangneungFixtureIds.itinerary.depart,
      {
        endTime: "09:00",
        placeId: gangneungFixtureIds.places.terraRosa,
      },
    );
    await repositories.itinerary.updateItineraryItem(
      GANGNEUNG_TRIP_ID,
      gangneungFixtureIds.itinerary.depart,
      {
        startTime: null,
        endTime: null,
        placeId: null,
        memo: null,
      },
    );

    const updated = repositories
      .snapshot()
      .itinerary.find((item) => item.id === gangneungFixtureIds.itinerary.depart);
    expect(updated).toBeDefined();
    expect(updated).not.toHaveProperty("startTime");
    expect(updated).not.toHaveProperty("endTime");
    expect(updated).not.toHaveProperty("placeId");
    expect(updated).not.toHaveProperty("memo");
  });

  it("returns an AppError when a command has no authenticated actor", async () => {
    const repositories = createInMemoryTripRepositories(gangneungTripRepositorySeed, {
      getActorUid: () => null,
    });

    await expect(
      repositories.trips.updateTrip(GANGNEUNG_TRIP_ID, { title: "변경" }),
    ).rejects.toEqual({
      code: "unauthenticated",
      message: "로그인이 필요합니다.",
      retryable: false,
    });
  });
});
