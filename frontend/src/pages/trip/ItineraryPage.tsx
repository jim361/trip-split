import { useEffect, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";

import { useTripContext } from "../../app/providers";
import { ItineraryWorksheet } from "../../features/itinerary/ItineraryWorksheet";
import { PlannerMapPreview } from "../../features/map/PlannerMapPreview";
import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";
import type { ItineraryPlanId, Place } from "../../shared/types";

const dateFormatter = new Intl.DateTimeFormat("ko-KR", {
  month: "numeric",
  day: "numeric",
  weekday: "short",
  timeZone: "UTC",
});

function enumerateDates(startDate?: string, endDate?: string): string[] {
  if (!startDate || !endDate) return [];
  const start = new Date(`${startDate}T00:00:00Z`);
  const end = new Date(`${endDate}T00:00:00Z`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || start > end) return [];

  const dates: string[] = [];
  for (let cursor = start; cursor <= end; cursor = new Date(cursor.getTime() + 86_400_000)) {
    dates.push(cursor.toISOString().slice(0, 10));
  }
  return dates;
}

function formatDate(date: string) {
  return dateFormatter.format(new Date(`${date}T00:00:00Z`));
}

function buildTransitUrl(origin: Place, destination: Place) {
  const params = new URLSearchParams({
    api: "1",
    origin: origin.name,
    destination: destination.name,
    travelmode: "transit",
  });
  return `https://www.google.com/maps/dir/?${params.toString()}`;
}

/** [TASK-04 / TASK-05 · 일정·지도] 작은 지도와 날짜별 일정을 한 화면에 제공하는 진입점입니다. */
export function ItineraryPage() {
  const { tripId, trip, itinerary, places, isLoading, error, dataSource } = useTripContext();
  const [searchParams, setSearchParams] = useSearchParams();
  const drawerRef = useRef<HTMLDialogElement>(null);
  const drawerTriggerRef = useRef<HTMLButtonElement>(null);
  const drawerOpen =
    searchParams.get("details") === "open" || searchParams.get("map") === "expanded";
  const itineraryDates = [...new Set(itinerary.map((item) => item.date))].sort();
  const dates = enumerateDates(trip?.startDate, trip?.endDate);
  const visibleDates = dates.length ? dates : itineraryDates;
  const [requestedDate, setRequestedDate] = useState(() => searchParams.get("day") ?? "");
  const [planId, setPlanId] = useState<ItineraryPlanId>("A");
  const selectedDate = visibleDates.includes(requestedDate) ? requestedDate : visibleDates[0];
  const dayNumber = Math.max(visibleDates.indexOf(selectedDate) + 1, 1);
  const dayItinerary = itinerary.filter(
    (item) => item.date === selectedDate && (item.planId ?? "A") === planId,
  );
  const placeById = new Map(places.map((place) => [place.id, place]));

  const setDrawerOpen = (open: boolean) => {
    const next = new URLSearchParams(searchParams);
    if (open) next.set("details", "open");
    else {
      next.delete("details");
      next.delete("map");
    }
    setSearchParams(next, { replace: true });
  };

  useEffect(() => {
    const drawer = drawerRef.current;
    if (drawerOpen && !drawer?.open) drawer?.showModal();
    else if (!drawerOpen && drawer?.open) {
      drawer.close();
      drawerTriggerRef.current?.focus();
    }
    // 확대 지도로 직접 들어와도 지도를 축소할 때 서랍은 유지합니다.
    if (drawerOpen && searchParams.get("details") !== "open") {
      const next = new URLSearchParams(searchParams);
      next.set("details", "open");
      setSearchParams(next, { replace: true });
    }
  }, [drawerOpen, searchParams, setSearchParams]);

  return (
    <FeaturePlaceholder
      eyebrow="01 / ITINERARY MAP"
      title="일정·지도"
      compactHeader
      description="날짜별 시간표로 여행을 계획하고 A안·B안을 바로 전환해요. 이동 동선과 일차별 일정은 오른쪽 서랍에서 확인하세요."
      statusLabel={
        error?.message ??
        (isLoading ? "일정 불러오는 중…" : `${dataSource} · ${visibleDates.length}일 여행`)
      }
      headerActions={
        <button
          ref={drawerTriggerRef}
          className="button button--quiet"
          type="button"
          aria-controls="itinerary-detail-drawer"
          aria-expanded={drawerOpen}
          aria-haspopup="dialog"
          onClick={() => setDrawerOpen(true)}
        >
          동선·일정 열기 <span aria-hidden="true">→</span>
        </button>
      }
    >
      <div className="itinerary-workspace">
        <ItineraryWorksheet
          tripId={tripId}
          startDate={trip?.startDate}
          endDate={trip?.endDate}
          selectedDate={selectedDate}
          dates={visibleDates}
          planId={planId}
          items={itinerary}
          places={places}
          onSelectDate={setRequestedDate}
          onSelectPlan={setPlanId}
        />

        <dialog
          ref={drawerRef}
          id="itinerary-detail-drawer"
          className="itinerary-drawer"
          aria-labelledby="itinerary-detail-title"
          onCancel={(event) => {
            event.preventDefault();
            setDrawerOpen(false);
          }}
        >
          <header className="itinerary-drawer__header">
            <div>
              <p className="eyebrow">DAILY ROUTE / ITINERARY</p>
              <h2 id="itinerary-detail-title">동선·일정</h2>
            </div>
            <button
              className="button button--quiet"
              type="button"
              aria-label="동선·일정 닫기"
              onClick={() => setDrawerOpen(false)}
              autoFocus
            >
              닫기 <span aria-hidden="true">→</span>
            </button>
          </header>
          <div className="itinerary-drawer__controls">
            <label>
              <span>동선 날짜</span>
              <select
                value={selectedDate ?? ""}
                onChange={(event) => setRequestedDate(event.target.value)}
              >
                {visibleDates.map((date, index) => (
                  <option key={date} value={date}>
                    {index + 1}일차 · {formatDate(date)}
                  </option>
                ))}
              </select>
            </label>
            <label>
              <span>동선 계획안</span>
              <select
                value={planId}
                onChange={(event) => setPlanId(event.target.value as ItineraryPlanId)}
              >
                <option value="A">A안</option>
                <option value="B">B안</option>
              </select>
            </label>
          </div>
          <div className="itinerary-drawer__content">
            <PlannerMapPreview
              itinerary={dayItinerary}
              places={places}
              isLoading={isLoading}
              tripTitle={trip?.title}
              dayNumber={dayNumber}
            />

            <PlaceholderPanel
              className="itinerary-placeholder__timeline"
              title={`${dayNumber}일차 일정${selectedDate ? ` · ${formatDate(selectedDate)}` : ""}`}
              description={`${planId}안 · 저장된 일정 순서로 동선을 표시합니다. 장소 사이 이동은 Google Maps 대중교통 길찾기로 확인합니다.`}
            >
              {dayItinerary.length ? (
                <ol className="trip-timeline" aria-label="Mock 일정">
                  {dayItinerary.map((item, index) => {
                    const place = item.placeId ? placeById.get(item.placeId) : undefined;
                    const previousItem = dayItinerary[index - 1];
                    const previousPlace = previousItem?.placeId
                      ? placeById.get(previousItem.placeId)
                      : undefined;

                    return (
                      <li key={item.id}>
                        <time>{item.startTime ?? "미정"}</time>
                        <div className="trip-timeline__marker" aria-hidden="true">
                          {index + 1}
                        </div>
                        <div className="trip-timeline__content">
                          {previousPlace && place ? (
                            <a
                              className="trip-timeline__route"
                              href={buildTransitUrl(previousPlace, place)}
                              target="_blank"
                              rel="noreferrer"
                            >
                              {previousPlace.name}에서 대중교통 길찾기 ↗
                            </a>
                          ) : null}
                          <strong>{item.title}</strong>
                          {place ? <span>{place.name}</span> : null}
                          {item.memo ? <p>{item.memo}</p> : null}
                        </div>
                      </li>
                    );
                  })}
                </ol>
              ) : (
                <div className="empty-state" role="status">
                  <p>
                    {planId}안에 아직 일정이 없어요. 시간표 아래에서 이 날짜에 일정을 추가해보세요.
                  </p>
                </div>
              )}
            </PlaceholderPanel>
          </div>
        </dialog>
      </div>
    </FeaturePlaceholder>
  );
}
