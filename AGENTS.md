# Trip Split 작업 규칙

## 프로젝트 경계

- `frontend/`: React/Vite/PWA, 화면, mock·Firestore Web repository와 지도 adapter
- `backend/`: Firebase Functions, Firestore 규칙과 Emulator 통합 테스트
- `docs/`: 회의용 기능 범위와 구현 인계
- `MarkDown/`: 합의된 제품·기술 계약과 기능별 task

공통 타입, Firestore 경로, Callable 요청·응답을 바꾸면 frontend와 backend 영향을 함께 확인합니다. 기존 파일이나 다른 작업자의 변경을 삭제하거나 되돌리지 않습니다.

## Git 흐름

1. 최신 `dev`에서 짧은 기능 브랜치를 만듭니다.
2. 브랜치 이름으로 영역을 드러냅니다: `frontend/itinerary-map`, `backend/receipt-ocr`, `docs/feature-scope`, `platform/firebase`.
3. Pull Request 대상은 `dev`입니다.
4. `dev`에서 전체 검증과 목업 공유를 마친 뒤 `dev`에서 `main`으로 릴리스 Pull Request를 만듭니다.
5. `main`과 `dev`에 직접 커밋하거나 서로 다른 폴더 구조를 따로 만들지 않습니다.

## 검증

저장소 루트에서 다음 명령을 실행합니다.

```bash
npm run format:check
npm run typecheck
npm run lint
npm test
npm run build
npm run test:emulator
```

도메인 기능은 mock repository로 먼저 완성하고 외부 Firebase·지도·OCR 연결은 service/repository 경계에서 추가합니다.
