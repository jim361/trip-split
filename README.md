# Trip Split

> **[안내 00 · 프로젝트 시작]** 저장소 구조, 실행 방법, 협업 흐름을 안내합니다.

일정·장소·지도·준비와 여행 지출 정산을 하나의 여행 세션에서 다루는 Flutter/Firebase Android 앱입니다. 첫 실사용 기준은 2026년 11월 도쿄 여행이며 Google Maps와 JPY를 우선합니다.

2026-08-28 현재 저장소의 `frontend/`는 전환 전 React/Vite 목업입니다. Flutter scaffold와 앱 코드는 아직 생성하지 않았으며 [Flutter Android 전환 계획](docs/flutter-android-migration.md)의 순서로 옮깁니다. 기존 목업과 다른 작업자의 변경은 각 Flutter 세로 기능 조각이 대체될 때까지 보존합니다.

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

| 경로                             | 역할                                                                 | 독립 실행                                             |
| -------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------- |
| [`frontend`](frontend/README.md) | 현재 React 목업, 목표 Flutter Android 앱·mock/FlutterFire repository | 전환 전 `npm run dev:frontend`, 전환 후 `flutter run` |
| [`backend`](backend/README.md)   | 유지하는 Firebase Functions, Firestore 규칙, Emulator 통합 테스트    | `npm run dev:backend`                                 |
| `docs`                           | 기능 회의, 구현 인계와 팀 검토용 목업                                | 문서                                                  |
| `MarkDown`                       | 합의된 제품·요구사항·기술 계약과 기능별 task                         | 문서                                                  |
| `.github`                        | 현재 npm CI·목업 Pages, 전환 후 Flutter/backend 분리 CI              | GitHub Actions                                        |
| 루트 `package.json`              | 전환 전 npm workspace와 backend 명령 위임                            | 전환 PR에서 단순화                                    |

## Git 운영

- `main`: 배포·발표 가능한 안정 버전만 유지합니다.
- `dev`: 기능을 모아 통합 검증하고 GitHub Pages로 팀에 공유합니다.
- 작업 브랜치: 최신 `dev`에서 분기하고 Pull Request로 다시 `dev`에 합칩니다.
- 출시 시점에는 `dev`에서 `main`으로 Pull Request를 만듭니다.

`run-trip`과 같은 scope 방식으로 `frontend/itinerary-map`, `frontend/settlement-ui`, `backend/receipt-ocr`, `platform/firebase`, `docs/feature-scope`처럼 담당 영역을 브랜치 이름에 드러냅니다. `frontend`와 `backend`라는 장기 브랜치를 따로 만들지는 않습니다. 두 폴더는 항상 같은 `dev`와 `main` 트리 안에 있고, `dev → main` 승격으로 동일한 구조를 유지합니다.

`dev`와 `main` 대상 Pull Request는 CI의 format, typecheck, lint, test, build, Firebase Emulator 검증을 통과해야 합니다. Codex를 포함한 작업자는 루트 [AGENTS.md](AGENTS.md)의 경계와 검증 명령을 따릅니다.

## 빠른 시작

Flutter scaffold 전 현재 React 목업 확인에는 Node.js 22를 사용합니다.

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

위 명령과 URL은 모두 전환 전 React 목업용입니다. `TASK-01` 완료 뒤 Android 개발 명령은 다음으로 교체합니다.

```bash
cd frontend
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

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

## Firebase 모드 · 전환 전 React 목업

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

이 절은 현재 React 목업의 환경변수입니다. Flutter 전환 뒤에는 `flutterfire configure`로 Android Firebase App을 생성하고 Auth·Firestore·Functions Emulator를 사용합니다. Android Emulator에서 host 주소는 `10.0.2.2`입니다. 실제 Firebase 프로젝트 생성·배포·secret 등록은 수행하지 않았습니다.

Functions 일반 환경변수와 secret 구조는 `backend/.env.example`에 있습니다. OCR·번역 provider가 benchmark 뒤 확정되면 provider별 secret 이름을 추가하며 실제 secret은 repository에 저장하지 않습니다.

## 구현 경계

- Flutter Widget은 Firebase나 외부 API SDK를 직접 호출하지 않습니다.
- 전환 후 앱 조립 계층이 mock 또는 FlutterFire 구현을 선택해 주입합니다.
- Auth controller가 익명 세션을 자동 시작하고 Android Google credential의 선택 연결을 제공합니다.
- `TripSession`이 route의 `tripId`로 여행·멤버·참여자·장소·일정·준비·지출 Stream을 결합합니다.
- `createTrip`, `createShareCode`, `joinTrip`은 인증된 HTTPS Callable Function입니다. `createTrip`은 입력한 초기 정산 인원만큼 `Participant`를 함께 생성합니다.
- 최초 공유 코드는 무기한·무제한이며, 재생성하면 기존 활성 코드를 모두 비활성화합니다.
- 모든 MVP 여행 멤버는 `editor`입니다.
- Android Firestore 캐시와 pending write 상태를 구분합니다. Google 장소·OCR 호출은 온라인 전용입니다.

현재 React 목업에는 완성된 정산 엔진, OCR·번역 provider, 실제 Google Maps SDK와 Android `.trip.json` 처리가 없습니다. 도쿄 목업은 API 키와 과금 없이 정보 구조만 검토하는 자료입니다.

화면 검토는 [일정·지도 통합 목업 리뷰](docs/mockup-review.md), 자세한 경로와 인계 사항은 [플랫폼 인계 문서](docs/platform-handoff.md)를 참고하세요.
