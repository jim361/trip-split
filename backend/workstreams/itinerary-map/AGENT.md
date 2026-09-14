# 일정·지도 백엔드 작업 지침

> 이 파일은 요청한 이름의 일반 문서다. 새 작업에서 명시적으로 읽는다. Codex 자동 발견을 가정하지 않는다.

- 루트 `AGENTS.md`, 이 폴더의 `SPEC.md` → `plan.md` → `tasks.md`, 최신 `docs/development-kickoff.md`를 먼저 읽는다.
- 이 역할은 일정·지도 백엔드다. 인계 문서의 “사용자·프론트/공통/통합”과 구분한다.
- 작업 전·push 직전 저장소 루트에서 `git status --short`, `git fetch origin dev`로 상태를 확인한다.
- 별도 clone의 `dev`를 사용한다. 깨끗한 작업 상태에서 `git merge --ff-only origin/dev`로 동기화한다.
- 쓰기는 `backend/src/places/`, `backend/tests/emulator/itinerary-map/`, 이 문서 폴더로 제한한다.
- `settlement/`·`ocr/`·Flutter는 읽기만 한다. 공용 테스트·Rules·index·공통 모델·계약·설정 변경은 SPEC의 소유권 절차를 따른다.
- 공통 변경은 문제·재현·대상 파일·호출자 영향·검증안을 `tasks.md`에 적고 통합 담당과 조율한다.
- 기존 Callable·ID·wire를 유지하고 공통 helper·Node 표준 기능·설치된 Vitest를 먼저 재사용한다.
- 입력·여행 멤버 검증 전에 외부 요청을 보내지 않는다. 운영에서 Emulator fixture로 성공을 반환하지 않는다.
- 비밀값·외부 응답 원문을 Git·사용자 오류·로그에 넣지 않는다. 실제 API·secret 등록·배포는 승인된 범위에서만 한다.
- Node 22·Java 21에서 실행한다. 최초 설치는 저장소 루트의 `npm ci`, Emulator 시작은 `npm run dev:backend`다.
- 작업 중 `npm run verify:fast`, dev 반영 전 `npm run verify:full`을 실행하고 종료 코드·실행 범위를 기록한다.
- 로직 변경에는 깨지면 실패하는 최소 회귀를 남긴다. 실패한 테스트·fixture·검증 조건을 약화하지 않는다.
- 한 번에 한 IMB 작업을 진행한다. 작업별 정지 조건은 `plan.md`의 정지 계약을 따른다.
- commit·push·PR은 해당 요청의 명시적 승인 범위에서 수행한다. 승인된 정확한 파일만 stage하고 diff를 확인한다.
- force push·강제 reset/clean·자동 전체 stage를 하지 않는다. 새 dev 변경은 통합 후 담당 검증을 다시 실행한다.
- 종료 전 `tasks.md`의 작업 상태·실행 기록·다음 세션 인계를 갱신한다.
