import { FirebaseError } from "firebase/app";

import {
  createAppError,
  isAppError,
  type AppError,
  type AppErrorCode,
} from "../../shared/contracts";

const CODE_MAP: Record<string, AppErrorCode> = {
  unauthenticated: "unauthenticated",
  "auth/user-token-expired": "unauthenticated",
  "auth/invalid-user-token": "unauthenticated",
  "permission-denied": "permission-denied",
  "firestore/permission-denied": "permission-denied",
  "functions/permission-denied": "permission-denied",
  "invalid-argument": "invalid-argument",
  "functions/invalid-argument": "invalid-argument",
  "not-found": "not-found",
  "functions/not-found": "not-found",
  "already-exists": "conflict",
  "auth/credential-already-in-use": "conflict",
  "auth/email-already-in-use": "conflict",
  "resource-exhausted": "resource-exhausted",
  "functions/resource-exhausted": "resource-exhausted",
  "auth/too-many-requests": "resource-exhausted",
  unavailable: "unavailable",
  "firestore/unavailable": "unavailable",
  "functions/unavailable": "unavailable",
  "auth/network-request-failed": "unavailable",
};

const MESSAGES: Record<AppErrorCode, string> = {
  unauthenticated: "로그인 세션이 필요합니다.",
  "permission-denied": "이 여행에 접근할 권한이 없습니다.",
  "invalid-argument": "입력값을 확인해 주세요.",
  "not-found": "요청한 데이터를 찾을 수 없습니다.",
  conflict: "이미 사용 중이거나 충돌한 데이터입니다.",
  "resource-exhausted": "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.",
  unavailable: "서비스에 연결할 수 없습니다. 네트워크를 확인해 주세요.",
  "invalid-image": "지원하지 않는 이미지입니다.",
  "payload-too-large": "이미지 크기가 너무 큽니다.",
  "ocr-unavailable": "영수증 인식 서비스를 사용할 수 없습니다.",
  "ocr-no-result": "영수증에서 항목을 찾지 못했습니다.",
  unknown: "알 수 없는 오류가 발생했습니다.",
};

function normalizeCode(code: string): AppErrorCode {
  return CODE_MAP[code] ?? CODE_MAP[code.replace(/^functions\//, "")] ?? "unknown";
}

export function mapFirebaseError(error: unknown): AppError {
  if (isAppError(error)) {
    return error;
  }

  const firebaseCode = error instanceof FirebaseError ? error.code : "unknown";
  const code = normalizeCode(firebaseCode);

  return createAppError(code, MESSAGES[code], {
    retryable: code === "unavailable" || code === "resource-exhausted",
    details: { source: "firebase", firebaseCode },
  });
}
