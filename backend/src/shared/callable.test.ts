import type { Firestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { describe, expect, it, vi } from "vitest";

import { appError, requireAuth, requireTripMember } from "./callable";

type CallableAuth = NonNullable<CallableRequest<unknown>["auth"]>;

const auth = { uid: "member-a", token: {} } as CallableAuth;

function request(requestAuth?: CallableAuth): CallableRequest<unknown> {
  return { auth: requestAuth } as CallableRequest<unknown>;
}

describe("Callable 공통 경계", () => {
  it("인증 정보를 그대로 반환한다", () => {
    expect(requireAuth(request(auth))).toBe(auth);
  });

  it("인증 정보가 없으면 공통 unauthenticated 오류를 반환한다", () => {
    expect(() => requireAuth(request())).toThrowError(
      expect.objectContaining({
        code: "unauthenticated",
        details: {
          appCode: "unauthenticated",
          retryable: false,
        },
      }),
    );
  });

  it("정확한 멤버 문서를 확인하고 인증 정보를 반환한다", async () => {
    const get = vi.fn().mockResolvedValue({ exists: true });
    const doc = vi.fn().mockReturnValue({ get });
    const db = { doc } as unknown as Firestore;

    await expect(requireTripMember(request(auth), "trip-a", db)).resolves.toBe(auth);
    expect(doc).toHaveBeenCalledOnce();
    expect(doc).toHaveBeenCalledWith("trips/trip-a/members/member-a");
    expect(get).toHaveBeenCalledOnce();
  });

  it("멤버가 아니면 여행 존재 여부를 드러내지 않고 거부한다", async () => {
    const db = {
      doc: vi.fn().mockReturnValue({
        get: vi.fn().mockResolvedValue({ exists: false }),
      }),
    } as unknown as Firestore;

    await expect(requireTripMember(request(auth), "trip-a", db)).rejects.toMatchObject({
      code: "permission-denied",
      details: {
        appCode: "permission-denied",
        retryable: false,
      },
    });
  });

  it("경로로 해석될 수 있는 tripId를 provider 호출 전에 거부한다", async () => {
    const doc = vi.fn();
    const db = { doc } as unknown as Firestore;

    await expect(requireTripMember(request(auth), "trip/a", db)).rejects.toMatchObject({
      code: "invalid-argument",
      details: expect.objectContaining({ field: "tripId" }),
    });
    expect(doc).not.toHaveBeenCalled();
  });

  it("멤버십 검사와 이후 사용 값이 달라지는 공백 tripId를 거부한다", async () => {
    const doc = vi.fn();
    const db = { doc } as unknown as Firestore;

    await expect(requireTripMember(request(auth), " trip-a ", db)).rejects.toMatchObject({
      code: "invalid-argument",
      details: expect.objectContaining({ field: "tripId" }),
    });
    expect(doc).not.toHaveBeenCalled();
  });

  it("앱 전용 OCR 오류와 재시도 정책을 details에 보존한다", () => {
    const error = appError("invalid-argument", "이미지를 확인해 주세요.", {
      appCode: "invalid-image",
      field: "image",
      details: { maxBytes: 5_242_880 },
    });

    expect(error.details).toEqual({
      maxBytes: 5_242_880,
      appCode: "invalid-image",
      retryable: false,
      field: "image",
    });
    expect(appError("unavailable", "잠시 후 다시 시도해 주세요.").details).toMatchObject({
      appCode: "unavailable",
      retryable: true,
    });
  });
});
