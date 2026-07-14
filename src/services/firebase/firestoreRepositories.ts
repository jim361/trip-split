import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  onSnapshot,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  type DocumentData,
  type DocumentSnapshot,
  type Firestore,
  type QueryDocumentSnapshot,
} from "firebase/firestore";

import {
  createAppError,
  isAppError,
  type AppError,
  type AppErrorCode,
  type EntityId,
} from "../../shared/contracts";
import type {
  Expense,
  ItineraryItem,
  MoneyAllocation,
  Participant,
  Place,
  ReceiptItem,
  Trip,
  TripMember,
  UserProfile,
} from "../../shared/types";
import type {
  CreateExpenseInput,
  CreateItineraryItemInput,
  CreateParticipantInput,
  CreatePlaceInput,
  TripRepositories,
  UpdateExpenseInput,
  UpdateItineraryItemInput,
  UpdateParticipantInput,
  UpdatePlaceInput,
  UpdateTripInput,
} from "../repositories";

type FirestoreRecord = Record<string, unknown>;

export type FirestoreRepositoriesOptions = {
  getActorUid: () => string | null;
  now?: () => number;
};

const firestorePaths = {
  user: (uid: string) => ["users", uid] as const,
  trip: (tripId: EntityId) => ["trips", tripId] as const,
  members: (tripId: EntityId) => ["trips", tripId, "members"] as const,
  participants: (tripId: EntityId) => ["trips", tripId, "participants"] as const,
  places: (tripId: EntityId) => ["trips", tripId, "places"] as const,
  itinerary: (tripId: EntityId) => ["trips", tripId, "itinerary"] as const,
  expenses: (tripId: EntityId) => ["trips", tripId, "expenses"] as const,
};

function invalidDocument(field: string): AppError {
  return createAppError("invalid-argument", "저장된 데이터 형식이 올바르지 않습니다.", {
    retryable: false,
    field,
  });
}

function asRecord(value: unknown, field: string): FirestoreRecord {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw invalidDocument(field);
  }

  return value as FirestoreRecord;
}

function dataFrom(snapshot: DocumentSnapshot<DocumentData>): FirestoreRecord {
  const value = snapshot.data();
  if (value === undefined) {
    throw invalidDocument(snapshot.id);
  }

  return asRecord(value, snapshot.id);
}

function stringField(data: FirestoreRecord, field: string): string {
  const value = data[field];
  if (typeof value !== "string") {
    throw invalidDocument(field);
  }
  return value;
}

function optionalStringField(data: FirestoreRecord, field: string): string | undefined {
  const value = data[field];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw invalidDocument(field);
  }
  return value;
}

function numberField(data: FirestoreRecord, field: string): number {
  const value = data[field];
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw invalidDocument(field);
  }
  return value;
}

function integerField(data: FirestoreRecord, field: string): number {
  const value = numberField(data, field);
  if (!Number.isInteger(value)) {
    throw invalidDocument(field);
  }
  return value;
}

function optionalNumberField(data: FirestoreRecord, field: string): number | undefined {
  const value = data[field];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw invalidDocument(field);
  }
  return value;
}

function booleanField(data: FirestoreRecord, field: string): boolean {
  const value = data[field];
  if (typeof value !== "boolean") {
    throw invalidDocument(field);
  }
  return value;
}

function literalField<T extends string>(
  data: FirestoreRecord,
  field: string,
  allowed: readonly T[],
): T {
  const value = stringField(data, field);
  if (!allowed.includes(value as T)) {
    throw invalidDocument(field);
  }
  return value as T;
}

function stringArrayField(data: FirestoreRecord, field: string): string[] {
  const value = data[field];
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) {
    throw invalidDocument(field);
  }
  return [...value] as string[];
}

function epochMillisField(data: FirestoreRecord, field: string, pendingFallback: number): number {
  const value = data[field];
  if (value === undefined || value === null) {
    return pendingFallback;
  }
  if (value instanceof Timestamp) {
    return value.toMillis();
  }
  if (typeof value === "number" && Number.isInteger(value) && value >= 0) {
    return value;
  }
  throw invalidDocument(field);
}

function parseMoneyAllocation(value: unknown, field: string): MoneyAllocation {
  const data = asRecord(value, field);
  return {
    participantId: stringField(data, "participantId"),
    amount: integerField(data, "amount"),
  };
}

function allocationsField(data: FirestoreRecord, field: string): MoneyAllocation[] {
  const value = data[field];
  if (!Array.isArray(value)) {
    throw invalidDocument(field);
  }
  return value.map((item, index) => parseMoneyAllocation(item, `${field}.${index}`));
}

function parseReceiptItem(value: unknown, index: number): ReceiptItem {
  const data = asRecord(value, `receiptItems.${index}`);
  return {
    id: stringField(data, "id"),
    kind: literalField(data, "kind", ["item", "discount", "serviceFee", "adjustment"] as const),
    name: stringField(data, "name"),
    amount: integerField(data, "amount"),
    consumers: stringArrayField(data, "consumers"),
    allocationMethod: literalField(data, "allocationMethod", ["equal", "custom"] as const),
    allocatedAmounts: allocationsField(data, "allocatedAmounts"),
    source: literalField(data, "source", ["ocr", "manual"] as const),
    sortOrder: integerField(data, "sortOrder"),
  };
}

function receiptItemsField(data: FirestoreRecord): ReceiptItem[] {
  const value = data.receiptItems;
  if (!Array.isArray(value)) {
    throw invalidDocument("receiptItems");
  }
  return value.map(parseReceiptItem);
}

function parseTrip(snapshot: DocumentSnapshot<DocumentData>, pendingFallback: number): Trip {
  const data = dataFrom(snapshot);
  return {
    id: snapshot.id,
    title: stringField(data, "title"),
    regionType: literalField(data, "regionType", ["domestic", "international"] as const),
    currency: literalField(data, "currency", ["KRW"] as const),
    startDate: stringField(data, "startDate"),
    endDate: stringField(data, "endDate"),
    ownerUid: stringField(data, "ownerUid"),
    shareCode: stringField(data, "shareCode"),
    createdAt: epochMillisField(data, "createdAt", pendingFallback),
    updatedAt: epochMillisField(data, "updatedAt", pendingFallback),
  };
}

function parseUserProfile(
  snapshot: DocumentSnapshot<DocumentData>,
  pendingFallback: number,
): UserProfile {
  const data = dataFrom(snapshot);
  const email = optionalStringField(data, "email");
  const photoURL = optionalStringField(data, "photoURL");
  return {
    uid: snapshot.id,
    displayName: stringField(data, "displayName"),
    ...(email === undefined ? {} : { email }),
    ...(photoURL === undefined ? {} : { photoURL }),
    authProvider: literalField(data, "authProvider", ["anonymous", "google"] as const),
    createdAt: epochMillisField(data, "createdAt", pendingFallback),
    updatedAt: epochMillisField(data, "updatedAt", pendingFallback),
  };
}

function parseMember(
  snapshot: QueryDocumentSnapshot<DocumentData>,
  tripId: EntityId,
  pendingFallback: number,
): TripMember {
  const data = dataFrom(snapshot);
  const photoURL = optionalStringField(data, "photoURL");
  return {
    uid: snapshot.id,
    tripId,
    displayName: stringField(data, "displayName"),
    ...(photoURL === undefined ? {} : { photoURL }),
    role: literalField(data, "role", ["editor"] as const),
    joinedAt: epochMillisField(data, "joinedAt", pendingFallback),
    lastActiveAt: epochMillisField(data, "lastActiveAt", pendingFallback),
  };
}

function parseParticipant(
  snapshot: QueryDocumentSnapshot<DocumentData>,
  tripId: EntityId,
  pendingFallback: number,
): Participant {
  const data = dataFrom(snapshot);
  const color = optionalStringField(data, "color");
  const linkedUid = optionalStringField(data, "linkedUid");
  return {
    id: snapshot.id,
    tripId,
    name: stringField(data, "name"),
    ...(color === undefined ? {} : { color }),
    ...(linkedUid === undefined ? {} : { linkedUid }),
    isActive: booleanField(data, "isActive"),
    createdAt: epochMillisField(data, "createdAt", pendingFallback),
    updatedAt: epochMillisField(data, "updatedAt", pendingFallback),
  };
}

function parsePlace(
  snapshot: QueryDocumentSnapshot<DocumentData>,
  tripId: EntityId,
  pendingFallback: number,
): Place {
  const data = dataFrom(snapshot);
  const address = optionalStringField(data, "address");
  const lat = optionalNumberField(data, "lat");
  const lng = optionalNumberField(data, "lng");
  const providerPlaceId = optionalStringField(data, "providerPlaceId");
  const sourceUrl = optionalStringField(data, "sourceUrl");
  const addedBy = optionalStringField(data, "addedBy");
  const memo = optionalStringField(data, "memo");
  return {
    id: snapshot.id,
    tripId,
    name: stringField(data, "name"),
    ...(address === undefined ? {} : { address }),
    ...(lat === undefined ? {} : { lat }),
    ...(lng === undefined ? {} : { lng }),
    provider: literalField(data, "provider", ["naver", "manual"] as const),
    source: literalField(data, "source", ["naverSearch", "naverLink", "manual"] as const),
    ...(providerPlaceId === undefined ? {} : { providerPlaceId }),
    ...(sourceUrl === undefined ? {} : { sourceUrl }),
    ...(addedBy === undefined ? {} : { addedBy }),
    ...(memo === undefined ? {} : { memo }),
    createdAt: epochMillisField(data, "createdAt", pendingFallback),
    updatedAt: epochMillisField(data, "updatedAt", pendingFallback),
  };
}

function parseItineraryItem(
  snapshot: QueryDocumentSnapshot<DocumentData>,
  tripId: EntityId,
  pendingFallback: number,
): ItineraryItem {
  const data = dataFrom(snapshot);
  const startTime = optionalStringField(data, "startTime");
  const endTime = optionalStringField(data, "endTime");
  const placeId = optionalStringField(data, "placeId");
  const memo = optionalStringField(data, "memo");
  const updatedBy = optionalStringField(data, "updatedBy");
  return {
    id: snapshot.id,
    tripId,
    date: stringField(data, "date"),
    ...(startTime === undefined ? {} : { startTime }),
    ...(endTime === undefined ? {} : { endTime }),
    ...(placeId === undefined ? {} : { placeId }),
    title: stringField(data, "title"),
    ...(memo === undefined ? {} : { memo }),
    order: integerField(data, "order"),
    ...(updatedBy === undefined ? {} : { updatedBy }),
    updatedAt: epochMillisField(data, "updatedAt", pendingFallback),
  };
}

function parseExpense(
  snapshot: QueryDocumentSnapshot<DocumentData>,
  tripId: EntityId,
  pendingFallback: number,
): Expense {
  const data = dataFrom(snapshot);
  const payer = asRecord(data.payer, "payer");
  const placeId = optionalStringField(data, "placeId");
  const itineraryItemId = optionalStringField(data, "itineraryItemId");
  const memo = optionalStringField(data, "memo");
  return {
    id: snapshot.id,
    tripId,
    title: stringField(data, "title"),
    category: stringField(data, "category"),
    expenseDate: stringField(data, "expenseDate"),
    totalAmount: integerField(data, "totalAmount"),
    currency: literalField(data, "currency", ["KRW"] as const),
    payer: {
      participantId: stringField(payer, "participantId"),
      amount: integerField(payer, "amount"),
    },
    consumers: stringArrayField(data, "consumers"),
    allocationMethod: literalField(data, "allocationMethod", [
      "equal",
      "itemized",
      "custom",
    ] as const),
    allocatedAmounts: allocationsField(data, "allocatedAmounts"),
    receiptItems: receiptItemsField(data),
    source: literalField(data, "source", ["manual", "ocr"] as const),
    ...(placeId === undefined ? {} : { placeId }),
    ...(itineraryItemId === undefined ? {} : { itineraryItemId }),
    ...(memo === undefined ? {} : { memo }),
    createdBy: stringField(data, "createdBy"),
    updatedBy: stringField(data, "updatedBy"),
    createdAt: epochMillisField(data, "createdAt", pendingFallback),
    updatedAt: epochMillisField(data, "updatedAt", pendingFallback),
  };
}

function removeUndefined(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(removeUndefined);
  }

  if (
    typeof value !== "object" ||
    value === null ||
    Object.getPrototypeOf(value) !== Object.prototype
  ) {
    return value;
  }

  return Object.fromEntries(
    Object.entries(value)
      .filter(([, item]) => item !== undefined)
      .map(([key, item]) => [key, removeUndefined(item)]),
  );
}

function errorCodeOf(error: unknown): string | undefined {
  if (typeof error !== "object" || error === null || !("code" in error)) {
    return undefined;
  }
  const code = (error as { code?: unknown }).code;
  if (typeof code !== "string") {
    return undefined;
  }
  return code.includes("/") ? code.slice(code.lastIndexOf("/") + 1) : code;
}

const firebaseErrorMap: Partial<
  Record<string, { code: AppErrorCode; message: string; retryable: boolean }>
> = {
  unauthenticated: {
    code: "unauthenticated",
    message: "로그인이 필요합니다.",
    retryable: false,
  },
  "permission-denied": {
    code: "permission-denied",
    message: "이 여행 데이터에 접근할 권한이 없습니다.",
    retryable: false,
  },
  "invalid-argument": {
    code: "invalid-argument",
    message: "입력한 내용을 확인해 주세요.",
    retryable: false,
  },
  "not-found": {
    code: "not-found",
    message: "요청한 데이터를 찾을 수 없습니다.",
    retryable: false,
  },
  "already-exists": {
    code: "conflict",
    message: "이미 존재하는 데이터입니다.",
    retryable: false,
  },
  aborted: {
    code: "conflict",
    message: "다른 변경과 충돌했습니다. 최신 내용을 확인해 주세요.",
    retryable: true,
  },
  "resource-exhausted": {
    code: "resource-exhausted",
    message: "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.",
    retryable: true,
  },
  unavailable: {
    code: "unavailable",
    message: "네트워크 연결을 확인하고 다시 시도해 주세요.",
    retryable: true,
  },
  "deadline-exceeded": {
    code: "unavailable",
    message: "응답 시간이 초과되었습니다. 다시 시도해 주세요.",
    retryable: true,
  },
};

export function toFirestoreAppError(error: unknown): AppError {
  if (isAppError(error)) {
    return error;
  }

  const mapped = firebaseErrorMap[errorCodeOf(error) ?? ""];
  if (mapped !== undefined) {
    return createAppError(mapped.code, mapped.message, {
      retryable: mapped.retryable,
    });
  }

  return createAppError("unknown", "데이터를 처리하지 못했습니다.", {
    retryable: false,
  });
}

async function runCommand<T>(work: () => Promise<T>): Promise<T> {
  try {
    return await work();
  } catch (error) {
    throw toFirestoreAppError(error);
  }
}

function writeData(value: unknown): DocumentData {
  return removeUndefined(value) as DocumentData;
}

export function createFirestoreTripRepositories(
  db: Firestore,
  options: FirestoreRepositoriesOptions,
): TripRepositories {
  const now = options.now ?? Date.now;

  const requireActorUid = (): string => {
    const uid = options.getActorUid();
    if (uid === null || uid.trim().length === 0) {
      throw createAppError("unauthenticated", "로그인이 필요합니다.", {
        retryable: false,
      });
    }
    return uid;
  };

  const assertLinkedUidAvailable = async (
    tripId: EntityId,
    linkedUid: string | undefined,
    exceptParticipantId?: EntityId,
  ): Promise<void> => {
    if (linkedUid === undefined) {
      return;
    }

    const memberSnapshot = await getDoc(doc(db, "trips", tripId, "members", linkedUid));
    if (!memberSnapshot.exists()) {
      throw createAppError("invalid-argument", "연결할 여행 멤버를 찾을 수 없습니다.", {
        retryable: false,
        field: "linkedUid",
      });
    }

    const participantSnapshots = await getDocs(
      collection(db, ...firestorePaths.participants(tripId)),
    );
    const duplicated = participantSnapshots.docs.some((snapshot) => {
      if (snapshot.id === exceptParticipantId) {
        return false;
      }
      return optionalStringField(dataFrom(snapshot), "linkedUid") === linkedUid;
    });
    if (duplicated) {
      throw createAppError(
        "conflict",
        "한 여행 멤버는 하나의 정산 참여자에만 연결할 수 있습니다.",
        { retryable: false, field: "linkedUid" },
      );
    }
  };

  return {
    userProfiles: {
      subscribeUserProfile(uid, onData, onError) {
        return onSnapshot(
          doc(db, ...firestorePaths.user(uid)),
          (snapshot) => {
            try {
              onData(snapshot.exists() ? parseUserProfile(snapshot, now()) : null);
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
      upsertUserProfile(uid, input) {
        return runCommand(async () => {
          const actorUid = requireActorUid();
          if (actorUid !== uid) {
            throw createAppError(
              "permission-denied",
              "다른 사용자의 프로필은 수정할 수 없습니다.",
              { retryable: false },
            );
          }

          const reference = doc(db, ...firestorePaths.user(uid));
          const existing = await getDoc(reference);
          const localTimestamp = now();
          const createdAt = existing.exists()
            ? parseUserProfile(existing, localTimestamp).createdAt
            : localTimestamp;

          await setDoc(
            reference,
            writeData({
              ...input,
              ...(existing.exists() ? {} : { createdAt: serverTimestamp() }),
              updatedAt: serverTimestamp(),
            }),
            { merge: true },
          );

          return {
            uid,
            ...input,
            createdAt,
            updatedAt: localTimestamp,
          };
        });
      },
    },

    trips: {
      subscribeTrip(tripId, onData, onError) {
        return onSnapshot(
          doc(db, ...firestorePaths.trip(tripId)),
          (snapshot) => {
            try {
              onData(snapshot.exists() ? parseTrip(snapshot, now()) : null);
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
      updateTrip(tripId, input: UpdateTripInput) {
        return runCommand(async () => {
          requireActorUid();
          await updateDoc(
            doc(db, ...firestorePaths.trip(tripId)),
            writeData({ ...input, updatedAt: serverTimestamp() }),
          );
        });
      },
    },

    members: {
      subscribeMembers(tripId, onData, onError) {
        return onSnapshot(
          collection(db, ...firestorePaths.members(tripId)),
          (snapshot) => {
            try {
              const fallback = now();
              onData(
                snapshot.docs
                  .map((item) => parseMember(item, tripId, fallback))
                  .sort(
                    (left, right) =>
                      left.joinedAt - right.joinedAt || left.uid.localeCompare(right.uid),
                  ),
              );
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
    },

    participants: {
      subscribeParticipants(tripId, onData, onError) {
        return onSnapshot(
          collection(db, ...firestorePaths.participants(tripId)),
          (snapshot) => {
            try {
              const fallback = now();
              onData(
                snapshot.docs
                  .map((item) => parseParticipant(item, tripId, fallback))
                  .sort((left, right) => left.id.localeCompare(right.id)),
              );
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
      createParticipant(tripId, input: CreateParticipantInput) {
        return runCommand(async () => {
          requireActorUid();
          await assertLinkedUidAvailable(tripId, input.linkedUid);
          const reference = doc(collection(db, ...firestorePaths.participants(tripId)));
          const localTimestamp = now();
          await setDoc(
            reference,
            writeData({
              ...input,
              createdAt: serverTimestamp(),
              updatedAt: serverTimestamp(),
            }),
          );
          return {
            id: reference.id,
            tripId,
            ...input,
            createdAt: localTimestamp,
            updatedAt: localTimestamp,
          };
        });
      },
      updateParticipant(tripId, id, input: UpdateParticipantInput) {
        return runCommand(async () => {
          requireActorUid();
          await assertLinkedUidAvailable(tripId, input.linkedUid, id);
          await updateDoc(
            doc(db, ...firestorePaths.participants(tripId), id),
            writeData({ ...input, updatedAt: serverTimestamp() }),
          );
        });
      },
      deleteParticipant(tripId, id) {
        return runCommand(async () => {
          requireActorUid();
          const expenseSnapshots = await getDocs(
            collection(db, ...firestorePaths.expenses(tripId)),
          );
          const fallback = now();
          const referenced = expenseSnapshots.docs.some((snapshot) => {
            const expense = parseExpense(snapshot, tripId, fallback);
            return expense.payer.participantId === id || expense.consumers.includes(id);
          });
          if (referenced) {
            throw createAppError(
              "conflict",
              "지출에서 사용 중인 참여자는 삭제할 수 없습니다. 대신 비활성화해 주세요.",
              { retryable: false, details: { participantId: id } },
            );
          }
          await deleteDoc(doc(db, ...firestorePaths.participants(tripId), id));
        });
      },
    },

    places: {
      subscribePlaces(tripId, onData, onError) {
        return onSnapshot(
          collection(db, ...firestorePaths.places(tripId)),
          (snapshot) => {
            try {
              const fallback = now();
              onData(
                snapshot.docs
                  .map((item) => parsePlace(item, tripId, fallback))
                  .sort((left, right) => left.id.localeCompare(right.id)),
              );
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
      createPlace(tripId, input: CreatePlaceInput) {
        return runCommand(async () => {
          const actorUid = requireActorUid();
          const reference = doc(collection(db, ...firestorePaths.places(tripId)));
          const localTimestamp = now();
          await setDoc(
            reference,
            writeData({
              ...input,
              addedBy: actorUid,
              createdAt: serverTimestamp(),
              updatedAt: serverTimestamp(),
            }),
          );
          return {
            id: reference.id,
            tripId,
            ...input,
            addedBy: actorUid,
            createdAt: localTimestamp,
            updatedAt: localTimestamp,
          };
        });
      },
      updatePlace(tripId, id, input: UpdatePlaceInput) {
        return runCommand(async () => {
          requireActorUid();
          await updateDoc(
            doc(db, ...firestorePaths.places(tripId), id),
            writeData({ ...input, updatedAt: serverTimestamp() }),
          );
        });
      },
      deletePlace(tripId, id) {
        return runCommand(async () => {
          requireActorUid();
          await deleteDoc(doc(db, ...firestorePaths.places(tripId), id));
        });
      },
    },

    itinerary: {
      subscribeItinerary(tripId, onData, onError) {
        return onSnapshot(
          collection(db, ...firestorePaths.itinerary(tripId)),
          (snapshot) => {
            try {
              const fallback = now();
              onData(
                snapshot.docs
                  .map((item) => parseItineraryItem(item, tripId, fallback))
                  .sort(
                    (left, right) =>
                      left.date.localeCompare(right.date) ||
                      left.order - right.order ||
                      left.id.localeCompare(right.id),
                  ),
              );
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
      createItineraryItem(tripId, input: CreateItineraryItemInput) {
        return runCommand(async () => {
          const actorUid = requireActorUid();
          const reference = doc(collection(db, ...firestorePaths.itinerary(tripId)));
          const localTimestamp = now();
          await setDoc(
            reference,
            writeData({
              ...input,
              updatedBy: actorUid,
              updatedAt: serverTimestamp(),
            }),
          );
          return {
            id: reference.id,
            tripId,
            ...input,
            updatedBy: actorUid,
            updatedAt: localTimestamp,
          };
        });
      },
      updateItineraryItem(tripId, id, input: UpdateItineraryItemInput) {
        return runCommand(async () => {
          const actorUid = requireActorUid();
          await updateDoc(
            doc(db, ...firestorePaths.itinerary(tripId), id),
            writeData({
              ...input,
              updatedBy: actorUid,
              updatedAt: serverTimestamp(),
            }),
          );
        });
      },
      deleteItineraryItem(tripId, id) {
        return runCommand(async () => {
          requireActorUid();
          await deleteDoc(doc(db, ...firestorePaths.itinerary(tripId), id));
        });
      },
    },

    expenses: {
      subscribeExpenses(tripId, onData, onError) {
        return onSnapshot(
          collection(db, ...firestorePaths.expenses(tripId)),
          (snapshot) => {
            try {
              const fallback = now();
              onData(
                snapshot.docs
                  .map((item) => parseExpense(item, tripId, fallback))
                  .sort(
                    (left, right) =>
                      left.expenseDate.localeCompare(right.expenseDate) ||
                      left.createdAt - right.createdAt ||
                      left.id.localeCompare(right.id),
                  ),
              );
            } catch (error) {
              onError(toFirestoreAppError(error));
            }
          },
          (error) => onError(toFirestoreAppError(error)),
        );
      },
      createExpense(tripId, input: CreateExpenseInput) {
        return runCommand(async () => {
          const actorUid = requireActorUid();
          const reference = doc(collection(db, ...firestorePaths.expenses(tripId)));
          const localTimestamp = now();
          await setDoc(
            reference,
            writeData({
              ...input,
              createdBy: actorUid,
              updatedBy: actorUid,
              createdAt: serverTimestamp(),
              updatedAt: serverTimestamp(),
            }),
          );
          return {
            id: reference.id,
            tripId,
            ...input,
            createdBy: actorUid,
            updatedBy: actorUid,
            createdAt: localTimestamp,
            updatedAt: localTimestamp,
          };
        });
      },
      updateExpense(tripId, id, input: UpdateExpenseInput) {
        return runCommand(async () => {
          const actorUid = requireActorUid();
          await updateDoc(
            doc(db, ...firestorePaths.expenses(tripId), id),
            writeData({
              ...input,
              updatedBy: actorUid,
              updatedAt: serverTimestamp(),
            }),
          );
        });
      },
      deleteExpense(tripId, id) {
        return runCommand(async () => {
          requireActorUid();
          await deleteDoc(doc(db, ...firestorePaths.expenses(tripId), id));
        });
      },
    },
  };
}
