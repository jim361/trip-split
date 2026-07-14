import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";
import { useTripContext } from "../../app/providers";

export function SettlementPage() {
  const { expenses, participants, isLoading, error, dataSource } = useTripContext();

  return (
    <FeaturePlaceholder
      title="정산"
      description="내 결제와 부담을 구분해 보고, 마지막 송금 관계를 확인해요."
      statusLabel={
        error?.message ??
        (isLoading ? "지출 불러오는 중…" : `${dataSource} · 지출 ${expenses.length}건`)
      }
    >
      <div className="settlement-placeholder">
        <PlaceholderPanel
          className="settlement-placeholder__personal"
          title="개인 요약"
          description="결제액·부담액·정산 결과"
        >
          <dl className="amount-placeholder" aria-label="개인 정산 요약 자리">
            <div>
              <dt>내가 결제한 금액</dt>
              <dd>— 원</dd>
            </div>
            <div>
              <dt>내가 부담한 금액</dt>
              <dd>— 원</dd>
            </div>
            <div>
              <dt>받을 금액 또는 보낼 금액</dt>
              <dd>— 원</dd>
            </div>
          </dl>
        </PlaceholderPanel>

        <PlaceholderPanel
          className="settlement-placeholder__transfers"
          title="최종 정산"
          description="참여자 사이의 송금 제안"
        >
          <p className="supporting-text">정산 엔진의 계산 결과만 받아 표시합니다.</p>
        </PlaceholderPanel>

        <PlaceholderPanel
          className="settlement-placeholder__expenses"
          title="지출 목록"
          description="첫 지출을 추가하면 정산 결과가 계산됩니다."
        >
          {expenses.length ? (
            <ul className="placeholder-list" aria-label="Mock 지출 원장">
              {expenses.map((expense) => (
                <li key={expense.id}>
                  <span>{expense.title}</span>&nbsp;
                  <strong>{expense.totalAmount.toLocaleString("ko-KR")}원</strong>
                </li>
              ))}
            </ul>
          ) : (
            <div className="empty-state" role="status">
              <p>첫 지출을 추가하면 정산 결과가 계산됩니다.</p>
            </div>
          )}
          <p className="supporting-text">
            참여자 {participants.length}명 · 계산 엔진은 정산 담당 모듈이 이 원장을 소비합니다.
          </p>
        </PlaceholderPanel>
      </div>
    </FeaturePlaceholder>
  );
}
