import type { SVGProps } from "react";
import { Link, useLocation } from "react-router-dom";

type NavigationIconProps = SVGProps<SVGSVGElement>;

function CalendarIcon(props: NavigationIconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <path d="M7 3v3M17 3v3M4 9h16" />
      <rect x="4" y="5" width="16" height="16" rx="3" />
      <path d="M8 13h3v3H8z" />
    </svg>
  );
}

function WalletIcon(props: NavigationIconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <path d="M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v11a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17.5z" />
      <path d="M4 8h16M15 12h5v4h-5a2 2 0 1 1 0-4Z" />
    </svg>
  );
}

function PreparationIcon(props: NavigationIconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <path d="M8 7V5a4 4 0 0 1 8 0v2" />
      <path d="M5 7h14l1 14H4z" />
      <path d="m9 14 2 2 4-5" />
    </svg>
  );
}

const navigationItems = [
  { key: "itinerary", label: "일정·지도", icon: CalendarIcon },
  {
    key: "preparation",
    label: "준비",
    icon: PreparationIcon,
  },
  {
    key: "settlement",
    label: "비용",
    icon: WalletIcon,
  },
] as const;

export interface TripNavigationProps {
  tripId: string;
}

export function TripNavigation({ tripId }: TripNavigationProps) {
  const { pathname } = useLocation();

  return (
    <nav id="trip-navigation" className="trip-navigation" aria-label="여행 주요 메뉴">
      <Link className="trip-navigation__brand" to="/trips" aria-label="내 여행 목록으로 이동">
        <strong>TRIP SPLIT</strong>
        <span>TRAVEL WORKSPACE / 01</span>
      </Link>
      <ul className="trip-navigation__list">
        {navigationItems.map((item) => {
          const Icon = item.icon;
          const isCostChild = item.key === "settlement" && pathname.endsWith("/receipts");
          const isActive = pathname.endsWith(`/${item.key}`) || isCostChild;

          return (
            <li key={item.key}>
              <Link
                className={`trip-navigation__link${isActive ? " is-active" : ""}`}
                to={`/trips/${encodeURIComponent(tripId)}/${item.key}`}
                aria-label={item.label}
                aria-current={isActive ? "page" : undefined}
              >
                <Icon className="trip-navigation__icon" aria-hidden="true" />
                <span>{item.label}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
