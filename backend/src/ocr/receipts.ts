import { onCall } from "firebase-functions/v2/https";
import { appError, requireTripMember } from "../shared/callable";
import { asRecord, requireDocumentId } from "../shared/input";

export const receiptImageMaxBytes = 5 * 1024 * 1024;
export function validateReceiptImage(imageBase64: unknown, mimeType: unknown): Buffer {
  if (
    typeof imageBase64 !== "string" ||
    !["image/jpeg", "image/png", "image/webp"].includes(String(mimeType))
  ) {
    throw appError("invalid-argument", "JPEG/PNG/WebP 이미지를 선택해 주세요.", {
      appCode: "invalid-image",
      field: "mimeType",
    });
  }
  if (imageBase64.length > 4 * Math.ceil(receiptImageMaxBytes / 3))
    throw appError("invalid-argument", "이미지는 5 MiB 이하여야 합니다.", {
      appCode: "payload-too-large",
    });
  const bytes = Buffer.from(imageBase64, "base64");
  if (bytes.length > receiptImageMaxBytes)
    throw appError("invalid-argument", "이미지는 5 MiB 이하여야 합니다.", {
      appCode: "payload-too-large",
    });
  const valid =
    imageBase64.length > 0 &&
    bytes.toString("base64") === imageBase64 &&
    ((mimeType === "image/jpeg" &&
      bytes.length >= 4 &&
      bytes[0] === 0xff &&
      bytes[1] === 0xd8 &&
      bytes[2] === 0xff) ||
      (mimeType === "image/png" &&
        bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) ||
      (mimeType === "image/webp" &&
        bytes.length >= 12 &&
        bytes.toString("ascii", 0, 4) === "RIFF" &&
        bytes.toString("ascii", 8, 12) === "WEBP"));
  if (!valid)
    throw appError("invalid-argument", "이미지 형식과 내용을 확인해 주세요.", {
      appCode: "invalid-image",
    });
  return bytes;
}

export const parseReceipt = onCall(async (request) => {
  const input = asRecord(request.data);
  const tripId = requireDocumentId(input, "tripId");
  await requireTripMember(request, tripId);
  validateReceiptImage(input.imageBase64, input.mimeType);
  if (process.env.FUNCTIONS_EMULATOR !== "true")
    throw appError(
      "unavailable",
      "영수증 인식 연결이 준비되지 않았습니다. 수동 등록을 사용해 주세요.",
      { appCode: "ocr-unavailable", retryable: false },
    );
  // 외부 provider 승인 전에는 Emulator의 고정 fixture만 반환하며 이미지는 저장하지 않습니다.
  return {
    rawText: "浅草食堂\n2026年11月26日\n天ぷら定食 1,200円\n抹茶ラテ 550円\n合計 1,750円",
    sourceLanguage: "ja",
    merchantNameOriginal: "浅草食堂",
    merchantNameTranslated: "아사쿠사 식당",
    expenseDate: "2026-11-26",
    currencyCandidate: "JPY",
    totalAmountCandidate: 1750,
    items: [
      {
        nameOriginal: "天ぷら定食",
        nameTranslated: "튀김 정식",
        amount: 1200,
        confidence: 0.98,
        sourceOrder: 0,
      },
      {
        nameOriginal: "抹茶ラテ",
        nameTranslated: "말차 라테",
        amount: 550,
        confidence: 0.96,
        sourceOrder: 1,
      },
    ],
    warnings: [
      "Emulator 샘플 결과입니다. 실제 이미지 인식 결과가 아닙니다.",
      "번역과 금액을 원문 이미지에서 확인해 주세요.",
    ],
  };
});
