# Trip Split Frontend

> **[코드 안내 · 프론트엔드]** 화면과 기능별 코드 진입점을 안내합니다.

현재 이 폴더에는 Flutter·Dart Android 앱 기반과 React·Vite 팀 공유 목업이 임시 공존합니다. Flutter가 기본 제품이며, 각 세로 기능이 동등한 흐름을 제공하기 전에는 기존 React 목업을 삭제하지 않습니다.

## Flutter Android 실행

```bash
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Flutter 3.47.2, Dart 3.13.2, Android API 24 이상을 기준으로 합니다. Flutter Web은 후속 보조 타깃이며 Android 완료 게이트가 아닙니다.

기본값은 Firebase가 필요 없는 mock입니다. 호스트에서 Firebase Emulator를 실행한 뒤 Android Emulator로 FlutterFire 흐름을 확인할 때는 다음 예시 설정을 사용합니다.

```bash
flutter run --dart-define-from-file=dart_defines.example.json
```

실제 프로젝트 값은 Git에 올리지 않는 `dart_defines.local.json`에 두고 같은 옵션으로 실행합니다. demo 프로젝트 값으로 Emulator 없이 시작하면 앱이 이를 거부합니다.

## React Pages 목업 실행

저장소 루트에서 한 번 `npm install`한 뒤 다음 중 하나를 사용합니다.

```bash
# 저장소 루트
npm run dev:frontend

# frontend 폴더
cd frontend
npm run dev
```

검증은 `npm run typecheck`, `npm test`, `npm run build`로 실행합니다. 실제 Firebase 연결값은 `.env.example`을 `.env.local`로 복사해 설정하며 기본 데이터 소스는 mock입니다.

## 현재 코드 경계

- `lib/app`: 인증 게이트, router, `TripShell`과 repository 기반 `TripSession`
- `lib/domain`: canonical 모델, `AppError`와 repository interface
- `lib/data/mock`, `lib/data/firebase`: 고정 도쿄 fixture와 같은 계약의 in-memory/Firestore repository
- `lib/services`: 익명·Google 연결 Auth와 여행 공유 Callable의 mock/FlutterFire 구현
- `lib/features`: 여행 생성·입장과 일정·지도, 준비, 비용, 영수증 Widget
- `android`: `com.jim361.tripsplit`, minSdk 24, targetSdk 36
- `test`: route/widget와 mock repository 테스트

전환 전 React 목업은 다음 경계에 남아 있습니다.

- `src/app`, `src/pages`: 앱 셸, 라우트와 화면
- `src/features`: 일정·지도, 준비, 정산·영수증 기능
- `src/services`: mock 및 Firebase Web SDK repository/service
- `src/shared`: 공통 타입, 오류, ID와 UI
- `public`: PWA manifest와 정적 자산

## 기능별 코드 찾기

| 기능                            | 주요 진입점                                                           |
| ------------------------------- | --------------------------------------------------------------------- |
| `TASK-01 · 플랫폼`              | `lib/app`, `lib/domain`, `lib/data/mock`, `lib/platform`              |
| `TASK-02 · 인증·여행·공유`      | `lib/app/auth_session_gate.dart`, `lib/services`, `lib/data/firebase` |
| `TASK-04 / TASK-05 · 일정·지도` | `lib/features/itinerary`, `lib/features/map`                          |
| `TASK-06 · 정산`                | `lib/features/settlement`                                             |
| `TASK-07 · 영수증 OCR`          | `lib/features/receipts`                                               |
| `전환 전 React/PWA 목업`        | `src`, `vite.config.ts`, `public`                                     |

화면 컴포넌트에서 Firebase SDK나 외부 지도 SDK를 직접 호출하지 않고 service, repository 또는 adapter를 사용합니다.

## 남은 Flutter 경계

- Android Emulator에서 Flutter 클라이언트→로컬 Emulator 전체 수직 조각 확인
- `android`: Maps 설정과 Android 전용 capability
- `web`: 후속 Flutter Web 진입점

Flutter Widget과 controller도 Firebase, Google Maps와 OCR SDK를 직접 호출하지 않습니다.
