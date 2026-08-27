import { useState } from "react";

import { useTripContext } from "../../app/providers";
import { PlannerMapPreview } from "../../features/map/PlannerMapPreview";
import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";
import type { Place } from "../../shared/types";

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
  for (
    let cursor = start;
    cursor <= end && dates.length < 31;
    cursor = new Date(cursor.getTime() + 86_400_000)
  ) {
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

export function ItineraryPage() {
  const { trip, itinerary, places, isLoading, error, dataSource } = useTripContext();
  const itineraryDates = [...new Set(itinerary.map((item) => item.date))].sort();
  const dates = enumerateDates(trip?.startDate, trip?.endDate);
  const visibleDates = dates.length ? dates : itineraryDates;
  const [requestedDate, setRequestedDate] = useState("");
  const selectedDate = visibleDates.includes(requestedDate) ? requestedDate : visibleDates[0];
  const dayNumber = Math.max(visibleDates.indexOf(selectedDate) + 1, 1);
  const dayItinerary = itinerary.filter((item) => item.date === selectedDate);
  const placeById = new Map(places.map((place) => [place.id, place]));

  return (
    <FeaturePlaceholder
      eyebrow={trip?.regionType === "international" ? `해외여행 · ${trip.currency}` : "국내여행"}
      title="일정·지도"
      description="날짜를 고르면 그날의 Google Maps 동선과 시간표를 한 화면에서 확인해요."
      statusLabel={
        error?.message ??
        (isLoading ? "일정 불러오는 중…" : `${dataSource} · ${visibleDates.length}일 여행`)
      }
    >
      <div className="day-switcher" role="group" aria-label="여행 날짜 선택">
        {visibleDates.map((date, index) => (
          <button
            key={date}
            type="button"
            className={`day-switcher__button${date === selectedDate ? " is-selected" : ""}`}
            aria-pressed={date === selectedDate}
            onClick={() => setRequestedDate(date)}
          >
            <strong>{index + 1}일차</strong>
            <span>{formatDate(date)}</span>
          </button>
        ))}
      </div>

      <div className="planner-layout">
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
          description="장소 사이 이동은 Google Maps 대중교통 길찾기로 바로 확인합니다."
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
              <p>아직 일정이 없어요. 준비 탭의 장소 후보를 이 날짜에 추가해보세요.</p>
            </div>
          )}
        </PlaceholderPanel>
      </div>
    </FeaturePlaceholder>
  );
}
