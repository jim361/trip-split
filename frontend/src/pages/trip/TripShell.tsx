import { useState, type ReactNode } from "react";
import { Link, Outlet, useParams } from "react-router-dom";

import { TripNavigation } from "../../shared/components/TripNavigation";

export interface TripShellProps {
  tripTitle?: string;
  syncLabel?: string;
  sessionLabel?: string;
  headerActions?: ReactNode;
}

function getFallbackTitle(tripId: string) {
  if (tripId === "gangneung") return "강릉 여행";
  if (tripId === "tokyo-2026-11") return "2026년 11월 도쿄 여행";
  return "여행";
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
  const [isNavigationCollapsed, setIsNavigationCollapsed] = useState(false);

  if (!tripId) {
    return (
      <main className="standalone-state">
        <h1>여행을 찾을 수 없어요</h1>
        <Link className="button button--primary" to="/trips">
          홈으로 돌아가기
        </Link>
      </main>
    );
  }

  return (
    <div className={`trip-shell${isNavigationCollapsed ? " is-navigation-collapsed" : ""}`}>
      <a className="skip-link" href="#trip-page-content">
        본문으로 건너뛰기
      </a>

      <header className="trip-shell__app-bar">
        <Link
          className="icon-button trip-shell__home-link"
          to="/trips"
          aria-label="내 여행으로 이동"
        >
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M20 12H4M10 6l-6 6 6 6" />
          </svg>
        </Link>
        <button
          className="icon-button trip-shell__drawer-toggle"
          type="button"
          aria-label={isNavigationCollapsed ? "여행 메뉴 펼치기" : "여행 메뉴 접기"}
          aria-controls="trip-navigation"
          aria-expanded={!isNavigationCollapsed}
          onClick={() => setIsNavigationCollapsed((collapsed) => !collapsed)}
        >
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M4 7h16M4 12h16M4 17h16" />
          </svg>
        </button>

        <div className="trip-shell__title-group">
          <p className="trip-shell__title">TRIP SPLIT / MY TRIPS</p>
          <p className="trip-shell__context">{tripTitle ?? getFallbackTitle(tripId)}</p>
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
