# Task Function 7 - OCR

## 목표

사용자가 로컬 영수증 이미지를 선택하면 stateless Firebase Cloud Function이 CLOVA OCR을 호출하고, 결과를 저장되지 않은 수정 가능한 초안으로 돌려준다. 사용자는 항목명·금액을 수정하거나 누락 항목과 조정 금액을 추가하고 소비자를 배분한 뒤, 합계를 확인해 명시적으로 하나의 canonical `Expense`를 저장한다.

## 담당

정산·영수증 담당이 `parseReceipt`, OCR 화면과 지출 변환을 소유한다. 플랫폼·통합 담당은 Functions 공통 진입점, Auth/Trip Context, 환경변수 예시와 보안 규칙 변경을 검토·병합한다. 장소·일정·지도 담당은 장소 선택 컴포넌트의 공개 인터페이스만 제공한다.

## 범위와 의존성

- 선행: Task 1의 Firebase Auth·Functions 로컬 실행 환경과 Task 6의 `Expense`, `ReceiptItem`, validator, 지출 저장 command가 준비되어야 한다.
- 병렬 가능: CLOVA 응답 fixture를 사용하는 초안 편집 UI와 배분 테스트는 실제 API 연결 전에 구현한다.
- MVP: 동기식 단건 OCR, 메모리 내 초안, 사용자 확인 후 지출 한 건 저장, 실패 시 총액 기반 수동 등록을 포함한다.
- MVP에서는 Firebase Storage, `receiptJobs` 컬렉션, OCR 초안·원문·이미지 영구 저장, 자동 지출 저장을 사용하지 않는다.
- 후속: 비동기 큐·재시도, 여러 장 일괄 처리, 영수증 이미지 보관, OCR 작업 이력, 원본/수정본 비교는 제외한다.

## 처리 경계와 API 계약

```ts
type ParseReceiptRequest = {
  tripId: string;
  imageBase64: string;
  mimeType: string;
};

type OcrItemCandidate = {
  name: string;
  amount?: number;
  confidence?: number;
  sourceOrder: number;
};

type ParseReceiptResponse = {
  rawText: string;
  merchantName?: string;
  expenseDate?: string;
  totalAmountCandidate?: number;
  items: OcrItemCandidate[];
  warnings: string[];
};
```

`ParseReceiptResponse`는 `tech.md`의 canonical `ParsedReceipt`와 같은 구조다. `items[].sourceOrder`는 초안 생성 시 `ReceiptItem.sortOrder`로 복사하고, 사용자가 행을 재정렬하면 저장 직전에 0부터 다시 정규화한다.

- `parseReceipt`는 인증이 필요한 HTTPS callable Function으로 구현한다. `tripId`의 멤버인지 확인한 뒤에만 CLOVA를 호출한다.
- 클라이언트와 Function은 허용 MIME type과 최대 원본 크기를 하나의 설정으로 공유하고, 허용하지 않는 파일은 외부 전송 전에 거부한다.
- 선택한 이미지는 미리보기와 검토가 끝날 때까지 브라우저 메모리와 로컬 object URL에만 유지한다. 전송된 이미지 바이트는 Function 요청 처리 중에만 메모리에 두며, Storage·Firestore·로그·분석 이벤트에 이미지나 전체 OCR 원문을 남기지 않는다.
- CLOVA secret은 Functions secret/environment에만 두고 클라이언트 번들 또는 repository에 넣지 않는다.
- Function은 CLOVA 응답을 위 형태로 정규화하고 외부 오류를 공통 `AppError`로 변환한다. 최소 오류 코드는 `unauthenticated`, `permission-denied`, `invalid-image`, `payload-too-large`, `ocr-unavailable`, `ocr-no-result`다.
- `ReceiptDraft`는 화면 메모리의 임시 상태다. Firestore에는 사용자가 `지출 저장`을 누른 뒤 Task 6 validator를 통과한 `Expense`만 저장한다.

## 구현 단계

### 7.1 로컬 이미지 선택과 전송 고지

- [ ] 파일 선택기와 drag-and-drop에서 허용 MIME·크기를 검증한다.
- [ ] 로컬 object URL로 미리보기를 만들고 새 파일 선택, 취소, 화면 이탈 시 `URL.revokeObjectURL`로 해제한다.
- [ ] OCR 호출 전에 `이미지는 Firebase Storage에 저장하지 않으며 OCR 처리를 위해 CLOVA OCR로 전송됩니다.` 문구를 표시하고, CLOVA 측 보관·폐기 안내는 확인된 공급자 정책에 근거해 별도로 제공한다.
- [ ] 업로드 전송, 인식 중, 성공, 실패, 취소 상태를 구분하고 처리 중 중복 요청을 막는다.

완료 조건:

- 잘못된 파일은 CLOVA를 호출하지 않고 필드 오류를 보여준다.
- 정상 파일은 로컬 미리보기가 보이며 초기 상태로 돌아가면 브라우저 참조가 해제된다.

### 7.2 stateless `parseReceipt` Function

- [ ] callable 요청의 Auth와 trip membership을 검증한다.
- [ ] base64와 MIME을 안전하게 디코딩하고 이미지 크기·형식을 서버에서도 다시 검증한다.
- [ ] CLOVA OCR을 호출하고 secret, timeout, 외부 오류를 처리한다.
- [ ] 원문, 가게명·날짜·총액 후보, 항목 후보를 `ParseReceiptResponse`로 정규화한다.
- [ ] 이미지·전체 OCR 원문·민감한 CLOVA 응답이 로그에 기록되지 않게 한다.
- [ ] 성공·실패 후 모든 요청 데이터를 폐기하고 Firestore나 Storage를 쓰지 않는다.

완료 조건:

- mock CLOVA fixture에서 정규화된 응답을 반환하고, 인증·권한·형식·외부 장애가 지정된 오류 코드로 반환된다.
- Function 실행 전후 Firestore와 Storage에 OCR 관련 문서·파일이 생성되지 않는다.

### 7.3 수정 가능한 영수증 초안

- [ ] OCR 응답으로 저장되지 않는 `ReceiptDraft`를 생성한다.
- [ ] 지출명, 날짜, 카테고리, 총액 후보, 결제자, 연결 장소·일정을 수정할 수 있게 한다.
- [ ] 각 OCR 항목의 이름과 금액을 수정하고, 잘못 인식한 행을 제외하며, 누락 항목을 수동 추가할 수 있게 한다.
- [ ] OCR의 `sourceOrder`를 `ReceiptItem.sortOrder`로 옮기고 사용자가 재정렬한 순서를 저장 직전에 정규화한다.
- [ ] 수동 행은 `source: "manual"`, OCR 행은 `source: "ocr"`로 표시한다.
- [ ] 할인, 봉사료, 기타 조정 금액을 별도 `kind` 행으로 추가한다.
- [ ] 원문 보기와 `다시 인식`을 제공하되 원문은 화면을 벗어나면 폐기한다.

완료 조건:

- OCR 결과를 한 줄도 그대로 믿지 않고 모든 저장 필드를 사용자가 편집할 수 있다.
- 수정, 행 제외, 누락 항목 추가, 할인·봉사료·조정 추가가 새 OCR 호출 없이 초안에 반영된다.

### 7.4 소비자 배분과 합계 검증

- [ ] `전체 균등 분할`은 선택한 참여자에게 총액을 나누고 `allocationMethod: "equal"`, 빈 `receiptItems`로 만든다.
- [ ] `항목별 분할`은 각 메뉴를 소비한 참여자를 지정하고 공용 메뉴를 선택한 사람끼리 균등 배분한다.
- [ ] 각 항목 또는 조정 행에서 참여자별 부담 금액을 직접 입력할 수 있게 한다.
- [ ] `참여자별 직접 입력`은 총액 기준 `allocationMethod: "custom"`, 빈 `receiptItems`로 만든다.
- [ ] Task 6의 1원 나머지 규칙과 validator를 그대로 사용한다.
- [ ] `항목+조정 합계`, `영수증 총액`, `참여자별 배분 합계`를 함께 보여주고 차액이 0원이 아닐 때 저장을 막는다.

완료 조건:

- 전체 균등, 메뉴별 소비자, 공용 메뉴 균등, 직접 부담액, 할인·봉사료·기타 조정이 모두 canonical allocation으로 변환된다.
- 차액이 있으면 금액과 수정할 위치가 표시되고 저장할 수 없다.

### 7.5 명시적 지출 저장

- [ ] 사용자가 `확인하고 지출 저장`을 누를 때만 `ReceiptDraft`를 `Expense`로 변환한다.
- [ ] 항목별 저장은 `allocationMethod: "itemized"`, `source: "ocr"`, 검토된 `receiptItems`와 집계된 `allocatedAmounts`를 사용한다.
- [ ] 저장 직전에 Task 6 validator를 다시 실행하고 현재 uid를 `createdBy/updatedBy`에 넣는다.
- [ ] 저장 중 버튼을 비활성화해 중복 지출 생성을 막고, 성공하면 저장된 지출 상세로 이동한 뒤 이미지·원문·초안을 폐기한다.
- [ ] 취소하거나 화면을 벗어나면 확인되지 않은 OCR 결과를 저장하지 않는다.

완료 조건:

- OCR 성공만으로 Firestore 지출 수가 변하지 않고, 명시적으로 저장한 뒤에만 한 건 증가한다.
- 저장된 지출은 Task 6 엔진에서 별도 변환 없이 개인 소비와 정산 결과에 반영된다.

### 7.6 실패와 총액 기반 수동 등록

- [ ] OCR 인식 실패, 항목 미검출, 네트워크 오류, timeout, rate limit별 복구 문구와 `다시 시도`를 제공한다.
- [ ] 항상 `전체 금액으로 직접 등록` 경로를 제공해 제목, 총액, 결제자, 소비자와 equal/custom 배분만으로 등록할 수 있게 한다.
- [ ] 수동 fallback은 인식 항목을 만들지 않고 `source: "manual"`, 빈 `receiptItems`인 total-only `Expense`를 저장한다.
- [ ] 오류 상태에서도 사용자가 선택한 로컬 이미지를 교체하거나 제거할 수 있게 한다.

완료 조건:

- CLOVA가 응답하지 않아도 사용자는 영수증 탭을 벗어나지 않고 총액 기반 지출을 완료할 수 있다.
- 수동 fallback에도 합계 검증, 1원 나머지, 명시 저장 규칙이 동일하게 적용된다.

## 단위 테스트

- [ ] CLOVA fixture의 원문·총액·항목 후보가 `ParseReceiptResponse`로 정규화된다.
- [ ] 금액이 없는 항목, 중복 행, 총액 후보 여러 개, 항목 없는 응답이 경고와 편집 가능한 초안으로 변환된다.
- [ ] `순두부 12,000원: 나`, `커피 6,000원: 지연`, `감자전 15,000원: 나·민수·지연 균등`이 각각 `12,000 / 6,000 / 5,000·5,000·5,000원`으로 배분된다.
- [ ] 누락 항목 수동 추가와 할인·봉사료·기타 조정 후 항목 합계가 총액과 정확히 일치해야 저장 가능하다.
- [ ] 전체 균등 및 수동 fallback의 1원 나머지가 Task 6 엔진과 동일하다.
- [ ] 초안 취소·재인식·저장 성공 시 이미지 URL, raw text와 draft가 폐기된다.

## 통합 및 UI 테스트

- [ ] Auth 없음, trip 비멤버, invalid image, payload 초과, CLOVA timeout과 빈 결과를 Function 통합 테스트로 검증한다.
- [ ] Firebase Emulator와 mock CLOVA로 `로컬 선택 → OCR → 항목 수정/추가 → 배분 → 합계 검증 → 명시 저장 → 정산 재계산`을 E2E 테스트한다.
- [ ] OCR 실패 후 total-only 수동 지출을 저장하는 E2E를 테스트한다.
- [ ] OCR 호출 및 초안 편집만으로 Firestore·Storage에 쓰기가 발생하지 않는지 테스트한다.
- [ ] 390px 모바일의 단계형 흐름과 PC의 이미지/초안 2열 흐름에서 로딩·오류·키보드·터치 조작을 확인한다.

## 완료 기준

- 로컬 이미지는 처리 중에만 사용되고 Firebase Storage나 Firestore에 영구 저장되지 않는다.
- OCR 항목명·금액 수정, 누락 항목 추가, 소비자/직접 금액 배분, 할인·봉사료·조정 배분과 합계 검증이 가능하다.
- OCR 성공 여부와 무관하게 사용자 명시 확인 전에는 지출이나 정산 결과가 변하지 않는다.
- OCR 실패 시 전체 금액 기반 수동 등록을 완료할 수 있다.
- 명시된 Function, 단위, Emulator, E2E, 반응형 UI 테스트가 모두 통과한다.
