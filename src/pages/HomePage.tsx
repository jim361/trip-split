import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useAuth, usePlatformServices } from "../app/providers";
import type { AppError } from "../shared/contracts";

export function HomePage() {
  const navigate = useNavigate();
  const { user, status, error: authError, linkGoogleAccount } = useAuth();
  const { tripSessions, dataSource } = usePlatformServices();
  const [shareCode, setShareCode] = useState("");
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState<"create" | "join" | null>(null);

  const createTrip = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitError(null);
    setSubmitting("create");
    const form = new FormData(event.currentTarget);
    try {
      const result = await tripSessions.createTrip({
        title: String(form.get("title") ?? ""),
        startDate: String(form.get("startDate") ?? ""),
        endDate: String(form.get("endDate") ?? ""),
      });
      navigate(`/trips/${result.tripId}/itinerary`);
    } catch (error) {
      setSubmitError((error as AppError).message ?? "여행을 만들지 못했습니다.");
    } finally {
      setSubmitting(null);
    }
  };

  const joinTrip = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitError(null);
    setSubmitting("join");
    try {
      const result = await tripSessions.joinTrip(shareCode);
      navigate(`/trips/${result.tripId}/itinerary`);
    } catch (error) {
      setSubmitError((error as AppError).message ?? "여행에 참여하지 못했습니다.");
    } finally {
      setSubmitting(null);
    }
  };

  return (
    <main className="home-page">
      <section className="home-page__card" aria-labelledby="home-title">
        <p className="eyebrow">함께 만드는 여행</p>
        <h1 id="home-title">Trip Split</h1>
        <p className="home-page__description">
          일정과 지도를 함께 정리하고, 여행에서 쓴 비용까지 한곳에서 나눠요.
        </p>

        <div className="session-card" role="status">
          <strong>{user?.isAnonymous ? "익명 세션" : "Google 계정"}</strong>
          <span>{user ? `uid: ${user.uid}` : "uid 발급 중…"}</span>
          <span>데이터 소스: {dataSource}</span>
          {user?.isAnonymous ? (
            <button
              className="button button--quiet"
              type="button"
              disabled={status === "linking"}
              onClick={() => void linkGoogleAccount()}
            >
              {status === "linking" ? "Google 연결 중…" : "Google 계정 연결"}
            </button>
          ) : null}
        </div>

        <div className="home-page__actions" aria-label="여행 시작">
          <Link className="button button--primary" to="/trips/gangneung/itinerary">
            강릉 데모 여행 열기
          </Link>
          <p className="supporting-text">현재 데모는 Firebase 없이 mock repository로 열립니다.</p>
        </div>

        <div className="home-page__forms">
          <form className="compact-form" onSubmit={(event) => void createTrip(event)}>
            <h2>여행 만들기</h2>
            <label>
              여행 제목
              <input name="title" defaultValue="강릉 여름 여행" required maxLength={80} />
            </label>
            <div className="compact-form__dates">
              <label>
                시작일
                <input name="startDate" type="date" defaultValue="2026-07-24" required />
              </label>
              <label>
                종료일
                <input name="endDate" type="date" defaultValue="2026-07-25" required />
              </label>
            </div>
            <button className="button button--primary" disabled={!user || submitting !== null}>
              {submitting === "create" ? "만드는 중…" : "여행 만들기"}
            </button>
          </form>

          <form className="compact-form" onSubmit={(event) => void joinTrip(event)}>
            <h2>공유 코드로 참여</h2>
            <label>
              공유 코드
              <input
                value={shareCode}
                onChange={(event) => setShareCode(event.target.value)}
                placeholder="예: GANG26"
                required
              />
            </label>
            <button className="button button--quiet" disabled={!user || submitting !== null}>
              {submitting === "join" ? "참여 중…" : "여행 참여"}
            </button>
          </form>
        </div>

        {authError || submitError ? (
          <p className="form-error" role="alert">
            {authError?.message ?? submitError}
          </p>
        ) : null}
      </section>
    </main>
  );
}
