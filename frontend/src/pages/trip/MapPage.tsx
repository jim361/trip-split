import { Navigate, useParams } from "react-router-dom";

/**
 * @deprecated 지도는 일정 화면에 통합됐다. 이 컴포넌트는 기존 북마크와
 * 공유 링크를 확대된 통합 화면으로 연결하는 호환 경계만 담당한다.
 */
export function MapPage() {
  const { tripId } = useParams<{ tripId: string }>();

  if (!tripId) return <Navigate to="/" replace />;

  return <Navigate to={`/trips/${encodeURIComponent(tripId)}/itinerary?map=expanded`} replace />;
}
