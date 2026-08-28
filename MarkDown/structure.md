# Trip Split Structure Draft

> **[계약 04 · 구조·협업 계약]** 역할, 폴더 구조, 모듈과 공통 도메인 경계입니다.

## 1. 프로젝트 구조 원칙

Trip Split 클라이언트는 Flutter stable·Dart 기반 Android 앱으로 만들고 기존 Node.js·TypeScript Firebase backend를 유지한다. 세 명의 작업 영역은 `플랫폼·통합`, `정산·영수증`, `장소·일정·지도`로 나누되 공통 계약을 먼저 고정하고 각 기능을 mock으로 독립 개발한 뒤 작은 단위로 지속 통합한다.

핵심 원칙은 다음과 같다.

- 제품 앱은 `frontend/pubspec.yaml`을 사용하는 Flutter workspace이고 backend는 `backend/package.json`을 사용하는 Node.js workspace다. 전환 기간에는 GitHub Pages React 목업 검증을 위해 `frontend/package.json`도 루트 npm workspaces에 임시로 남긴다. Flutter 공유본으로 대체한 뒤 React workspace를 제거한다.
- 두 프로젝트는 같은 `dev`와 `main` 트리에 유지하고 모든 개발 변경을 `dev`에 직접 통합한다.
- 화면은 사용 흐름 중심으로 구성한다.
- 지도, 정산, OCR, Firebase 호출은 UI와 분리한다.
- 정산 로직은 순수 함수로 작성해 테스트하기 쉽게 만든다.
- 지도 표시는 provider/adapter로 감싸 첫 Google Maps 의존성을 한 곳에 모으고 NAVER 구현은 후속으로 둔다.
- Firestore 경로와 공통 타입은 세 명이 함께 검토하고 플랫폼·통합 담당자가 최종 승인한다.
- 사용자-facing 로그인은 선택으로 두되, 내부적으로는 Firebase Auth `uid`를 기준으로 여행 멤버와 권한을 관리한다.
- 로그인·공동 편집 주체인 `TripMember`와 비용을 부담하는 `Participant`를 분리한다.
- Android 하단 내비게이션은 `일정·지도`, `준비`, `비용` 세 목적지를 사용하며 영수증은 비용의 하위 흐름이다.
- Flutter Web은 공유 가능한 도메인과 Widget을 재사용하되 Android 전용 기능과 동일한 capability를 약속하지 않는다.

## 2. 역할 분담

### 플랫폼·통합 담당

담당: 앱 기반, 사용자 세션, 공통 계약과 통합 품질 최종 확인

- Flutter Android 프로젝트, router와 Material 앱 셸 구성
- 공통 `TripSession` 상태, 디자인 토큰과 공통 Widget 관리
- Firebase 클라이언트, Emulator Suite, Anonymous Auth와 선택적 Google 계정 연결
- 여행 생성, 공유 코드 참여, 멤버와 권한 관리. Android App Links는 후속
- Firestore 보안 규칙과 실시간 세션의 통합 검증
- `.trip.json` 백업·복원·데모 데이터 흐름 관리
- 공통 타입, Firestore 경로, `pubspec.lock`과 backend lockfile 변경의 최종 승인
- 통합 QA, `dev` 검증 결과와 릴리스 기준 최종 확인

### 정산·영수증 담당

담당: `Participant`, `Expense`, `ReceiptItem`, 정산 엔진과 OCR 검토 흐름

- 결제액, 부담액, 받을 금액·보낼 금액을 분리한 개인 정산 모델 설계
- 전체 균등, 영수증 항목별, 참여자별 직접 입력 분할 계산
- 할인, 봉사료, 기타 조정 금액 배분과 최소 통화 단위 나머지 처리
- 개인별 카테고리 합계와 날짜·장소·메뉴/지출 항목별 소비 내역 계산
- 수동 지출 등록, 지출 목록과 최종 송금 결과 UI
- provider-neutral OCR·번역 요청, 원문/번역 항목 수정·추가, 합계 검증과 수동 등록 fallback
- 정산 repository와 Firestore 데이터 구조 제안
- 순수 계산 함수, fixture와 단위 테스트 관리

### 장소·일정·지도 담당

담당: 장소 정규화, 일정·준비 편집, 지도 표시와 Google API 어댑터

- Google 장소 검색, Google Maps URL 해석, 직접 입력 흐름
- 장소 보관함과 날짜별 일정·세로 타임라인 UI
- 앱 내부 `Place` 정규화 모델과 장소 repository 제안
- 일정 순서 기반 커스텀 번호 핀과 날짜별 색상 적용
- 같은 날짜 장소를 잇는 직선 동선 표시
- 지도 provider 인터페이스와 `google_maps_flutter` 어댑터
- 예약·체크리스트의 최소 준비 화면과 repository
- 장소·일정·지도 fixture와 단위/통합 테스트 관리

### 공유 파일과 Cloud Function 소유권

| 범위 | 주 담당 | 변경 규칙 |
| --- | --- | --- |
| 루트 검증 wrapper, `frontend/pubspec.yaml`·`pubspec.lock`, `frontend/lib/app`, Firebase 진입점·설정·보안 규칙 | 플랫폼·통합 | 다른 담당자는 변경안을 제안하고 플랫폼·통합 담당자가 최종 확인한다. |
| `frontend/lib/features/settlement`, `frontend/lib/features/receipts`, expense repository | 정산·영수증 | 공통 타입이나 Firestore 경로 변경은 세 명의 리뷰가 필요하다. |
| `frontend/lib/features/places`, `itinerary`, `map`, `preparation`과 관련 repository | 장소·일정·지도 | 공통 타입이나 Firestore 경로 변경은 세 명의 리뷰가 필요하다. |
| 여행 생성, 공유 코드 검증·참여 Function | 플랫폼·통합 | 인증·보안 규칙과 함께 통합한다. |
| `parseReceipt` Function | 정산·영수증 | OCR 비밀 키, 검증·오류 형식은 공통 계약을 따른다. |
| 장소 검색, 장소 URL 해석 Function | 장소·일정·지도 | Google 서버 키, 검증·오류 형식은 공통 계약을 따른다. |
| `backend/src/index.ts`, 공통 HTTP·환경변수 유틸리티 | 플랫폼·통합 | 각 담당의 handler를 export만 하며 도메인 로직을 두지 않는다. |

담당 영역은 코드 소유권과 1차 리뷰 책임을 뜻한다. 다른 영역을 수정할 수 없는 경계가 아니며, 계약 변경은 푸시 전에 영향 범위와 migration 여부를 공유하고 플랫폼·통합 담당자가 최종 승인한다.

## 3. 권장 폴더 구조

```text
trip-split/
  frontend/
    pubspec.yaml
    pubspec.lock
    dart_defines.example.json
    .env.example          # 전환 전 React Pages 목업 전용
    lib/
      app/
        app.dart
        router.dart
        trip_shell.dart
      domain/
        models/
        repositories/
        errors/
      data/
        firebase/
        mock/
        mappers/
      features/
        places/
        itinerary/
        map/
        preparation/
        settlement/
        receipts/
      services/
        functions/
      shared/
        widgets/
        theme/
    test/
      fixtures/
      unit/
      widgets/
    integration_test/
    android/
    web/                 # 후속 Flutter Web 진입점; 첫 출시 게이트 아님
  backend/
    package.json
    .env.example
    firestore.rules
    firestore.indexes.json
    src/
      index.ts
      share/
      shared/
    tests/
      emulator/
  docs/
  MarkDown/
  .github/workflows/
  firebase.json
  package.json           # backend와 임시 React Pages 목업 검증 위임용
  package-lock.json      # backend·임시 React dependency용
```

## 4. 앱 셸과 라우트 계약

여행에 입장한 뒤 Android에서는 `TripShell` 안에서 세 개의 주요 목적지를 사용한다. route 이름은 Android navigation, App Link와 후속 Flutter Web deep link가 같은 의미를 공유하기 위한 논리 계약이다.

| 메뉴 | 라우트 | 기본 역할 |
| --- | --- | --- |
| 일정·지도 | `/trips/:tripId/itinerary` | 상단 지도 동선과 날짜별 일정·장소 배치 |
| 준비 | `/trips/:tripId/preparation` | 예약과 공동·개인 체크리스트 |
| 비용 | `/trips/:tripId/settlement` | 참여자, 개인 소비, 최종 정산과 지출 관리 |

- `/trips/:tripId`는 일정 라우트로 redirect한다.
- 기존 `/trips/:tripId/map`은 북마크·공유 링크 호환을 위해 `/trips/:tripId/itinerary?map=expanded`로 redirect한다.
- `/trips/:tripId/receipts`는 비용 탭 안의 영수증 검토 하위 route로 보존한다.
- 지도 compact/expanded와 선택 날짜는 Android router state로 복원하고 Web/App Link를 제공할 때 query와 매핑한다.
- 장소 보관함은 독립 라우트나 네 번째 메뉴로 만들지 않고 일정·지도 통합 페이지의 패널 또는 바텀시트로 제공한다.
- 여행 제목, 참여자, 공유, 익명/계정 연결과 동기화 상태는 `TripShell`이 공통으로 제공한다.
- 각 feature는 router의 `tripId`와 `TripSession` 상태를 받고 Firebase Auth·Firestore 객체를 직접 받지 않는다.
- Android Firestore 캐시의 데이터와 보류 중 write를 표시한다. Google 장소·OCR 호출은 온라인 전용이며 실패를 저장 완료로 표시하지 않는다.

## 5. 주요 모듈 경계

### `features/itinerary`

날짜별 타임테이블과 장소 배치를 담당한다. 지도나 정산 계산을 직접 하지 않고, `placeId`, `date`, `order`를 포함한 일정 데이터를 제공한다. 같은 날짜의 `order`는 중복되지 않는 0부터 시작하는 정수로 정규화한다.

### `features/map`

지도 렌더링만 담당한다. 입력은 앱 내부 `Place` 목록과 `ItineraryItem`의 `date`, `placeId`, `order`뿐이며 Firestore 문서, Google 검색 응답과 정산 데이터는 받지 않는다. 지도 adapter는 이 입력으로 날짜별 색상, 일정 순서 번호 핀과 직선 동선을 그린다.

### `features/preparation`

예약과 체크리스트의 최소 CRUD를 담당한다. 민감한 여권·결제 문서를 보관하지 않으며 알림·첨부·복잡한 업무 배정은 후속이다.

### `features/settlement`

정산 계산을 담당한다. UI나 Firebase에 의존하지 않는 순수 함수로 `Expense`를 검증·배분하고, 참여자별 결제액·부담액·정산 차액과 결정적인 송금 제안을 계산한다.

### `features/receipts`

Android 카메라·Photo Picker의 영수증 이미지 선택, OCR·번역 요청, 원문/번역 항목 편집·추가, 분할과 합계 검증을 담당한다. 이미지는 MVP에서 Firebase Storage에 영구 저장하지 않는다. OCR 결과를 자동으로 정산에 반영하지 않고, 사용자가 검토하고 확정한 `Expense`와 `ReceiptItem`만 저장한다. OCR 실패 시 총액 기반 수동 지출 등록으로 전환한다.

### `services/firebase`

FlutterFire 읽기/쓰기와 snapshot 구독을 담당한다. Widget과 순수 도메인 함수에서 Firebase SDK를 직접 호출하지 않으며 repository가 Firestore Timestamp와 오류를 공통 앱 계약으로 변환한다.

### `backend/src`

클라이언트에 노출하면 안 되는 API 호출을 담당한다. Google 장소 검색·URL 해석, OCR·번역 provider와 공유 코드 검증은 이곳에서 처리한다. 각 handler는 동일한 인증 확인, 입력 검증과 `AppError` 응답 형식을 사용한다.

## 6. 데이터 모델과 도메인 계약

```ts
// Firestore/Callable wire 계약을 읽기 쉽게 표현한 TypeScript 표기다.
// Flutter는 같은 필드와 불변식을 immutable Dart 모델로 구현한다.
type EntityId = string;
type ParticipantId = EntityId;
type EpochMillis = number;
type LocalDate = string; // YYYY-MM-DD
type CurrencyAmount = number; // ISO 통화별 최소 단위 정수
type CurrencyCode = string; // ISO 4217 대문자 코드

type AllocationMethod = "equal" | "itemized" | "custom";

type MoneyAllocation = {
  participantId: ParticipantId;
  amount: CurrencyAmount;
};

type ExpensePayer = {
  participantId: ParticipantId;
  amount: CurrencyAmount;
};

type Trip = {
  id: EntityId;
  title: string;
  countryCode: string;
  timeZone: string;
  mapProvider: "google" | "naver";
  defaultCurrency: CurrencyCode;
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
  provider: "google" | "naver" | "manual";
  source: "googleSearch" | "googleMapsUrl" | "naverSearch" | "naverLink" | "manual";
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

type Reservation = {
  id: EntityId;
  tripId: EntityId;
  title: string;
  kind: "flight" | "lodging" | "transport" | "activity" | "other";
  status: "planned" | "booked" | "cancelled";
  url?: string;
  memo?: string;
  itineraryItemId?: EntityId;
  updatedBy: string;
  updatedAt: EpochMillis;
};

type ChecklistItem = {
  id: EntityId;
  tripId: EntityId;
  title: string;
  scope: "shared" | "personal";
  participantId?: ParticipantId;
  isDone: boolean;
  updatedBy: string;
  updatedAt: EpochMillis;
};

type ReceiptItem = {
  id: EntityId;
  kind: "item" | "discount" | "serviceFee" | "adjustment";
  name: string;
  amount: CurrencyAmount;
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
  totalAmount: CurrencyAmount;
  currency: CurrencyCode;
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

MVP 첫 코드는 `createTrip`이 만들며 `expiresAt`과 `maxUses`를 저장하지 않는다. 재생성 시 기존 활성 코드를 모두 비활성화하고 새 코드만 활성화한다.

`TripMember`는 Firebase Auth 사용자이자 Firestore 접근 권한의 주체다. MVP에서는 모든 멤버의 `role`을 `editor`로 저장하고 여행 생성자는 `Trip.ownerUid`로 구분한다. `owner | editor | viewer` 역할 확장은 후속에서 타입과 보안 규칙을 함께 넓힌다. `Participant`는 정산 원장의 주체이며 계정이 없는 동행자도 생성할 수 있다. 사용자가 자기 소비 내역을 볼 때는 `Participant.linkedUid`로 선택 연결하되, 두 타입이나 ID를 같은 값으로 간주하지 않는다. `linkedUid`가 있으면 같은 여행의 `TripMember.uid`를 참조해야 하고 한 여행에서 하나의 `Participant`만 같은 uid를 연결할 수 있다.

`Place`는 Google 검색 응답, Google Maps URL과 직접 입력을 모두 같은 형태로 정규화한 뒤 저장한다. 지도 기능에는 정규화된 `Place`와 `ItineraryItem.date/placeId/order`만 전달하며 provider 원본 응답은 도메인 모델에 저장하지 않는다. 후속 NAVER adapter도 같은 계약을 사용한다.

### 정산 불변식

- 모든 금액은 통화의 최소 단위 정수다. UI에서 받은 구분자와 통화 기호는 저장 전에 제거·검증한다.
- 서로 다른 통화의 합계·net·송금안은 통화별로 분리하고 자동 환율 없이 합산하지 않는다.
- 단일 결제자 MVP에서 `expense.payer.amount === expense.totalAmount`여야 한다.
- `sum(expense.allocatedAmounts[].amount) === expense.totalAmount`여야 한다.
- `equal`은 `totalAmount`를 `consumers`에게 균등 배분하고, `custom`은 사용자가 입력한 `allocatedAmounts`를 사용한다.
- `itemized`는 하나 이상의 `receiptItems`가 필요하다. 모든 `receiptItems[].allocatedAmounts`를 참여자별로 합산해 `expense.allocatedAmounts`를 만들며 `sum(receiptItems[].amount) === expense.totalAmount`여야 한다.
- 각 항목도 `sum(item.allocatedAmounts[].amount) === item.amount`여야 한다. 항목의 `equal`과 `custom`도 지출과 같은 배분 규칙을 사용한다.
- 일반 항목과 봉사료는 양수, 할인은 음수이고 기타 조정은 0이 아닌 양수 또는 음수다. 조정까지 반영한 참여자별 최종 부담액은 음수가 될 수 없다.
- 균등 분할은 0 방향 정수 나눗셈으로 계산하고 남은 최소 단위 `±1`을 UI에 표시된 `consumers` 배열 순서대로 배분한다. 배열 순서는 저장하고 계산 중에 다시 정렬하지 않는다.
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

```dart
abstract interface class ExpensesRepository {
  Stream<List<Expense>> watchExpenses(EntityId tripId);

  Future<Expense> createExpense(
    EntityId tripId,
    CreateExpenseInput input,
  );

  Future<void> updateExpense(
    EntityId tripId,
    EntityId expenseId,
    UpdateExpenseInput input,
  );

  Future<void> deleteExpense(EntityId tripId, EntityId expenseId);
}
```

- 다른 기능 repository도 `Stream<T>` 기반 watch와 `Future<T>` 기반 생성·수정·삭제 패턴을 따른다.
- 생성·수정 input에는 서버가 만드는 ID·timestamp와 Auth에서 주입할 `createdBy/updatedBy`를 받지 않는다.
- Widget과 controller는 repository만 사용하며 Firestore collection 경로나 Firebase SDK 타입을 알지 않는다.
- 공통 mock repository와 `tokyo-2026-11` fixture는 같은 interface를 구현해 외부 API와 Firebase 없이 세 탭을 검증할 수 있게 한다. 기존 강릉 fixture는 회귀용으로 보존한다.

## 8. 협업 규칙

- 공통 타입은 `frontend/lib/domain`의 Dart 모델과 repository interface에 먼저 정의한다.
- 기능 간 직접 참조를 줄이고 필요한 데이터만 immutable model, controller 또는 service로 전달한다.
- 정산 계산은 UI 변경과 독립적으로 테스트한다.
- 지도 API 응답은 앱 내부 `Place` 모델로 정규화해서 저장한다.
- API 키와 OCR 키는 Cloud Functions 환경변수로만 관리한다.
- 공유 코드 검증은 클라이언트 직접 조회가 아니라 Cloud Function을 우선한다.
- Firestore 접근은 `trips/{tripId}/members/{uid}` 기준으로 제한하는 방향을 우선한다.
- 공통 타입·Firestore 경로·정산 불변식 변경은 나머지 두 명이 모두 검토한다. 라우트나 공유 파일의 구현 변경은 최소 한 명이 검토하고 플랫폼·통합 담당자가 최종 확인한다.
- 각 담당자는 최신 `dev`에서 한 번에 하나의 작은 작업을 진행하고, 로딩·빈 상태·오류 상태, Android emulator·실기기 확인 결과와 계약 변경 여부를 공유한 뒤 직접 커밋·푸시한다.
- 매일 `완료 / 오늘 / 막힌 점 / 계약 변경` 네 항목을 공유하고 동시에 진행하는 작업은 한 명당 하나로 제한한다.
