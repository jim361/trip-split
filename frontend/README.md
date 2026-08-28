# Trip Split Frontend

> **[코드 안내 · 프론트엔드]** 화면과 기능별 코드 진입점을 안내합니다.

현재 이 폴더는 React·Vite·TypeScript로 만든 전환 전 목업입니다. 2026-08-28 결정에 따라 같은 `frontend/`를 Flutter·Dart Android 앱으로 교체합니다. 각 Flutter 기능이 동등한 mock 흐름을 제공하기 전에는 기존 목업을 삭제하지 않습니다.

## 현재 React 목업 실행

저장소 루트에서 한 번 `npm install`한 뒤 다음 중 하나를 사용합니다.

```bash
# 저장소 루트
npm run dev:frontend

# frontend 폴더
cd frontend
npm run dev
```

검증은 `npm run typecheck`, `npm test`, `npm run build`로 실행합니다. 실제 Firebase 연결값은 `.env.example`을 `.env.local`로 복사해 설정하며 기본 데이터 소스는 mock입니다.

## Flutter 전환 후 실행

`TASK-01`이 Flutter scaffold를 추가한 뒤 이 절이 기본 실행법이 됩니다.

```bash
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

첫 실행 대상은 Android API 24 이상입니다. Flutter Web은 후속 보조 타깃이며 Android 완료 게이트가 아닙니다.

## 현재 목업 경계

- `src/app`, `src/pages`: 앱 셸, 라우트와 화면
- `src/features`: 일정·지도, 준비, 정산·영수증 기능
- `src/services`: mock 및 Firebase Web SDK repository/service
- `src/shared`: 공통 타입, 오류, ID와 UI
- `public`: PWA manifest와 정적 자산

## 기능별 코드 찾기

| 기능                            | 주요 진입점                                                                              |
| ------------------------------- | ---------------------------------------------------------------------------------------- |
| `TASK-01 · 플랫폼`              | `src/app`, `src/services/firebase`, `src/shared`                                         |
| `TASK-02 · 인증·여행·공유`      | `src/app/providers`, `src/services/auth`, `src/services/functions/tripSessionService.ts` |
| `TASK-03 · 장소`                | `src/features/places`, repository의 `places`                                             |
| `TASK-04 / TASK-05 · 일정·지도` | `src/pages/trip/ItineraryPage.tsx`, `src/features/map`                                   |
| `TASK-06 · 정산`                | `src/pages/trip/SettlementPage.tsx`, repository의 `expenses`                             |
| `TASK-07 · 영수증 OCR`          | `src/pages/trip/ReceiptsPage.tsx`, `src/services/functions/receiptParser.ts`             |
| `전환 전 PWA 목업`              | `vite.config.ts`, `public`, `src/shared/styles`                                          |

화면 컴포넌트에서 Firebase SDK나 외부 지도 SDK를 직접 호출하지 않고 service, repository 또는 adapter를 사용합니다.

## 목표 Flutter 경계

- `lib/app`: router, `TripShell`, Auth와 `TripSession` 조립
- `lib/domain`: immutable Dart 모델, 오류와 repository interface
- `lib/data`: mock·FlutterFire repository와 mapper
- `lib/features`: 일정·지도, 준비, 비용과 영수증 검토 Widget
- `test`, `integration_test`: 순수 Dart, Widget와 Android Emulator 검증
- `android`: package, Maps 설정과 Android 전용 capability
- `web`: 후속 Flutter Web 진입점

Flutter Widget과 controller도 Firebase, Google Maps와 OCR SDK를 직접 호출하지 않습니다.
