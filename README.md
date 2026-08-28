# Trip Split

일정·장소·지도와 여행 지출 정산을 하나의 여행 세션에서 다루는 모바일 우선 React/Firebase PWA입니다.

현재 기반 단계는 Firebase 없이도 고정 ID 강릉·도쿄 fixture와 mock repository로 세 개의 주요 화면을 열 수 있으며, 같은 repository 계약을 Firestore 구현으로 교체할 수 있습니다.

팀 검토용 반응형 목업은 [GitHub Pages](https://jim361.github.io/trip-split/)에서 설치 없이 확인할 수 있습니다. 공개 목업은 항상 mock repository를 사용하며 실제 Firebase 프로젝트에는 연결하지 않습니다.

기능을 빼거나 추가하는 팀 회의에서는 [기능 논의 홈](docs/README.md)에서 `일정·지도`와 `정산·영수증` 문서를 탭처럼 이동하며 기능 ID와 결정 상태를 기록할 수 있습니다.

## 저장소 구성

| 경로                             | 역할                                                              | 독립 실행              |
| -------------------------------- | ----------------------------------------------------------------- | ---------------------- |
| [`frontend`](frontend/README.md) | React/Vite/PWA, 화면, mock·Firestore Web repository, 지도 adapter | `npm run dev:frontend` |
| [`backend`](backend/README.md)   | Firebase Functions, Firestore 규칙, Emulator 통합 테스트          | `npm run dev:backend`  |
| `docs`                           | 기능 회의, 구현 인계와 팀 검토용 목업                             | 문서                   |
| `MarkDown`                       | 합의된 제품·요구사항·기술 계약과 기능별 task                      | 문서                   |
| `.github`                        | dev/main CI와 GitHub Pages 배포                                   | GitHub Actions         |
| 루트 `package.json`              | 두 npm workspace의 공통 설치·검증 명령                            | `npm install`          |

## Git 운영

- `main`: 배포·발표 가능한 안정 버전만 유지합니다.
- `dev`: 기능을 모아 통합 검증하고 GitHub Pages로 팀에 공유합니다.
- 작업 브랜치: 최신 `dev`에서 분기하고 Pull Request로 다시 `dev`에 합칩니다.
- 출시 시점에는 `dev`에서 `main`으로 Pull Request를 만듭니다.

`run-trip`과 같은 scope 방식으로 `frontend/itinerary-map`, `frontend/settlement-ui`, `backend/receipt-ocr`, `platform/firebase`, `docs/feature-scope`처럼 담당 영역을 브랜치 이름에 드러냅니다. `frontend`와 `backend`라는 장기 브랜치를 따로 만들지는 않습니다. 두 폴더는 항상 같은 `dev`와 `main` 트리 안에 있고, `dev → main` 승격으로 동일한 구조를 유지합니다.

`dev`와 `main` 대상 Pull Request는 CI의 format, typecheck, lint, test, build, Firebase Emulator 검증을 통과해야 합니다. Codex를 포함한 작업자는 루트 [AGENTS.md](AGENTS.md)의 경계와 검증 명령을 따릅니다.

## 빠른 시작

필수 로컬 런타임은 Node.js 22입니다. 전체 검증과 Firebase Emulator에는 Java 21도 필요합니다.

```bash
npm install
npm run dev:frontend
```

기본값은 `VITE_DATA_SOURCE=mock`입니다. 별도 환경변수 없이 다음 데모를 열 수 있습니다.

- `/trips/tokyo-2026-11/itinerary`
- `/trips/tokyo-2026-11/preparation`
- `/trips/tokyo-2026-11/settlement`
- `/trips/tokyo-2026-11/receipts` (OCR 담당자용 호환 경로)

`/trips/gangneung/map`은 기존 링크 호환을 위해 확대된 통합 일정 화면으로 redirect합니다. 일정 화면의 `지도 크게 보기` 상태는 `?map=expanded` URL로 공유할 수 있습니다.

390px 모바일에서는 `일정·지도 / 준비 / 비용` 세 메뉴가 하단 내비게이션으로, 1024px 이상에서는 같은 순서의 좌측 확장 내비게이션으로 표시됩니다. 기존 강릉 경로와 `/map`, `/receipts`는 회귀 검토와 담당자 연결을 위해 유지합니다.

## 검증 명령

```bash
npm run verify:fast
npm run verify:full
npm run build:pages
npm run preview:pages
```

`verify:fast`는 format, lint, 두 workspace의 typecheck와 test를 실행합니다. `verify:full`은 여기에 production build와 안전한 `demo-trip-split` 프로젝트의 Auth, Firestore, Functions Emulator 테스트를 추가합니다. 실제 Firebase 프로젝트나 과금 가능한 외부 API에는 접근하지 않습니다.

## Firebase 모드

`frontend/.env.example`을 `frontend/.env.local`로 복사한 뒤 다음 값을 설정합니다.

```dotenv
VITE_DATA_SOURCE=firebase
VITE_USE_FIREBASE_EMULATORS=true
VITE_FIREBASE_PROJECT_ID=demo-trip-split
VITE_FIREBASE_API_KEY=demo-api-key
VITE_FIREBASE_AUTH_DOMAIN=localhost
VITE_FIREBASE_FUNCTIONS_REGION=asia-northeast3
```

다른 터미널에서 backend Emulator를 실행한 뒤 frontend를 시작합니다.

```bash
npm run dev:backend
npm run dev:frontend
```

실제 프로젝트를 연결할 때는 Firebase Console에서 Web App, Anonymous Auth, 선택적 Google Provider, Firestore, Functions와 Hosting을 별도로 활성화해야 합니다. GitHub Pages 목업과 별개로 Firebase 프로젝트 생성·배포·secret 등록은 수행하지 않았습니다.

Functions 일반 환경변수와 secret 구조는 `backend/.env.example`에 있습니다. CLOVA secret은 향후 OCR 담당자가 다음 방식으로만 등록합니다.

```bash
firebase functions:secrets:set CLOVA_OCR_SECRET
```

## 구현 경계

- UI는 Firebase SDK를 직접 호출하지 않습니다.
- `PlatformServicesProvider`가 mock 또는 Firebase 구현을 선택해 주입합니다.
- `AuthProvider`가 익명 세션을 자동 시작하고 선택적 Google 계정 연결을 제공합니다.
- `TripProvider`가 URL의 `tripId`로 여행·멤버·참여자·장소·일정·지출을 구독합니다.
- `createTrip`, `createShareCode`, `joinTrip`은 인증된 HTTPS Callable Function입니다. `createTrip`은 입력한 초기 정산 인원만큼 `Participant`를 함께 생성합니다.
- 최초 공유 코드는 무기한·무제한이며, 재생성하면 기존 활성 코드를 모두 비활성화합니다.
- 모든 MVP 여행 멤버는 `editor`입니다.
- PWA service worker는 정적 앱 셸만 precache합니다. Firestore 쓰기와 외부 API 호출은 온라인 전용입니다.

정산 계산 엔진, CLOVA OCR 구현, 실제 Google Maps SDK, `.trip.json` 백업/복원은 이 기반 작업에 포함하지 않았습니다. 도쿄 목업은 Google Maps URL로 실제 장소·대중교통 길찾기를 열고, 앱 내부 지도는 API 키와 과금 없이 검토할 수 있는 mock입니다.

화면 검토는 [일정·지도 통합 목업 리뷰](docs/mockup-review.md), 자세한 경로와 인계 사항은 [플랫폼 인계 문서](docs/platform-handoff.md)를 참고하세요.
