/** UTC Unix epoch time in milliseconds. */
export type EpochMillis = number;

export function isEpochMillis(value: unknown): value is EpochMillis {
  return Number.isInteger(value) && Number(value) >= 0;
}

export function epochMillisFromDate(value: Date): EpochMillis {
  const epochMillis = value.getTime();

  if (!isEpochMillis(epochMillis)) {
    throw new RangeError("유효한 날짜가 아닙니다.");
  }

  return epochMillis;
}
