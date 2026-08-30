import { useTripContext } from "../../app/providers";
import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";

const internationalChecklist = [
  "여권 유효기간 확인",
  "Visit Japan Web 등록",
  "eSIM 준비",
  "기내 보조배터리 확인",
];

const domesticChecklist = [
  "신분증 확인",
  "숙소 예약 확인",
  "날씨와 옷차림 확인",
  "보조배터리 준비",
];

const internationalReservations = [
  ["ICN → NRT 항공", "예약 완료"],
  ["우에노 숙소", "확인 필요"],
  ["공항 교통", "미정"],
] as const;

const domesticReservations = [
  ["이동 교통", "확인 필요"],
  ["숙소", "예약 완료"],
  ["현지 이동", "미정"],
] as const;

/** [TASK-04 · 준비 목업] 예약과 체크리스트를 검토하는 현재 화면 진입점입니다. */
export function PreparationPage() {
  const { itinerary, places, isLoading, error, dataSource } = useTripContext();
  const scheduledPlaceIds = new Set(
    itinerary.flatMap((item) => (item.placeId ? [item.placeId] : [])),
  );
  const candidates = places.filter((place) => !scheduledPlaceIds.has(place.id));
  const usesGoogleMaps = places.some((place) => place.provider === "google");
  const mapProviderLabel = usesGoogleMaps ? "Google Maps" : "지도";
  const checklist = usesGoogleMaps ? internationalChecklist : domesticChecklist;
  const reservations = usesGoogleMaps ? internationalReservations : domesticReservations;

  return (
    <FeaturePlaceholder
      eyebrow="02 / PREPARATION"
      title="준비"
      description="가고 싶은 장소, 예약, 짐과 출발 전 할 일을 여행 전에 한곳에서 정리해요."
      statusLabel={
        error?.message ??
        (isLoading ? "준비 목록 불러오는 중…" : `${dataSource} · 장소 후보 ${candidates.length}개`)
      }
    >
      <div className="preparation-grid">
        <PlaceholderPanel
          title="장소 후보"
          description={`${mapProviderLabel}에서 저장하고 일정으로 옮길 장소`}
        >
          <ul className="place-candidate-list" aria-label={`${mapProviderLabel} 장소 후보`}>
            {candidates.map((place) => (
              <li key={place.id}>
                <div>
                  <strong>{place.name}</strong>
                  <span>{place.memo ?? place.address ?? "세부 정보 확인 전"}</span>
                </div>
                {place.sourceUrl ? (
                  <a href={place.sourceUrl} target="_blank" rel="noreferrer">
                    지도 ↗
                  </a>
                ) : null}
              </li>
            ))}
          </ul>
        </PlaceholderPanel>

        <PlaceholderPanel title="예약" description="항공·숙소·교통 예약을 일정과 연결">
          <ul className="preparation-list">
            {reservations.map(([label, status]) => (
              <li key={label}>
                <span>{label}</span>
                <strong>{status}</strong>
              </li>
            ))}
          </ul>
        </PlaceholderPanel>

        <PlaceholderPanel title="체크리스트" description="개인 준비 목록 mock">
          <ul className="checklist" aria-label="출발 전 체크리스트">
            {checklist.map((item, index) => (
              <li key={item}>
                <label>
                  <input type="checkbox" defaultChecked={index === 1} />
                  <span>{item}</span>
                </label>
              </li>
            ))}
          </ul>
        </PlaceholderPanel>
      </div>
    </FeaturePlaceholder>
  );
}
