# Trip Split 작업 규칙

- Node.js 22에서 `npm ci`로 의존성을 설치하고 `npm run dev`로 로컬 앱을 실행한다.
- 기능 브랜치는 `dev`에서 만들고 PR 대상은 `dev`로 지정하며 `main` 또는 `dev`에 직접 커밋하거나 push하지 않는다.
- 제품·데이터 계약은 `MarkDown/tech.md`, `MarkDown/structure.md`, `MarkDown/task/tasks.md`, 최신 결정은 `MarkDown/decision_history.md`, 현재 구현 경계는 `docs/platform-handoff.md`를 따른다.
- 문서가 충돌하면 날짜가 더 최신인 결정과 현재 코드·테스트를 우선하고 충돌을 보고한다.
- Codex 협업 문서와 검증 방법은 `docs/codex/README.md`에서 찾는다.
- 화면 컴포넌트에서 Firebase SDK를 직접 호출하지 말고 repository 또는 service 경계를 사용한다.
- `TripMember.uid`와 `Participant.id`를 같은 값으로 가정하지 말고 `Participant.linkedUid`로만 연결한다.
- 금액은 해당 통화의 최소 단위 정수로 저장하고 균등 분할 나머지는 표시된 소비자 순서대로 1단위씩 배분한다.
- 지도 모듈에는 provider 원문이 아니라 정규화된 `Place[]`와 정렬된 `ItineraryItem[]`만 전달한다.
- OCR 결과는 사용자가 검토·확정하기 전 원장에 반영하지 않고 영수증 이미지는 Firebase Storage에 영구 저장하지 않는다.
- 외부 API 원문, 비밀 키, 토큰 또는 이미지 본문을 UI 오류·로그·커밋에 넣지 않는다.
- `package.json`, lockfile, 공통 타입, Firestore 경로·규칙, 앱·Functions 진입점 변경은 PR에 영향 범위와 migration 여부를 적고 나머지 두 담당자의 리뷰를 받는다.
- 공개 GitHub Pages 목업은 `VITE_DATA_SOURCE=mock`을 유지하고 실제 Firebase 프로젝트에 연결하지 않는다.
- 빠른 확인은 `pwsh -File scripts/verify.ps1 -Mode Fast`, 커밋 또는 PR 전 확인은 `pwsh -File scripts/verify.ps1 -Mode Full`을 종료 코드 0으로 통과시킨다.
- 테스트·fixture·검증 조건을 약화해야 통과할 것 같으면 수정하지 말고 근거와 함께 사용자에게 묻는다.
- 실제 Firebase 배포, secret 등록 또는 유료 외부 API 호출은 사용자 승인 후에만 수행한다.
