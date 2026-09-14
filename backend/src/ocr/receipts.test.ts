import { expect, it } from "vitest";
import { receiptImageMaxBytes, validateReceiptImage } from "./receipts";

it("OCR 입력은 원본 크기·base64·MIME과 시그니처를 검증한다", () => {
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xd9]);
  expect(validateReceiptImage(jpeg.toString("base64"), "image/jpeg")).toEqual(jpeg);
  for (const [image, mime] of [
    ["", "image/jpeg"],
    ["%%%%", "image/png"],
    [jpeg.toString("base64"), "image/png"],
    [jpeg.toString("base64"), "image/heic"],
  ]) {
    expect(() => validateReceiptImage(image, mime)).toThrow();
  }
  expect(() =>
    validateReceiptImage(Buffer.alloc(receiptImageMaxBytes + 1).toString("base64"), "image/jpeg"),
  ).toThrow();
});
