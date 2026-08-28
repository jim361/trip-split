const DEFAULT_SHARE_CODE_LENGTH = 8;

export const FUNCTIONS_REGION = process.env.FUNCTIONS_REGION ?? "asia-northeast3";

export function getShareCodeLength(): number {
  const parsed = Number.parseInt(process.env.SHARE_CODE_LENGTH ?? "", 10);

  if (!Number.isInteger(parsed) || parsed < 6 || parsed > 12) {
    return DEFAULT_SHARE_CODE_LENGTH;
  }

  return parsed;
}

export const functionSecretNames = {
  clovaOcr: "CLOVA_OCR_SECRET",
} as const;
