import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";

import { usePlatformServices, useTripContext } from "../../app/providers";
import type { AppError } from "../../shared/contracts";
import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";
import type { CurrencyCode } from "../../shared/types";

const participantColors = ["#1A73E8", "#E56B6F", "#2A9D8F", "#F4A261", "#7B61FF"];

function formatMoney(amount: number, currency: CurrencyCode) {
  return new Intl.NumberFormat(currency === "JPY" ? "ja-JP" : "ko-KR", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function SettlementPage() {
  const { repositories } = usePlatformServices();
  const { tripId, trip, expenses, participants, isLoading, error, dataSource } = useTripContext();
  const [name, setName] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const orderedParticipants = [...participants].sort(
    (left, right) =>
      Number(Boolean(right.linkedUid)) - Number(Boolean(left.linkedUid)) ||
      left.createdAt - right.createdAt ||
      left.id.localeCompare(right.id),
  );
  const activeParticipants = orderedParticipants.filter((participant) => participant.isActive);
  const inactiveParticipants = orderedParticipants.filter((participant) => !participant.isActive);
  const currency = trip?.currency ?? "KRW";
  const totalsByCurrency = expenses.reduce<Map<CurrencyCode, number>>((totals, expense) => {
    totals.set(expense.currency, (totals.get(expense.currency) ?? 0) + expense.totalAmount);
    return totals;
  }, new Map());
  const displayedTotals = [currency, ...totalsByCurrency.keys()]
    .filter((item, index, currencies) => currencies.indexOf(item) === index)
    .map((item) => ({ currency: item, amount: totalsByCurrency.get(item) ?? 0 }));

  const addParticipant = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;
    setActionError(null);
    setBusyId("new");
    try {
      await repositories.participants.createParticipant(tripId, {
        name: trimmed,
        color: participantColors[participants.length % participantColors.length],
        isActive: true,
      });
      setName("");
    } catch (nextError) {
      setActionError((nextError as AppError).message ?? "정산 인원을 추가하지 못했습니다.");
    } finally {
      setBusyId(null);
    }
  };

  const setParticipantActive = async (participantId: string, isActive: boolean) => {
    if (!isActive && activeParticipants.length === 1) {
      setActionError("정산 인원은 최소 1명이어야 합니다.");
      return;
    }
    setActionError(null);
    setBusyId(participantId);
    try {
      await repositories.participants.updateParticipant(tripId, participantId, { isActive });
    } catch (nextError) {
      setActionError((nextError as AppError).message ?? "정산 인원을 변경하지 못했습니다.");
    } finally {
      setBusyId(null);
    }
  };

  return (
    <FeaturePlaceholder
      eyebrow={trip?.regionType === "international" ? `해외여행 비용 · ${currency}` : "여행 비용"}
      title="비용"
      description="예상 인원으로 시작하고, 실제 정산에서는 사람을 포함하거나 제외할 수 있어요."
      statusLabel={
        error?.message ??
        (isLoading
          ? "비용 불러오는 중…"
          : `${dataSource} · 활성 정산 인원 ${activeParticipants.length}명`)
      }
    >
      <div className="settlement-placeholder">
        <PlaceholderPanel
          className="settlement-placeholder__participants"
          title={`정산 인원 ${activeParticipants.length}명`}
          description="제외해도 기존 지출 기록은 유지되고 새 지출 대상에서만 빠집니다."
        >
          <ul className="participant-list" aria-label="활성 정산 인원">
            {activeParticipants.map((participant) => (
              <li key={participant.id}>
                <span
                  className="participant-list__color"
                  style={{ background: participant.color }}
                  aria-hidden="true"
                />
                <strong>{participant.name}</strong>
                <button
                  type="button"
                  aria-label={`${participant.name} 정산에서 제외`}
                  disabled={busyId !== null}
                  onClick={() => void setParticipantActive(participant.id, false)}
                >
                  정산에서 제외
                </button>
              </li>
            ))}
          </ul>

          <form className="participant-form" onSubmit={(event) => void addParticipant(event)}>
            <label htmlFor="participant-name">인원 추가</label>
            <div>
              <input
                id="participant-name"
                value={name}
                onChange={(event) => setName(event.target.value)}
                placeholder="이름 또는 별명"
                maxLength={20}
                required
              />
              <button className="button button--quiet" disabled={busyId !== null}>
                추가
              </button>
            </div>
          </form>

          {inactiveParticipants.length ? (
            <div className="inactive-participants">
              <p>제외된 인원</p>
              {inactiveParticipants.map((participant) => (
                <button
                  key={participant.id}
                  type="button"
                  aria-label={`${participant.name} 다시 정산에 포함`}
                  disabled={busyId !== null}
                  onClick={() => void setParticipantActive(participant.id, true)}
                >
                  + {participant.name} 다시 포함
                </button>
              ))}
            </div>
          ) : null}

          {actionError ? (
            <p className="form-error" role="alert">
              {actionError}
            </p>
          ) : null}
        </PlaceholderPanel>

        <PlaceholderPanel
          className="settlement-placeholder__summary"
          title="비용 요약"
          description="환율 적용 전 통화별 실제 지출을 구분해 보여줍니다."
        >
          <dl className="amount-placeholder">
            <div>
              <dt>기준 통화</dt>
              <dd>{currency}</dd>
            </div>
            <div>
              <dt>실제 지출</dt>
              <dd className="amount-placeholder__currency-totals">
                {displayedTotals.map((total) => (
                  <span key={total.currency}>{formatMoney(total.amount, total.currency)}</span>
                ))}
              </dd>
            </div>
            <div>
              <dt>새 지출 기본 대상</dt>
              <dd>{activeParticipants.length}명</dd>
            </div>
          </dl>
        </PlaceholderPanel>

        <PlaceholderPanel
          className="settlement-placeholder__expenses"
          title="지출 목록"
          description="정산 계산 엔진은 이 원장과 활성 인원 정보를 사용합니다."
        >
          {expenses.length ? (
            <ul className="placeholder-list" aria-label="Mock 지출 원장">
              {expenses.map((expense) => (
                <li key={expense.id}>
                  <span>{expense.title}</span>&nbsp;
                  <strong>{formatMoney(expense.totalAmount, expense.currency)}</strong>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state" role="status">
              <p>아직 실제 지출이 없어요. 예약비나 여행 중 결제부터 추가해보세요.</p>
            </div>
          )}
          <Link
            className="button button--quiet receipt-entry-link"
            to={`/trips/${encodeURIComponent(tripId)}/receipts`}
          >
            영수증으로 지출 추가
          </Link>
        </PlaceholderPanel>
      </div>
    </FeaturePlaceholder>
  );
}
