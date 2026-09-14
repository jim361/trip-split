import { useMemo } from "react";
import { useSearchParams } from "react-router-dom";

import type { ItineraryItem, Place } from "../../shared/types";
import { createMapRenderModel } from "./mapAdapter";

export interface PlannerMapPreviewProps {
  itinerary: ItineraryItem[];
  places: Place[];
  isLoading?: boolean;
  tripTitle?: string;
  dayNumber?: number;
}

type PositionedPin = ReturnType<typeof createMapRenderModel>["pins"][number] & {
  day: number;
  x: number;
  y: number;
};

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

function positionPins(
  pins: ReturnType<typeof createMapRenderModel>["pins"],
  dayNumber: number,
): PositionedPin[] {
  if (!pins.length) return [];

  const latitudes = pins.map((pin) => pin.lat);
  const longitudes = pins.map((pin) => pin.lng);
  const minLat = Math.min(...latitudes);
  const maxLat = Math.max(...latitudes);
  const minLng = Math.min(...longitudes);
  const maxLng = Math.max(...longitudes);
  const latRange = Math.max(maxLat - minLat, 0.01);
  const lngRange = Math.max(maxLng - minLng, 0.01);
  const positioned: PositionedPin[] = [];

  for (const pin of pins) {
    let x = 18 + ((pin.lng - minLng) / lngRange) * 54;
    let y = 20 + ((maxLat - pin.lat) / latRange) * 50;
    let attempts = 0;
    while (
      positioned.some((placed) => Math.hypot(placed.x - x, placed.y - y) < 12) &&
      attempts < 5
    ) {
      y -= 13;
      if (y < 18) {
        y = 24 + attempts * 9;
        x += 13;
      }
      x = clamp(x, 16, 74);
      y = clamp(y, 18, 72);
      attempts += 1;
    }

    positioned.push({
      ...pin,
      day: dayNumber,
      x,
      y,
    });
  }

  return positioned;
}

function buildGoogleMapsUrl(
  pins: ReturnType<typeof createMapRenderModel>["pins"],
  places: Place[],
) {
  const placeById = new Map(places.map((place) => [place.id, place]));
  const orderedPlaces = pins.flatMap((pin) => {
    const place = placeById.get(pin.placeId);
    return place ? [place] : [];
  });
  const first = orderedPlaces[0];
  const last = orderedPlaces.at(-1);
  if (!first) return "https://www.google.com/maps";
  if (!last || first.id === last.id) {
    const params = new URLSearchParams({ api: "1", query: first.name });
    return `https://www.google.com/maps/search/?${params.toString()}`;
  }

  const params = new URLSearchParams({
    api: "1",
    origin: first.name,
    destination: last.name,
    travelmode: "transit",
  });
  const waypoints = orderedPlaces
    .slice(1, -1)
    .slice(0, 3)
    .map((place) => place.name)
    .join("|");
  if (waypoints) params.set("waypoints", waypoints);
  return `https://www.google.com/maps/dir/?${params.toString()}`;
}

function MapCanvas({
  pins,
  itinerary,
  expanded,
  tripTitle,
  mapUrl,
  usesGoogle,
  dayNumber,
}: {
  pins: PositionedPin[];
  itinerary: ItineraryItem[];
  expanded: boolean;
  tripTitle?: string;
  mapUrl: string;
  usesGoogle: boolean;
  dayNumber: number;
}) {
  const itemById = new Map(itinerary.map((item) => [item.id, item]));
  const dates = [...new Set(pins.map((pin) => pin.date))];

  return (
    <div
      id="planner-map-canvas"
      className={`planner-map__canvas${expanded ? " is-expanded" : ""}`}
      aria-label={`${tripTitle ?? "여행"} 동선 지도, 일정 장소 ${pins.length}개`}
    >
      <div className="planner-map__water" aria-hidden="true" />
      <span className="planner-map__city-label" aria-hidden="true">
        {tripTitle?.includes("도쿄") ? "TOKYO · 東京" : "TRIP MAP"}
      </span>

      {dates.map((date) => {
        const routePins = pins.filter((pin) => pin.date === date);
        if (routePins.length < 2) return null;

        return (
          <svg
            key={date}
            className={`planner-map__route planner-map__route--day-${dayNumber}`}
            viewBox="0 0 100 100"
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            <polyline points={routePins.map((pin) => `${pin.x},${pin.y}`).join(" ")} />
          </svg>
        );
      })}

      {pins.map((pin) => {
        const item = itemById.get(pin.itineraryItemId);
        return (
          <span
            key={pin.itineraryItemId}
            className={`planner-map__pin planner-map__pin--day-${pin.day}`}
            style={{ left: `${pin.x}%`, top: `${pin.y}%` }}
            role="img"
            aria-label={`${pin.day}일차 ${pin.label}번, ${item?.title ?? "일정 장소"}`}
            title={item?.title}
          >
            <span aria-hidden="true">{pin.label}</span>
          </span>
        );
      })}

      {!pins.length ? (
        <div className="planner-map__empty" role="status">
          지도에 표시할 장소를 일정에 연결해보세요.
        </div>
      ) : null}

      <div className="planner-map__sdk-note">
        <strong>{usesGoogle ? "Google Maps Mock" : "Mock 지도"}</strong>
        <span>실제 지도 API 연결 전</span>
      </div>
      <div className="planner-map__zoom" aria-hidden="true">
        <span>＋</span>
        <span>−</span>
      </div>
      <a className="planner-map__open-link" href={mapUrl} target="_blank" rel="noreferrer">
        Google Maps에서 열기 ↗
      </a>
    </div>
  );
}

/**
 * 일정 화면에서 사용하는 provider-neutral 지도 미리보기다. `map=expanded`
 * query를 사용해 확대 상태 자체도 팀원에게 링크로 공유할 수 있다.
 */
export function PlannerMapPreview({
  itinerary,
  places,
  isLoading,
  tripTitle,
  dayNumber = 1,
}: PlannerMapPreviewProps) {
  const [searchParams, setSearchParams] = useSearchParams();
  const expanded = searchParams.get("map") === "expanded";
  const model = useMemo(() => createMapRenderModel(places, itinerary), [itinerary, places]);
  const pins = useMemo(() => positionPins(model.pins, dayNumber), [dayNumber, model.pins]);
  const dates = [...new Set(pins.map((pin) => pin.date))];
  const mapUrl = useMemo(() => buildGoogleMapsUrl(model.pins, places), [model.pins, places]);
  const usesGoogle = places.some((place) => place.provider === "google");

  const toggleExpanded = () => {
    const next = new URLSearchParams(searchParams);
    if (expanded) next.delete("map");
    else next.set("map", "expanded");
    setSearchParams(next, { replace: true });
  };

  return (
    <section className="planner-map" aria-labelledby="planner-map-title">
      <div className="planner-map__heading">
        <div>
          <p className="planner-map__kicker">Google Maps 연결 미리보기</p>
          <h2 id="planner-map-title">오늘의 이동 동선</h2>
          <p>번호 핀으로 순서를 보고, 실제 길찾기는 Google Maps에서 바로 열어요.</p>
        </div>

        <button
          className="planner-map__expand-button"
          type="button"
          aria-controls="planner-map-canvas"
          aria-expanded={expanded}
          onClick={toggleExpanded}
        >
          <svg viewBox="0 0 24 24" aria-hidden="true">
            {expanded ? (
              <path d="M9 3v6H3M15 21v-6h6M3 9l6-6M21 15l-6 6" />
            ) : (
              <path d="M9 3H3v6M15 21h6v-6M3 3l6 6M21 21l-6-6" />
            )}
          </svg>
          {expanded ? "지도 작게 보기" : "지도 크게 보기"}
        </button>
      </div>

      <div className="planner-map__meta" aria-live="polite">
        <span>{isLoading ? "지도 데이터 불러오는 중…" : `핀 ${pins.length}개`}</span>
        {dates.map((date) => (
          <span key={date} className={`planner-map__legend planner-map__legend--day-${dayNumber}`}>
            {dayNumber}일차
          </span>
        ))}
      </div>

      <MapCanvas
        pins={pins}
        itinerary={itinerary}
        expanded={expanded}
        tripTitle={tripTitle}
        mapUrl={mapUrl}
        usesGoogle={usesGoogle}
        dayNumber={dayNumber}
      />
    </section>
  );
}
