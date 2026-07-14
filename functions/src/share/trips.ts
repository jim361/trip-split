import type { DecodedIdToken } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest, onCall } from "firebase-functions/v2/https";

import { FUNCTIONS_REGION } from "../shared/env";
import { asRecord, optionalString, requireLocalDate, requireString } from "../shared/input";
import { generateShareCode, isValidShareCode, normalizeShareCode } from "./shareCode";

const MAX_CODE_GENERATION_ATTEMPTS = 8;

class ShareCodeCollisionError extends Error {}

function requireAuth(request: CallableRequest<unknown>) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인 세션이 필요합니다.");
  }

  return request.auth;
}

function getDisplayName(token: DecodedIdToken, uid: string, requestedName?: string): string {
  const tokenName = typeof token.name === "string" ? token.name.trim() : "";
  return requestedName || tokenName || `여행자 ${uid.slice(0, 6)}`;
}

function getAuthProvider(token: DecodedIdToken): "anonymous" | "google" {
  return token.firebase?.sign_in_provider === "google.com" ? "google" : "anonymous";
}

function isExpired(expiresAt: unknown): boolean | null {
  if (expiresAt === undefined) {
    return false;
  }

  if (expiresAt instanceof Timestamp) {
    return expiresAt.toMillis() <= Date.now();
  }

  if (typeof expiresAt === "number" && Number.isFinite(expiresAt)) {
    return expiresAt <= Date.now();
  }

  return null;
}

export const createTrip = onCall({ region: FUNCTIONS_REGION, cors: true }, async (request) => {
  const auth = requireAuth(request);
  const input = asRecord(request.data);
  const title = requireString(input, "title", { minLength: 1, maxLength: 80 });
  const startDate = requireLocalDate(input, "startDate");
  const endDate = requireLocalDate(input, "endDate");
  const requestedDisplayName = optionalString(input, "displayName", 40);

  if (startDate > endDate) {
    throw new HttpsError("invalid-argument", "종료일은 시작일보다 빠를 수 없습니다.", {
      field: "endDate",
    });
  }

  const db = getFirestore();
  const tripRef = db.collection("trips").doc();
  const memberRef = tripRef.collection("members").doc(auth.uid);
  const userRef = db.collection("users").doc(auth.uid);
  const displayName = getDisplayName(auth.token, auth.uid, requestedDisplayName);

  for (let attempt = 0; attempt < MAX_CODE_GENERATION_ATTEMPTS; attempt += 1) {
    const code = generateShareCode();
    const codeRef = db.collection("shareCodes").doc(code);

    try {
      await db.runTransaction(async (transaction) => {
        const [codeSnapshot, userSnapshot] = await Promise.all([
          transaction.get(codeRef),
          transaction.get(userRef),
        ]);

        if (codeSnapshot.exists) {
          throw new ShareCodeCollisionError();
        }

        const timestamp = FieldValue.serverTimestamp();
        transaction.create(tripRef, {
          title,
          regionType: "domestic",
          currency: "KRW",
          startDate,
          endDate,
          ownerUid: auth.uid,
          shareCode: code,
          createdAt: timestamp,
          updatedAt: timestamp,
        });
        transaction.create(memberRef, {
          displayName,
          ...(typeof auth.token.picture === "string" ? { photoURL: auth.token.picture } : {}),
          role: "editor",
          joinedAt: timestamp,
          lastActiveAt: timestamp,
        });
        transaction.create(codeRef, {
          tripId: tripRef.id,
          createdBy: auth.uid,
          createdAt: timestamp,
          isActive: true,
          useCount: 0,
        });

        if (userSnapshot.exists) {
          transaction.update(userRef, {
            displayName,
            ...(typeof auth.token.email === "string" ? { email: auth.token.email } : {}),
            ...(typeof auth.token.picture === "string" ? { photoURL: auth.token.picture } : {}),
            authProvider: getAuthProvider(auth.token),
            updatedAt: timestamp,
          });
        } else {
          transaction.create(userRef, {
            displayName,
            ...(typeof auth.token.email === "string" ? { email: auth.token.email } : {}),
            ...(typeof auth.token.picture === "string" ? { photoURL: auth.token.picture } : {}),
            authProvider: getAuthProvider(auth.token),
            createdAt: timestamp,
            updatedAt: timestamp,
          });
        }
      });

      return { tripId: tripRef.id, shareCode: code };
    } catch (error) {
      if (error instanceof ShareCodeCollisionError) {
        continue;
      }

      throw error;
    }
  }

  throw new HttpsError(
    "resource-exhausted",
    "공유 코드를 만들지 못했습니다. 잠시 후 다시 시도해 주세요.",
  );
});

export const createShareCode = onCall({ region: FUNCTIONS_REGION, cors: true }, async (request) => {
  const auth = requireAuth(request);
  const input = asRecord(request.data);
  const tripId = requireString(input, "tripId", { minLength: 1, maxLength: 160 });
  const db = getFirestore();
  const tripRef = db.collection("trips").doc(tripId);
  const memberRef = tripRef.collection("members").doc(auth.uid);

  for (let attempt = 0; attempt < MAX_CODE_GENERATION_ATTEMPTS; attempt += 1) {
    const code = generateShareCode();
    const codeRef = db.collection("shareCodes").doc(code);
    const activeCodesQuery = db
      .collection("shareCodes")
      .where("tripId", "==", tripId)
      .where("isActive", "==", true);

    try {
      await db.runTransaction(async (transaction) => {
        const [tripSnapshot, memberSnapshot, codeSnapshot, activeCodesSnapshot] = await Promise.all(
          [
            transaction.get(tripRef),
            transaction.get(memberRef),
            transaction.get(codeRef),
            transaction.get(activeCodesQuery),
          ],
        );

        if (!tripSnapshot.exists) {
          throw new HttpsError("not-found", "여행을 찾을 수 없습니다.");
        }

        if (!memberSnapshot.exists) {
          throw new HttpsError("permission-denied", "이 여행의 멤버만 공유할 수 있습니다.");
        }

        if (codeSnapshot.exists) {
          throw new ShareCodeCollisionError();
        }

        const timestamp = FieldValue.serverTimestamp();
        for (const activeCode of activeCodesSnapshot.docs) {
          transaction.update(activeCode.ref, {
            isActive: false,
          });
        }

        transaction.create(codeRef, {
          tripId,
          createdBy: auth.uid,
          createdAt: timestamp,
          isActive: true,
          useCount: 0,
        });
        transaction.update(tripRef, {
          shareCode: code,
          updatedAt: timestamp,
        });
      });

      return { tripId, shareCode: code };
    } catch (error) {
      if (error instanceof ShareCodeCollisionError) {
        continue;
      }

      throw error;
    }
  }

  throw new HttpsError(
    "resource-exhausted",
    "공유 코드를 만들지 못했습니다. 잠시 후 다시 시도해 주세요.",
  );
});

export const joinTrip = onCall({ region: FUNCTIONS_REGION, cors: true }, async (request) => {
  const auth = requireAuth(request);
  const input = asRecord(request.data);
  const rawCode = requireString(input, "shareCode", { minLength: 6, maxLength: 20 });
  const requestedDisplayName = optionalString(input, "displayName", 40);
  const shareCode = normalizeShareCode(rawCode);

  if (!isValidShareCode(shareCode)) {
    throw new HttpsError("invalid-argument", "공유 코드 형식을 확인해 주세요.", {
      field: "shareCode",
    });
  }

  const db = getFirestore();
  const codeRef = db.collection("shareCodes").doc(shareCode);

  return db.runTransaction(async (transaction) => {
    const codeSnapshot = await transaction.get(codeRef);

    if (!codeSnapshot.exists) {
      throw new HttpsError("not-found", "유효한 공유 코드를 찾을 수 없습니다.");
    }

    const codeData = codeSnapshot.data() ?? {};
    const tripId = codeData.tripId;
    const expired = isExpired(codeData.expiresAt);
    const hasInvalidUsageLimit =
      (codeData.maxUses !== undefined && typeof codeData.maxUses !== "number") ||
      (codeData.useCount !== undefined && typeof codeData.useCount !== "number");
    if (
      typeof tripId !== "string" ||
      !codeData.isActive ||
      expired === null ||
      expired ||
      hasInvalidUsageLimit
    ) {
      throw new HttpsError("not-found", "만료되었거나 비활성화된 공유 코드입니다.");
    }

    if (
      typeof codeData.maxUses === "number" &&
      typeof codeData.useCount === "number" &&
      codeData.useCount >= codeData.maxUses
    ) {
      throw new HttpsError("resource-exhausted", "공유 코드 사용 가능 횟수를 초과했습니다.");
    }

    const tripRef = db.collection("trips").doc(tripId);
    const memberRef = tripRef.collection("members").doc(auth.uid);
    const userRef = db.collection("users").doc(auth.uid);
    const [tripSnapshot, memberSnapshot, userSnapshot] = await Promise.all([
      transaction.get(tripRef),
      transaction.get(memberRef),
      transaction.get(userRef),
    ]);

    if (!tripSnapshot.exists) {
      throw new HttpsError("not-found", "여행을 찾을 수 없습니다.");
    }

    const timestamp = FieldValue.serverTimestamp();
    const displayName = getDisplayName(auth.token, auth.uid, requestedDisplayName);

    if (memberSnapshot.exists) {
      transaction.update(memberRef, { lastActiveAt: timestamp });
    } else {
      transaction.create(memberRef, {
        displayName,
        ...(typeof auth.token.picture === "string" ? { photoURL: auth.token.picture } : {}),
        role: "editor",
        joinedAt: timestamp,
        lastActiveAt: timestamp,
      });
      transaction.update(codeRef, {
        useCount: (typeof codeData.useCount === "number" ? codeData.useCount : 0) + 1,
      });
    }

    if (userSnapshot.exists) {
      transaction.update(userRef, {
        displayName,
        ...(typeof auth.token.email === "string" ? { email: auth.token.email } : {}),
        ...(typeof auth.token.picture === "string" ? { photoURL: auth.token.picture } : {}),
        authProvider: getAuthProvider(auth.token),
        updatedAt: timestamp,
      });
    } else {
      transaction.create(userRef, {
        displayName,
        ...(typeof auth.token.email === "string" ? { email: auth.token.email } : {}),
        ...(typeof auth.token.picture === "string" ? { photoURL: auth.token.picture } : {}),
        authProvider: getAuthProvider(auth.token),
        createdAt: timestamp,
        updatedAt: timestamp,
      });
    }

    const tripData = tripSnapshot.data() ?? {};
    return {
      tripId,
      title: typeof tripData.title === "string" ? tripData.title : "여행",
      shareCode,
    };
  });
});
