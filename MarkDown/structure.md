# Trip Split Structure Draft

## 1. 프로젝트 구조 원칙

Trip Split은 Vite + React + TypeScript 기반의 모바일 우선 웹/PWA로 만든다. 세 명의 작업 영역은 `플랫폼·통합`, `정산·영수증`, `장소·일정·지도`로 나누되, 공통 계약을 먼저 고정하고 각 기능을 독립적으로 개발한 뒤 작은 단위로 지속 통합한다.

핵심 원칙은 다음과 같다.

- 화면은 사용 흐름 중심으로 구성한다.
- 지도, 정산, OCR, Firebase 호출은 UI와 분리한다.
- 정산 로직은 순수 함수로 작성해 테스트하기 쉽게 만든다.
- 지도 표시는 provider/service로 감싸 네이버 지도 의존성을 한 곳에 모은다.
- Firestore 경로와 공통 타입은 세 명이 함께 검토하고 플랫폼·통합 담당자가 최종 승인한다.
- 사용자-facing 로그인은 선택으로 두되, 내부적으로는 Firebase Auth `uid`를 기준으로 여행 멤버와 권한을 관리한다.
- 로그인·공동 편집 주체인 `TripMember`와 비용을 부담하는 `Participant`를 분리한다.
- 모바일과 PC는 `일정·지도`, `정산`, `영수증`의 같은 세 개 주요 목적지를 사용하고, 화면 폭에 따라 배치만 확장한다.

## 2. 역할 분담

### 플랫폼·통합 담당

담당: 앱 기반, 사용자 세션, 공통 계약, 통합 품질과 최종 병합

- Vite + React + TypeScript 프로젝트와 모바일 우선 PWA 앱 셸 구성
- 공통 라우팅, `TripContext`, 디자인 시스템과 공통 UI 관리
- Firebase 클라이언트, Emulator Suite, Anonymous Auth와 선택적 Google 계정 연결
- 여행 생성, 공유 코드·초대 링크 참여, 멤버와 권한 관리
- Firestore 보안 규칙과 실시간 세션의 통합 검증
- `.trip.json` 백업·복원·데모 데이터 흐름 관리
- 공통 타입, Firestore 경로, package/lock 파일 변경의 최종 승인
- 통합 QA, 릴리스 기준 확인과 PR 최종 병합

### 정산·영수증 담당

담당: `Participant`, `Expense`, `ReceiptItem`, 정산 엔진과 OCR 검토 흐름

- 결제액, 부담액, 받을 금액·보낼 금액을 분리한 개인 정산 모델 설계
- 전체 균등, 영수증 항목별, 참여자별 직접 입력 분할 계산
- 할인, 봉사료, 기타 조정 금액 배분과 원 단위 나머지 처리
- 개인별 카테고리 합계와 날짜·장소·메뉴/지출 항목별 소비 내역 계산
- 수동 지출 등록, 지출 목록과 최종 송금 결과 UI
- CLOVA OCR 요청, 항목 수정·추가, 합계 검증과 수동 등록 fallback
- 정산 repository와 Firestore 데이터 구조 제안
- 순수 계산 함수, fixture와 단위 테스트 관리

### 장소·일정·지도 담당

담당: 장소 정규화, 일정 편집, 지도 표시와 네이버 API 어댑터

- 네이버 장소 검색, 네이버 지도 장소 링크 파싱, 직접 입력 흐름
- 장소 보관함과 날짜별 일정·세로 타임라인 UI
- 앱 내부 `Place` 정규화 모델과 장소 repository 제안
- 일정 순서 기반 커스텀 번호 핀과 날짜별 색상 적용
- 같은 날짜 장소를 잇는 직선 동선 표시
- 지도 provider 인터페이스와 네이버 지도 어댑터
- 장소·일정·지도 fixture와 단위/통합 테스트 관리

### 공유 파일과 Cloud Function 소유권

| 범위 | 주 담당 | 변경 규칙 |
| --- | --- | --- |
| `package.json`, lockfile, `src/app/routes.tsx`, Firebase 진입점·설정·보안 규칙 | 플랫폼·통합 | 다른 담당자는 변경안을 제안하고 플랫폼·통합 담당자가 병합한다. |
| `features/settlement`, `features/receipts`, `expensesRepository` | 정산·영수증 | 공통 타입이나 Firestore 경로 변경은 세 명의 리뷰가 필요하다. |
| `features/places`, `features/itinerary`, `features/map`, 관련 repository | 장소·일정·지도 | 공통 타입이나 Firestore 경로 변경은 세 명의 리뷰가 필요하다. |
| 여행 생성, 공유 코드 검증·참여 Function | 플랫폼·통합 | 인증·보안 규칙과 함께 통합한다. |
| `parseReceipt` Function | 정산·영수증 | OCR 비밀 키, 검증·오류 형식은 공통 계약을 따른다. |
| 장소 검색, 장소 링크 파싱 Function | 장소·일정·지도 | 네이버 비밀 키, 검증·오류 형식은 공통 계약을 따른다. |
| `functions/src/index.ts`, 공통 HTTP·환경변수 유틸리티 | 플랫폼·통합 | 각 담당의 handler를 export만 하며 도메인 로직을 두지 않는다. |

담당 영역은 코드 소유권과 1차 리뷰 책임을 뜻한다. 다른 영역을 수정할 수 없는 경계가 아니며, 계약 변경은 PR 설명에 영향 범위와 migration 여부를 기록한 뒤 플랫폼·통합 담당자가 최종 승인한다.

## 3. 권장 폴더 구조

```text
trip-split/
  public/
    manifest.webmanifest
    icons/
  src/
    app/
      App.tsx
      routes.tsx
      providers/
    pages/
      HomePage.tsx
      ImportPage.tsx
      trip/
        TripShell.tsx
        ItineraryPage.tsx
        MapPage.tsx
        SettlementPage.tsx
        ReceiptsPage.tsx
    features/
      trips/
        components/
        hooks/
        trip.types.ts
      auth/
        components/
        hooks/
        auth.types.ts
      members/
        components/
        hooks/
        member.types.ts
      places/
        components/
        hooks/
        place.types.ts
        placeLinkParser.ts
      itinerary/
        components/
        hooks/
        itinerary.types.ts
      map/
        components/
        map.types.ts
        mapAdapter.ts
        naverMapAdapter.ts
      settlement/
        components/
        settlement.types.ts
        settlementEngine.ts
        settlementText.ts
      receipts/
        components/
        receipt.types.ts
        receiptOcr.ts
    shared/
      components/
      contracts/
        error.ts
        id.ts
        repository.ts
        timestamp.ts
      hooks/
      lib/
      styles/
      types/
    services/
      firebase/
        client.ts
        authRepository.ts
        membersRepository.ts
        tripsRepository.ts
        placesRepository.ts
        itineraryRepository.ts
        expensesRepository.ts
      functions/
        callable.ts
    test/
      fixtures/
        gangneungTrip.ts
  functions/
    src/
      index.ts
      naver/
        places.ts
        placeLinks.ts
      share/
        shareCodes.ts
        trips.ts
      ocr/
        clova.ts
      shared/
        http.ts
        env.ts
  docs/
```

## 4. 앱 셸과 라우트 계약

여행에 입장한 뒤에는 모바일과 PC 모두 `TripShell` 안에서 같은 세 개의 주요 목적지를 사용한다. 반응형 breakpoint는 패널의 위치와 열 수만 바꾸며, 별도의 PC 전용 대시보드나 모바일 전용 URL을 만들지 않는다.

| 메뉴 | 라우트 | 기본 역할 |
| --- | --- | --- |
| 일정·지도 | `/trips/:tripId/itinerary` | 상단 지도 동선과 날짜별 일정·장소 배치 |
| 정산 | `/trips/:tripId/settlement` | 개인 소비 요약, 최종 정산과 지출 관리 |
| 영수증 | `/trips/:tripId/receipts` | OCR 검토, 항목 편집과 분할 |

- `/trips/:tripId`는 일정 라우트로 redirect한다.
- 기존 `/trips/:tripId/map`은 북마크·공유 링크 호환을 위해 `/trips/:tripId/itinerary?map=expanded`로 redirect한다.
- 세 메뉴의 순서와 명칭은 모바일 하단 내비게이션과 PC 확장 내비게이션에서 동일하다.
- 장소 보관함은 독립 라우트나 네 번째 메뉴로 만들지 않고 일정·지도 통합 페이지의 패널 또는 바텀시트로 제공한다.
- 여행 제목, 참여자, 공유, 익명/계정 연결과 동기화 상태는 `TripShell`이 공통으로 제공한다.
- 각 페이지는 `tripId`를 URL에서 받고, 인증·멤버·여행 세션은 `TripContext`를 통해 받는다.
- PWA service worker는 정적 앱 셸만 캐시한다. MVP의 Firestore 편집과 네이버·OCR 호출은 온라인 연결을 요구하며, 오프라인 변경을 저장 완료로 표시하지 않는다.

## 5. 주요 모듈 경계

### `features/itinerary`

날짜별 타임테이블과 장소 배치를 담당한다. 지도나 정산 계산을 직접 하지 않고, `placeId`, `date`, `order`를 포함한 일정 데이터를 제공한다. 같은 날짜의 `order`는 중복되지 않는 0부터 시작하는 정수로 정규화한다.

### `features/map`

지도 렌더링만 담당한다. 입력은 앱 내부 `Place` 목록과 `ItineraryItem`의 `date`, `placeId`, `order`뿐이며 Firestore 문서, 네이버 검색 응답, 정산 데이터는 받지 않는다. 지도 adapter는 이 입력으로 날짜별 색상, 일정 순서 번호 핀과 직선 동선을 그린다.

### `features/settlement`

정산 계산을 담당한다. UI나 Firebase에 의존하지 않는 순수 함수로 `Expense`를 검증·배분하고, 참여자별 결제액·부담액·정산 차액과 결정적인 송금 제안을 계산한다.

### `features/receipts`

사용자 기기의 영수증 이미지 선택, OCR 요청, 항목 편집·추가, 분할과 합계 검증을 담당한다. 이미지는 MVP에서 Firebase Storage에 영구 저장하지 않는다. OCR 결과를 자동으로 정산에 반영하지 않고, 사용자가 검토하고 확정한 `Expense`와 `ReceiptItem`만 저장한다. OCR 실패 시 총액 기반 수동 지출 등록으로 전환한다.

### `services/firebase`

Firestore 읽기/쓰기와 실시간 구독을 담당한다. 화면 컴포넌트와 순수 도메인 함수에서 Firebase SDK를 직접 호출하지 않으며, repository가 Firestore Timestamp와 오류를 공통 앱 계약으로 변환한다.

### `functions`

클라이언트에 노출하면 안 되는 API 호출을 담당한다. 네이버 장소 검색, 장소 링크 파싱, CLOVA OCR과 공유 코드 검증은 이곳에서 처리한다. 각 handler는 동일한 인증 확인, 입력 검증과 `AppError` 응답 형식을 사용한다.

## 6. 데이터 모델과 도메인 계약

```ts
type EntityId = string;
type ParticipantId = EntityId;
type EpochMillis = number;
type LocalDate = string; // YYYY-MM-DD
type KrwAmount = number; // 원 단위 정수

type AllocationMethod = "equal" | "itemized" | "custom";

type MoneyAllocation = {
  participantId: ParticipantId;
  amount: KrwAmount;
};

type ExpensePayer = {
  participantId: ParticipantId;
  amount: KrwAmount;
};

type Trip = {
  id: EntityId;
  title: string;
  regionType: "domestic" | "international";
  currency: "KRW";
  startDate: LocalDate;
  endDate: LocalDate;
  ownerUid: string;
  shareCode: string;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

type UserProfile = {
  uid: string;
  displayName: string;
  email?: string;
  photoURL?: string;
  authProvider: "anonymous" | "google";
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

type TripMember = {
  uid: string;
  tripId: EntityId;
  displayName: string;
  photoURL?: string;
  role: "editor";
  joinedAt: EpochMillis;
  lastActiveAt: EpochMillis;
};

type Participant = {
  id: ParticipantId;
  tripId: EntityId;
  name: string;
  color?: string;
  linkedUid?: string;
  isActive: boolean;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

type Place = {
  id: EntityId;
  tripId: EntityId;
  name: string;
  address?: string;
  lat?: number;
  lng?: number;
  provider: "naver" | "manual";
  source: "naverSearch" | "naverLink" | "manual";
  providerPlaceId?: string;
  sourceUrl?: string;
  addedBy?: string;
  memo?: string;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

type ItineraryItem = {
  id: EntityId;
  tripId: EntityId;
  date: LocalDate;
  startTime?: string;
  endTime?: string;
  placeId?: EntityId;
  title: string;
  memo?: string;
  order: number;
  updatedBy?: string;
  updatedAt: EpochMillis;
};

type ReceiptItem = {
  id: EntityId;
  kind: "item" | "discount" | "serviceFee" | "adjustment";
  name: string;
  amount: KrwAmount;
  consumers: ParticipantId[];
  allocationMethod: "equal" | "custom";
  allocatedAmounts: MoneyAllocation[];
  source: "ocr" | "manual";
  sortOrder: number;
};

type Expense = {
  id: EntityId;
  tripId: EntityId;
  title: string;
  category: string;
  expenseDate: LocalDate;
  totalAmount: KrwAmount;
  currency: "KRW";
  payer: ExpensePayer;
  consumers: ParticipantId[];
  allocationMethod: AllocationMethod;
  allocatedAmounts: MoneyAllocation[];
  receiptItems: ReceiptItem[];
  source: "manual" | "ocr";
  placeId?: EntityId;
  itineraryItemId?: EntityId;
  memo?: string;
  createdBy: string;
  updatedBy: string;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

type ShareCode = {
  code: string;
  tripId: EntityId;
  createdBy: string;
  createdAt: EpochMillis;
  expiresAt?: EpochMillis;
  isActive: boolean;
  maxUses?: number;
  useCount: number;
};
```

`TripMember`는 Firebase Auth 사용자이자 Firestore 접근 권한의 주체다. MVP에서는 모든 멤버의 `role`을 `editor`로 저장하고 여행 생성자는 `Trip.ownerUid`로 구분한다. `owner | editor | viewer` 역할 확장은 후속에서 타입과 보안 규칙을 함께 넓힌다. `Participant`는 정산 원장의 주체이며 계정이 없는 동행자도 생성할 수 있다. 사용자가 자기 소비 내역을 볼 때는 `Participant.linkedUid`로 선택 연결하되, 두 타입이나 ID를 같은 값으로 간주하지 않는다. `linkedUid`가 있으면 같은 여행의 `TripMember.uid`를 참조해야 하고 한 여행에서 하나의 `Participant`만 같은 uid를 연결할 수 있다.

`Place`는 네이버 검색 응답, 네이버 링크와 직접 입력을 모두 같은 형태로 정규화한 뒤 저장한다. 지도 기능에는 정규화된 `Place`와 `ItineraryItem.date/placeId/order`만 전달하며, provider 원본 응답은 도메인 모델에 저장하지 않는다.

### 정산 불변식

- 모든 KRW 금액은 소수점 없는 원 단위 정수다. UI에서 받은 쉼표와 통화 기호는 저장 전에 제거·검증한다.
- 단일 결제자 MVP에서 `expense.payer.amount === expense.totalAmount`여야 한다.
- `sum(expense.allocatedAmounts[].amount) === expense.totalAmount`여야 한다.
- `equal`은 `totalAmount`를 `consumers`에게 균등 배분하고, `custom`은 사용자가 입력한 `allocatedAmounts`를 사용한다.
- `itemized`는 하나 이상의 `receiptItems`가 필요하다. 모든 `receiptItems[].allocatedAmounts`를 참여자별로 합산해 `expense.allocatedAmounts`를 만들며 `sum(receiptItems[].amount) === expense.totalAmount`여야 한다.
- 각 항목도 `sum(item.allocatedAmounts[].amount) === item.amount`여야 한다. 항목의 `equal`과 `custom`도 지출과 같은 배분 규칙을 사용한다.
- 일반 항목과 봉사료는 양수, 할인은 음수이고 기타 조정은 0이 아닌 양수 또는 음수다. 조정까지 반영한 참여자별 최종 부담액은 음수가 될 수 없다.
- 균등 분할은 `base = Math.trunc(amount / count)`로 계산하고, 남은 `±1원`을 UI에 표시된 `consumers` 배열 순서대로 배분한다. 배열 순서는 저장하고 계산 중에 다시 정렬하지 않는다.
- `consumers`는 비어 있거나 중복될 수 없다. 지출과 각 항목의 `allocatedAmounts`에는 각 consumer마다 정확히 한 행을 두고 `participantId` 중복을 금지하며, 두 참여자 집합은 일치해야 한다. 1원보다 소비자가 많은 균등 분할처럼 0원인 배분 행도 유지한다. 삭제되거나 비활성인 참여자를 새 지출에 저장하지 않는다.
- OCR 값은 초안일 뿐이다. `source`로 OCR/수동 항목을 구분하고 사용자가 확정한 배분 결과만 정산 원장에 저장한다.

## 7. 공통 기반 계약

### ID와 timestamp

- Entity ID는 의미를 해석하지 않는 opaque string이며 Firestore document ID를 사용한다. 배열 index, 이름, 공유 코드를 entity ID로 재사용하지 않는다.
- 공유 코드는 여행 ID가 아니라 만료·폐기 가능한 입장 credential이다.
- 도메인 계층 timestamp는 UTC Unix epoch milliseconds 정수인 `EpochMillis`를 사용한다.
- Firestore 생성·수정 시각은 `serverTimestamp()`로 기록하고 repository 경계에서 `EpochMillis`로 변환한다. 화면 컴포넌트에 Firestore `Timestamp`를 노출하지 않는다.
- 새 문서의 서버 timestamp가 아직 확정되지 않았으면 로컬 생성 시각을 임시 표시하고, snapshot에서 서버 값을 받으면 교체한다.
- `createdBy/updatedBy`에는 Firebase Auth `uid`를, 결제자·소비자에는 `participantId`를 사용한다.

### 오류 형식

```ts
type AppErrorCode =
  | "unauthenticated"
  | "permission-denied"
  | "invalid-argument"
  | "not-found"
  | "conflict"
  | "resource-exhausted"
  | "unavailable"
  | "invalid-image"
  | "payload-too-large"
  | "ocr-unavailable"
  | "ocr-no-result"
  | "unknown";

type AppError = {
  code: AppErrorCode;
  message: string;
  retryable: boolean;
  field?: string;
  details?: Record<string, unknown>;
};
```

- repository와 callable Function은 기술별 오류를 `AppError`로 변환한다.
- `message`는 화면에 바로 노출 가능한 한국어 기본 문구로 제공하고, 비밀 키·외부 API 원문·stack trace는 포함하지 않는다.
- 입력 오류는 `invalid-argument`와 `field`, 서비스 일시 장애·오프라인은 `unavailable`, 호출량 제한은 `resource-exhausted`로 통일한다.
- 재시도 버튼은 `retryable === true`인 경우에만 제공한다.

### Repository 형식

```ts
type Unsubscribe = () => void;
type OnData<T> = (value: T) => void;
type OnError = (error: AppError) => void;
type CreateExpenseInput = Omit<
  Expense,
  "id" | "tripId" | "createdBy" | "updatedBy" | "createdAt" | "updatedAt"
>;
type UpdateExpenseInput = Partial<CreateExpenseInput>;

interface ExpensesRepository {
  subscribeExpenses(
    tripId: EntityId,
    onData: OnData<Expense[]>,
    onError: OnError,
  ): Unsubscribe;
  createExpense(tripId: EntityId, input: CreateExpenseInput): Promise<Expense>;
  updateExpense(tripId: EntityId, id: EntityId, input: UpdateExpenseInput): Promise<void>;
  deleteExpense(tripId: EntityId, id: EntityId): Promise<void>;
}
```

- 다른 기능 repository도 `subscribe*(tripId, onData, onError): Unsubscribe`와 Promise 기반 생성·수정·삭제 명령 패턴을 따른다.
- 생성·수정 input에는 서버가 만드는 ID·timestamp와 Auth에서 주입할 `createdBy/updatedBy`를 받지 않는다.
- 컴포넌트는 repository만 사용하며 Firestore collection 경로나 Firebase SDK 타입을 알지 않는다.
- 공통 mock repository와 강릉 여행 fixture는 같은 interface를 구현해 외부 API와 Firebase 없이 네 화면을 검증할 수 있게 한다.

## 8. 협업 규칙

- 공통 타입은 각 기능의 `*.types.ts`에 먼저 정의한다.
- 기능 간 직접 참조를 줄이고 필요한 데이터만 props 또는 service로 전달한다.
- 정산 계산은 UI 변경과 독립적으로 테스트한다.
- 지도 API 응답은 앱 내부 `Place` 모델로 정규화해서 저장한다.
- API 키와 OCR 키는 Cloud Functions 환경변수로만 관리한다.
- 공유 코드 검증은 클라이언트 직접 조회가 아니라 Cloud Function을 우선한다.
- Firestore 접근은 `trips/{tripId}/members/{uid}` 기준으로 제한하는 방향을 우선한다.
- 공통 타입·Firestore 경로·정산 불변식을 바꾸는 PR은 나머지 두 명이 모두 검토한다. 라우트나 공유 파일의 구현 변경은 최소 한 명이 검토하고 플랫폼·통합 담당자가 최종 병합한다.
- 각 담당자는 작은 기능 브랜치와 PR을 사용하고, PR 설명에 로딩·빈 상태·오류 상태, 모바일/PC 확인 결과, 계약 변경 여부를 기록한다.
- 매일 `완료 / 오늘 / 막힌 점 / 계약 변경` 네 항목을 공유하고 동시에 진행하는 작업은 한 명당 하나로 제한한다.
