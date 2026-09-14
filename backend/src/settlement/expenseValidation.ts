import { appError } from "../shared/callable";
import {
  asRecord,
  requireDocumentId,
  requireLocalDate,
  requireString,
  type UnknownRecord,
} from "../shared/input";

export type Allocation = { participantId: string; amount: number };
export type ReceiptItem = {
  id: string;
  kind: "item" | "discount" | "serviceFee" | "adjustment";
  name: string;
  amount: number;
  consumers: string[];
  allocationMethod: "equal" | "custom";
  allocatedAmounts: Allocation[];
  source: "ocr" | "manual";
  sortOrder: number;
};
export type ExpenseDraft = {
  title: string;
  category: string;
  expenseDate: string;
  totalAmount: number;
  currency: "KRW" | "JPY";
  payer: Allocation;
  consumers: string[];
  allocationMethod: "equal" | "custom" | "itemized";
  allocatedAmounts: Allocation[];
  receiptItems: ReceiptItem[];
  source: "manual" | "ocr";
  placeId?: string;
  itineraryItemId?: string;
  memo?: string;
};

function invalid(field: string, message = "지출 입력과 배분 합계를 확인해 주세요."): never {
  throw appError("invalid-argument", message, { field });
}
function keys(data: UnknownRecord, allowed: string[]) {
  if (Object.keys(data).some((key) => !allowed.includes(key)))
    invalid("draft", "허용되지 않은 지출 필드입니다.");
}
function money(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value))
    invalid(field, "금액은 안전한 범위의 정수로 입력해 주세요.");
  return value;
}
function sum(values: number[], field: string): number {
  return values.reduce((total, amount) => money(total + amount, field), 0);
}
function consumers(value: unknown, field: string): string[] {
  if (!Array.isArray(value) || value.length === 0 || value.length > 100) invalid(field);
  const ids = value.map((id) => requireDocumentId({ id }, "id"));
  if (new Set(ids).size !== ids.length) invalid(field, "같은 소비자를 중복 선택할 수 없습니다.");
  return ids;
}
export function allocateEqual(total: number, ids: string[]): Allocation[] {
  const base = Math.trunc(total / ids.length);
  const rest = total - base * ids.length;
  return ids.map((participantId, i) => ({
    participantId,
    amount: base + (i < Math.abs(rest) ? Math.sign(rest) : 0),
  }));
}
function allocations(
  value: unknown,
  ids: string[],
  total: number,
  method: string,
  signed: boolean,
): Allocation[] {
  if (!Array.isArray(value) || value.length !== ids.length) invalid("allocatedAmounts");
  const rows = value.map((v) => {
    const row = asRecord(v);
    keys(row, ["participantId", "amount"]);
    const participantId = requireDocumentId(row, "participantId");
    const amount = money(row.amount, "allocatedAmounts");
    if (
      !ids.includes(participantId) ||
      (!signed && amount < 0) ||
      (signed && amount !== 0 && Math.sign(amount) !== Math.sign(total))
    )
      invalid("allocatedAmounts");
    return { participantId, amount };
  });
  if (
    new Set(rows.map((r) => r.participantId)).size !== ids.length ||
    sum(
      rows.map((r) => r.amount),
      "allocatedAmounts",
    ) !== total
  )
    invalid("allocatedAmounts");
  if (
    method === "equal" &&
    allocateEqual(total, ids).some(
      (expected) =>
        rows.find((r) => r.participantId === expected.participantId)?.amount !== expected.amount,
    )
  )
    invalid("allocatedAmounts", "균등 배분은 표시한 소비자 순서로 나머지를 배분해야 합니다.");
  return rows;
}

export function validateExpenseDraft(value: unknown): ExpenseDraft {
  const input = asRecord(value);
  keys(input, [
    "title",
    "category",
    "expenseDate",
    "totalAmount",
    "currency",
    "payer",
    "consumers",
    "allocationMethod",
    "allocatedAmounts",
    "receiptItems",
    "source",
    "placeId",
    "itineraryItemId",
    "memo",
  ]);
  const totalAmount = money(input.totalAmount, "totalAmount");
  if (totalAmount <= 0) invalid("totalAmount", "총액은 0보다 커야 합니다.");
  if (input.currency !== "KRW" && input.currency !== "JPY") invalid("currency");
  if (input.source !== "manual" && input.source !== "ocr") invalid("source");
  if (
    input.allocationMethod !== "equal" &&
    input.allocationMethod !== "custom" &&
    input.allocationMethod !== "itemized"
  )
    invalid("allocationMethod");
  if (input.source === "ocr" && input.allocationMethod !== "itemized")
    invalid("source", "총액 등록은 수동 지출로 저장해 주세요.");
  const selected = consumers(input.consumers, "consumers");
  const payerInput = asRecord(input.payer);
  keys(payerInput, ["participantId", "amount"]);
  const payer = {
    participantId: requireDocumentId(payerInput, "participantId"),
    amount: money(payerInput.amount, "payer"),
  };
  if (payer.amount !== totalAmount) invalid("payer");
  const allocatedAmounts = allocations(
    input.allocatedAmounts,
    selected,
    totalAmount,
    input.allocationMethod,
    false,
  );
  if (!Array.isArray(input.receiptItems) || input.receiptItems.length > 200)
    invalid("receiptItems");
  if (
    input.allocationMethod === "itemized"
      ? input.receiptItems.length === 0
      : input.receiptItems.length !== 0
  )
    invalid("receiptItems");
  const receiptItems: ReceiptItem[] = input.receiptItems.map((raw, index) => {
    const item = asRecord(raw);
    keys(item, [
      "id",
      "kind",
      "name",
      "amount",
      "consumers",
      "allocationMethod",
      "allocatedAmounts",
      "source",
      "sortOrder",
    ]);
    const amount = money(item.amount, "receiptItems");
    const kind = item.kind;
    if (!(
      ((kind === "item" || kind === "serviceFee") && amount > 0) ||
      (kind === "discount" && amount < 0) ||
      (kind === "adjustment" && amount !== 0)
    ))
      invalid("receiptItems");
    if (item.allocationMethod !== "equal" && item.allocationMethod !== "custom")
      invalid("receiptItems");
    if (item.source !== "ocr" && item.source !== "manual") invalid("receiptItems");
    if (item.sortOrder !== index)
      invalid("receiptItems", "영수증 항목 순서는 0부터 연속이어야 합니다.");
    const ids = consumers(item.consumers, "receiptItems");
    if (ids.some((id) => !selected.includes(id))) invalid("receiptItems");
    return {
      id: requireDocumentId(item, "id"),
      name: requireString(item, "name", { maxLength: 160 }),
      kind: kind as ReceiptItem["kind"],
      amount,
      consumers: ids,
      allocationMethod: item.allocationMethod,
      source: item.source,
      sortOrder: index,
      allocatedAmounts: allocations(
        item.allocatedAmounts,
        ids,
        amount,
        item.allocationMethod,
        true,
      ),
    };
  });
  if (new Set(receiptItems.map((i) => i.id)).size !== receiptItems.length) invalid("receiptItems");
  if (input.allocationMethod === "itemized") {
    if (
      sum(
        receiptItems.map((i) => i.amount),
        "receiptItems",
      ) !== totalAmount
    )
      invalid("receiptItems", "항목과 조정 합계가 총액과 다릅니다.");
    for (const allocation of allocatedAmounts) {
      if (
        sum(
          receiptItems
            .flatMap((i) => i.allocatedAmounts)
            .filter((a) => a.participantId === allocation.participantId)
            .map((a) => a.amount),
          "allocatedAmounts",
        ) !== allocation.amount
      )
        invalid("allocatedAmounts");
    }
  }
  const result: ExpenseDraft = {
    title: requireString(input, "title", { maxLength: 160 }),
    category: requireString(input, "category", { maxLength: 80 }),
    expenseDate: requireLocalDate(input, "expenseDate"),
    totalAmount,
    currency: input.currency,
    payer,
    consumers: selected,
    allocationMethod: input.allocationMethod,
    allocatedAmounts,
    receiptItems,
    source: input.source,
  };
  for (const field of ["placeId", "itineraryItemId"] as const) {
    if (input[field] !== undefined) result[field] = requireDocumentId(input, field);
  }
  if (input.memo !== undefined) result.memo = requireString(input, "memo", { maxLength: 2000 });
  return result;
}
