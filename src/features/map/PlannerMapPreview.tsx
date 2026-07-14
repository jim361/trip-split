import { useMemo } from "react";
import { useSearchParams } from "react-router-dom";

import type { ItineraryItem, Place } from "../../shared/types";
import { createMapRenderModel } from "./mapAdapter";

export interface PlannerMapPreviewProps {
  itinerary: ItineraryItem[];
  places: Place[];
  isLoading?: boolean;
}

type PositionedPin = ReturnType<typeof createMapRenderModel>["pins"][number] & {
  day: number;
  x: number;
  y: number;
};

function positionPins(pins: ReturnType<typeof createMapRenderModel>["pins"]): PositionedPin[] {
  if (!pins.length) return [];

  const latitudes = pins.map((pin) => pin.lat);
  const longitudes = pins.map((pin) => pin.lng);
  const minLat = Math.min(...latitudes);
  const maxLat = Math.max(...latitudes);
  const minLng = Math.min(...longitudes);
  const maxLng = Math.max(...longitudes);
  const latRange = Math.max(maxLat - minLat, 0.01);
  const lngRange = Math.max(maxLng - minLng, 0.01);
  const dayByDate = new Map<string, number>();

  return pins.map((pin) => {
    if (!dayByDate.has(pin.date)) dayByDate.set(pin.date, dayByDate.size + 1);

    return {
      ...pin,
      day: dayByDate.get(pin.date) ?? 1,
      x: 12 + ((pin.lng - minLng) / lngRange) * 76,
      y: 14 + ((maxLat - pin.lat) / latRange) * 68,
    };
  });
}

function MapCanvas({
  pins,
  itinerary,
  expanded,
}: {
  pins: PositionedPin[];
  itinerary: ItineraryItem[];
  expanded: boolean;
}) {
  const itemById = new Map(itinerary.map((item) => [item.id, item]));
  const dates = [...new Set(pins.map((pin) => pin.date))];

  return (
    <div
      id="planner-map-canvas"
      className={`planner-map__canvas${expanded ? " is-expanded" : ""}`}
      aria-label={`강릉 여행 동선 지도, 일정 장소 ${pins.length}개`}
    >
      <div className="planner-map__water" aria-hidden="true" />
      <span className="planner-map__place-label planner-map__place-label--city" aria-hidden="true">
        강릉시
      </span>
      <span className="planner-map__place-label planner-map__place-label--coast" aria-hidden="true">
        동해
      </span>

      {dates.map((date, index) => {
        const routePins = pins.filter((pin) => pin.date === date);
        if (routePins.length < 2) return null;

        return (
          <svg
            key={date}
            className={`planner-map__route planner-map__route--day-${index + 1}`}
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
        <strong>Mock 지도</strong>
        <span>실제 지도 SDK 연결 전</span>
      </div>
    </div>
  );
}

/**
 * 일정 화면에서 사용하는 provider-neutral 지도 미리보기다. `map=expanded`
 * query를 사용해 확대 상태 자체도 팀원에게 링크로 공유할 수 있다.
 */
export function PlannerMapPreview({ itinerary, places, isLoading }: PlannerMapPreviewProps) {
  const [searchParams, setSearchParams] = useSearchParams();
  const expanded = searchParams.get("map") === "expanded";
  const model = useMemo(() => createMapRenderModel(places, itinerary), [itinerary, places]);
  const pins = useMemo(() => positionPins(model.pins), [model.pins]);
  const dates = [...new Set(pins.map((pin) => pin.date))];

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
          <p className="planner-map__kicker">일정과 함께 보는 지도</p>
          <h2 id="planner-map-title">여행 동선</h2>
          <p>번호 핀과 직선 동선으로 날짜별 이동 순서를 빠르게 확인해요.</p>
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
        {dates.map((date, index) => (
          <span key={date} className={`planner-map__legend planner-map__legend--day-${index + 1}`}>
            {index + 1}일차
          </span>
        ))}
      </div>

      <MapCanvas pins={pins} itinerary={itinerary} expanded={expanded} />
    </section>
  );
}
