import { describe, expect, it } from "vitest";

import { toFirestoreAppError } from "./firestoreRepositories";

describe("toFirestoreAppError", () => {
  it("normalizes Firebase errors without exposing their raw message", () => {
    expect(
      toFirestoreAppError({
        code: "firestore/permission-denied",
        message: "sensitive backend detail",
      }),
    ).toEqual({
      code: "permission-denied",
      message: "이 여행 데이터에 접근할 권한이 없습니다.",
      retryable: false,
    });
  });

  it("marks temporary service failures as retryable", () => {
    expect(toFirestoreAppError({ code: "unavailable" })).toMatchObject({
      code: "unavailable",
      retryable: true,
    });
  });
});
