import { getFirestore, type Firestore } from "firebase-admin/firestore";
import {
  HttpsError,
  type CallableRequest,
  type FunctionsErrorCode,
} from "firebase-functions/v2/https";

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

type AppErrorOptions = {
  appCode?: AppErrorCode;
  retryable?: boolean;
  field?: string;
  details?: Record<string, unknown>;
};

/** Callable 표준 code와 앱 전용 code를 함께 전달합니다. */
export function appError(
  httpsCode: FunctionsErrorCode,
  message: string,
  options: AppErrorOptions = {},
): HttpsError {
  const appCode = options.appCode ?? appCodeFromHttpsCode(httpsCode);
  const retryable =
    options.retryable ??
    (appCode === "unavailable" ||
      appCode === "resource-exhausted" ||
      appCode === "ocr-unavailable");

  return new HttpsError(httpsCode, message, {
    ...options.details,
    appCode,
    retryable,
    ...(options.field === undefined ? {} : { field: options.field }),
  });
}

export function requireAuth<T>(
  request: CallableRequest<T>,
): NonNullable<CallableRequest<T>["auth"]> {
  if (!request.auth) {
    throw appError("unauthenticated", "로그인 세션이 필요합니다.");
  }

  return request.auth;
}

/** 유료 provider 호출 전에 현재 사용자의 여행 멤버십을 확인합니다. */
export async function requireTripMember<T>(
  request: CallableRequest<T>,
  tripId: string,
  db: Firestore = getFirestore(),
): Promise<NonNullable<CallableRequest<T>["auth"]>> {
  const auth = requireAuth(request);
  const normalizedTripId = tripId.trim();

  if (
    tripId !== normalizedTripId ||
    normalizedTripId.length === 0 ||
    normalizedTripId.length > 160 ||
    normalizedTripId.includes("/")
  ) {
    throw appError("invalid-argument", "tripId 값을 확인해 주세요.", { field: "tripId" });
  }

  const member = await db.doc(`trips/${normalizedTripId}/members/${auth.uid}`).get();
  if (!member.exists) {
    throw appError("permission-denied", "이 여행의 멤버만 사용할 수 있습니다.");
  }

  return auth;
}

function appCodeFromHttpsCode(code: FunctionsErrorCode): AppErrorCode {
  switch (code) {
    case "unauthenticated":
    case "permission-denied":
    case "invalid-argument":
    case "not-found":
    case "resource-exhausted":
    case "unavailable":
      return code;
    case "already-exists":
    case "aborted":
    case "failed-precondition":
      return "conflict";
    case "deadline-exceeded":
      return "unavailable";
    default:
      return "unknown";
  }
}
