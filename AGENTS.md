# Trip Split 작업 규칙

## 프로젝트 경계와 계약

- `frontend/`: React/Vite/PWA 화면·라우팅·mock/Firestore repository·provider/adapter를 담당합니다. 화면 컴포넌트에서 Firebase SDK를 직접 호출하지 않습니다.
- `backend/`: Firebase Functions, Firestore 보안 규칙, Emulator 통합 테스트와 비공개 외부 API 호출을 담당합니다.
- `docs/`: 기능 후보 회의와 현재 구현 인계 문서입니다.
- `MarkDown/`: 합의된 제품·요구사항·기술·구조 계약과 기능별 task의 source of truth입니다.
- 공통 타입, Firestore 경로, Callable 요청·응답을 바꾸면 frontend와 backend 영향을 함께 확인합니다. 기존 파일이나 다른 작업자의 변경을 삭제하거나 되돌리지 않습니다.
- `TripMember.uid`와 `Participant.id`는 다른 ID이며, 연결할 때만 `Participant.linkedUid`를 사용합니다.
- Entity ID는 의미를 해석하지 않는 문자열입니다. 배열 index, 이름, 공유 코드를 ID로 재사용하지 않습니다.
- 현재 Callable 이름과 계약(`createTrip`, `createShareCode`, `joinTrip`)을 임의로 바꾸지 않습니다.

## 문서와 충돌 처리

- 구현·테스트가 `MarkDown/` 계약과 다르면 코드를 조용히 우선하지 말고 충돌과 필요한 결정을 보고합니다.
- 문서 충돌은 관련 `MarkDown/`, 최신 `MarkDown/decision_history.md`, `README.md`·`docs/`, 현재 구현·테스트 순서로 확인합니다.
- 병합 충돌을 해결할 때 기존 문서 기능 ID, `task_function1`~`task_function9` 파일명, Firestore document/path ID와 Callable 이름을 임의로 rename·delete하지 않습니다.

## Git 흐름과 사용자 작업 계약

- 최신 `dev`에서 짧은 기능 브랜치를 만들고 Pull Request 대상은 `dev`로 합니다.
- `main`과 `dev`에 직접 commit하거나 push하지 않습니다.
- commit, push, Pull Request 생성·갱신·merge는 사용자가 해당 작업을 별도로 명시적으로 요청한 경우에만 수행합니다.
- force push, `reset --hard`, 강제 clean을 사용하지 않습니다.
- 사용자에게 제공하는 설명, 진행 업데이트와 결과 보고는 한국어로 작성합니다.

## 검증과 안전

- 필수 런타임은 Node.js 22와 Java 21입니다.
- 작업 중 빠른 검증: `pwsh -File scripts/verify.ps1 -Mode Fast`
- Pull Request 전 전체 검증: `pwsh -File scripts/verify.ps1 -Mode Full`
- 테스트·fixture·검증 조건을 약화하거나 삭제해 통과시키지 않습니다.
- 도메인 기능은 mock repository로 먼저 완성하고 외부 Firebase·지도·OCR 연결은 service/repository 경계에서 추가합니다.
- 비밀 키, 토큰, 외부 API 원문, 이미지 본문을 UI 오류·로그·commit에 넣지 않습니다.
- OCR은 사용자가 검토·확정하기 전 원장에 반영하지 않고 이미지를 Firebase Storage에 영구 저장하지 않습니다.
- 실제 Firebase 배포, secret 등록, 유료 외부 API 호출은 사용자의 명시적 승인 후에만 수행합니다.
- 공개 GitHub Pages 목업은 `VITE_DATA_SOURCE=mock`을 유지하고 실제 Firebase 프로젝트에 연결하지 않습니다.
