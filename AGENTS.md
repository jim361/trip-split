# Trip Split 작업 규칙

## 프로젝트 경계

- `frontend/`: React/Vite/PWA, 화면, mock·Firestore Web repository와 지도 adapter
- `backend/`: Firebase Functions, Firestore 규칙과 Emulator 통합 테스트
- `docs/`: 회의용 기능 범위와 구현 인계
- `MarkDown/`: 합의된 제품·기술 계약과 기능별 task의 source of truth

공통 타입, Firestore 경로, Callable 요청·응답을 바꾸면 frontend와 backend 영향을 함께 확인합니다. 기존 파일이나 다른 작업자의 변경을 삭제하거나 되돌리지 않습니다.
구현·테스트가 `MarkDown/` 계약과 다르면 구현을 조용히 우선하지 말고 충돌을 보고해 결정을 요청합니다.

## Git 흐름

1. 최신 `dev`에서 짧은 기능 브랜치를 만듭니다.
2. 브랜치 이름으로 영역을 드러냅니다: `frontend/itinerary-map`, `backend/receipt-ocr`, `docs/feature-scope`, `platform/firebase`.
3. Pull Request 대상은 `dev`입니다.
4. `dev`에서 전체 검증과 목업 공유를 마친 뒤 `dev`에서 `main`으로 릴리스 Pull Request를 만듭니다.
5. `main`과 `dev`에 직접 커밋하거나 서로 다른 폴더 구조를 따로 만들지 않습니다.

## 검증

- 작업 중 빠른 검증: `pwsh -File scripts/verify.ps1 -Mode Fast`
- PR 전 전체 검증: `pwsh -File scripts/verify.ps1 -Mode Full`

## 안전 규칙

- 도메인 기능은 mock repository로 먼저 완성하고 외부 Firebase·지도·OCR 연결은 service/repository 경계에서 추가합니다.
- 외부 API 원문, 비밀 키, 토큰 또는 이미지 본문을 UI 오류·로그·커밋에 넣지 않습니다.
- OCR은 사용자가 검토·확정하기 전 원장에 반영하지 않고 이미지를 Firebase Storage에 영구 저장하지 않으며, 실제 Firebase 배포·secret 등록·유료 API 호출은 사용자 승인 후에만 합니다.
- 공개 GitHub Pages 목업은 `VITE_DATA_SOURCE=mock`을 유지하고 실제 Firebase 프로젝트에 연결하지 않습니다.
- 테스트·fixture·검증 조건을 약화하거나 삭제해 통과시키지 않으며, force push·`reset --hard`·강제 clean을 사용하지 않습니다.
