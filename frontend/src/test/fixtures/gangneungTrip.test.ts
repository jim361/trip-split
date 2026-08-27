import { describe, expect, it } from "vitest";

import { GANGNEUNG_TRIP_ID, gangneungFixtureIds, gangneungTripFixture } from "./gangneungTrip";

describe("gangneungTripFixture", () => {
  it("uses stable IDs and the MVP share-code policy", () => {
    expect(gangneungTripFixture.trip.id).toBe(GANGNEUNG_TRIP_ID);
    expect(gangneungTripFixture.trip.shareCode).toBe(gangneungFixtureIds.shareCode);
    expect(gangneungTripFixture.shareCodes).toEqual([
      expect.objectContaining({
        code: gangneungFixtureIds.shareCode,
        isActive: true,
        useCount: 1,
      }),
    ]);
    expect(gangneungTripFixture.shareCodes[0]).not.toHaveProperty("expiresAt");
    expect(gangneungTripFixture.shareCodes[0]).not.toHaveProperty("maxUses");
  });

  it("contains canonical manual and itemized expenses with conserved totals", () => {
    expect(gangneungTripFixture.expenses.map((expense) => expense.source)).toEqual(
      expect.arrayContaining(["manual", "ocr"]),
    );

    for (const expense of gangneungTripFixture.expenses) {
      expect(expense.payer.amount).toBe(expense.totalAmount);
      expect(
        expense.allocatedAmounts.reduce((total, allocation) => total + allocation.amount, 0),
      ).toBe(expense.totalAmount);

      if (expense.allocationMethod === "itemized") {
        expect(expense.receiptItems.length).toBeGreaterThan(0);
        expect(expense.receiptItems.reduce((total, item) => total + item.amount, 0)).toBe(
          expense.totalAmount,
        );
      }
    }
  });

  it("matches the shared paid, owed and net settlement example", () => {
    const summary = Object.fromEntries(
      gangneungTripFixture.participants.map((participant) => [
        participant.id,
        { paid: 0, owed: 0, net: 0 },
      ]),
    );

    for (const expense of gangneungTripFixture.expenses) {
      summary[expense.payer.participantId].paid += expense.payer.amount;
      for (const allocation of expense.allocatedAmounts) {
        summary[allocation.participantId].owed += allocation.amount;
      }
    }

    for (const value of Object.values(summary)) {
      value.net = value.paid - value.owed;
    }

    expect(summary).toMatchObject({
      [gangneungFixtureIds.participants.me]: {
        paid: 33_000,
        owed: 62_000,
        net: -29_000,
      },
      [gangneungFixtureIds.participants.minsu]: {
        paid: 180_000,
        owed: 50_000,
        net: 130_000,
      },
      [gangneungFixtureIds.participants.jiyeon]: {
        paid: 0,
        owed: 56_000,
        net: -56_000,
      },
      [gangneungFixtureIds.participants.doyun]: {
        paid: 0,
        owed: 45_000,
        net: -45_000,
      },
    });
  });
});
