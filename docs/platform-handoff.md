# 플랫폼·통합 기반 인계

> **[인계 01 · 플랫폼·통합 구현 현황]** 공통 계약과 도메인 담당자 연결점을 정리합니다.

## 현재 Flutter 진입점

- 앱 조립: `frontend/lib/main.dart`
- 인증 게이트와 여행 세션: `frontend/lib/app/auth_session_gate.dart`, `trip_session.dart`
- mock/Firestore 공통 계약: `frontend/lib/domain/repositories.dart`
- 구현체: `frontend/lib/data/mock`, `frontend/lib/data/firebase`
- Auth와 Callable: `frontend/lib/services`
- 실행 설정: `frontend/lib/platform/app_config.dart`, `frontend/dart_defines.example.json`

앱은 기본 mock으로 시작하고 Firebase 모드에서는 Auth를 먼저 준비한 뒤 route와 Firestore 구독을 연다. Android Google Sign-In credential은 현재 익명 사용자에 `linkWithCredential`로 연결해 uid를 유지한다. `shareCodes` 컬렉션은 보안 규칙상 클라이언트가 직접 읽지 않으며 활성 코드는 `Trip.shareCode`, 생성·재생성·입장은 Callable을 사용한다.

> **전환 전 구현 스냅샷:** 아래 `frontend/src`, React Provider와 PWA 설명은 2026-08-28 이전 목업의 실제 상태를 기록합니다. 현재 제품 계약은 Flutter Android이며 새 코드는 이 구조를 확장하지 말고 [전환 계획](flutter-android-migration.md)에 따라 포팅합니다. backend Callable, Firestore 경로·Rules와 fixture의 의미는 재사용합니다.

## 공통 계약

- 도메인 타입·ID·epoch timestamp·`AppError`: `frontend/lib/domain/models.dart`
- repository 인터페이스와 draft: `frontend/lib/domain/repositories.dart`
- 고정 ID 도쿄 fixture와 in-memory mock: `frontend/lib/data/mock/`
- Firestore 구현과 SDK 오류 변환: `frontend/lib/data/firebase/`
- 전환 전 강릉 회귀 fixture: `frontend/src/test/fixtures/gangneungTrip.ts`

`TripMember.uid`는 인증·공동 편집 주체이고 `Participant.id`는 정산 주체입니다. 두 값은 같다고 가정하지 않으며 `Participant.linkedUid`로만 선택 연결합니다.

## 주입과 세션

`frontend/lib/main.dart`가 `AppConfig`에 따라 같은 `TripRepositories` 인터페이스의 mock 또는 FlutterFire 구현을 선택합니다.

- `mock` 기본값: 도쿄 fixture, `InMemoryTripRepositories`, `MockAuthService`
- `firebase`: FlutterFire Auth, `FirestoreTripRepositories`, `CallableTripShareService`

`AuthSessionGate`는 앱 진입 시 Anonymous Auth를 자동 시작합니다. Google credential 연결에는 실제 Firebase 설정 시 `GOOGLE_SERVER_CLIENT_ID`가 필요하며 예제 dart-define에는 빈 값만 둡니다.

`TripSessionController`는 route의 `tripId`를 받아 다음 데이터를 구독합니다.

- trip
- members
- participants
- places
- itinerary
- expenses

각 Widget은 controller가 조립한 같은 모델만 읽으며 Firebase SDK를 직접 호출하지 않습니다.

## 도메인 담당 연결점

### 정산·영수증

- `frontend/lib/domain/repositories.dart`의 participant·expense 계약
- `frontend/lib/features/settlement/settlement_engine.dart`의 deterministic equal 엔진
- `frontend/lib/features/receipts/receipt_parser.dart`의 bytes 기반 요청·응답 계약과 mock parser

equal 외 custom/itemized·runtime validator·paid/owed/net은 아직 없습니다. validator가 모든 중첩 배분을 검사하는 서버 저장 경계를 만들기 전까지 Firestore Rules는 expense 직접 쓰기를 거부합니다. `parseReceipt` backend handler와 OCR provider도 아직 없으며 향후 Callable은 `details.appCode` 오류 계약을 함께 정해야 합니다.

### 장소·일정·지도

- `frontend/lib/domain/repositories.dart`의 place·itinerary 계약
- `frontend/lib/features/places/place_provider.dart`의 provider-neutral 입력 경계
- `frontend/lib/features/map/map_render_model.dart`의 번호 핀·날짜 색·직선 segment·좌표 누락 모델
- `frontend/lib/features/itinerary/`의 편집 core와 상단 지도 placeholder

첫 Android 여행은 Google provider를 사용합니다. 실제 Google 응답은 `PlaceCandidate`로 정규화한 뒤 repository에 저장하며 manual을 제외한 place provider는 부모 trip의 provider와 같아야 합니다. NAVER adapter는 후속입니다.

일정과 지도는 `/trips/:tripId/itinerary` 한 화면에서 지도 미리보기 → 일정 순서로 표시합니다. `?map=expanded`는 확대 상태를 공유하는 canonical query이며, 기존 `/trips/:tripId/map`은 이 URL로 redirect합니다. 실제 지도 adapter를 연결할 때 컨테이너 크기 전환 뒤 지도 SDK의 resize/recenter를 호출해야 합니다.

## Callable Functions

`backend/src/share/trips.ts`에서 다음 세 함수를 export합니다.

- `createTrip`: trip, 생성자 member, 첫 share code와 user profile을 transaction으로 생성
- `createShareCode`: 멤버 확인 후 기존 활성 코드를 비활성화하고 새 코드와 `Trip.shareCode`를 transaction으로 갱신
- `joinTrip`: 코드를 검증하고 현재 auth uid를 editor member로 등록

MVP 생성 코드에는 `expiresAt`과 `maxUses`를 기록하지 않습니다. 손상됐거나 타입이 잘못된 제한 필드가 존재하면 join은 fail-closed로 거부합니다.

## 보안 규칙

`backend/firestore.rules`는 다음을 검증합니다.

- 인증 사용자 자기 `users/{uid}`만 접근
- `shareCodes` 클라이언트 직접 접근 금지
- `trips/{tripId}/members/{uid}` 존재 여부 기반 여행 접근
- trip 불변 필드와 update allowlist
- member role·joinedAt 불변 및 자기 프로필 필드만 수정
- participants의 client `linkedUid` 변경 금지, trip provider와 place provider 일치
- places와 itinerary의 canonical top-level 필드와 타입
- runtime validator 전 expense client write 전체 차단
- 생성·수정자 uid, `serverTimestamp`, created 감사 필드 불변

`npm run test:emulator`가 익명 사용자 두 명의 생성·참여, 코드 정책, 비멤버·무인증 거부와 보안 규칙을 검증합니다.

## 전환 전 PWA와 온라인 경계

- manifest: `frontend/public/manifest.webmanifest`
- 임시 SVG 아이콘: `frontend/public/icons/`
- service worker: `vite-plugin-pwa`의 `generateSW`
- 캐시: 빌드된 HTML, JS, CSS, SVG, webmanifest 정적 자산

Firestore 편집, Callable, 장소 provider와 OCR 요청은 오프라인 저장 완료로 표시하면 안 됩니다. 후속 UI는 `unavailable`인 `AppError`에 재시도 action을 제공해야 합니다.

## 아직 연결하지 않은 것

- 실제 Firebase 프로젝트와 배포
- Firebase Console의 Auth Provider 활성화
- Google/NAVER 지도·장소 검색 adapter와 링크 파싱 Functions
- provider-neutral OCR·번역 `parseReceipt` Function과 adapter secret
- custom/itemized·net 정산 엔진과 validated expense 저장 Callable
- `linkedUid` member 참조·유일성을 transaction으로 보장하는 연결 Callable
- Android `.trip.json` 파일 선택·Firebase 가져오기. schema codec은 구현됨
- 실제 PNG 설치 아이콘과 최종 시각 디자인

Functions 배포 런타임은 Node 22로 지정했습니다. 로컬 Firebase CLI도 Node 22 사용을 권장합니다.

현재 `npm audit --omit=dev`는 `firebase-admin@13`이 사용하는 Google SDK의 `uuid@9` 경로에서 moderate 8건을 보고합니다. 자동 수정은 `firebase-admin@14`로 올리지만, 설치된 `firebase-functions@7.2.5`의 공식 peer 범위는 아직 `firebase-admin@13`까지입니다. 강제 업그레이드나 transitive override는 적용하지 않았으며, Functions가 Admin 14를 공식 지원하면 함께 올리고 Emulator 회귀 테스트를 다시 실행해야 합니다.

## Flutter 포팅 연결점

| React 스냅샷                 | Flutter 목표                                         |
| ---------------------------- | ---------------------------------------------------- |
| `PlatformServicesProvider`   | app composition에서 mock/FlutterFire repository 주입 |
| `AuthProvider`               | Auth controller와 Android Google credential link     |
| `TripProvider`               | repository `Stream`을 조합하는 `TripSession`         |
| `frontend/src/shared/types`  | `frontend/lib/domain/models`의 immutable Dart 모델   |
| callback subscribe·`Promise` | Dart `Stream` watch와 `Future` command               |
| React route와 query          | Flutter router state, 후속 App Link/Web deep link    |
| Vite PWA cache               | Android Firestore cache·pending write 상태           |

- Android Emulator는 host Firebase Emulator에 `10.0.2.2`로 연결합니다.
- 첫 지도 adapter는 Google Maps이며 NAVER는 후속입니다.
- `parseReceipt` 이름과 사용자 확정 전 미반영 원칙은 유지하고 CLOVA 고정은 제거합니다.
- 기존 React 목업이 Flutter 세로 기능 조각으로 대체되기 전에는 파일을 일괄 삭제하지 않습니다.
