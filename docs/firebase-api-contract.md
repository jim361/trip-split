# Firebase/API 계약 및 연결 감사

> **[구현 인계 · Firebase/API]** 2026-08-30 기준 모바일 Flutter, 전환기 React 목업, Firebase Functions와 Firestore Rules의 실제 연결 상태입니다.

## 결론

- 제품 기준 모델은 `frontend/lib/domain/models.dart`의 Flutter canonical 계약입니다.
- `frontend/src`는 GitHub Pages 회귀 목업이며 기본값 `VITE_DATA_SOURCE=mock`을 유지합니다. React 도메인도 canonical Trip 필드를 사용하고, 기존 Firestore 문서의 `regionType`·`currency` 호환은 repository 읽기 경계에만 남깁니다.
- 실제 export된 Callable은 `createTrip`, `createShareCode`, `joinTrip` 세 개뿐입니다.
- Auth·Firestore·Functions Emulator 구성과 세 공유 Callable의 통합 테스트는 존재합니다.
- 장소 검색, 준비 저장, 지출 쓰기와 OCR은 Firebase mode에서 아직 사용할 수 없습니다.
- React 날짜×시간 grid의 하단 일정 form은 기존 itinerary repository만 사용합니다. 선택 값을 비우는 update는 `null`을 전달하며 mock은 해당 key를 제거하고 Firestore adapter는 `deleteField()`로 변환합니다.
- 실제 Firebase 프로젝트 설정·배포 credential·Google OAuth/Maps 설정·OCR provider credential은 저장소와 현재 환경에 없습니다. 따라서 지금 가능한 외부 연결은 `demo-trip-split` Emulator뿐입니다.

상태 표기는 다음과 같습니다.

| 상태 | 의미                                                               |
| ---- | ------------------------------------------------------------------ |
| 구현 | handler/repository/Rules가 서로 맞고 테스트가 있음                 |
| 부분 | 읽기 또는 인터페이스만 있으며 화면 흐름 전체는 연결되지 않음       |
| mock | 외부 연결 없이 fixture로만 동작                                    |
| 차단 | 호출하거나 쓰면 function-not-found 또는 permission-denied가 발생함 |

## 화면별 데이터와 API 경계

| 화면           | 필요한 데이터·명령                                     | Flutter Android                                 | React/Vite 목업                               | Firebase backend·Rules                                          | 현재 판정                                    |
| -------------- | ------------------------------------------------------ | ----------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------- |
| 계정 시작      | 익명 Auth, 선택 Google 연결, `users/{uid}`             | Auth service와 user upsert 구현                 | Auth service 구현, 기본 mock                  | 자기 user 문서 Rules 구현                                       | Emulator 구현; 운영 설정 없음                |
| 여행 생성·참여 | 여행·초기 Participant 생성, 코드 재생성·참여           | 세 Callable client 구현                         | canonical 입력을 세 Callable client로 전달    | `createTrip`, `createShareCode`, `joinTrip` 구현                | 구현                                         |
| 내 여행 선택   | 현재 uid의 여행 목록                                   | 고정 mock 여행 선택만 제공                      | fixture 선택만 제공                           | 멤버십 기반 목록 query/index/API 없음                           | mock                                         |
| 일정·지도      | trip, members, places, itinerary 실시간 구독과 CRUD    | Firestore repository 구현; 지도는 mock renderer | Firestore repository와 mock map 구현          | places/itinerary member Rules 구현                              | 데이터는 구현, 실제 Google 지도 SDK는 미연결 |
| 장소 검색·링크 | `searchPlaces`, `parsePlaceLink`, 직접 입력 Place 저장 | provider 인터페이스와 mock만 있음               | provider 인터페이스와 mock만 있음             | 두 Callable handler 없음; Place 직접 CRUD Rules는 있음          | 검색·링크 차단, 직접 입력만 연결 가능        |
| 준비           | Reservation, ChecklistItem 실시간 구독·편집            | 정적 화면 데이터                                | 정적 화면 데이터                              | 컬렉션 Rules·repository·모델 없음                               | mock                                         |
| 비용·정산      | participants/expenses 구독, validated expense CRUD     | Firestore 읽기와 직접 쓰기 메서드가 함께 존재   | Firestore 읽기와 직접 쓰기 메서드가 함께 존재 | expense read만 허용, 모든 client write 거부; CRUD Callable 없음 | 읽기 부분 구현, 쓰기 차단                    |
| 영수증         | 이미지 검증, `parseReceipt`, 검토 후 expense 저장      | 5 MiB 이미지 검증·canonical mock parser만 있음  | legacy Callable client와 mock 응답이 있음     | `parseReceipt` handler/provider 없음                            | mock; Firebase 호출 차단                     |

`TripSession`이 현재 구독하는 컬렉션은 `trip`, `members`, `participants`, `places`, `itinerary`, `expenses`입니다. `reservations`와 `checklistItems`는 목표 경로만 문서에 있고 코드에는 없습니다.

React의 날짜×시간 grid와 Flutter의 일정 요약·일차별 목록은 같은 `trips/{tripId}/itinerary` 모델을 표현합니다. `planId`는 `A | B`, `category`는 `flight | transport | meal | activity | stay | other`이며 선택한 안만 지도·요약에 전달합니다. 누락된 legacy 값은 `A/other`로 읽고 기존 ID·문서는 자동 변경하지 않습니다. 값이 존재하지만 enum 밖이면 repository와 Rules에서 거부합니다. 순서 계산은 planId와 date별로 분리합니다.

`VITE_DATA_SOURCE=firebase` 또는 Emulator에서 같은 trip을 열었을 때는 변경이 stream으로 공유됩니다. 기본 `VITE_DATA_SOURCE=mock`의 in-memory 변경은 브라우저 프로세스 밖이나 Flutter mock fixture로 전파되지 않습니다. 이번 변경은 Rules 배포나 실제 Firebase 연결을 포함하지 않습니다.

## Firestore 경로와 쓰기 주체

| 경로                                              | canonical 핵심 필드                                              | 읽기        | 쓰기 주체·제약                                                       | 상태             |
| ------------------------------------------------- | ---------------------------------------------------------------- | ----------- | -------------------------------------------------------------------- | ---------------- |
| `users/{uid}`                                     | `displayName`, `email?`, `photoURL?`, `authProvider`, timestamps | 본인        | 본인; auth provider와 server timestamp 검증                          | 구현             |
| `shareCodes/{code}`                               | `tripId`, `createdBy`, `isActive`, `useCount`, 제한 필드         | client 금지 | Admin Callable transaction만 허용                                    | 구현             |
| `trips/{tripId}`                                  | canonical Trip 필드; 생성 시 legacy 호환 필드도 함께 기록        | member      | 생성·코드 변경은 Callable; client는 title/date만 수정 가능           | 구현             |
| `trips/{tripId}/members/{uid}`                    | display/profile, `role=editor`, timestamps                       | member      | 생성·참여는 Callable; 본인은 제한된 profile/lastActive만 수정        | 구현             |
| `trips/{tripId}/participants/{participantId}`     | name/color/`linkedUid?`/isActive/timestamps                      | member      | client create/update 가능하나 `linkedUid` 쓰기·변경과 물리 삭제 금지 | 부분             |
| `trips/{tripId}/places/{placeId}`                 | canonical Place, `addedBy`, timestamps                           | member      | member 직접 CRUD; non-manual provider는 trip provider와 일치         | 구현             |
| `trips/{tripId}/itinerary/{itemId}`               | date/time/place/title/planId/category/order, `updatedBy/At`      | member      | member 직접 CRUD                                                     | 구현             |
| `trips/{tripId}/reservations/{reservationId}`     | 목표 계약만 존재                                                 | 없음        | Rules·repository 없음                                                | mock             |
| `trips/{tripId}/checklistItems/{checklistItemId}` | 목표 계약만 존재                                                 | 없음        | Rules·repository 없음                                                | mock             |
| `trips/{tripId}/expenses/{expenseId}`             | canonical Expense와 중첩 allocation/receipt items                | member      | client create/update/delete 전부 거부                                | 읽기만 부분 구현 |

중요한 제한:

- React `deleteParticipant`는 실제 Rules에서 항상 거부됩니다. canonical 동작은 Flutter처럼 `isActive: false`로 비활성화하는 것입니다.
- React participant input은 `linkedUid`를 받을 수 있지만 실제 Rules는 client 연결을 거부합니다. 연결 전용 Callable은 아직 없습니다.
- Flutter와 React의 Firestore expense 직접 쓰기 메서드는 현재 Rules와 맞지 않습니다. 서버 validator와 세 expense Callable을 만든 뒤 그 client adapter로 교체해야 합니다.
- React trip update도 Flutter와 같이 title/date만 받습니다. `regionType`·`currency`는 기존 Firestore 문서를 canonical 필드로 읽기 위한 adapter 호환과 생성 Callable의 전환기 출력에만 남습니다.

## Callable 계약과 구현 상태

Callable 이름은 고정하며 변경하거나 별칭을 추가하지 않습니다.

| Callable          | 요청                                                                                                      | 응답                                            | Auth/멤버     | 구현 상태                                            |
| ----------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ------------- | ---------------------------------------------------- |
| `createTrip`      | canonical Trip 입력, `participantNames`; 전환기에는 `regionType`, `currency`, `participantCount`도 정규화 | `{ tripId, shareCode }`                         | Auth          | 구현·Emulator 테스트                                 |
| `createShareCode` | `{ tripId }`                                                                                              | `{ tripId, shareCode }`                         | Auth + member | 구현·Emulator 테스트                                 |
| `joinTrip`        | `{ shareCode, displayName? }`                                                                             | `{ tripId, title, shareCode }`                  | Auth          | 구현·Emulator 테스트                                 |
| `searchPlaces`    | `{ tripId, query }`                                                                                       | `PlaceCandidate[]`                              | Auth + member | 이름·계약만 고정, handler/client adapter 없음        |
| `parsePlaceLink`  | `{ tripId, url }`                                                                                         | `PlaceCandidate`                                | Auth + member | 이름·계약만 고정, handler/client adapter 없음        |
| `createExpense`   | `tripId`와 canonical Expense draft                                                                        | 저장된 expense 식별 정보 또는 canonical Expense | Auth + member | 이름만 고정; payload·응답 wire와 validator 구현 필요 |
| `updateExpense`   | `tripId`, `expenseId`, canonical Expense draft                                                            | 갱신 결과                                       | Auth + member | 이름만 고정; payload·응답 wire와 validator 구현 필요 |
| `deleteExpense`   | `{ tripId, expenseId }`                                                                                   | 삭제 결과                                       | Auth + member | 이름만 고정; 참조·멱등 정책 구현 필요                |
| `parseReceipt`    | `{ tripId, imageBase64, mimeType }`                                                                       | canonical `ParseReceiptResponse`                | Auth + member | Flutter 요청/응답·mock만 구현; backend 없음          |

구현되지 않은 지출 Callable의 구체적인 성공 응답을 이 문서에서 임의로 확정하지 않습니다. 같은 runtime validator와 transaction 경계가 설계될 때 세 함수와 Flutter adapter를 한 변경으로 확정해야 합니다.

`parseReceipt`의 canonical 응답은 Flutter 계약을 따릅니다.

```text
rawText
sourceLanguage?
merchantNameOriginal?
merchantNameTranslated?
expenseDate?
currencyCandidate?
totalAmountCandidate?
items[]
  nameOriginal
  nameTranslated?
  amount?
  confidence?
  sourceOrder
warnings[]
```

## 모바일·웹 계약 정합성과 남은 경계

| 범위             | Flutter canonical                                           | React 목업                              | 처리 원칙                                                                                |
| ---------------- | ----------------------------------------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------- |
| Trip             | `countryCode`, `timeZone`, `mapProvider`, `defaultCurrency` | 동일                                    | legacy `regionType`·`currency`는 Firestore 읽기 경계와 Callable 전환 출력에만 유지       |
| Place `addedBy`  | 필수                                                        | Firestore wire에서 필수                 | 저장 wire에서 필수                                                                       |
| 도메인 enum      | Dart 내부는 일부 `String`                                   | TypeScript literal union                | backend/Rules runtime 검증이 최종 방어선                                                 |
| OCR 이름         | original/translated 필드 분리                               | 아직 legacy `merchantName`, item `name` | 향후 `parseReceipt`는 Flutter canonical 응답 사용; React client는 production 기준이 아님 |
| Participant 제거 | 비활성화                                                    | 물리 삭제 메서드 존재                   | 비활성화만 canonical                                                                     |
| 준비 데이터      | 모델 없음                                                   | 모델 없음                               | 정적 mock; Firebase 데이터로 오인하지 않음                                               |

두 Tokyo fixture는 `tripId = tokyo-2026-11`, canonical Trip 핵심 값과 JPY 4,500 지출을 맞췄지만 stable ID 전체를 강제로 같게 만들지는 않았습니다.

- React의 기존 stable ID와 Flutter ID 관계는 `frontend/src/test/fixtures/tokyoTrip.ts`의 `tokyoFlutterIdMap`이 명시합니다.
- core 일정의 날짜·시간·장소 의미와 JPY equal 지출은 정합화했고, React가 가진 추가 장소·일정 행은 목업 회귀 범위로 보존합니다.
- 기존 ID는 변경하지 않습니다. 이름이 같다는 이유로 ID를 치환하지 말고 명시적 mapping을 사용합니다.
- 강릉 React fixture는 KRW·NAVER·itemized 회귀 데이터이며 Flutter Firebase seed가 아닙니다.

## 실제 Firebase 연결 가능 여부

### 지금 가능한 것

- Node.js 22 Functions runtime, Firestore Rules와 Auth/Firestore/Functions Emulator 설정
- `demo-trip-split` 프로젝트 ID를 사용하는 과금 없는 Emulator 통합 테스트
- Flutter `--dart-define`의 `DATA_SOURCE=firebase`, `USE_FIREBASE_EMULATORS=true`, Android host `10.0.2.2`
- Web의 `VITE_DATA_SOURCE=firebase`, `VITE_USE_FIREBASE_EMULATORS=true`, localhost Emulator
- 익명 Auth, user profile, 공유 세 Callable, member 기반 trip/participant/place/itinerary 읽기·허용된 직접 쓰기

### 2026-08-30 Android Emulator smoke

API 36 AVD `TripSplit_API_36`에서 다음 설정과 실제 Flutter APK로 확인했습니다.

```powershell
npm run dev:backend
cd frontend
flutter build apk --debug --dart-define-from-file=dart_defines.example.json
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

- 첫 익명 사용자: Auth 성공 → `createTrip` 성공 → 생성된 trip route에서 Firestore `trip`·하위 컬렉션 stream 구독 성공
- 생성 결과: canonical JP/Tokyo/Google/JPY Trip, owner member 1개, Participant 3개와 활성 share code 생성
- 두 번째 익명 사용자: `joinTrip` 성공 → 같은 trip stream 구독 성공; member 2명과 share code `useCount = 1` 확인
- `createShareCode`: Flutter adapter와 backend/Rules 통합 테스트는 존재하지만 현재 앱에는 코드 재생성 action이 없어 Android 수동 smoke 대상은 아님
- backend Emulator 회귀 테스트는 세 Callable의 생성·재생성·참여와 Rules를 모두 검증함

Android Firebase SDK는 emulator에서도 API key의 기본 형식을 검사합니다. `dart_defines.example.json`의 값은 외부 프로젝트에 권한이 없는 39자 emulator 전용 더미 값이며, 이전 `demo-api-key`처럼 형식이 맞지 않으면 Auth 후 Functions 호출이 시작되기 전에 Firebase Installations 오류가 납니다. 운영에서는 이 값을 재사용하지 않고 실제 Firebase Android app의 API key를 secret 주입 경계로 제공합니다.

### 운영 연결을 막는 것

- `.firebaserc`는 `demo-trip-split`만 가리키고 실제 Firebase project alias가 없습니다.
- 실제 `.env`, `google-services.json`, 생성된 `firebase_options.dart`, Flutter production dart-define 파일이 없습니다.
- 현재 환경에 Firebase/Google 관련 credential 환경변수나 승인된 ADC가 없습니다.
- Firebase Console의 Anonymous/Google Auth provider 활성화와 Android SHA/OAuth client 설정 여부를 검증할 수 없습니다.
- Google Maps Flutter SDK 의존성·Android API key와 실제 map adapter가 없습니다.
- Google Places, OCR·번역 provider handler와 credential이 없습니다. `.env.example`의 OCR provider 기본값도 외부 호출이 없는 `mock`입니다.
- 실제 Firebase 배포는 수행되지 않았고 승인 없이 배포하지 않습니다.

운영 연결에는 실제 project의 API key/app ID/sender ID/project ID, Auth provider 설정, Android OAuth server client ID, 필요한 SHA fingerprint, Functions 배포와 Rules/index 배포가 추가로 필요합니다. 이 값은 Git에 넣지 않고 승인된 로컬 dart-define 또는 CI secret으로 주입합니다.

## 다음 구현 순서

Android Emulator 수직 흐름 `Anonymous Auth → createTrip/joinTrip → trip 구독`은 위 smoke로 완료했습니다. 다음 순서는 아래와 같습니다.

1. expense runtime validator와 `createExpense`·`updateExpense`·`deleteExpense`를 구현하고 client 직접 쓰기를 Callable adapter로 교체합니다.
2. `searchPlaces`·`parsePlaceLink`와 Google provider adapter를 구현합니다.
3. 준비 기능을 실제 MVP에 저장하기로 확정하면 Reservation/ChecklistItem 모델·repository·Rules를 함께 추가합니다.
4. 지출 저장 경계 뒤에 `parseReceipt` mock backend, 실제 provider benchmark와 사용자 전송 고지를 연결합니다.
5. 실제 Firebase 프로젝트와 비용 한도를 설정한 뒤 별도 승인을 받아 배포합니다.

화면만 Firebase로 전환하거나 Rules만 느슨하게 열어 우회하지 않습니다. 특히 expense client write 허용은 validator가 없는 중첩 금액 데이터를 원장에 넣을 수 있으므로 유지하지 않습니다.
