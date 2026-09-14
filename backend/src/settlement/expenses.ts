import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall, type CallableRequest } from "firebase-functions/v2/https";
import { appError, requireTripMember } from "../shared/callable";
import { asRecord, requireDocumentId } from "../shared/input";
import { validateExpenseDraft } from "./expenseValidation";
import { referenceUpdate } from "../shared/references";

async function saveExpense(request: CallableRequest<unknown>, updating: boolean) {
  const input = asRecord(request.data);
  const tripId = requireDocumentId(input, "tripId");
  const auth = await requireTripMember(request, tripId);
  const draft = validateExpenseDraft(input.draft);
  const trip = getFirestore().doc(`trips/${tripId}`);
  const ref = updating
    ? trip.collection("expenses").doc(requireDocumentId(input, "expenseId"))
    : trip.collection("expenses").doc();
  await getFirestore().runTransaction(async (tx) => {
    const tripSnapshot = await tx.get(trip);
    const previous = updating ? await tx.get(ref) : null;
    if (updating && !previous?.exists) throw appError("not-found", "이미 삭제된 지출입니다.");
    const member = await tx.get(trip.collection("members").doc(auth.uid));
    if (!member.exists) throw appError("permission-denied", "이 여행의 멤버만 사용할 수 있습니다.");
    const old = previous?.data();
    const prior = new Set([
      ...(Array.isArray(old?.consumers) ? old.consumers : []),
      old?.payer?.participantId,
    ]);
    const participantIds = new Set([draft.payer.participantId, ...draft.consumers]);
    for (const id of participantIds) {
      const participant = await tx.get(trip.collection("participants").doc(id));
      if (!participant.exists || (!participant.data()?.isActive && !prior.has(id))) {
        throw appError("invalid-argument", "같은 여행의 활성 참여자를 선택해 주세요.", {
          field: "consumers",
        });
      }
    }
    for (const [id, collection, field] of [
      [draft.placeId, "places", "placeId"],
      [draft.itineraryItemId, "itinerary", "itineraryItemId"],
    ] as const) {
      if (id && !(await tx.get(trip.collection(collection).doc(id))).exists)
        throw appError("invalid-argument", "연결 대상이 삭제되었거나 다른 여행에 있습니다.", {
          field,
        });
    }
    tx.update(trip, referenceUpdate(tripSnapshot));
    tx.set(ref, {
      ...draft,
      createdBy: old?.createdBy ?? auth.uid,
      createdAt: old?.createdAt ?? FieldValue.serverTimestamp(),
      updatedBy: auth.uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  const saved = (await ref.get()).data();
  if (!saved) throw appError("aborted", "지출이 변경되었습니다. 원장을 다시 확인해 주세요.");
  return {
    expense: {
      ...saved,
      id: ref.id,
      tripId,
      createdAt: (saved.createdAt as Timestamp).toMillis(),
      updatedAt: (saved.updatedAt as Timestamp).toMillis(),
    },
  };
}

export const createExpense = onCall((request) => saveExpense(request, false));
export const updateExpense = onCall((request) => saveExpense(request, true));
export const deleteExpense = onCall(async (request) => {
  const input = asRecord(request.data);
  const tripId = requireDocumentId(input, "tripId");
  const auth = await requireTripMember(request, tripId);
  const expenseId = requireDocumentId(input, "expenseId");
  const trip = getFirestore().doc(`trips/${tripId}`);
  await getFirestore().runTransaction(async (tx) => {
    const tripSnapshot = await tx.get(trip);
    if (!(await tx.get(trip.collection("members").doc(auth.uid))).exists)
      throw appError("permission-denied", "여행 멤버만 삭제할 수 있습니다.");
    tx.update(trip, referenceUpdate(tripSnapshot));
    tx.delete(trip.collection("expenses").doc(expenseId));
  });
  return { expenseId };
});
