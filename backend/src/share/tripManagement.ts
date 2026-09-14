import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { appError, requireAuth, requireTripMember } from "../shared/callable";
import { asRecord, requireDocumentId } from "../shared/input";

export const listMyTrips = onCall(async (request) => {
  const auth = requireAuth(request);
  const input = asRecord(request.data);
  if (Object.keys(input).length)
    throw appError("invalid-argument", "내 여행 목록은 별도 사용자 ID를 받지 않습니다.");
  const db = getFirestore();
  const memberships = await db.collectionGroup("members").where("uid", "==", auth.uid).get();
  const trips = [];
  for (const member of memberships.docs) {
    const ref = member.ref.parent.parent;
    if (!ref || ref.parent.path !== "trips" || member.id !== auth.uid) continue;
    const trip = await ref.get();
    if (!trip.exists) continue;
    const data = trip.data()!;
    trips.push({
      ...data,
      id: trip.id,
      createdAt: (data.createdAt as Timestamp).toMillis(),
      updatedAt: (data.updatedAt as Timestamp).toMillis(),
    });
  }
  return { trips: trips.sort((a, b) => b.updatedAt - a.updatedAt || a.id.localeCompare(b.id)) };
});

export const linkMyParticipant = onCall(async (request) => {
  const input = asRecord(request.data);
  if (Object.keys(input).some((k) => !["tripId", "participantId"].includes(k)))
    throw appError("invalid-argument", "다른 계정의 연결은 변경할 수 없습니다.");
  const tripId = requireDocumentId(input, "tripId");
  const auth = await requireTripMember(request, tripId);
  if (!("participantId" in input))
    throw appError("invalid-argument", "연결할 참여자 또는 해제(null)를 지정해 주세요.");
  const participantId =
    input.participantId === null ? null : requireDocumentId(input, "participantId");
  const db = getFirestore();
  const trip = db.doc(`trips/${tripId}`);
  await db.runTransaction(async (tx) => {
    const member = await tx.get(trip.collection("members").doc(auth.uid));
    if (!member.exists) throw appError("permission-denied", "여행 멤버만 연결할 수 있습니다.");
    const participants = await tx.get(trip.collection("participants"));
    const target = participants.docs.find((p) => p.id === participantId);
    if (participantId && !target) throw appError("not-found", "정산 참여자를 찾을 수 없습니다.");
    if (
      target &&
      (!target.data().isActive || (target.data().linkedUid && target.data().linkedUid !== auth.uid))
    ) {
      throw appError("failed-precondition", "다른 계정과 연결되었거나 비활성화된 참여자입니다.");
    }
    for (const participant of participants.docs) {
      if (participant.data().linkedUid === auth.uid || participant.id === participantId) {
        tx.update(participant.ref, {
          linkedUid: participant.id === participantId ? auth.uid : FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }
  });
  return { tripId, participantId };
});
