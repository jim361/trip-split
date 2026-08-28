# Trip Split

> **[안내 00 · 프로젝트 시작]** 저장소 구조, 실행 방법, 협업 흐름을 안내합니다.

일정·장소·지도·준비와 여행 지출 정산을 하나의 여행 세션에서 다루는 Flutter/Firebase Android 앱입니다. 첫 실사용 기준은 2026년 11월 도쿄 여행이며 Google Maps와 JPY를 우선합니다.

2026-08-28 `frontend/`에 Flutter 3.47.2 Android scaffold, 도쿄 fixture, mock repository와 세 탭 앱 셸을 추가했습니다. 기존 React/Vite 목업은 팀 공유 Pages가 끊기지 않도록 `src/`·`public/`에 임시 보존하며 [Flutter Android 전환 계획](docs/flutter-android-migration.md)의 세로 기능 조각이 대체할 때 정리합니다.

팀 검토용 [GitHub Pages React 목업](https://jim361.github.io/trip-split/)은 UI 참고 자료로 계속 볼 수 있습니다. 현재 Flutter 앱이나 Android 배포본은 아니며 실제 Firebase 프로젝트에는 연결하지 않습니다.

기능을 빼거나 추가하는 팀 회의에서는 [기능 논의 홈](docs/README.md)에서 `일정·지도`와 `정산·영수증` 문서를 탭처럼 이동하며 기능 ID와 결정 상태를 기록할 수 있습니다.

## 문서·기능 번호

번호는 우선순위가 아니라 팀원이 같은 문서와 기능을 가리키기 위한 고정 ID입니다. 파일명과 코드 경로는 바꾸지 않으며, 사용을 중단한 번호도 다른 기능에 재사용하지 않습니다.

### 문서 찾기

| 구분      | 시작 문서                                                           | 용도                                                |
| --------- | ------------------------------------------------------------------- | --------------------------------------------------- |
| 계약      | [계약 01 · 제품 정의](MarkDown/product.md)                          | 합의된 제품·요구사항·기술·구조·디자인 기준          |
| 작업      | [작업 00 · 작업 인덱스](MarkDown/task/tasks.md)                     | `TASK-01`~`TASK-09` 구현 순서와 담당                |
| 회의      | [회의 00 · 기능 범위 회의](docs/README.md)                          | 기능 후보를 추가·제외하기 위한 논의 자료            |
| 검토      | [검토 01 · 해외여행 목업](docs/mockup-review.md)                    | 반응형 목업 확인과 리뷰 질문                        |
| 인계      | [인계 01 · 플랫폼·통합 현황](docs/platform-handoff.md)              | 구현된 공통 계약과 담당자 연결점                    |
| 전환      | [회의 04 · Flutter Android 전환](docs/flutter-android-migration.md) | 현재 React 목업에서 Android 앱으로 옮기는 경계      |
| 이력·참고 | [이력 01 · 제품 결정 이력](MarkDown/decision_history.md)            | 결정 이유와 보조 자료, 현재 계약의 대체 문서가 아님 |

### 기능 찾기

| 기능 ID   | 한글 이름                 | 주요 코드 위치                                                     |
| --------- | ------------------------- | ------------------------------------------------------------------ |
| `TASK-01` | 프로젝트 기반·공통 플랫폼 | 목표: `frontend/lib/app`, `frontend/lib/data`, 루트 설정           |
| `TASK-02` | 인증·여행 생성·공유       | 목표: Flutter `TripSession`, Functions client, `backend/src/share` |
| `TASK-03` | 장소 보관함·검색          | 목표: `frontend/lib/features/places`, place repository             |
| `TASK-04` | 일정·준비                 | 목표: `frontend/lib/features/itinerary`, `preparation`             |
| `TASK-05` | 지도                      | 목표: `frontend/lib/features/map`                                  |
| `TASK-06` | 정산                      | 목표: `frontend/lib/features/settlement`, expense repository       |
| `TASK-07` | 영수증 OCR·번역           | 목표: `frontend/lib/features/receipts`, `backend/src/ocr`          |
| `TASK-08` | 백업·내보내기             | 데이터 모델 확정 후 구현 예정                                      |
| `TASK-09` | 마감·출시                 | Android 접근성·권한·APK, CI와 승인된 내부 배포                     |

회의 기능 ID는 영역에 따라 `BASE`(공통), `IT`(일정·지도), `PREP`(준비), `ST`(정산), `OCR`(영수증 인식)을 사용합니다.

## 저장소 구성

| 경로                             | 역할                                                              | 독립 실행                                    |
| -------------------------------- | ----------------------------------------------------------------- | -------------------------------------------- |
| [`frontend`](frontend/README.md) | Flutter Android 앱·mock repository와 임시 React Pages 목업        | `flutter run`, 목업은 `npm run dev:frontend` |
| [`backend`](backend/README.md)   | 유지하는 Firebase Functions, Firestore 규칙, Emulator 통합 테스트 | `npm run dev:backend`                        |
| `docs`                           | 기능 회의, 구현 인계와 팀 검토용 목업                             | 문서                                         |
| `MarkDown`                       | 합의된 제품·요구사항·기술 계약과 기능별 task                      | 문서                                         |
| `.github`                        | Flutter Android, npm·Emulator CI와 React 목업 Pages               | GitHub Actions                               |
| 루트 `package.json`              | 임시 React Pages와 backend 명령 위임                              | React 목업 제거 시 단순화                    |

## Git 운영

- `main`: 배포·발표 가능한 안정 버전만 유지합니다.
- `dev`: 모든 개발 변경을 직접 커밋·푸시하고 GitHub Pages로 팀에 공유합니다.
- 작업 전 최신 `origin/dev`를 동기화하고, 담당 범위의 검증을 로컬에서 통과시킨 뒤 작은 커밋으로 푸시합니다.
- 별도 기능 브랜치와 `dev` 대상 Pull Request는 만들지 않습니다.
- 출시 시점에는 검증된 `dev`에서 `main`으로 릴리스 Pull Request를 만듭니다.

`frontend`와 `backend`는 별도 장기 브랜치가 아니라 같은 `dev`와 `main` 트리의 폴더입니다. 두 영역의 공통 타입, Firestore 경로 또는 Callable 계약을 바꾸면 한 커밋에서 양쪽 영향과 테스트를 함께 확인합니다.

`dev` push와 `main` 대상 릴리스 Pull Request에서는 CI의 format, typecheck, lint, test, build, Firebase Emulator와 Flutter Android 검증을 실행합니다. Codex를 포함한 작업자는 루트 [AGENTS.md](AGENTS.md)의 경계와 검증 명령을 따릅니다.

## 빠른 시작

필수 로컬 런타임은 Node.js 22입니다. 전체 검증과 Firebase Emulator에는 Java 21, Flutter 변경에는 Flutter 3.47.2가 필요합니다.

Android SDK가 준비된 환경에서는 Flutter 앱을 기본으로 실행합니다.

```bash
cd frontend
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

팀 공유용 React 목업 확인에는 Node.js 22를 사용합니다.

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

390px 모바일에서는 `일정·지도 / 준비 / 비용` 세 메뉴가 하단 내비게이션으로 표시됩니다. Flutter는 720px 이상에서 같은 순서의 좌측 내비게이션을 사용합니다. 기존 강릉 React 경로와 Flutter의 `/map`, `/receipts` 호환 경로는 회귀 검토와 담당자 연결을 위해 유지합니다.

위 URL은 React Pages 목업과 Flutter route가 공유하는 정보 구조입니다. Flutter의 `/map` 호환 route는 확대된 일정·지도 상태로 정규화됩니다.

## 검증 명령

```bash
npm run verify:fast
npm run verify:full
npm run format:check
npm run typecheck
npm run lint
npm test
npm run build
npm run build:pages
npm run preview:pages
```

`verify:fast`는 임시 React 목업과 backend npm workspace의 format, lint, typecheck와 test를 실행합니다. `verify:full`은 여기에 production build와 안전한 `demo-trip-split` 프로젝트의 Auth, Firestore, Functions Emulator 테스트를 추가합니다. Flutter는 위의 Flutter 명령과 별도 CI job으로 검증하며, 실제 Firebase 프로젝트나 과금 가능한 외부 API에는 접근하지 않습니다.

## Firebase 모드

Flutter 앱의 기본값은 mock입니다. 로컬 Auth·Firestore·Functions Emulator와 연결할 때는 backend Emulator를 먼저 실행하고 Android Emulator에서 `10.0.2.2`를 사용합니다.

```bash
npm run dev:backend
cd frontend
flutter run --dart-define-from-file=dart_defines.example.json
```

실제 Firebase 프로젝트 값은 `frontend/dart_defines.local.json`에 두며 Git에 저장하지 않습니다. Console 프로젝트 생성, Auth provider 활성화와 배포는 별도 승인 후 수행합니다.

### 전환 전 React 목업

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

이 절은 현재 React 목업의 환경변수입니다. 실제 Firebase 프로젝트 생성·배포·secret 등록은 수행하지 않았습니다.

Functions 일반 환경변수와 secret 구조는 `backend/.env.example`에 있습니다. OCR·번역 provider가 benchmark 뒤 확정되면 provider별 secret 이름을 추가하며 실제 secret은 repository에 저장하지 않습니다.

## 구현 경계

- Flutter Widget은 Firebase나 외부 API SDK를 직접 호출하지 않습니다.
- 전환 후 앱 조립 계층이 mock 또는 FlutterFire 구현을 선택해 주입합니다.
- Auth controller가 익명 세션을 자동 시작하고 Android Google credential의 선택 연결을 제공합니다.
- `TripSession`이 route의 `tripId`로 여행·멤버·참여자·장소·일정·지출 Stream을 결합합니다. 준비 데이터 repository는 후속입니다.
- `createTrip`, `createShareCode`, `joinTrip`은 인증된 HTTPS Callable Function입니다. `createTrip`은 입력한 초기 정산 인원만큼 `Participant`를 함께 생성합니다.
- 최초 공유 코드는 무기한·무제한이며, 재생성하면 기존 활성 코드를 모두 비활성화합니다.
- 모든 MVP 여행 멤버는 `editor`입니다.
- Android Firestore 캐시와 pending write 상태를 구분합니다. Google 장소·OCR 호출은 온라인 전용입니다.

현재 Flutter 기반에는 FlutterFire 인증·실시간 repository와 여행 생성·공유·입장 경계가 있습니다. expense는 완성된 runtime validator와 서버 저장 경계가 생길 때까지 Firestore Rules에서 직접 쓰기를 막습니다. 아직 없는 범위는 완성된 정산 엔진, Participant 계정 연결 Callable, OCR·번역 provider, 실제 Google Maps SDK, Flutter 클라이언트의 Android Emulator 수직 통합 테스트와 Android `.trip.json` 처리입니다. 도쿄 mock은 API 키와 과금 없이 정보 구조와 개발 경계를 검토하는 자료입니다.

화면 검토는 [일정·지도 통합 목업 리뷰](docs/mockup-review.md), 자세한 경로와 인계 사항은 [플랫폼 인계 문서](docs/platform-handoff.md)를 참고하세요.
