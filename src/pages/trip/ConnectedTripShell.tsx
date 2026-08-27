import { useAuth, useTripContext } from "../../app/providers";
import { TripShell } from "./TripShell";

export function ConnectedTripShell() {
  const { trip, participants, isLoading, error, dataSource } = useTripContext();
  const { user, status, linkGoogleAccount } = useAuth();
  const activeParticipantCount = participants.filter((participant) => participant.isActive).length;
  const syncLabel = error
    ? error.message
    : isLoading
      ? "여행 데이터를 불러오는 중…"
      : dataSource === "mock"
        ? `Mock · 정산 ${activeParticipantCount}명`
        : `저장됨 · 정산 ${activeParticipantCount}명`;
  const sessionLabel = user
    ? `${user.isAnonymous ? "익명" : "Google"} · ${user.uid.slice(0, 8)}`
    : "세션 준비 중";

  return (
    <TripShell
      tripTitle={trip?.title}
      syncLabel={syncLabel}
      sessionLabel={sessionLabel}
      headerActions={
        user?.isAnonymous ? (
          <button
            className="button button--quiet"
            type="button"
            disabled={status === "linking"}
            onClick={() => void linkGoogleAccount()}
          >
            {status === "linking" ? "연결 중…" : "Google 연결"}
          </button>
        ) : null
      }
    />
  );
}
