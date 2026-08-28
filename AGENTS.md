# Trip Split 작업 규칙

## 프로젝트 경계

- `frontend/`: 목표 구조는 Flutter/Dart Android 앱, 화면, mock·FlutterFire repository와 지도 adapter
- `backend/`: Firebase Functions, Firestore 규칙과 Emulator 통합 테스트
- `docs/`: 회의용 기능 범위와 구현 인계
- `MarkDown/`: 합의된 제품·기술 계약과 기능별 task

공통 타입, Firestore 경로, Callable 요청·응답을 바꾸면 frontend와 backend 영향을 함께 확인합니다. 기존 파일이나 다른 작업자의 변경을 삭제하거나 되돌리지 않습니다.

2026-08-28 `frontend/`에는 Flutter Android scaffold와 mock 앱 셸이 추가됐습니다. React/Vite 코드는 GitHub Pages 목업을 유지하기 위해 같은 폴더의 `src/`·`public/`에 임시 보존하며, Flutter의 `lib/`·`android/`와 장기 이중 제품으로 운영하지 않습니다.

- 첫 실행·출시 대상은 Android이며 Flutter Web과 iOS는 후속입니다.
- Widget과 controller에서 Firebase, Google Maps 또는 OCR SDK를 직접 호출하지 않습니다.
- 실제 Firebase 프로젝트, secret, 유료 API, Android signing과 배포는 승인 없이 연결하지 않습니다.

## 문서와 기능 ID

- 작업 ID는 `TASK-01`~`TASK-09`, 회의 기능 ID는 `BASE`, `IT`, `PREP`, `ST`, `OCR` 접두사를 사용합니다.
- ID는 우선순위가 아닌 고정 식별자이며 삭제된 ID를 재번호화하거나 다른 기능에 재사용하지 않습니다.
- 파일·폴더·함수 이름을 번호나 한글 때문에 바꾸지 않고, 문서 표지와 주요 코드 경계의 짧은 한글 주석으로 역할을 표시합니다.
- 단순 helper나 이름만으로 역할이 분명한 코드에는 설명을 반복하지 않습니다.

## Git 흐름

1. 최신 `dev`에서 짧은 기능 브랜치를 만듭니다.
2. 브랜치 이름으로 영역을 드러냅니다: `frontend/itinerary-map`, `backend/receipt-ocr`, `docs/feature-scope`, `platform/firebase`.
3. Pull Request 대상은 `dev`입니다.
4. `dev`에서 전체 검증과 목업 공유를 마친 뒤 `dev`에서 `main`으로 릴리스 Pull Request를 만듭니다.
5. `main`과 `dev`에 직접 커밋하거나 서로 다른 폴더 구조를 따로 만들지 않습니다.

## 검증

React 목업과 backend 회귀는 저장소 루트의 기존 npm 명령으로 확인합니다.

```bash
npm run format:check
npm run typecheck
npm run lint
npm test
npm run build
npm run test:emulator
```

Flutter frontend는 다음 명령으로 검증하고 backend npm·Emulator 검증도 유지합니다.

```bash
cd frontend
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Android Emulator에서 Firebase Emulator host는 `10.0.2.2`를 사용합니다. Flutter Web build는 첫 Android 완료 게이트가 아닙니다.

도메인 기능은 mock repository로 먼저 완성하고 외부 Firebase·지도·OCR 연결은 service/repository 경계에서 추가합니다.
