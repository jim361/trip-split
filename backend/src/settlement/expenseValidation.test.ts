import { describe, expect, it } from "vitest";
import { allocateEqual, validateExpenseDraft } from "./expenseValidation";

export const manualDraft = () => ({
  title: "점심",
  category: "food",
  expenseDate: "2026-11-25",
  totalAmount: 10000,
  currency: "JPY",
  payer: { participantId: "a", amount: 10000 },
  consumers: ["a", "b", "c"],
  allocationMethod: "equal",
  allocatedAmounts: allocateEqual(10000, ["a", "b", "c"]),
  receiptItems: [],
  source: "manual",
});

describe("expense wire validator", () => {
  it("소비자 순서에 따른 나머지와 0원 행을 보존한다", () => {
    expect(validateExpenseDraft(manualDraft()).allocatedAmounts.map((a) => a.amount)).toEqual([
      3334, 3333, 3333,
    ]);
    expect(allocateEqual(1, ["c", "a", "b"])).toEqual([
      { participantId: "c", amount: 1 },
      { participantId: "a", amount: 0 },
      { participantId: "b", amount: 0 },
    ]);
    expect(allocateEqual(-2, ["a", "b", "c"]).map((a) => a.amount)).toEqual([-1, -1, 0]);
  });
  it("금액·참조 형태·감사 정보·중복·배분 변조를 거부한다", () => {
    const bad = [
      { totalAmount: 0 },
      { totalAmount: 1.2 },
      { totalAmount: Number.MAX_SAFE_INTEGER + 1 },
      { currency: "USD" },
      { title: " " },
      { expenseDate: "2026-02-30" },
      { createdBy: "spoof" },
      { placeId: "trips/other" },
      { payer: { participantId: "a", amount: 9000 } },
      { consumers: ["a", "a", "b"] },
      {
        allocatedAmounts: [
          { participantId: "a", amount: 5000 },
          { participantId: "b", amount: 5000 },
        ],
      },
      {
        allocatedAmounts: [
          { participantId: "a", amount: 3333 },
          { participantId: "b", amount: 3334 },
          { participantId: "c", amount: 3333 },
        ],
      },
      { payer: { participantId: "a", amount: 10000, uid: "spoof" } },
      { allocationMethod: "itemized" },
      { source: "ocr" },
    ];
    for (const patch of bad)
      expect(() => validateExpenseDraft({ ...manualDraft(), ...patch })).toThrow();
  });
  it("항목·할인·봉사료의 합계와 참여자별 누적을 함께 검증한다", () => {
    const ids = ["a", "b", "c"];
    const rows = [
      { id: "meal", kind: "item", name: "식사", amount: 10000 },
      { id: "discount", kind: "discount", name: "할인", amount: -1000 },
      { id: "service", kind: "serviceFee", name: "봉사료", amount: 1000 },
    ].map((r, i) => ({
      ...r,
      consumers: ids,
      allocationMethod: "equal",
      allocatedAmounts: allocateEqual(r.amount, ids),
      source: "ocr",
      sortOrder: i,
    }));
    const draft = {
      ...manualDraft(),
      allocationMethod: "itemized",
      source: "ocr",
      receiptItems: rows,
    };
    expect(validateExpenseDraft(draft).receiptItems).toHaveLength(3);
    expect(() =>
      validateExpenseDraft({
        ...draft,
        receiptItems: [{ ...rows[0], amount: 9999 }, ...rows.slice(1)],
      }),
    ).toThrow();
    expect(() =>
      validateExpenseDraft({
        ...draft,
        receiptItems: [{ ...rows[0], sortOrder: 2 }, ...rows.slice(1)],
      }),
    ).toThrow();
    expect(() =>
      validateExpenseDraft({ ...draft, allocatedAmounts: allocateEqual(10000, ["c", "a", "b"]) }),
    ).toThrow();
  });
});
