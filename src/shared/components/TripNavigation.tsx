import type { SVGProps } from "react";
import { NavLink } from "react-router-dom";

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

function ReceiptIcon(props: NavigationIconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <path d="M6 3h12v18l-3-2-3 2-3-2-3 2z" />
      <path d="M9 8h6M9 12h6M9 16h4" />
    </svg>
  );
}

const navigationItems = [
  { key: "itinerary", label: "일정·지도", icon: CalendarIcon },
  {
    key: "settlement",
    label: "정산",
    icon: WalletIcon,
  },
  {
    key: "receipts",
    label: "영수증",
    icon: ReceiptIcon,
  },
] as const;

export interface TripNavigationProps {
  tripId: string;
}

export function TripNavigation({ tripId }: TripNavigationProps) {
  return (
    <nav className="trip-navigation" aria-label="여행 주요 메뉴">
      <ul className="trip-navigation__list">
        {navigationItems.map((item) => {
          const Icon = item.icon;

          return (
            <li key={item.key}>
              <NavLink
                className={({ isActive }) => `trip-navigation__link${isActive ? " is-active" : ""}`}
                to={`/trips/${encodeURIComponent(tripId)}/${item.key}`}
              >
                <Icon className="trip-navigation__icon" aria-hidden="true" />
                <span>{item.label}</span>
              </NavLink>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
