# Trip Split Tech Draft

## 1. 확정된 기술 방향

Trip Split MVP는 Vite + React + TypeScript 기반 모바일 우선 웹/PWA로 개발하고, Firebase BaaS를 백엔드로 사용한다. 초기 타겟은 국내 여행이며, 지도와 OCR은 네이버 계열 API를 우선 사용한다. 정산의 원본 데이터는 지출과 사용자 확정 영수증 항목이며, 개인 소비 요약과 최종 송금 결과는 이 원장에서 파생 계산한다.

## 2. 전체 구조

```text
Web/PWA
  -> Firebase Hosting
  -> Firebase Auth
       -> Anonymous Auth
       -> Google Provider(optional link)
  -> Firestore
  -> Firebase Storage(post-MVP optional)
  -> Cloud Functions
       -> Share code validation
       -> NAVER Maps API
       -> NAVER place link parsing
       -> CLOVA OCR API
```

프론트엔드는 사용자가 실제로 여행을 만들고, 장소를 저장하고, 일정과 비용을 편집하는 화면을 담당한다. Firebase는 배포, 인증, 데이터 저장, 공유 코드, 멤버 세션, 실시간 동기화를 담당한다. 네이버 API 호출과 OCR 호출은 Cloud Functions를 통해 처리해 API 키를 클라이언트에 직접 노출하지 않는다. 모바일과 PC는 같은 라우트와 기능 컴포넌트를 사용하고, 앱 셸의 배치만 반응형으로 확장한다.

PWA MVP는 manifest, 설치 아이콘, standalone 앱 셸과 정적 자산 캐시를 제공한다. Firestore 쓰기와 네이버·OCR 요청은 온라인 연결을 전제로 하며 오프라인 편집·충돌 해결은 보장하지 않는다. 연결이 없을 때는 상태를 표시하고 네트워크 의존 action을 재시도 가능한 오류로 처리한다.

## 3. Firebase 사용 범위

- Firebase Hosting: 웹/PWA 배포
- Firebase Auth: 익명 인증, 선택 Google 로그인 연결
- Firestore: 사용자, 여행, 멤버, 장소, 일정, 지출, 정산 데이터 저장
- Firebase Storage: MVP에서는 영수증 이미지에 사용하지 않으며, 이미지 보관 기능을 별도로 도입할 때만 후속 사용
- Cloud Functions: 공유 코드 검증, 네이버 지도 API, CLOVA OCR, 장소 링크 파싱 등 서버 측 작업

MVP에서는 사용자-facing 로그인 화면 없이 시작한다. 앱 진입 시 Anonymous Auth로 내부 `uid`를 발급하고, 사용자가 원하면 Google 계정을 연결한다. 이 방식은 진입 장벽을 낮추면서도 Firestore 보안 규칙, 멤버 관리, 내 여행 목록, 수정자 표시의 기반을 만든다.

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
  regionType
  currency
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

trips/{tripId}/expenses/{expenseId}
  title
  category
  expenseDate
  totalAmount
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

- 모든 KRW 금액은 부동소수점이 아닌 원 단위 정수다.
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

Firebase SDK 오류와 Callable `HttpsError`는 service 계층에서 `AppError`로 변환한다. 외부 API 원문 응답, 비밀 키, 이미지 본문은 UI 오류나 로그에 노출하지 않는다.

### Repository 계약

- 화면 컴포넌트는 Firebase SDK를 직접 호출하지 않는다.
- 목록과 실시간 데이터는 `subscribe*(tripId, onData, onError): Unsubscribe` 형태로 제공한다.
- 생성·수정·삭제는 `Promise` 기반 명령으로 제공하고 실패 시 `AppError`를 반환한다.
- 각 repository는 동일 인터페이스의 Firestore 구현체와 mock 구현체를 가져 외부 API나 Firebase 연결 전에도 화면과 도메인 테스트를 진행할 수 있게 한다.
- 장소 provider 응답은 저장 전에 앱 내부 `Place`로 정규화하고, 지도 모듈은 provider 원문이 아니라 `Place[]`와 정렬된 `ItineraryItem[]`만 입력받는다.

### Callable Function과 담당

| 담당 | Callable Function | 책임 |
| --- | --- | --- |
| 플랫폼·통합 | `createTrip`, `createShareCode`, `joinTrip` | 여행·생성자 멤버 원자적 생성, 공유 코드 생성·검증, 참여 멤버 등록 |
| 정산·영수증 | `parseReceipt` | 이미지 검증, CLOVA OCR 호출, `ParsedReceipt` 정규화 |
| 장소·일정·지도 | `searchPlaces`, `parsePlaceLink` | 네이버 장소 검색·링크 파싱, `Place` 후보 정규화 |

플랫폼·통합 담당은 Firebase 초기화, Functions 진입점, 보안 규칙, 공통 라우트, dependency와 lockfile을 최종 병합한다. 도메인 담당은 자신의 `features`, repository, Function 모듈과 테스트를 소유한다. 공통 타입이나 Firestore 경로를 바꾸는 PR은 세 담당자가 함께 검토한다.

공통 강릉 fixture는 고정 ID를 사용하고 장소, 일정, 참여자, 수동 지출, 항목형 영수증을 모두 포함한다. 세 도메인의 mock repository와 통합 테스트가 같은 fixture를 사용해 계약 불일치를 조기에 찾는다.

## 6. 인증과 공유 코드 흐름

```text
1. 사용자가 앱에 접속한다.
2. Firebase Anonymous Auth로 uid를 발급받는다.
3. 사용자가 여행 생성 폼을 제출하고 `createTrip`을 호출한다.
4. Function이 여행, 생성자의 member 문서와 첫 공유 코드를 원자적으로 만든다.
5. 친구가 공유 코드 또는 초대 링크로 접근한다.
6. `joinTrip`이 코드를 검증하고 친구의 uid를 `trips/{tripId}/members/{uid}`에 등록한다.
7. 프론트는 여행 하위 컬렉션을 `onSnapshot`으로 구독한다.
```

Google 로그인은 선택 기능이다. 익명 사용자에서 Google Provider를 연결하면 기존 uid와 여행 접근 권한을 유지하는 방향을 우선 검토한다.

## 7. 네이버 지도 API 사용 범위

국내 여행을 우선 타겟으로 하므로 네이버 지도 API를 우선 검토한다.

- Dynamic Map: 지도 표시
- Places: 장소 검색
- Geocoding: 주소를 좌표로 변환
- Reverse Geocoding: 좌표를 주소로 변환
- Map Styling: 배경 지도 테마, 기본 지도 요소, 아이콘 스타일 조정
- Directions: 장소 간 이동 경로와 이동 시간 계산, 이후 확장

초기 MVP에서는 장소 검색, 장소 링크 붙여넣기, 지도 표시를 먼저 구현한다. 타임테이블에 장소가 배치되면 지도에는 일정 순서 번호가 붙은 핀과 날짜별 직선 동선을 표시한다. 실제 도로 경로 계산과 이동 시간 표시는 이후 확장한다.

Map Styling은 앱의 번호 핀과 직선 동선이 잘 보이도록 배경 지도와 기본 POI 표현을 조정하는 용도로 사용한다. 여행 일정의 번호 핀, 날짜별 색상, 직선 동선은 Map Styling이 아니라 Dynamic Map 위에 커스텀 마커와 폴리라인으로 구현한다.

## 8. 네이버 저장 리스트 import 리스크

네이버 지도에 사용자가 저장해둔 개인 저장 리스트를 공식 API로 직접 가져올 수 있는지는 별도 검증이 필요하다. 공식 Maps 제품 범위에는 Dynamic Map, Places, Geocoding, Reverse Geocoding, Map Styling, Directions 등이 확인되지만, 개인 계정의 저장 리스트 조회 API는 현재 MVP 가정에 포함하지 않는다.

네이버 저장 리스트 import는 MVP의 기본 흐름이 아니라 실험 기능 후보로 둔다. 샘플 링크 `https://naver.me/xoGa4sgy`는 다음 URL로 리다이렉트되는 것을 확인했다.

```text
https://map.naver.com/p/favorite/sharedPlace/folder/{shareId}
```

네이버 지도 웹앱은 공유 리스트 본문을 다음 iframe URL에서 로드한다.

```text
https://pages.map.naver.com/save-pages/pc/detail-list/{shareId}
```

그리고 장소 목록은 다음 JSON API로 조회되는 것을 샘플로 확인했다.

```text
https://pages.map.naver.com/save-pages/api/maps-bookmark/v3/shares/{shareId}/bookmarks?start=0&limit=5000&sort=lastUseTime&createIdNo=false
```

응답에는 `folder`와 `bookmarkList`가 포함되며, 각 장소는 `name`, `px`, `py`, `sid`, `address`, `mcidName` 등을 가진다. 따라서 네이버 지도 공유 리스트 링크 import는 기술적으로 가능성이 있지만, MVP의 필수 기능으로 두지 않는다.

이 API는 NAVER Cloud Maps의 공식 공개 API가 아니라 네이버 지도 웹앱이 사용하는 내부 API로 보인다. 따라서 MVP는 공유 리스트 import에 의존하지 않는다. 기본 장소 추가 흐름은 네이버 장소 검색, 네이버 장소 링크 붙여넣기, 수동 입력으로 설계한다. 공유 리스트 import는 약관, 호출 제한, CORS, 차단 가능성, 응답 구조 변경 가능성을 확인한 뒤 베타 기능으로 검토한다.

## 9. OCR 사용 범위

영수증 인식은 CLOVA OCR을 사용한다. 목표는 사용자가 로컬에서 선택한 영수증 이미지로부터 수정 가능한 지출 초안을 만들고, 항목과 배분을 검토한 뒤 확정 지출로 등록하게 하는 것이다. OCR은 소비자를 자동 판단하거나 검토 없이 정산을 확정하지 않는다.

MVP OCR 흐름은 다음과 같다.

1. 사용자가 기기에서 영수증 이미지를 선택하고 외부 전송 안내를 확인한다.
2. 클라이언트가 파일 형식과 크기를 검사한 뒤 HTTPS Callable Function으로 전송한다.
3. Cloud Function이 CLOVA OCR을 호출하고 원문 텍스트, 상호·날짜·총액 후보, 항목명·금액 후보를 정규화해 반환한다.
4. 클라이언트가 결과를 Firestore 밖의 편집 가능한 `ReceiptDraft`로 만든다.
5. 사용자가 OCR 항목명과 금액을 고치고, 누락 항목 및 할인·봉사료·기타 조정을 추가한다.
6. 사용자가 결제자와 분할 방식을 정하고 전체 또는 항목별 소비자와 부담액을 지정한다.
7. OCR 인식에 실패하면 같은 화면에서 지출명과 전체 금액을 입력하는 수동 등록으로 전환한다.
8. 총액과 항목·배분 합계가 맞을 때 사용자가 명시적으로 저장한다.
9. 확정된 `Expense`만 Firestore에 저장되고 지출 구독을 통해 정산 결과가 재계산된다.

MVP에서는 영수증 이미지를 Firebase Storage나 Firestore에 영구 저장하지 않는다. Function은 요청 처리 중에만 이미지 바이트를 사용하고 응답 후 폐기하며, 요청 본문이나 이미지 내용을 로그에 남기지 않는다. 이미지를 저장하지 않더라도 OCR 처리를 위해 Firebase Functions와 CLOVA OCR로 전송된다는 점은 선택 전에 사용자에게 고지한다. 미확정 `ReceiptDraft`도 서버에 자동 저장하지 않는다.

```ts
type ParsedReceipt = {
  rawText: string;
  merchantName?: string;
  expenseDate?: string;
  totalAmountCandidate?: number;
  items: Array<{
    name: string;
    amount?: number;
    confidence?: number;
    sourceOrder: number;
  }>;
  warnings: string[];
};
```

## 10. 실시간 동기화 방식

프론트는 다음 데이터를 Firestore `onSnapshot`으로 구독한다.

- trip 기본 정보
- members
- participants
- places
- itinerary
- expenses

지출 변경 시 정산 엔진은 클라이언트에서 다음 값을 순수 함수로 재계산한다.

- 개인 결제액: 해당 참여자가 `payer`인 지출의 `payer.amount` 합
- 개인 부담액: 해당 참여자의 `allocatedAmounts.amount` 합
- 개인 정산 결과: 결제액 - 부담액. 양수는 받을 금액, 음수는 보낼 금액
- 개인 소비 분석: 개인 배분액을 카테고리별로 집계하고 날짜·장소·영수증 항목 또는 지출별로 펼친 내역
- 최종 송금 목록: 음수 잔액 참여자에서 양수 잔액 참여자로 보내도록 계산한 전송 목록

모든 참여자의 순잔액 합은 0이어야 한다. 같은 원장에서는 클라이언트마다 같은 송금 목록이 나오도록 잔액과 `participantId`를 기준으로 안정적으로 정렬한다. 정산 결과 snapshot 저장은 MVP 이후로 둔다. `receiptItems`는 `Expense`에 포함되므로 확정 지출은 문서 한 번의 write로 저장하고, 일정 정렬처럼 여러 문서를 함께 바꾸는 작업에만 batch write 또는 transaction을 사용한다.

## 11. 공유 방식

기본 공유 방식은 Firebase 기반 공유 코드 또는 초대 링크다.

- 여행장이 여행 생성
- 공유 코드 또는 초대 링크 생성
- 참여자가 코드 입력 또는 링크 접속
- Anonymous Auth uid 발급
- Cloud Function이 코드 검증
- Firestore members에 등록
- 여행 정보 실시간 구독

MVP에서는 모든 멤버가 편집 가능한 모델로 시작한다. 세부 권한, 작성자 추적 강화, 변경 이력은 이후 확장한다.

보조 공유 방식으로 `.trip.json` 내보내기/가져오기를 제공한다. 이 기능은 백업, 포트폴리오 데모, 서버 장애 대비, 데이터 이전에 유용하다.

## 12. 해외 확장 방향

국내 여행 MVP가 안정화되면 해외 여행 모드를 추가한다. 해외 여행에서는 지도 provider를 Google Maps 기반으로 교체하고, 통화, 환율, 타임존, 다국어 OCR을 추가한다.

이를 위해 지도와 OCR은 처음부터 provider 인터페이스를 둔다.

```ts
interface PlaceProvider {
  searchPlaces(query: string): Promise<Place[]>;
  getPlaceDetail(placeId: string): Promise<PlaceDetail>;
  getRoute(input: RouteInput): Promise<RouteResult>;
}

type ReceiptImageInput = {
  bytes: Uint8Array;
  mimeType: string;
};

interface OcrProvider {
  parseReceipt(input: ReceiptImageInput): Promise<ParsedReceipt>;
}
```

`ReceiptImageInput`은 Cloud Function 내부 provider용 `{ bytes: Uint8Array; mimeType: string }`다. 클라이언트의 base64 callable 요청은 Function에서 검증·디코딩한 뒤 이 타입으로 변환한다.

초기 구현체는 `NaverPlaceProvider`, `ClovaOcrProvider`로 시작한다.

## 13. MVP와 후속 기능 경계

| 영역 | MVP | 후속 또는 실험 |
| --- | --- | --- |
| 계정/공유 | 익명 인증, 선택 Google 연결, 공유 코드·초대 링크, 멤버 기반 접근 | 세부 역할, 링크별 권한, 활동 이력 |
| 지도 | 네이버 장소 검색·링크·직접 입력, 번호 핀, 날짜별 색상, 직선 동선 | 실제 경로·이동 시간, 해외 Google Maps |
| 정산 | 전체 균등, 항목별 소비자 균등, 참여자별 직접 금액, 조정 배분, 개인 소비와 최종 송금 | 다중 결제자, 송금 연동·완료 상태, snapshot, 자동 소비자 추천 |
| OCR | 수정 가능한 항목 후보, 수동 항목·총액 fallback, 명시적 확정 | 이미지 보관, 비동기 검토 큐, 자동 품목 분류·고급 추천 |
| 장소 가져오기 | 공식 흐름인 검색·개별 링크·직접 입력 | 네이버 저장 목록은 공식 API와 약관 검증 전 실험만 가능 |
| 데이터 파일 | `.trip.json` 백업·복원·데모 | 핵심 공동 편집 수단으로 사용하지 않음 |

MVP UI는 국내 여행, KRW, 네이버 지도만 노출한다. `regionType`과 provider 인터페이스는 확장 지점일 뿐 해외 모드가 현재 동작한다는 의미가 아니다.

## 14. 남은 구현 결정

- 공유 코드 만료, 최대 사용 횟수, 재생성 정책을 MVP에서 어디까지 단순화할지
- Firestore 보안 규칙에서 멤버 읽기/쓰기와 참여자·지출 참조 무결성을 어떻게 검증할지
- 네이버 장소 링크에서 장소 ID, 장소명, 좌표를 안정적으로 얻지 못하는 경우의 허용 목록과 fallback
- OCR 이미지의 최대 크기·형식, Functions timeout, 사용자별 호출 제한
- Firebase Blaze 요금제와 네이버 API 예산 알림 및 호출량 제한
- OCR 외부 전송 동의 문구와 장애·재시도 안내의 최종 표현

## 15. 1차 권장 결정

- 프론트엔드: Vite + React + TypeScript
- 배포: Firebase Hosting
- 인증: Anonymous Auth 기본, Google 로그인 선택 연결
- 백엔드: Firestore와 Cloud Functions. 영수증용 Storage는 MVP 제외
- 공유: Cloud Function 기반 공유 코드와 초대 링크 우선
- 세션: `trips/{tripId}/members/{uid}` 기반 멤버 관리
- 지도: 네이버 장소 검색, 장소 링크 붙여넣기, 지도 표시, 번호 핀, 직선 동선 우선
- 정산: 확정 지출 원장을 기준으로 결제액, 부담액, 정산 결과와 개인 소비 내역 파생
- OCR: 로컬 이미지에서 수정 가능한 항목 초안을 만들고 사용자 확인 후에만 지출 저장
- `.trip.json`: 백업, 복원, 데모 데이터 용도

이 조합은 구현 난이도와 서비스 경험 사이의 균형이 좋다.

## 16. 참고 공식 문서

- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [NAVER Cloud Maps](https://www.ncloud.com/product/applicationService/maps)
- [NAVER Cloud CLOVA OCR](https://www.ncloud.com/product/aiService/ocr)
