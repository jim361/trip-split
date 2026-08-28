import { HttpsError } from "firebase-functions/v2/https";

import { type UnknownRecord, requireLocalDate, requireString } from "../shared/input";

export type NormalizedCreateTripInput = {
  title: string;
  countryCode: string;
  timeZone: string;
  mapProvider: "google" | "naver";
  defaultCurrency: string;
  startDate: string;
  endDate: string;
  participantNames: string[];
};

function invalid(field: string, message: string): never {
  throw new HttpsError("invalid-argument", message, { field });
}

function normalizedCode(
  input: UnknownRecord,
  field: string,
  fallback: string,
  pattern: RegExp,
): string {
  const value = input[field] ?? fallback;
  if (typeof value !== "string" || !pattern.test(value.trim().toUpperCase())) {
    return invalid(field, `${field} 값을 확인해 주세요.`);
  }

  return value.trim().toUpperCase();
}

function normalizeTimeZone(value: unknown, fallback: string): string {
  if (value !== undefined && typeof value !== "string") {
    return invalid("timeZone", "timeZone 값을 확인해 주세요.");
  }

  const timeZone = typeof value === "string" ? value.trim() : fallback;
  if (timeZone.length < 1 || timeZone.length > 80) {
    return invalid("timeZone", "timeZone 값을 확인해 주세요.");
  }
  try {
    new Intl.DateTimeFormat("ko-KR", { timeZone }).format(0);
  } catch {
    return invalid("timeZone", "지원하지 않는 IANA 시간대입니다.");
  }

  return timeZone;
}

function normalizeParticipantNames(input: UnknownRecord, ownerDisplayName: string): string[] {
  if (input.participantNames !== undefined) {
    if (
      !Array.isArray(input.participantNames) ||
      input.participantNames.length < 1 ||
      input.participantNames.length > 20
    ) {
      return invalid("participantNames", "정산 인원은 1명부터 20명까지 설정할 수 있습니다.");
    }

    return input.participantNames.map((value) => {
      if (typeof value !== "string" || value.trim().length < 1 || value.trim().length > 80) {
        return invalid("participantNames", "참여자 이름은 1자부터 80자까지 입력해 주세요.");
      }
      return value.trim();
    });
  }

  const participantCount = input.participantCount ?? 1;
  if (
    typeof participantCount !== "number" ||
    !Number.isInteger(participantCount) ||
    participantCount < 1 ||
    participantCount > 20
  ) {
    return invalid("participantCount", "정산 인원은 1명부터 20명까지 설정할 수 있습니다.");
  }

  return Array.from({ length: participantCount }, (_, index) =>
    index === 0 ? ownerDisplayName : `동행 ${index + 1}`,
  );
}

/** [TASK-02] Flutter canonical 입력과 전환기 React 입력을 한 형태로 정규화합니다. */
export function normalizeCreateTripInput(
  input: UnknownRecord,
  ownerDisplayName: string,
): NormalizedCreateTripInput {
  const title = requireString(input, "title", { minLength: 1, maxLength: 80 });
  const startDate = requireLocalDate(input, "startDate");
  const endDate = requireLocalDate(input, "endDate");

  if (startDate > endDate) {
    return invalid("endDate", "종료일은 시작일보다 빠를 수 없습니다.");
  }

  const legacyRegionType = input.regionType;
  if (
    legacyRegionType !== undefined &&
    legacyRegionType !== "domestic" &&
    legacyRegionType !== "international"
  ) {
    return invalid("regionType", "지원하지 않는 여행 지역 유형입니다.");
  }

  const international = legacyRegionType === "international";
  const countryCode = normalizedCode(
    input,
    "countryCode",
    international ? "JP" : "KR",
    /^[A-Z]{2}$/,
  );
  const defaultTimeZone =
    countryCode === "KR" ? "Asia/Seoul" : countryCode === "JP" ? "Asia/Tokyo" : undefined;
  if (input.timeZone === undefined && defaultTimeZone === undefined) {
    return invalid("timeZone", "해당 국가의 IANA 시간대를 입력해 주세요.");
  }
  const timeZone = normalizeTimeZone(input.timeZone, defaultTimeZone ?? "UTC");
  const mapProviderValue = input.mapProvider ?? (countryCode === "KR" ? "naver" : "google");
  if (mapProviderValue !== "google" && mapProviderValue !== "naver") {
    return invalid("mapProvider", "지원하지 않는 지도 제공자입니다.");
  }

  if (
    input.defaultCurrency === undefined &&
    input.currency !== undefined &&
    typeof input.currency !== "string"
  ) {
    return invalid("currency", "currency 값을 확인해 주세요.");
  }
  const defaultCurrencyFallback =
    typeof input.currency === "string"
      ? input.currency
      : countryCode === "KR"
        ? "KRW"
        : countryCode === "JP"
          ? "JPY"
          : undefined;
  if (input.defaultCurrency === undefined && defaultCurrencyFallback === undefined) {
    return invalid("defaultCurrency", "기본 통화를 입력해 주세요.");
  }
  const defaultCurrency = normalizedCode(
    input,
    "defaultCurrency",
    defaultCurrencyFallback ?? "",
    /^[A-Z]{3}$/,
  );
  if (defaultCurrency !== "KRW" && defaultCurrency !== "JPY") {
    return invalid("defaultCurrency", "MVP에서는 KRW와 JPY 통화만 지원합니다.");
  }

  return {
    title,
    countryCode,
    timeZone,
    mapProvider: mapProviderValue,
    defaultCurrency,
    startDate,
    endDate,
    participantNames: normalizeParticipantNames(input, ownerDisplayName),
  };
}
