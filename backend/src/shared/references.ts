import { FieldValue, getFirestore, type DocumentSnapshot } from "firebase-admin/firestore";
import { onCall, type CallableRequest } from "firebase-functions/v2/https";
import { appError, requireTripMember } from "./callable";
import { asRecord, requireDocumentId } from "./input";

export function referenceUpdate(trip: DocumentSnapshot) {
  if (!trip.exists) throw appError("not-found", "여행을 찾을 수 없습니다.");
  const stored: unknown = trip.get("referenceVersion");
  const version = stored === undefined ? 0 : stored;
  if (
    typeof version !== "number" ||
    !Number.isSafeInteger(version) ||
    version < 0 ||
    version >= Number.MAX_SAFE_INTEGER
  ) {
    throw appError("failed-precondition", "여행의 참조 버전을 확인해 주세요.");
  }
  // ponytail: 여행 하나의 참조 쓰기를 직렬화한다. 실제 경합이 커지면 대상별 버전으로 분리한다.
  return { referenceVersion: version + 1, updatedAt: FieldValue.serverTimestamp() };
}

async function deleteTarget(request: CallableRequest<unknown>, kind: "place" | "itinerary") {
  const input = asRecord(request.data);
  const tripId = requireDocumentId(input, "tripId");
  const field = kind === "place" ? "placeId" : "itineraryItemId";
  const id = requireDocumentId(input, field);
  const auth = await requireTripMember(request, tripId);
  const trip = getFirestore().doc(`trips/${tripId}`);
  const target = trip.collection(kind === "place" ? "places" : "itinerary").doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const tripSnapshot = await tx.get(trip);
    if (!(await tx.get(trip.collection("members").doc(auth.uid))).exists) {
      throw appError("permission-denied", "이 여행의 멤버만 삭제할 수 있습니다.");
    }
    if (!(await tx.get(target)).exists) return;
    for (const collection of kind === "place"
      ? ["itinerary", "expenses"]
      : ["reservations", "expenses"]) {
      if (!(await tx.get(trip.collection(collection).where(field, "==", id).limit(1))).empty) {
        throw appError(
          "failed-precondition",
          "연결된 항목이 있습니다. 먼저 연결을 해제해 주세요.",
          { field },
        );
      }
    }
    // 연결·해제도 이 여행 문서를 갱신하므로, 역참조 조회 뒤의 동시 연결과 충돌한다.
    tx.update(trip, referenceUpdate(tripSnapshot));
    tx.delete(target);
  });
  return { [field]: id };
}

export const deletePlace = onCall((request) => deleteTarget(request, "place"));
export const deleteItineraryItem = onCall((request) => deleteTarget(request, "itinerary"));
