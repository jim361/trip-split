# Trip Split Tech Draft

> **[계약 03 · 기술 계약]** 기술 스택, Firebase 데이터와 외부 연동 경계입니다.

## 1. 확정된 기술 방향

Trip Split MVP 클라이언트는 Flutter stable·Dart 기반 Android 앱으로 개발하고 Firebase BaaS를 사용한다. TASK-01 기준 버전은 Flutter 3.47.2·Dart 3.13.2다. 기존 Node.js 22·TypeScript Cloud Functions와 Firestore Rules 테스트는 유지한다. 첫 실사용은 도쿄 여행이며 Google Maps와 JPY를 우선 검증한다. Flutter Web은 공유 Dart 도메인과 repository를 재사용하는 후속 보조 타깃이고 첫 Android 출시 게이트에 포함하지 않는다.

## 2. 전체 구조

```text
Flutter Android
  -> FlutterFire Auth
       -> Anonymous Auth
       -> Google credential link(optional)
  -> Cloud Firestore
  -> Cloud Functions callable
       -> createTrip / createShareCode / joinTrip
       -> Google Places URL·검색 adapter
       -> parseReceipt provider adapter
            -> Document AI Expense Parser 또는 일반 OCR
            -> Translation
  -> google_maps_flutter

Node.js 22 + TypeScript backend
  -> Firestore Rules와 Emulator 통합 테스트
  -> 외부 API secret와 요청 제한
```

Flutter 앱은 장소·일정·준비·비용을 편집하는 Widget과 상태를 담당한다. Firebase는 인증, 데이터 저장, 공유 코드, 멤버 세션과 실시간 동기화를 담당한다. 외부 장소 검색과 OCR·번역 호출은 Cloud Functions를 통해 처리해 secret을 앱에 넣지 않는다. Widget은 SDK를 직접 호출하지 않고 service/repository/adapter 경계를 사용한다.

Android Firestore 영속 캐시는 마지막 동기화 데이터와 latency-compensated write를 제공한다. UI는 캐시 데이터, 동기화 대기와 실패를 구분한다. 여러 기기의 같은 문서 충돌은 기본적으로 last-write-wins이며 고급 병합 UI는 후속이다. Google 장소 검색과 OCR Callable은 온라인 기능으로 두고 재시도 가능한 오류와 수동 fallback을 제공한다.

## 3. Firebase 사용 범위

- Firebase App Distribution 또는 로컬 APK: Android 검증 배포. 실제 배포는 별도 승인 후 수행
- Firebase Hosting: Flutter Web을 후속 공개할 때만 사용
- Firebase Auth: 익명 인증, Android Google credential의 선택 연결
- Firestore: 사용자, 여행, 멤버, 장소, 일정, 지출, 정산 데이터 저장
- Firebase Storage: MVP에서는 영수증 이미지에 사용하지 않으며, 이미지 보관 기능을 별도로 도입할 때만 후속 사용
- Cloud Functions: 공유 코드 검증, Google 장소 검색·URL 해석, provider-neutral OCR·번역 등 서버 측 작업

MVP에서는 사용자-facing 로그인 화면 없이 시작한다. 앱 진입 시 Anonymous Auth로 내부 `uid`를 발급하고, 사용자가 원하면 Google 계정을 연결한다. 이 방식은 진입 장벽을 낮추면서도 Firestore 보안 규칙, 멤버 관리, 내 여행 목록, 수정자 표시의 기반을 만든다.

### Android와 Emulator 기준

- Android `minSdk 24`: Flutter, Google Maps와 camera 플러그인의 공통 하한
- Android `targetSdk 36`: 2026년 Play 신규 앱 요구사항을 기준으로 scaffold에서 검증
- Android Emulator에서 host Emulator Suite 주소는 `10.0.2.2`
- Auth·Firestore·Functions 인스턴스를 처음 사용하기 전에 각 Emulator 연결 설정 적용
- Flutter와 backend CI runtime은 JDK 21을 사용하고 Android 소스·Kotlin bytecode target은 생성된 scaffold의 Java 17을 유지
- Node.js 22는 기존 Firebase Functions runtime과 backend CI에 유지
- Flutter SDK는 CI와 `pubspec.yaml`에서 3.47.x stable 기준을 고정하고 별도 버전 관리 도구는 팀에 실제 필요가 생길 때 도입

## 4. Firestore 컬렉션과 정산 원장

```text
users/{uid}
  displayName
  email
  photoURL
  authProvider
  createdAt
  updatedAt

shareCodes/{code}
  tripId
  createdBy
  createdAt
  expiresAt
  isActive
  maxUses
  useCount

trips/{tripId}
  title
  countryCode
  timeZone
  mapProvider
  defaultCurrency
  startDate
  endDate
  ownerUid
  shareCode
  createdAt
  updatedAt

trips/{tripId}/members/{uid}
  displayName
  photoURL
  role
  joinedAt
  lastActiveAt

trips/{tripId}/participants/{participantId}
  name
  color
  linkedUid
  isActive
  createdAt
  updatedAt

trips/{tripId}/places/{placeId}
trips/{tripId}/itinerary/{itemId}
trips/{tripId}/reservations/{reservationId}
trips/{tripId}/checklistItems/{checklistItemId}

trips/{tripId}/expenses/{expenseId}
  title
  category
  expenseDate
  totalAmount             # 최소 화폐 단위 정수
  currency
  payer                 # { participantId, amount }
  consumers             # participantId[]
  allocationMethod      # equal | itemized | custom
  allocatedAmounts      # [{ participantId, amount }]
  receiptItems          # ReceiptItem[]; itemized일 때 사용
  source                # manual | ocr
  placeId
  itineraryItemId
  memo
  createdBy
  updatedBy
  createdAt
  updatedAt
```

`TripMember`는 인증된 공동 편집 사용자이고 `Participant`는 정산의 결제자 또는 소비자다. 한 사람이 두 역할을 함께 가질 수 있도록 `Participant.linkedUid`로 선택 연결하지만, 로그인하지 않은 동행도 정산에 포함할 수 있게 두 개념을 분리한다. `linkedUid`는 같은 여행의 member를 참조해야 하며 한 여행에서 유일해야 한다.

MVP의 `ReceiptItem`은 일반 메뉴뿐 아니라 할인, 봉사료, 기타 조정 금액을 같은 방식으로 배분한다.

```ts
type MoneyAllocation = {
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
```

일반 항목과 봉사료는 양수, 할인은 음수이고 기타 조정은 0이 아닌 양수 또는 음수다. `receiptItems`는 MVP에서 지출 문서에 포함해 한 번의 검토·저장으로 원자적으로 확정한다. 영수증이 지나치게 커지거나 항목별 동시 편집이 필요해지면 후속 버전에서 하위 컬렉션으로 분리한다.

정산 데이터는 다음 불변식을 만족해야 한다.

- 모든 금액은 부동소수점이 아니라 ISO 통화 코드별 최소 단위 정수다. 첫 fixture의 JPY와 KRW는 정수 1이 각각 1엔과 1원이다.
- 서로 다른 통화의 합계와 net은 통화별로 분리하고 환율 근거 없이 합산하지 않는다.
- `payer.amount === totalAmount`이고 MVP에서는 지출마다 결제자 한 명을 둔다.
- `sum(expense.allocatedAmounts.amount) === expense.totalAmount`다.
- `equal`은 지출 전체를 `consumers`에게 균등 배분한다.
- `itemized`는 하나 이상의 `receiptItems`를 가지며, 각 `receiptItem.allocatedAmounts`를 참여자별로 합산해 지출의 `allocatedAmounts`를 만든다.
- `custom`은 사용자가 지출 전체의 참여자별 부담액을 직접 입력한다.
- 항목별로 `sum(allocatedAmounts.amount) === item.amount`이며, 항목 및 조정 금액의 합은 `totalAmount`와 일치해야 한다.
- 균등 분할의 1원 나머지는 UI에 표시된 소비자 순서대로 1원씩 배분해 모든 클라이언트에서 같은 결과를 만든다.
- 지출과 각 항목의 `allocatedAmounts`에는 `consumers`의 참여자마다 정확히 한 행을 두며 `participantId`는 중복될 수 없다. 1원보다 소비자가 많은 균등 분할처럼 계산 결과가 0원인 행도 유지한다.
- `consumers`의 참여자 집합은 `allocatedAmounts.participantId` 집합과 일치해야 한다.
- 할인 배분을 포함한 참여자별 최종 부담액은 음수가 될 수 없다.

MVP에서는 미확정 OCR 초안, 정산 결과 snapshot, 송금 완료 상태를 Firestore의 별도 원장으로 저장하지 않는다. `receiptJobs`, `settlements`, `activityLogs` 컬렉션은 비동기 OCR 큐·재시도, 정산 확정/송금 상태, 변경 이력이 필요해질 때 후속으로 도입한다.

## 5. 공통 기술 계약과 소유권

### ID와 시간

- 모든 도메인 ID는 `string`이며 Firestore 문서 ID를 사용한다. 사람이 입력하는 공유 코드는 ID와 별도 필드로 관리한다.
- Firestore에는 `serverTimestamp()`로 `Timestamp`를 저장하고, repository 경계에서 epoch millisecond `number`로 변환한다.
- 새 문서의 서버 timestamp가 아직 확정되지 않은 동안에는 로컬 생성 시각을 임시 표시하되, 서버 값 수신 후 교체한다.
- `createdBy`와 `updatedBy`에는 인증 사용자 `uid`를, 결제자와 소비자 참조에는 `participantId`를 사용한다.

### 공통 오류 형식

```text
AppError
  code: unauthenticated | permission-denied | invalid-argument |
        not-found | conflict | resource-exhausted | unavailable |
        invalid-image | payload-too-large | ocr-unavailable |
        ocr-no-result | unknown
  message: string
  retryable: boolean
  field?: string
  details?: map
```

Flutter에서는 immutable Dart class로, backend에서는 TypeScript type으로 같은 wire 값을 구현한다. Firebase SDK 오류와 Callable `HttpsError`는 service 계층에서 `AppError`로 변환한다. 외부 API 원문 응답, 비밀 키와 이미지 본문은 UI 오류나 로그에 노출하지 않는다.

### Repository 계약

- Flutter Widget과 controller는 Firebase SDK를 직접 호출하지 않는다.
- 목록과 실시간 데이터는 `Stream<T>`로, 일회성 조회와 생성·수정·삭제는 `Future<T>`로 제공한다.
- 구독 생명주기는 controller/state 계층에서 관리하고 Widget dispose 뒤 이벤트를 전달하지 않는다.
- 각 repository는 동일 인터페이스의 Firestore 구현체와 mock 구현체를 가져 외부 API나 Firebase 연결 전에도 화면과 도메인 테스트를 진행할 수 있게 한다.
- 장소 provider 응답은 저장 전에 앱 내부 `Place`로 정규화하고, 지도 모듈은 provider 원문이 아니라 `Place[]`와 정렬된 `ItineraryItem[]`만 입력받는다.

### Callable Function과 담당

| 담당 | Callable Function | 책임 |
| --- | --- | --- |
| 플랫폼·통합 | `createTrip`, `createShareCode`, `joinTrip` | 여행·생성자 멤버 원자적 생성, 공유 코드 생성·검증, 참여 멤버 등록 |
| 정산·영수증 | `parseReceipt` | 이미지 검증, OCR·번역 provider 호출, `ParsedReceipt` 정규화 |
| 장소·일정·지도 | `searchPlaces`, `parsePlaceLink` | Google 장소 검색·URL 해석, `Place` 후보 정규화 |

플랫폼·통합 담당은 Firebase 초기화, Functions 진입점, 보안 규칙, 공통 라우트, dependency와 lockfile을 최종 병합한다. 도메인 담당은 자신의 `features`, repository, Function 모듈과 테스트를 소유한다. 공통 타입이나 Firestore 경로를 바꾸는 PR은 세 담당자가 함께 검토한다.

첫 공통 fixture는 고정 ID `tokyo-2026-11`을 사용하고 장소, 일정, 준비, 참여자, JPY 수동 지출과 일본어 항목형 영수증을 포함한다. 기존 강릉 fixture는 KRW·국내 회귀용으로 보존한다. 세 도메인의 mock repository와 통합 테스트가 같은 canonical fixture를 사용해 계약 불일치를 조기에 찾는다.

## 6. 인증과 공유 코드 흐름

```text
1. 사용자가 앱에 접속한다.
2. Firebase Anonymous Auth로 uid를 발급받는다.
3. 사용자가 여행 생성 폼을 제출하고 `createTrip`을 호출한다.
4. Function이 여행, 생성자의 member 문서와 첫 공유 코드를 원자적으로 만든다.
5. 친구가 공유 코드로 접근한다. Android App Links 초대는 후속이다.
6. `joinTrip`이 코드를 검증하고 친구의 uid를 `trips/{tripId}/members/{uid}`에 등록한다.
7. FlutterFire repository가 여행 하위 컬렉션의 snapshot을 `Stream`으로 노출한다.
```

Google 로그인은 선택 기능이다. 익명 사용자에서 Google Provider를 연결하면 기존 uid와 여행 접근 권한을 유지하는 방향을 우선 검토한다.

`createTrip`은 첫 공유 코드를 함께 만든다. MVP의 활성 코드는 `expiresAt`과 `maxUses`를 생략하고, `createShareCode` 재생성 transaction은 기존 활성 코드를 모두 비활성화한 뒤 새 코드만 활성화한다.

## 7. Google Maps Android 사용 범위

첫 Android MVP는 공식 `google_maps_flutter` adapter로 Google Maps를 표시한다.

- 일정 화면 상단 compact 지도와 같은 화면의 expanded 상태
- 정규화된 `Place` 좌표를 이용한 날짜별 색상·순서 번호 marker
- `ItineraryItem.order`에 따른 직선 polyline
- 선택한 날짜의 bounds 맞춤과 좌표 누락 상태
- 실제 길찾기는 앱 내부 Routes API 대신 외부 Google Maps 링크로 열기

Maps SDK for Android 키와 서버의 Places API 키는 용도와 제한을 분리한다. 앱 키는 Android package name·SHA 제한, 서버 키는 backend 실행 환경과 API 범위 제한을 적용한다. 키와 유료 API는 별도 승인 전에는 실제 프로젝트에 연결하지 않는다.

`google_maps_flutter`는 Web도 지원하지만 내 위치 UI, 회전·기울기와 실내 지도 등 capability 차이가 있다. 공통 지도 입력과 adapter는 재사용하되 Web에서 Android 기능 동등성을 보장하지 않는다.

## 8. 국내 지도 후속 경계

국내 NAVER 지도는 첫 Android MVP 이후 동일한 `PlaceProvider`와 `MapAdapter` 계약으로 추가한다. 한 여행에서는 하나의 지도 provider만 선택하고 Google과 NAVER 결과를 임의로 혼합하지 않는다.

NAVER 지도 웹앱의 비공개 저장 목록 endpoint는 약관, 안정성과 응답 변경 위험 때문에 제품 기능에서 사용하지 않는다. 국내 구현도 공식 검색·개별 장소 URL·직접 입력만 기본 흐름으로 사용한다.

## 9. OCR·번역 사용 범위

영수증 인식은 provider-neutral `parseReceipt` Callable 뒤의 backend adapter로 구현한다. 첫 후보는 일본어를 지원하는 Google Document AI Expense Parser이며, 지원 언어·항목 정확도가 맞지 않으면 일반 OCR과 Translation 또는 다른 provider를 fixture benchmark로 비교한다. OCR은 소비자를 자동 판단하거나 검토 없이 정산을 확정하지 않는다.

MVP OCR 흐름은 다음과 같다.

1. 사용자가 Android 카메라 또는 시스템 Photo Picker에서 영수증 이미지를 선택하고 외부 전송 안내를 확인한다.
2. 클라이언트가 MIME type, 파일 크기와 이미지 크기를 검사·축소한 뒤 HTTPS Callable Function으로 전송한다.
3. Cloud Function이 선택된 OCR·번역 adapter를 호출하고 원문, source language, 상호·날짜·통화·총액 후보, 원문 및 한국어 항목명·금액·confidence를 정규화해 반환한다.
4. 클라이언트가 결과를 Firestore 밖의 편집 가능한 `ReceiptDraft`로 만든다.
5. 사용자가 OCR 항목명과 금액을 고치고, 누락 항목 및 할인·봉사료·기타 조정을 추가한다.
6. 사용자가 결제자와 분할 방식을 정하고 전체 또는 항목별 소비자와 부담액을 지정한다.
7. OCR 인식에 실패하면 같은 화면에서 지출명과 전체 금액을 입력하는 수동 등록으로 전환한다.
8. 총액과 항목·배분 합계가 맞을 때 사용자가 명시적으로 저장한다.
9. 확정된 `Expense`만 Firestore에 저장되고 지출 구독을 통해 정산 결과가 재계산된다.

MVP에서는 영수증 이미지를 Firebase Storage나 Firestore에 영구 저장하지 않는다. Function은 요청 처리 중에만 이미지 바이트를 사용하고 응답 후 폐기하며 요청 본문이나 이미지 내용을 로그에 남기지 않는다. 이미지를 저장하지 않더라도 Firebase Functions와 선택한 OCR·번역 provider로 전송된다는 점은 선택 전에 사용자에게 고지한다. 미확정 `ReceiptDraft`도 서버에 자동 저장하지 않는다.

```text
ParsedReceipt
  rawText: string
  sourceLanguage?: string
  merchantNameOriginal?: string
  merchantNameTranslated?: string
  expenseDate?: string
  currencyCandidate?: string
  totalAmountCandidate?: integer
  items[]:
    nameOriginal: string
    nameTranslated?: string
    amount?: integer
    confidence?: number
    sourceOrder: integer
  warnings: string[]
```

번역은 사용자의 이해를 돕는 보조 정보다. 수량, 통화와 금액은 이미지와 원문을 기준으로 검토하며 provider가 구조화하지 못한 언어는 수동 등록으로 전환한다.

## 10. 실시간 동기화 방식

Flutter repository는 다음 Firestore snapshot을 Dart `Stream`으로 노출한다.

- trip 기본 정보
- members
- participants
- places
- itinerary
- reservations
- checklistItems
- expenses

지출 변경 시 정산 엔진은 클라이언트에서 다음 값을 순수 함수로 재계산한다.

- 개인 결제액: 해당 참여자가 `payer`인 지출의 `payer.amount` 합
- 개인 부담액: 해당 참여자의 `allocatedAmounts.amount` 합
- 개인 정산 결과: 결제액 - 부담액. 양수는 받을 금액, 음수는 보낼 금액
- 개인 소비 분석: 개인 배분액을 카테고리별로 집계하고 날짜·장소·영수증 항목 또는 지출별로 펼친 내역
- 최종 송금 목록: 음수 잔액 참여자에서 양수 잔액 참여자로 보내도록 계산한 전송 목록

모든 참여자의 순잔액 합은 0이어야 한다. 같은 원장에서는 클라이언트마다 같은 송금 목록이 나오도록 잔액과 `participantId`를 기준으로 안정적으로 정렬한다. 정산 결과 snapshot 저장은 MVP 이후로 둔다. `receiptItems`는 `Expense`에 포함되므로 확정 지출은 문서 한 번의 write로 저장하고, 일정 정렬처럼 여러 문서를 함께 바꾸는 작업에만 batch write 또는 transaction을 사용한다.

## 11. 공유 방식

Android MVP의 기본 공유 방식은 Firebase 기반 공유 코드다. App Links 초대는 공유 코드 흐름 안정화 뒤 추가한다.

- 여행장이 여행 생성
- 공유 코드 생성
- 참여자가 코드 입력
- Anonymous Auth uid 발급
- Cloud Function이 코드 검증
- Firestore members에 등록
- 여행 정보 실시간 구독

MVP에서는 모든 멤버가 편집 가능한 모델로 시작한다. 세부 권한, 작성자 추적 강화, 변경 이력은 이후 확장한다.

보조 공유 방식으로 `.trip.json` 내보내기/가져오기를 제공한다. 이 기능은 백업, 포트폴리오 데모, 서버 장애 대비, 데이터 이전에 유용하다.

## 12. Provider와 플랫폼 capability 경계

Flutter의 도메인 계약은 provider 응답과 SDK 객체를 포함하지 않는다.

```dart
abstract interface class PlaceProvider {
  Future<List<Place>> searchPlaces(String query);
  Future<PlaceDetail> getPlaceDetail(String placeId);
}

abstract interface class MapAdapter {
  MapCapabilities get capabilities;
  Widget buildMap(MapViewModel model);
}

abstract interface class ReceiptParser {
  Future<ParsedReceipt> parseReceipt({
    required EntityId tripId,
    required ReceiptImageInput image,
  });
}
```

Android의 첫 구현체는 Google place provider와 `google_maps_flutter` adapter다. NAVER는 국내 여행을 시작할 때 별도 adapter로 추가한다. 실제 경로 계산이 채택되기 전에는 `getRoute`를 repository 계약에 미리 넣지 않고 외부 Google Maps 링크만 만든다.

`ReceiptImageInput`의 앱 내부 값은 `Uint8List bytes`, `mimeType`과 선택적 파일명이다. Callable wire에서는 제한된 base64 또는 승인된 임시 업로드 방식으로 변환하고 backend가 다시 bytes로 검증한다. OCR provider SDK는 Node.js backend 안에만 존재한다.

Web을 추가할 때는 `MapCapabilities`, 로그인, 파일·카메라와 공유 adapter를 플랫폼별로 구현한다. `dart:io`를 domain이나 공통 Widget에 노출하지 않는다.

## 13. MVP와 후속 기능 경계

| 영역 | MVP | 후속 또는 실험 |
| --- | --- | --- |
| 계정/공유 | 익명 인증, 선택 Google 연결, 공유 코드, 멤버 기반 접근 | App Links 초대, 세부 역할, 링크별 권한, 활동 이력 |
| 플랫폼 | Flutter Android 앱, API 24 이상, mock과 FlutterFire repository | Flutter Web, iOS, tablet 최적화 |
| 지도 | Google 장소 검색·URL·직접 입력, 번호 핀, 날짜별 색상, 직선 동선 | 실제 경로·이동 시간, 국내 NAVER adapter |
| 준비 | 단순 예약과 체크리스트 | 알림, 첨부, 민감 문서 보관 |
| 정산 | 전체 균등, 항목별 소비자 균등, 참여자별 직접 금액, 조정 배분, 개인 소비와 최종 송금 | 다중 결제자, 송금 연동·완료 상태, snapshot, 자동 소비자 추천 |
| OCR | 일본어 원문·한국어 번역을 함께 보는 수정 가능한 후보, 수동 fallback, 명시적 확정 | 이미지 보관, 비동기 검토 큐, 자동 품목 분류·고급 추천 |
| 활동·위치 | 포함하지 않음 | opt-in 이동 기록, Health Connect, 권한·Play 정책 검토 |
| 장소 가져오기 | 공식 흐름인 검색·개별 URL·직접 입력 | 계정 저장 목록 자동 동기화 |
| 데이터 파일 | `.trip.json` 백업·복원·데모 | 핵심 공동 편집 수단으로 사용하지 않음 |

기존 강릉 KRW fixture는 회귀 데이터로 보존하지만 첫 구현 순서는 `tokyo-2026-11`과 Google Maps다.

## 14. 남은 구현 결정

- Firestore 보안 규칙에서 멤버 읽기/쓰기와 참여자·지출 참조 무결성을 어떻게 검증할지
- Google Maps 일반 URL과 단축 URL에서 장소 ID, 이름과 좌표를 얻지 못하는 경우의 허용 목록과 fallback
- OCR 이미지의 최대 크기·형식, Functions timeout, 사용자별 호출 제한
- Firebase Blaze, Google Maps와 Document AI·Translation 예산 알림 및 호출량 제한
- OCR 외부 전송 동의 문구와 장애·재시도 안내의 최종 표현
- 첫 여행에서 지출별 KRW·JPY를 허용할지와 통화별 공유 문구
- Flutter Web 보조판이 필요해지는 시점과 Android 대비 capability 수용 기준

## 15. 1차 권장 결정

- 프론트엔드: Flutter stable + Dart, Android API 24 이상 우선
- 배포: 로컬 debug APK와 승인된 내부 배포. Flutter Web Hosting은 후속
- 인증: Anonymous Auth 기본, Google 로그인 선택 연결
- 백엔드: Node.js 22·TypeScript Cloud Functions, Firestore와 Rules 테스트. 영수증용 영구 Storage는 MVP 제외
- 공유: Cloud Function 기반 공유 코드 우선, Android App Links는 후속
- 세션: `trips/{tripId}/members/{uid}` 기반 멤버 관리
- 지도: Google 장소 검색·URL·직접 입력, 지도 표시, 번호 핀과 직선 동선 우선
- 정산: 확정 지출 원장을 기준으로 결제액, 부담액, 정산 결과와 개인 소비 내역 파생
- OCR: Android 이미지의 원문과 번역을 담은 수정 가능한 항목 초안을 만들고 사용자 확인 후에만 지출 저장
- `.trip.json`: 백업, 복원, 데모 데이터 용도

이 조합은 구현 난이도와 서비스 경험 사이의 균형이 좋다.

## 16. 참고 공식 문서

- [Flutter 지원 플랫폼](https://docs.flutter.dev/reference/supported-platforms)
- [Flutter Web](https://docs.flutter.dev/platform-integration/web)
- [Flutter Android 배포](https://docs.flutter.dev/deployment/android)
- [FlutterFire 설정](https://firebase.google.com/docs/flutter/setup)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Google Maps for Flutter](https://developers.google.com/maps/flutter-package)
- [Google Document AI processors](https://cloud.google.com/document-ai/docs/processors-list)
