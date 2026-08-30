import { useEffect, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";

import { useAuth, usePlatformServices } from "../app/providers";
import type { AppError } from "../shared/contracts";

export function AccountEntryPage() {
  const navigate = useNavigate();
  const { user, status, error: authError, linkGoogleAccount, retry } = useAuth();
  const { tripSessions } = usePlatformServices();
  const [googleRequested, setGoogleRequested] = useState(false);
  const [shareCodeOpen, setShareCodeOpen] = useState(false);
  const [shareCode, setShareCode] = useState("");
  const [joinError, setJoinError] = useState<string | null>(null);
  const [joining, setJoining] = useState(false);

  useEffect(() => {
    if (googleRequested && status === "ready" && user && !user.isAnonymous) {
      navigate("/trips", { replace: true });
    }
  }, [googleRequested, navigate, status, user]);

  const continueWithGoogle = async () => {
    setGoogleRequested(true);
    await linkGoogleAccount();
  };

  const joinTrip = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setJoinError(null);
    setJoining(true);
    try {
      const result = await tripSessions.joinTrip(shareCode);
      navigate(`/trips/${encodeURIComponent(result.tripId)}/itinerary`);
    } catch (error) {
      setJoinError((error as AppError).message ?? "여행에 참여하지 못했습니다.");
    } finally {
      setJoining(false);
    }
  };

  const sessionReady = status === "ready" && Boolean(user);

  return (
    <main className="account-entry">
      <div className="account-entry__canvas">
        <section className="account-entry__intro" aria-labelledby="account-entry-title">
          <p className="account-entry__eyebrow">TRIP SPLIT / ACCOUNT</p>
          <div className="account-entry__message">
            <p className="account-entry__brand">Trip Split</p>
            <h1 id="account-entry-title">
              여행을 계획하고
              <br />
              함께 정산하세요.
            </h1>
          </div>
          <span className="account-entry__rule" aria-hidden="true" />
        </section>

        <div className="account-entry__divider" aria-hidden="true" />

        <section className="account-entry__panel" aria-labelledby="account-actions-title">
          <div className="account-entry__actions">
            <header className="account-entry__actions-header">
              <h2 id="account-actions-title">시작하기</h2>
            </header>

            <button
              className="account-entry__google"
              type="button"
              disabled={!user || status === "loading" || status === "linking"}
              onClick={() => void continueWithGoogle()}
            >
              <span aria-hidden="true">↪</span>
              {status === "linking" ? "Google 연결 중…" : "Google로 계속"}
            </button>

            <button
              className="account-entry__guest"
              type="button"
              disabled={!sessionReady}
              onClick={() => navigate("/trips")}
            >
              계정 없이 시작
            </button>

            <button
              className="account-entry__share-toggle"
              type="button"
              aria-expanded={shareCodeOpen}
              aria-controls="account-share-code"
              onClick={() => setShareCodeOpen((open) => !open)}
            >
              공유 코드로 여행 참여
            </button>

            {shareCodeOpen ? (
              <form
                id="account-share-code"
                className="account-entry__share-form"
                onSubmit={(event) => void joinTrip(event)}
              >
                <label htmlFor="account-share-code-input">공유 코드</label>
                <div>
                  <input
                    id="account-share-code-input"
                    value={shareCode}
                    onChange={(event) => setShareCode(event.target.value)}
                    placeholder="예: TKY26JP"
                    autoComplete="off"
                    required
                  />
                  <button type="submit" disabled={!sessionReady || joining}>
                    {joining ? "참여 중…" : "참여"}
                  </button>
                </div>
              </form>
            ) : null}

            {authError || joinError ? (
              <div className="account-entry__error" role="alert">
                <p>{authError?.message ?? joinError}</p>
                {authError ? (
                  <button type="button" onClick={() => void retry()}>
                    다시 시도
                  </button>
                ) : null}
              </div>
            ) : null}

            <p className="account-entry__note">
              계정 없이 시작해도 나중에 Google로 연결할 수 있어요.
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}
