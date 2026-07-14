# Task Function 6 - Settlement

## 목표

하나의 정산 원장에서 참여자별 `내가 결제한 금액`, `내가 부담한 금액`, `정산 결과(net)`를 서로 다른 값으로 계산한다. 지출 전체 균등 분할, 영수증 항목별 분할, 참여자별 직접 금액 입력을 지원하고, 개인 소비 내역과 최종 송금 제안을 같은 데이터에서 일관되게 파생한다.

## 담당

정산·영수증 담당이 구현을 소유하고 플랫폼·통합 담당이 공통 타입, Firestore 경로, 라우트와 보안 규칙 변경을 검토·병합한다.

## 범위와 의존성

- 선행: Task 1의 TypeScript·테스트 기반, Firebase Emulator, Auth/Trip Context가 준비되어야 한다.
- 선행 계약: `TripMember`와 `Participant` 분리, 공통 ID·timestamp·오류 형식, repository 인터페이스, 강릉 fixture가 확정되어야 한다.
- 병렬 가능: 순수 정산 엔진과 mock repository 기반 UI는 Firebase 연결 전에 개발할 수 있다.
- 후행: Task 7 OCR은 이 문서의 `Expense`, `ReceiptItem`, 검증 함수와 지출 저장 흐름을 재사용한다.
- MVP: 원화 단일 통화, 지출당 결제자 한 명, 실시간 원장 재계산, 개인 소비 조회와 송금 제안까지 포함한다.
- 후속: 복수 결제자, 외화·환율, 송금 완료 상태, 정산 snapshot, 수정 이력, 특수 보상 규칙은 제외한다.

## Canonical 데이터 계약

```ts
type AllocationMethod = "equal" | "itemized" | "custom";

type MoneyAllocation = {
  participantId: string;
  amount: number; // KRW 원 단위 정수
};

type ExpensePayer = {
  participantId: string;
  amount: number;
};

type ReceiptItem = {
  id: string;
  kind: "item" | "discount" | "serviceFee" | "adjustment";
  name: string;
  amount: number;
  consumers: string[];
  allocationMethod: "equal" | "custom";
  allocatedAmounts: MoneyAllocation[];
  source: "ocr" | "manual";
  sortOrder: number;
};

type Expense = {
  id: string;
  tripId: string;
  title: string;
  category: string;
  expenseDate: string;
  totalAmount: number;
  currency: "KRW";
  payer: ExpensePayer;
  consumers: string[];
  allocationMethod: AllocationMethod;
  allocatedAmounts: MoneyAllocation[];
  receiptItems: ReceiptItem[];
  source: "manual" | "ocr";
  placeId?: string;
  itineraryItemId?: string;
  memo?: string;
  createdBy: string;
  updatedBy: string;
  createdAt: number;
  updatedAt: number;
};
```

`receiptItems`는 MVP에서 `Expense` 문서 안에 저장한다. `equal`은 지출 전체, `itemized`는 각 `ReceiptItem`, `custom`은 지출 전체에 직접 입력한 금액을 기준으로 최종 `allocatedAmounts`를 만든다.

## 계산 불변식

- 모든 금액은 부동소수점이 아닌 원 단위 정수다.
- `payer.amount === totalAmount`이며 MVP의 결제자는 한 명이다.
- `sum(expense.allocatedAmounts.amount) === expense.totalAmount`다.
- `itemized`에서는 하나 이상의 `receiptItems`가 필요하고 `sum(receiptItems.amount) === totalAmount`이며, 각 항목의 `sum(allocatedAmounts.amount) === item.amount`다.
- 일반 항목과 봉사료는 양수, 할인은 음수, 기타 조정은 0이 아닌 양수 또는 음수다. 조정을 반영한 참여자별 최종 부담액은 음수가 될 수 없다.
- 지출과 각 항목의 `allocatedAmounts`는 consumer마다 정확히 한 행을 가지며 `participantId` 중복을 허용하지 않는다. 0원으로 계산된 consumer도 행을 유지하고 `consumers` 집합과 배분 행의 참여자 집합이 같아야 한다.
- 삭제되거나 비활성인 참여자 ID를 새 지출에 저장하지 않는다. `linkedUid`는 같은 여행의 멤버를 참조하고 한 여행에서 중복될 수 없다.
- 균등 분할은 `base = Math.trunc(amount / count)`로 계산하고 남은 ±1원을 UI에 표시된 `consumers` 순서대로 배분한다. 같은 입력은 모든 클라이언트에서 같은 결과를 만든다.
- 참여자 `p`의 파생값은 다음과 같다.
  - 결제액 `paid(p) = sum(expense.payer.amount where payer.participantId === p)`
  - 부담액 `owed(p) = sum(allocation.amount where allocation.participantId === p)`
  - 정산 결과 `net(p) = paid(p) - owed(p)`
  - `net > 0`이면 받을 금액, `net < 0`이면 보낼 금액, `net === 0`이면 정산 없음이다.

## 구현 단계

### 6.1 타입, fixture와 검증기

- [ ] `Participant`, `Expense`, `ExpensePayer`, `ReceiptItem`, `MoneyAllocation`, `AllocationMethod` 타입과 runtime validator를 정의한다.
- [ ] `TripMember`와 `Participant`를 혼용하지 않도록 지출 폼과 엔진 입력은 `participantId`만 받게 한다.
- [ ] 예시 영수증과 숙소 지출을 포함한 공통 강릉 fixture를 만든다.
- [ ] 금액 정수 여부, 결제액·총액·배분액 합계, 배분 participantId 유일성, 소비자 집합, itemized 최소 한 항목, 항목 합계, 음수 부담액과 linkedUid 참조·유일성을 검사하고 필드별 오류를 반환한다.

완료 조건:

- 유효한 fixture가 validator를 통과하고, 합계 불일치·빈 소비자·존재하지 않는 참여자·소수 금액은 저장 전에 거부된다.

### 6.2 순수 배분 엔진

- [ ] 지출 전체를 선택한 소비자에게 배분하는 `equal` 계산을 구현한다.
- [ ] 각 메뉴·공용 메뉴·할인·봉사료·기타 조정을 항목별 소비자에게 배분하고 이를 지출 `allocatedAmounts`로 합치는 `itemized` 계산을 구현한다.
- [ ] 참여자별 부담 금액을 직접 입력하고 합계를 검증하는 `custom` 계산을 구현한다.
- [ ] 소비자 순서에 따른 양수·음수 1원 나머지 배분을 구현한다.
- [ ] 계산 함수는 입력을 변경하지 않고 같은 입력에 같은 결과를 반환하게 한다.

완료 조건:

- 세 분할 방식이 모두 정확한 `allocatedAmounts`를 만들며 할인·봉사료·기타 조정을 포함해 총액이 보존된다.

### 6.3 개인 집계와 최종 송금 엔진

- [ ] 참여자별 `paid`, `owed`, `net`을 한 번의 집계로 계산한다.
- [ ] 개인 부담액을 카테고리별로 합산한다.
- [ ] 날짜, 장소, 메뉴 또는 지출 항목 단위의 개인 소비 행을 생성하고 원본 `expenseId`·`receiptItemId`를 연결한다.
- [ ] 양수 net의 채권자와 음수 net의 채무자를 안정적으로 정렬해 결정적인 송금 제안을 만든다.
- [ ] `participantId` 오름차순을 tie-breaker로 사용해 송금 제안과 공유 문구를 결정적으로 생성한다.

완료 조건:

- 모든 참여자의 `sum(net) === 0`이고 송금 후 각 net이 0이 된다.
- 개인 소비 합계가 같은 참여자의 `owed`와 일치하고, 상세 행에서 원본 지출을 열 수 있다.

### 6.4 repository와 실시간 원장

- [ ] `trips/{tripId}/participants/{participantId}`와 `trips/{tripId}/expenses/{expenseId}`의 CRUD·구독 인터페이스를 구현한다.
- [ ] 생성 시 `createdBy/createdAt`, 수정 시 `updatedBy/updatedAt`을 Auth uid와 server timestamp로 기록한다.
- [ ] 저장 직전에 동일한 validator를 실행하고 Firestore converter에서도 형식을 검증한다.
- [ ] `onSnapshot` 결과를 정산 엔진에 전달해 지출이나 참여자 변경 시 파생 결과만 다시 계산한다. 별도 settlement snapshot은 저장하지 않는다.
- [ ] 참여자 삭제는 참조 중이면 차단하고, 비활성화는 기존 원장 표시를 유지하되 새 지출 선택지에서는 제외한다.

완료 조건:

- Emulator의 두 클라이언트 중 하나가 지출을 추가·수정·삭제하면 다른 클라이언트의 결제액, 부담액, net, 송금 제안이 갱신된다.

### 6.5 지출 입력 UI

- [ ] 수동 지출의 제목, 날짜, 카테고리, 총액, 결제자, 장소·일정 연결, 메모 입력을 구현한다.
- [ ] `전체 균등`, `항목별 분할`, `직접 입력` 분할 방식을 전환할 수 있게 한다.
- [ ] 항목별 분할에서 항목명·금액을 추가·수정·삭제하고 각 항목 소비자 또는 직접 부담액을 지정한다.
- [ ] 공용 메뉴는 선택한 소비자끼리 균등 분할한다.
- [ ] 할인, 봉사료, 기타 조정 행을 추가하고 소비자 또는 직접 부담액을 지정한다.
- [ ] 총액, 항목 합계, 참여자별 배분 합계의 검증 상태와 1원 나머지 결과를 저장 전에 보여준다.
- [ ] 저장 중 중복 제출을 막고 성공 후 저장된 지출 상세로 이동한다.

완료 조건:

- 유효하지 않은 합계는 저장 버튼이 활성화되지 않고, 오류가 있는 행과 수정 방법이 표시된다.
- 전체 균등, 메뉴별 소비자, 직접 부담액 중 하나를 선택해 Firestore에 canonical `Expense`를 저장할 수 있다.

### 6.6 개인 정산과 지출 관리 UI

- [ ] 모바일 정산 화면은 `개인 요약 → 최종 정산 → 지출 목록` 순서로 배치한다.
- [ ] 개인 요약에 `내가 결제한 금액`, `내가 부담한 금액`, `받을 금액` 또는 `보낼 금액`을 서로 다른 카드로 표시한다.
- [ ] 카테고리별 개인 소비 합계와 날짜·장소·메뉴/지출 항목별 개인 소비 내역을 표시한다.
- [ ] PC에서는 지출 관리와 개인/전체 정산 결과를 다중 열로 확장하되 모바일과 같은 정보 구조를 유지한다.
- [ ] 참여자 선택, 지출 추가·수정·삭제, 원본 지출 열기, 정산 문구 복사를 구현한다.
- [ ] 로딩·빈 상태·구독 오류·권한 오류를 구현하고 금액은 한국어 KRW 형식과 tabular numerals로 표시한다.

완료 조건:

- 한 사용자가 참여자를 바꿔 보아도 결제액·부담액·net의 의미가 섞이지 않는다.
- 390px 모바일과 PC에서 카테고리 합계, 상세 내역, 송금 제안, 지출 CRUD에 접근할 수 있다.

## 단위 테스트

- [ ] `10,000원 / 3명`은 소비자 순서대로 `3,334 / 3,333 / 3,333원`이 된다.
- [ ] `1원 / 3명`은 `1 / 0 / 0원`이 되며 세 consumer의 배분 행이 모두 유지된다.
- [ ] `-1,000원 할인 / 3명`은 소비자 순서대로 `-334 / -333 / -333원`이 된다.
- [ ] 점심 33,000원을 `순두부 12,000원: 나`, `커피 6,000원: 지연`, `감자전 15,000원: 나·민수·지연 균등`으로 나누면 부담액은 `나 17,000원`, `지연 11,000원`, `민수 5,000원`이다.
- [ ] 숙소 180,000원을 `나·민수·지연·도윤`이 균등 부담하면 각 45,000원이다.
- [ ] 위 점심을 내가 결제하고 숙소를 민수가 결제하면 전체 `paid / owed / net`은 각각 `나 33,000 / 62,000 / -29,000`, `민수 180,000 / 50,000 / 130,000`, `지연 0 / 56,000 / -56,000`, `도윤 0 / 45,000 / -45,000원`이다.
- [ ] custom 배분 합계가 총액과 다르거나 항목 합계가 영수증 총액과 다르면 검증 오류가 난다.
- [ ] 같은 `participantId`의 배분 행이 두 개 있거나 consumer와 배분 참여자 집합이 다르면 검증 오류가 난다.
- [ ] 할인 배분 결과 한 참여자의 최종 부담액이 음수가 되면 검증 오류가 난다.
- [ ] 빈 지출 목록, 비활성 참여자, 같은 금액의 채권자·채무자에서도 결과 순서가 결정적이다.

## 통합 및 UI 테스트

- [ ] mock repository로 지출 생성·수정·삭제와 세 분할 폼의 성공/실패 흐름을 테스트한다.
- [ ] Firebase Emulator에서 권한이 있는 멤버만 참여자와 지출을 쓰고, 다른 멤버에게 변경이 실시간 반영되는지 테스트한다.
- [ ] 개인 소비의 카테고리 합계와 상세 행 합계가 정산 엔진 `owed`와 같은지 테스트한다.
- [ ] 모바일에서 요약→최종 정산→지출 목록 순서와 PC 다중 열 레이아웃을 시각 회귀 또는 E2E로 확인한다.
- [ ] 정산 문구의 모든 송금액 합계가 채무자 net 및 채권자 net과 일치하는지 테스트한다.

## 완료 기준

- 세 분할 방식과 조정 배분이 canonical `Expense`를 만들고 모든 계산 불변식을 만족한다.
- 개인 화면에서 결제액, 부담액, 받을/보낼 금액, 카테고리 합계, 날짜·장소·메뉴/지출별 내역을 확인할 수 있다.
- 실시간 변경이 별도 정산 snapshot 없이 모든 파생 결과와 정산 문구에 반영된다.
- 명시된 단위·repository·Emulator·반응형 UI 테스트가 모두 통과한다.
- Task 7이 별도 변환 로직 없이 같은 지출 저장 명령과 validator를 재사용할 수 있다.
