import { HttpsError } from "firebase-functions/v2/https";

export type UnknownRecord = Record<string, unknown>;

export function asRecord(value: unknown): UnknownRecord {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "요청 형식이 올바르지 않습니다.");
  }

  return value as UnknownRecord;
}

export function requireString(
  record: UnknownRecord,
  field: string,
  options: { minLength?: number; maxLength?: number } = {},
): string {
  const value = record[field];
  const minLength = options.minLength ?? 1;
  const maxLength = options.maxLength ?? 120;

  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} 값을 확인해 주세요.`, { field });
  }

  const normalized = value.trim();
  if (normalized.length < minLength || normalized.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} 길이를 확인해 주세요.`, { field });
  }

  return normalized;
}

export function optionalString(
  record: UnknownRecord,
  field: string,
  maxLength = 120,
): string | undefined {
  const value = record[field];

  if (value === undefined || value === null || value === "") {
    return undefined;
  }

  if (typeof value !== "string" || value.trim().length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} 값을 확인해 주세요.`, { field });
  }

  return value.trim();
}

export function requireLocalDate(record: UnknownRecord, field: string): string {
  const date = requireString(record, field, { minLength: 10, maxLength: 10 });
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);

  if (!match) {
    throw new HttpsError("invalid-argument", `${field} 날짜를 확인해 주세요.`, { field });
  }

  const [, yearText, monthText, dayText] = match;
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  const parsed = new Date(Date.UTC(year, month - 1, day));

  if (
    year < 2000 ||
    year > 2100 ||
    parsed.getUTCFullYear() !== year ||
    parsed.getUTCMonth() !== month - 1 ||
    parsed.getUTCDate() !== day
  ) {
    throw new HttpsError("invalid-argument", `${field} 날짜를 확인해 주세요.`, { field });
  }

  return date;
}
