# 플랫폼·통합 기반 인계

## 공통 계약

- 도메인 타입: `src/shared/types/domain.ts`
- ID, epoch timestamp, `AppError`, 구독 타입: `src/shared/contracts/`
- repository 인터페이스: `src/services/repositories/tripRepositories.ts`
- 고정 ID 강릉 fixture: `src/test/fixtures/gangneungTrip.ts`
- in-memory mock: `src/services/mock/inMemoryTripRepositories.ts`
- Firestore 구현: `src/services/firebase/firestoreRepositories.ts`

`TripMember.uid`는 인증·공동 편집 주체이고 `Participant.id`는 정산 주체입니다. 두 값은 같다고 가정하지 않으며 `Participant.linkedUid`로만 선택 연결합니다.

## 주입과 세션

`src/app/providers/PlatformServicesProvider.tsx`가 `VITE_DATA_SOURCE`에 따라 같은 `TripRepositories` 인터페이스의 구현을 선택합니다.

- `mock` 기본값: 강릉 fixture와 `MockAuthService`
- `firebase`: Firebase Auth, Firestore repository와 Callable service

`AuthProvider`는 앱 진입 시 Anonymous Auth를 자동 시작합니다. `FirebaseAuthService.linkGoogleAccount()`는 현재 익명 사용자에 `linkWithPopup`을 적용해 uid와 여행 접근 권한을 유지합니다.

`TripProvider`는 URL의 `tripId`를 받아 다음 데이터를 구독합니다.

- trip
- members
- participants
- places
- itinerary
- expenses

각 화면은 `useTripContext()`로 mock 또는 Firestore 데이터를 동일하게 읽습니다.

## 도메인 담당 연결점

### 정산·영수증

- `repositories.participants`
- `repositories.expenses`
- canonical `Expense`, `ReceiptItem`, `ParsedReceipt`
- `src/services/functions/receiptParser.ts`의 `ReceiptParser`와 `CallableReceiptParser`

플랫폼은 배분·정산 계산을 구현하지 않았습니다. 정산 담당은 fixture 원장을 입력으로 받는 순수 엔진을 추가하고 페이지 placeholder를 교체하면 됩니다. `parseReceipt` 서버 handler는 아직 export되지 않으며 callable 클라이언트 경계만 고정돼 있습니다.

### 장소·일정·지도

- `repositories.places`
- `repositories.itinerary`
- `src/features/places/placeProvider.ts`의 `PlaceProvider`
- `src/features/map/mapAdapter.ts`의 provider-neutral `MapAdapter`와 `createMapRenderModel`
- `src/features/map/PlannerMapPreview.tsx`의 일정 상단 지도 미리보기와 확대 상태

실제 NAVER 응답은 `PlaceCandidate`로 정규화한 뒤 repository에 저장해야 합니다. 지도 SDK에는 `Place[]`와 정렬된 `ItineraryItem[]`만 전달합니다.

일정과 지도는 `/trips/:tripId/itinerary` 한 화면에서 지도 미리보기 → 일정 순서로 표시합니다. `?map=expanded`는 확대 상태를 공유하는 canonical query이며, 기존 `/trips/:tripId/map`은 이 URL로 redirect합니다. 실제 지도 adapter를 연결할 때 컨테이너 크기 전환 뒤 지도 SDK의 resize/recenter를 호출해야 합니다.

## Callable Functions

`functions/src/share/trips.ts`에서 다음 세 함수를 export합니다.

- `createTrip`: trip, 생성자 member, 첫 share code와 user profile을 transaction으로 생성
- `createShareCode`: 멤버 확인 후 기존 활성 코드를 비활성화하고 새 코드와 `Trip.shareCode`를 transaction으로 갱신
- `joinTrip`: 코드를 검증하고 현재 auth uid를 editor member로 등록

MVP 생성 코드에는 `expiresAt`과 `maxUses`를 기록하지 않습니다. 손상됐거나 타입이 잘못된 제한 필드가 존재하면 join은 fail-closed로 거부합니다.

## 보안 규칙

`firestore.rules`는 다음을 검증합니다.

- 인증 사용자 자기 `users/{uid}`만 접근
- `shareCodes` 클라이언트 직접 접근 금지
- `trips/{tripId}/members/{uid}` 존재 여부 기반 여행 접근
- trip 불변 필드와 update allowlist
- member role·joinedAt 불변 및 자기 프로필 필드만 수정
- participants, places, itinerary, expenses의 canonical top-level 필드와 타입
- 생성·수정자 uid, `serverTimestamp`, created 감사 필드 불변

`npm run test:emulator`가 익명 사용자 두 명의 생성·참여, 코드 정책, 비멤버·무인증 거부와 보안 규칙을 검증합니다.

## PWA와 온라인 경계

- manifest: `public/manifest.webmanifest`
- 임시 SVG 아이콘: `public/icons/`
- service worker: `vite-plugin-pwa`의 `generateSW`
- 캐시: 빌드된 HTML, JS, CSS, SVG, webmanifest 정적 자산

Firestore 편집, Callable, NAVER와 OCR 요청은 오프라인 저장 완료로 표시하면 안 됩니다. 후속 UI는 `unavailable`인 `AppError`에 재시도 action을 제공해야 합니다.

## 아직 연결하지 않은 것

- 실제 Firebase 프로젝트와 배포
- Firebase Console의 Auth Provider 활성화
- NAVER Maps/Places/링크 파싱 Functions
- CLOVA OCR `parseReceipt` Function과 secret
- 정산·항목 배분 엔진
- `.trip.json` 내보내기/가져오기
- 실제 PNG 설치 아이콘과 최종 시각 디자인

Functions 배포 런타임은 Node 22로 지정했습니다. 로컬 Firebase CLI도 Node 22 사용을 권장합니다.

현재 `npm audit --omit=dev`는 `firebase-admin@13`이 사용하는 Google SDK의 `uuid@9` 경로에서 moderate 8건을 보고합니다. 자동 수정은 `firebase-admin@14`로 올리지만, 설치된 `firebase-functions@7.2.5`의 공식 peer 범위는 아직 `firebase-admin@13`까지입니다. 강제 업그레이드나 transitive override는 적용하지 않았으며, Functions가 Admin 14를 공식 지원하면 함께 올리고 Emulator 회귀 테스트를 다시 실행해야 합니다.
