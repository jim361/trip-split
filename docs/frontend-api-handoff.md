# Flutter 화면·API 구현 인계

> 2026-09-14. 사용자 승인에 따라 화면·mock·FlutterFire adapter와 필요한 서버 함수까지 함께 구현했다. **외부 Google/OCR 연결, 운영 배포와 Android 실기기 전체 검증은 별도**다. 역할은 사용자(프론트·공통·통합), 일정·지도 백엔드, 정산·영수증 백엔드로 유지한다.

기준: [기술 계약](../MarkDown/tech.md), [개발 시작 안내](development-kickoff.md), [Firebase 연결 상태](firebase-api-contract.md), [화면 캡처와 공유 문구](development-update-2026-09-14.md).

현재 전체 Flutter 화면의 진입 경로·구현 파일·사진은 [Android 화면 목록과 갤러리](flutter-screen-catalog.md)를 사용한다. mock AVD 캡처와 실제 외부 연결 검증을 구분한다.

현재 착수는 Phase B(P0) 핵심 통합이다. 아래 표는 구현 목록이며 모든 항목의 실제 연결을 동시에 시작하라는 지시가 아니다. 수동 equal/custom·최소 준비·기본 내 여행 목록·Google 지도/검색은 B, itemized·촬영/OCR·번역의 실제 통합은 B 완료 뒤 C(P1)다. P1 선행 구현과 회귀 테스트는 유지한다. 담당별 작업은 개발 시작 안내를 따른다.

## 1. 제작 순서와 화면 동작

| 순서           | 화면                            | 구현한 흐름                                                                                                             | 저장 경계                                          |
| -------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| 1 · TASK-03    | 장소 보관함·검색·링크·직접 입력 | 입력 → 결과/빈 결과/오류 → 후보 검토 → 저장·수정 → 일정에서 선택. 이름 필수, 주소·좌표·메모 선택                        | 검색·링크 Callable, places CRUD                    |
| 2 · TASK-04/05 | 일정·지도                       | 장소 없는 일정, 연결/해제, 날짜·A/B안·시간·메모, 편집/삭제, 길게 끌어 정렬, 시간순 정렬, 핀 선택과 외부 지도 열기       | itinerary CRUD, 그룹 전체 order transaction        |
| 3 · TASK-04    | 예약·체크리스트                 | 추가 → 편집 → 상태 변경/완료 → 집계 갱신 → 삭제 확인. 담당자·연결 일정 선택                                             | reservations/checklistItems CRUD + Rules           |
| 4 · TASK-02/06 | 참여자 관리·개인 정산           | 이름·색상·활성 상태 편집, 본인 연결/해제, 통화별 결제/부담/잔액, 날짜·유형 필터, 항목별 개인 소비, 송금 제안·복사       | participants CRUD + linkMyParticipant; 계산은 Dart |
| 5 · TASK-02    | 내 여행·설정·공유               | 가입 여행 조회·선택·새로고침, 제목·기간 편집, 공유 코드 복사·시스템 공유·재생성                                         | listMyTrips, trip update, createShareCode          |
| 6 · TASK-06/07 | 수동 비용·영수증                | equal/custom 수동 등록·상세·수정·삭제. 이미지 → 인식 후보 → 항목/할인/봉사료/조정 편집·재정렬 → 소비자 배분 → 확인 저장 | parseReceipt, 지출 Callable 3개                    |

짧은 입력은 두 칸이며 작은 폭·큰 글씨에서는 한 칸으로 바뀐다. 저장 중 버튼·뒤로 가기를 막고 실패 시 입력을 유지한다. 변경 후 이탈은 확인한다. 일정 편집 후 선택 날짜·A/B안·지도 확대 상태를 유지한다. 정산 상세 왕복도 개인 화면의 통화·필터 상태를 유지한다.

내 여행은 fixture 고정 카드가 아니라 repository 결과다. mock 변경은 현재 프로세스 메모리에서만 유지된다. React Pages는 기존 참고 목업이며 이번 Android UI가 자동 반영되는 배포본이 아니다.

## 2. 확정한 UX·데이터 결정

- **시간순 정렬**: 사용자 확인 후 시간 있는 일정 우선, 같은 시각은 기존 순서, 시간 없는 일정은 끝. 날짜·A/B 그룹 밖은 변경하지 않는다.
- **기간 수정**: 기존 일정의 날짜를 자동 변경하거나 삭제하지 않는다. 기간 밖 일정도 날짜 선택에서 계속 접근하며 설정에 안내한다.
- **장소·일정 삭제**: 화면 안내에 더해 서버 Callable도 참조 중 삭제를 거부한다. 장소는 일정·지출, 일정은 예약·지출의 연결을 먼저 명시적으로 해제해야 한다. 여행 referenceVersion을 참조 저장·해제와 삭제가 공유하여 동시 연결을 보호한다. 기존 고아 참조는 편집기에서 재선택·해제한다. 문서·정산 내역을 자동 삭제하지 않는다.
- **개인 체크리스트**: personal은 분류이며 비공개 접근 권한이 아니다. 해당 여행의 모든 멤버가 읽고 편집한다. 민감 문서 첨부는 제공하지 않는다.
- **내 계정 연결**: 요청자의 Auth UID만 사용한다. 같은 여행에서 하나만 연결하고 기존 본인 연결을 해제하며 새 연결을 transaction으로 적용한다. 다른 계정에 연결된 참여자·비활성 대상은 거부한다.
- **통화**: JPY/KRW 최소 단위 정수. 다른 통화는 합산·환산하지 않는다. OCR 미지원 통화는 사용자가 지원 통화와 금액을 확인하기 전 저장을 막는다.
- **OCR 총액 분할**: equal/custom은 `source: manual`, `receiptItems: []`. 항목별 확정은 `allocationMethod: itemized`, 검토된 행과 집계 배분을 저장한다. 인식 성공 자체는 저장이 아니다.
- **지도**: Flutter 내부 지도는 표시 모델을 사용하는 mock이다. 번호 핀에서 일정 편집, 외부 Google Maps 장소·구간 URL 열기는 연결했다. 실제 지도 SDK·유료 경로 계산은 포함하지 않는다.

## 3. Callable 목록

아래 요청과 응답은 Firebase Callable SDK의 `data`다. 기존 11개 이름을 유지하고 삭제 Callable 2개를 추가했다. Auth UID는 토큰에서 얻는다. 리전은 `asia-northeast3`다.

| 이름 / 소유                | 요청                                        | 성공 응답                    | 현재 구현                                             |
| -------------------------- | ------------------------------------------- | ---------------------------- | ----------------------------------------------------- |
| createTrip / 공통          | Trip 생성 입력 + participantNames           | `{tripId, shareCode}`        | Auth, 원자적 여행·멤버·참여자·코드 생성               |
| joinTrip / 공통            | `{shareCode, displayName?}`                 | `{tripId, title, shareCode}` | Auth, 코드 검증·멤버 등록                             |
| createShareCode / 공통     | `{tripId}`                                  | `{tripId, shareCode}`        | 멤버 확인, 이전 코드 비활성화                         |
| listMyTrips / 공통         | `{}`                                        | `{trips: Trip[]}`            | 현재 Auth UID로 membership 조회, updatedAt 내림차순   |
| linkMyParticipant / 공통   | `{tripId, participantId: string 또는 null}` | `{tripId, participantId}`    | null은 본인 연결 해제, 계정 경쟁 transaction          |
| searchPlaces / 일정·지도   | `{tripId, query: string}`                   | `PlaceCandidate[]`           | Auth·멤버·입력·provider 검증, Emulator fixture        |
| parsePlaceLink / 일정·지도 | `{tripId, url: string}`                     | `PlaceCandidate`             | URL 검증, Emulator fixture                            |
| deletePlace / 공통         | `{tripId, placeId}`                         | `{placeId}`                  | 멤버만 삭제, 일정·지출 참조 중 거부, 없는 ID는 성공   |
| deleteItineraryItem / 공통 | `{tripId, itineraryItemId}`                 | `{itineraryItemId}`          | 멤버만 삭제, 예약·지출 참조 중 거부, 없는 ID는 성공   |
| createExpense / 정산       | `{tripId, draft}`                           | `{expense: Expense}`         | 전체 runtime 검증·참조 확인·서버 감사 정보            |
| updateExpense / 정산       | `{tripId, expenseId, draft}`                | `{expense: Expense}`         | 전체 draft 교체, 생성 감사 정보 보존                  |
| deleteExpense / 정산       | `{tripId, expenseId}`                       | `{expenseId}`                | 멤버만 삭제, 없는 ID 재삭제도 성공                    |
| parseReceipt / 정산·영수증 | `{tripId, imageBase64, mimeType}`           | `ParseReceiptResponse`       | Auth·멤버·MIME/크기 검증, Emulator fixture, 저장 없음 |

searchPlaces/parsePlaceLink/parseReceipt는 Emulator 밖에서 `unavailable`을 반환한다. 실제 인식·검색 결과를 흉내 내 운영에 반환하지 않는다. backend 검색 후보의 source는 googleSearch, 링크 후보는 googleMapsUrl이다. 기존 Flutter 검색 fixture는 회귀를 위해 원래 source 메타데이터를 보존한다.

참조 중 삭제 오류는 `failed-precondition`, `details={appCode: conflict, retryable: false, field: placeId 또는 itineraryItemId}`다. 직접 Firestore 삭제는 거부한다. 일정 placeId·예약 itineraryItemId 변경과 연결된 예약 삭제는 같은 transaction에서 여행 `referenceVersion`을 +1 갱신한다. 구형 필드 생략은 0이고 단순 제목/order 수정은 기존 참조를 바꾸지 않으면 버전 증가를 요구하지 않는다. [저장 경계 상세](firebase-api-contract.md)를 함께 적용한다.

### 내 여행 인덱스와 기존 데이터

`trips/{tripId}/members/{uid}`에 동일 값의 `uid` 필드를 createTrip/joinTrip이 기록한다. 목록은 `members.uid` collection-group index를 사용하며 요청으로 다른 uid를 지정할 수 없다. Rules는 클라이언트의 uid 변경을 거부한다. 인덱스 정의는 `backend/firestore.indexes.json`에 포함했다.

이전 멤버 문서에 uid가 없으면 목록에 나오지 않는다. **기존 공유 코드로 재참여하면 같은 문서 ID에 uid를 보정한다.** 운영 데이터가 있으면 배포 전 관리자 backfill 또는 재참여 안내를 결정해야 한다. 이번 작업에서 운영 데이터 마이그레이션·배포는 하지 않았다.

### 장소 요청 예시

```json
{ "tripId": "example-trip", "query": "우에노" }
```

```json
[
  {
    "name": "우에노역",
    "address": "도쿄 다이토구",
    "lat": 35.7138,
    "lng": 139.7773,
    "provider": "google",
    "source": "googleSearch",
    "providerPlaceId": "example-place"
  }
]
```

PlaceCandidate 필수는 name/provider/source, 선택은 address/lat/lng/providerPlaceId/sourceUrl/memo다. ID·tripId·감사 필드는 저장할 때 생성한다. 좌표는 둘 다 없거나 유효한 유한 수여야 한다. 이름은 trim 후 1~160자다. non-manual provider는 여행의 mapProvider와 같아야 한다.

현재 서버 링크 허용: HTTPS의 `maps.google.com` 또는 `google.com`/`www.google.com`의 `/maps` 경로, `query` 또는 `q` 검색어. 예: `https://www.google.com/maps/search/?api=1&query=우에노`. 사용자 정보·비표준 포트·다른 호스트·단축 URL·임의 redirect/fetch는 허용하지 않는다. 실제 장소 URL의 모든 형식을 지원한다는 의미는 아니다. 해석 실패 시 검색·직접 입력을 제공한다.

### 지출 요청 예시

아래 participant ID는 해당 여행의 실제 정산 참여자 ID로 바꾼다. 로그인 UID를 넣지 않는다.

```json
{
  "tripId": "example-trip",
  "draft": {
    "title": "우에노 점심",
    "category": "food",
    "expenseDate": "2026-11-25",
    "totalAmount": 10000,
    "currency": "JPY",
    "payer": { "participantId": "a", "amount": 10000 },
    "consumers": ["a", "b", "c"],
    "allocationMethod": "equal",
    "allocatedAmounts": [
      { "participantId": "a", "amount": 3334 },
      { "participantId": "b", "amount": 3333 },
      { "participantId": "c", "amount": 3333 }
    ],
    "receiptItems": [],
    "source": "manual",
    "memo": "세 사람이 함께 먹은 점심"
  }
}
```

필수는 memo를 제외한 draft의 모든 필드다. placeId/itineraryItemId/memo는 선택이다. 요청의 감사 필드와 알려지지 않은 중첩 필드는 거부한다. 응답 Expense는 draft + id/tripId/createdBy/updatedBy/createdAt/updatedAt이며 시간은 epoch milliseconds다. Firestore에는 server timestamp로 저장한다.

- 금액은 JS safe integer, 총액 양수, payer.amount=totalAmount, 소비자 1~100명·중복 없음, 배분의 집합·합계·부호를 검증한다. 균등 나머지는 소비자 순서다.
- updateExpense는 전체 draft 교체다. 선택 필드 생략은 제거, createdBy/createdAt 보존, updatedBy/updatedAt 서버 기록. 삭제된 지출을 재생성하지 않는다.
- 같은 여행의 참여자와 장소·일정을 transaction에서 확인한다. 기존 지출에 있던 비활성 참여자는 유지할 수 있고 새 비활성 참여자는 거부한다.
- itemized는 1~200행, 고유 ID, sortOrder=0부터 연속, 행별 equal/custom, 행 소비자가 전체 소비자의 부분집합이어야 한다. item/serviceFee 양수, discount 음수, adjustment 0 아닌 정수다. 행·조정 총액과 참여자별 집계가 전체 배분과 같아야 한다.
- 자동 재전송으로 새 지출을 다시 생성하지 않는다. 중복 클릭은 UI에서 막고 네트워크 응답 유실은 원장을 확인한 후 재시도한다. 서버 idempotency key/오프라인 생성 큐는 이번 계약에 없다.

### OCR 요청·응답과 Android 입력

```json
{ "tripId": "example-trip", "imageBase64": "<JPEG/PNG/WebP base64>", "mimeType": "image/jpeg" }
```

```text
rawText, sourceLanguage?, merchantNameOriginal?, merchantNameTranslated?,
expenseDate?, currencyCandidate?, totalAmountCandidate?,
items[{nameOriginal, nameTranslated?, amount?, confidence?, sourceOrder}], warnings[]
```

이미지는 최대 5 MiB다. 서버는 base64 일치·MIME magic bytes·크기를 검사한다. 실제 provider 단계에는 전체 이미지 디코딩 및 provider timeout/보관 정책 검증이 추가로 필요하다. 현재 backend는 외부 호출·Firestore/Storage 저장·이미지 본문 로그 없이 고정 일본어 후보를 반환한다.

Android는 시스템 카메라, Android 13 이상 Photo Picker, 하위 버전 문서 선택을 사용한다. 이미지 디코딩·MIME·입력 크기 확인 후 방향을 보정하고 최대 2048px 이내 JPEG로 다시 인코딩해 EXIF 메타데이터를 제거한다. 촬영 파일은 전용 cache에만 두고 처리·취소·Activity 종료 시 삭제하며 이전 프로세스 잔여 파일은 다음 시작에 정리한다. 미리보기·OCR 원문은 메모리에 두며 영수증 화면 이탈 또는 저장 후 해제한다. 기기 카메라/공유 앱에 따른 동작은 실기기 QA 항목이다.

## 4. 준비 데이터 wire

경로는 기존 목표 경로를 구현했다. 아래 필드는 문서 최상위이며 `draft`라는 중첩 필드를 저장하지 않는다. Dart 객체 내부의 draft 합성은 wire와 구분한다.

| 컬렉션         | 필수                                                           | 선택                       |
| -------------- | -------------------------------------------------------------- | -------------------------- |
| reservations   | title, type, status, createdAt/updatedAt, createdBy/updatedBy  | url, memo, itineraryItemId |
| checklistItems | title, scope, isDone, createdAt/updatedAt, createdBy/updatedBy | assigneeParticipantId      |

예약 type은 flight/stay/transport/ticket/other, status는 planned/booked/cancelled다. 체크리스트 scope는 shared/personal이다. 제목은 trim 후 1~160자, 메모 2000자, URL은 http/https 2048자 이하다. optional 생략은 편집 시 제거된다. 참조 ID는 같은 여행의 문서를 가리켜야 한다. Rules가 멤버 여부·필드·서버 시간·감사 정보 보존을 검사한다. 체크 완료 명령은 isDone과 갱신 감사 정보만 수정해 제목 등의 동시 편집을 덮어쓰지 않는다.

## 5. 오류와 검증

Firebase 표준 HttpsError.code와 `details.appCode/retryable/field`를 Flutter AppError로 변환한다. 예: 권한 없음 permission-denied, 입력 invalid-argument, 삭제된 지출 not-found, 계정 선점 failed-precondition, provider 미연결 unavailable/ocr-unavailable, 이미지 invalid-image/payload-too-large. 외부 오류 원문·비밀 키·이미지 내용을 사용자 오류에 노출하지 않는다.

검증 명령은 `npm run verify:full`, `npm run verify:flutter:full`이다. 주요 새 테스트는 `frontend/test/development_flows_test.dart`, `backend/tests/emulator/domain-flows.emulator.test.ts`다. 기존 일정·수동 비용·Rules 회귀도 유지한다. Widget 캡처·APK 빌드·서버 Emulator 통과를 Android 실기기/실제 외부 서비스 통합 완료와 혼동하지 않는다.
