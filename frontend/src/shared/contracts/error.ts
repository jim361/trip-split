export type AppErrorCode =
  | "unauthenticated"
  | "permission-denied"
  | "invalid-argument"
  | "not-found"
  | "conflict"
  | "resource-exhausted"
  | "unavailable"
  | "invalid-image"
  | "payload-too-large"
  | "ocr-unavailable"
  | "ocr-no-result"
  | "unknown";

export type AppError = {
  code: AppErrorCode;
  message: string;
  retryable: boolean;
  field?: string;
  details?: Record<string, unknown>;
};

export function createAppError(
  code: AppErrorCode,
  message: string,
  options: Pick<AppError, "retryable"> & Partial<Pick<AppError, "field" | "details">>,
): AppError {
  return {
    code,
    message,
    retryable: options.retryable,
    ...(options.field === undefined ? {} : { field: options.field }),
    ...(options.details === undefined ? {} : { details: options.details }),
  };
}

export function isAppError(value: unknown): value is AppError {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const candidate = value as Partial<AppError>;
  return (
    typeof candidate.code === "string" &&
    typeof candidate.message === "string" &&
    typeof candidate.retryable === "boolean"
  );
}
