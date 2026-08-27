# 협업 문서 변경 기록

협업 문서·계약 해석·검증 절차에 영향을 준 변경만 짧게 기록한다. 일반 구현 내역은 기능 PR과 기존 프로젝트 문서에서 관리한다.

## 2026-08-27 — Codex 협업 하네스 도입

- 변경 범위: 프로젝트 지침, 협업 문서 지도, 인계·정지 계약·래칫 템플릿, 저장소 스킬, 단일 검증 진입점, 위험 Git 명령 훅, LF 규칙
- 변경 이유: Claude 전용 파일과 명령을 복제하지 않고 Codex가 실제로 읽고 실행하는 구조로 협업 절차를 고정하기 위해서
- 영향을 받는 문서·경로: `AGENTS.md`, `.agents/`, `.codex/`, `.gitattributes`, `docs/codex/`, `scripts/verify.ps1`
- 계약 해석 변경 여부: 제품 계약 변경은 없음. 기존 `MarkDown/` 문서를 제품·기술 계약의 기준으로 삼고, `decision_history.md`의 최신 결정을 그 안에서 우선한다는 판정 순서만 명시
- 검증 명령과 결과: LF 임시 checkout의 Node.js 22.19.0·Java 21 환경에서 `pwsh -File scripts/verify.ps1 -Mode Full` 종료 코드 `0`
- 후속 작업: 팀원이 저장소를 연 뒤 `/hooks`에서 프로젝트 훅 정의를 검토하고 신뢰한다.

## 2026-08-27 — 프론트엔드·백엔드 합치기 전 하네스 호환성 정정

- 변경 범위: `AGENTS.md`의 프로젝트 경계·Git 흐름, 계약 우선순위, 단일 검증 진입점과 CI, 위험 Git 명령 훅, 작업별 인계 정책
- 변경 이유: `origin/codex/frontend-backend-workspaces`의 `AGENTS.md`(e773cce)와 실제 구조를 기준으로 하네스가 합친 뒤에도 같은 경계와 검증 계약을 유지하게 하고 공유 로그 충돌을 줄이기 위해서
- 영향을 받는 문서·경로: `AGENTS.md`, `scripts/verify.ps1`, `.github/workflows/ci.yml`, `.codex/hooks/`, `docs/codex/`, `.agents/skills/trip-split-handoff/SKILL.md`
- 계약 해석 변경 여부: 제품 계약 변경은 없음. 기존 `MarkDown/` 문서가 source of truth이며 코드·테스트는 구현·검증 증거로만 기록
- 검증 명령과 결과: 깨끗한 LF checkout의 현재 구조와 `e773cce` 통합 시뮬레이션에서 Fast·Full 모두 `0`; 누락된 `build` script는 `1`, 누락된 Java 전제조건은 `2`; 훅 내장 21개 사례와 인계 스킬 형식 검사 `0`
- 후속 작업: 실제 합칠 때 `AGENTS.md` 합성본을 선택하고 검증기를 Git이 제안하는 `frontend/scripts/`가 아니라 루트 `scripts/`에 둔 뒤, push 후 Ubuntu CI 결과를 확인

## YYYY-MM-DD — 제목

- 변경 범위:
- 변경 이유:
- 영향을 받는 문서·경로:
- 계약 해석 변경 여부: `없음` / `있음`
- 검증 명령과 결과:
- 후속 작업:

## 기록 규칙

- 날짜는 변경이 실제로 확인된 날짜를 사용한다.
- 최신 결정이나 구현이 이전 초안과 달라졌다면 충돌과 우선한 근거를 적는다.
- 미완료·실험·미연결 상태를 완료로 표현하지 않는다.
