import { describe, expect, it, vi } from "vitest";

import {
  GANGNEUNG_TRIP_ID,
  gangneungFixtureIds,
  gangneungTripRepositorySeed,
} from "../../test/fixtures/gangneungTrip";
import { createInMemoryTripRepositories } from "./inMemoryTripRepositories";

describe("InMemoryTripRepositories", () => {
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
