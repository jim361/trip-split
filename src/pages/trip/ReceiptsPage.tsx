import { FeaturePlaceholder } from "../../shared/components/FeaturePlaceholder";
import { PlaceholderPanel } from "../../shared/components/PlaceholderPanel";
import { useTripContext } from "../../app/providers";

const receiptSteps = [
  "이미지 선택",
  "OCR 처리",
  "항목 검토·분할",
  "합계 확인",
  "지출 저장",
] as const;

export function ReceiptsPage() {
  const { expenses, isLoading, error, dataSource } = useTripContext();
  const receiptItems = expenses.flatMap((expense) => expense.receiptItems);

  return (
    <FeaturePlaceholder
      title="영수증"
      description="영수증 항목을 확인하고 직접 확정한 지출만 정산에 반영해요."
      statusLabel={
        error?.message ??
        (isLoading
          ? "영수증 불러오는 중…"
          : `${dataSource} · 확정 항목 예시 ${receiptItems.length}개`)
      }
    >
      <ol className="receipt-steps" aria-label="영수증 등록 단계">
        {receiptSteps.map((step, index) => (
          <li key={step}>
            <span aria-hidden="true">{index + 1}</span>
            {step}
          </li>
        ))}
      </ol>

      <div className="receipts-placeholder">
        <PlaceholderPanel
          className="receipts-placeholder__image"
          title="영수증 이미지"
          description="선택한 이미지는 로컬 미리보기로만 유지합니다."
        >
          <div className="empty-state" role="status">
            <p>이미지를 선택하면 미리보기가 여기에 표시됩니다.</p>
          </div>
        </PlaceholderPanel>

        <PlaceholderPanel
          className="receipts-placeholder__items"
          title="항목 검토"
          description="이름·금액·소비자와 배분 방식을 수정하는 영역"
        >
          <ul className="placeholder-list" aria-label="Mock 영수증 항목">
            {receiptItems.map((item) => (
              <li key={item.id}>
                {item.name} · {item.amount.toLocaleString("ko-KR")}원
              </li>
            ))}
          </ul>
          <p className="supporting-text">
            parseReceipt callable 경계는 준비됐으며 실제 CLOVA 연동은 구현하지 않았습니다.
          </p>
        </PlaceholderPanel>

        <PlaceholderPanel
          className="receipts-placeholder__summary"
          title="합계 확인"
          description="항목 합계와 참여자별 배분 합계"
        >
          <p className="supporting-text">
            영수증 담당자의 검증을 통과한 뒤에만 지출 저장을 활성화합니다.
          </p>
        </PlaceholderPanel>
      </div>
    </FeaturePlaceholder>
  );
}
