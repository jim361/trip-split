# Trip Split

일정·장소·지도와 여행 지출 정산을 하나의 여행 세션에서 다루는 모바일 우선 React/Firebase PWA입니다.

현재 기반 단계는 Firebase 없이도 고정 ID 강릉 fixture와 mock repository로 세 개의 주요 화면을 열 수 있으며, 같은 repository 계약을 Firestore 구현으로 교체할 수 있습니다.

팀 검토용 반응형 목업은 [GitHub Pages](https://jim361.github.io/trip-split/)에서 설치 없이 확인할 수 있습니다. 공개 목업은 항상 mock repository를 사용하며 실제 Firebase 프로젝트에는 연결하지 않습니다.

## 빠른 시작

권장 로컬 런타임은 Firebase Functions와 같은 Node.js 22입니다.

```bash
npm install
npm run dev
```

기본값은 `VITE_DATA_SOURCE=mock`입니다. 별도 환경변수 없이 다음 데모를 열 수 있습니다.

- `/trips/gangneung/itinerary`
- `/trips/gangneung/settlement`
- `/trips/gangneung/receipts`

`/trips/gangneung/map`은 기존 링크 호환을 위해 확대된 통합 일정 화면으로 redirect합니다. 일정 화면의 `지도 크게 보기` 상태는 `?map=expanded` URL로 공유할 수 있습니다.

390px 미만 모바일에서는 `일정·지도 / 정산 / 영수증` 세 메뉴가 하단 내비게이션으로, 1024px 이상에서는 같은 순서의 좌측 확장 내비게이션으로 표시됩니다.

## 검증 명령

```bash
npm run typecheck
npm run lint
npm test
npm run build
npm run build:pages
npm run preview:pages
npm run test:emulator
```

`test:emulator`는 안전한 `demo-trip-split` 프로젝트 ID로 Auth, Firestore, Functions Emulator를 실행합니다. 실제 Firebase 프로젝트나 과금 가능한 외부 API에는 접근하지 않습니다.

## Firebase 모드

`.env.example`을 `.env.local`로 복사한 뒤 다음 값을 설정합니다.

```dotenv
VITE_DATA_SOURCE=firebase
VITE_USE_FIREBASE_EMULATORS=true
VITE_FIREBASE_PROJECT_ID=demo-trip-split
VITE_FIREBASE_API_KEY=demo-api-key
VITE_FIREBASE_AUTH_DOMAIN=localhost
VITE_FIREBASE_FUNCTIONS_REGION=asia-northeast3
```

다른 터미널에서 Emulator를 실행한 뒤 앱을 시작합니다.

```bash
npx firebase emulators:start --project demo-trip-split --only auth,firestore,functions,hosting
npm run dev
```

실제 프로젝트를 연결할 때는 Firebase Console에서 Web App, Anonymous Auth, 선택적 Google Provider, Firestore, Functions와 Hosting을 별도로 활성화해야 합니다. GitHub Pages 목업과 별개로 Firebase 프로젝트 생성·배포·secret 등록은 수행하지 않았습니다.

Functions 일반 환경변수와 secret 구조는 `functions/.env.example`에 있습니다. CLOVA secret은 향후 OCR 담당자가 다음 방식으로만 등록합니다.

```bash
firebase functions:secrets:set CLOVA_OCR_SECRET
```

## 구현 경계

- UI는 Firebase SDK를 직접 호출하지 않습니다.
- `PlatformServicesProvider`가 mock 또는 Firebase 구현을 선택해 주입합니다.
- `AuthProvider`가 익명 세션을 자동 시작하고 선택적 Google 계정 연결을 제공합니다.
- `TripProvider`가 URL의 `tripId`로 여행·멤버·참여자·장소·일정·지출을 구독합니다.
- `createTrip`, `createShareCode`, `joinTrip`은 인증된 HTTPS Callable Function입니다.
- 최초 공유 코드는 무기한·무제한이며, 재생성하면 기존 활성 코드를 모두 비활성화합니다.
- 모든 MVP 여행 멤버는 `editor`입니다.
- PWA service worker는 정적 앱 셸만 precache합니다. Firestore 쓰기와 외부 API 호출은 온라인 전용입니다.

정산 계산 엔진, CLOVA OCR 구현, NAVER 장소 검색·지도 SDK, `.trip.json` 백업/복원은 이 기반 작업에 포함하지 않았습니다. 각 담당자가 이미 준비된 타입·repository·provider/callable 경계를 사용해 독립적으로 구현할 수 있습니다.

화면 검토는 [일정·지도 통합 목업 리뷰](docs/mockup-review.md), 자세한 경로와 인계 사항은 [플랫폼 인계 문서](docs/platform-handoff.md)를 참고하세요.
