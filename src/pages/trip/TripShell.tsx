import type { ReactNode } from "react";
import { Link, Outlet, useParams } from "react-router-dom";

import { TripNavigation } from "../../shared/components/TripNavigation";

export interface TripShellProps {
  tripTitle?: string;
  syncLabel?: string;
  sessionLabel?: string;
  headerActions?: ReactNode;
}

function getFallbackTitle(tripId: string) {
  return tripId === "gangneung" ? "강릉 여행" : "여행";
}

/**
 * Responsive shell shared by every trip feature. Auth and trip providers can
 * inject labels/actions through props without leaking Firebase into the UI.
 */
export function TripShell({
  tripTitle,
  syncLabel = "Mock 데이터 동기화됨",
  sessionLabel = "익명 세션",
  headerActions,
}: TripShellProps) {
  const { tripId } = useParams<{ tripId: string }>();

  if (!tripId) {
    return (
      <main className="standalone-state">
        <h1>여행을 찾을 수 없어요</h1>
        <Link className="button button--primary" to="/">
          홈으로 돌아가기
        </Link>
      </main>
    );
  }

  return (
    <div className="trip-shell">
      <a className="skip-link" href="#trip-page-content">
        본문으로 건너뛰기
      </a>

      <header className="trip-shell__app-bar">
        <Link className="icon-button" to="/" aria-label="홈으로 돌아가기">
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="m15 18-6-6 6-6" />
          </svg>
        </Link>

        <div className="trip-shell__title-group">
          <p className="trip-shell__title">{tripTitle ?? getFallbackTitle(tripId)}</p>
          <p className="trip-shell__sync" aria-live="polite">
            <span aria-hidden="true" />
            {syncLabel}
          </p>
        </div>

        <div className="trip-shell__session" aria-label="현재 사용자 세션">
          {sessionLabel}
        </div>

        {headerActions ? <div className="trip-shell__actions">{headerActions}</div> : null}
      </header>

      <TripNavigation tripId={tripId} />

      <main id="trip-page-content" className="trip-shell__main" tabIndex={-1}>
        <Outlet />
      </main>
    </div>
  );
}
