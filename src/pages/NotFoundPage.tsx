import { Link } from "react-router-dom";

export function NotFoundPage() {
  return (
    <main className="standalone-state" aria-labelledby="not-found-title">
      <p className="eyebrow">404</p>
      <h1 id="not-found-title">페이지를 찾을 수 없어요</h1>
      <p>주소를 다시 확인하거나 홈에서 여행을 선택해 주세요.</p>
      <Link className="button button--primary" to="/">
        홈으로 돌아가기
      </Link>
    </main>
  );
}
