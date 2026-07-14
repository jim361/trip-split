import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";
import { useTripContext } from "../../app/providers";
import { PlannerMapPreview } from "../../features/map/PlannerMapPreview";

export function ItineraryPage() {
  const { itinerary, places, isLoading, error, dataSource } = useTripContext();
  const dates = [...new Set(itinerary.map((item) => item.date))];
  const placeById = new Map(places.map((place) => [place.id, place]));

  return (
    <FeaturePlaceholder
      title="일정"
      description="지도에서 전체 동선을 살펴보고, 바로 아래에서 날짜별 일정을 정리해요."
      statusLabel={
        error?.message ??
        (isLoading ? "일정 불러오는 중…" : `${dataSource} · 일정 ${itinerary.length}개`)
      }
    >
      <div className="planner-layout">
        <PlannerMapPreview itinerary={itinerary} places={places} isLoading={isLoading} />

        <div className="itinerary-placeholder">
          <PlaceholderPanel
            className="itinerary-placeholder__dates"
            title="여행 날짜"
            description="날짜 선택 영역"
          >
            <ol className="placeholder-list placeholder-list--compact">
              {dates.map((date, index) => (
                <li key={date} aria-current={index === 0 ? "date" : undefined}>
                  {index + 1}일차 · {date}
                </li>
              ))}
            </ol>
          </PlaceholderPanel>

          <PlaceholderPanel
            className="itinerary-placeholder__timeline"
            title="시간표"
            description="시간을 추가하고 장소를 연결해보세요."
          >
            {itinerary.length ? (
              <ol className="placeholder-list" aria-label="Mock 일정">
                {itinerary.map((item) => (
                  <li key={item.id}>
                    <strong>{item.startTime ?? "시간 미정"}</strong>&nbsp; {item.title}
                    {item.placeId ? ` · ${placeById.get(item.placeId)?.name ?? "장소"}` : ""}
                  </li>
                ))}
              </ol>
            ) : (
              <div className="empty-state" role="status">
                <p>시간을 추가하고 장소를 연결해보세요.</p>
              </div>
            )}
          </PlaceholderPanel>

          <PlaceholderPanel
            className="itinerary-placeholder__places"
            title="장소 보관함"
            description="검색·링크·직접 입력으로 저장한 장소"
          >
            <ul className="placeholder-list" aria-label="Mock 장소 보관함">
              {places.slice(0, 4).map((place) => (
                <li key={place.id}>{place.name}</li>
              ))}
            </ul>
          </PlaceholderPanel>
        </div>
      </div>
    </FeaturePlaceholder>
  );
}
