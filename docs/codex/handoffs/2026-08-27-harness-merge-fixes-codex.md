# 합치기 전 Codex 하네스 수정

## 1. 목표

- 작업명: `frontend/`·`backend/` 구조 합치기 전 하네스 호환성 수정
- 이번 작업에서 끝내려는 관찰 가능한 결과: 현재 구조와 합칠 대상 구조에서 같은 검증 진입점이 동작하고, CI와 위험 명령 훅 및 협업 문서가 팀 정책과 일치한다.
- 범위에 포함하지 않은 것: 친구 브랜치의 제품 코드를 현재 브랜치로 병합, 실제 Firebase 배포·secret·유료 API
- 관련 문서·결정: `AGENTS.md`, `MarkDown/`, `scripts/verify.ps1`, `.github/workflows/ci.yml`, `.codex/hooks.json`

## 2. 끝난 것

- `AGENTS.md`에 확인된 `frontend/`, `backend/`, `docs/`, `MarkDown/` 경계와 Git 흐름을 유지하고 하네스 안전 규칙만 합쳤다.
- `MarkDown/`을 제품·기술 계약의 기준으로 명시하고 구현·테스트는 상태 증거로 분리했다.
- 검증기가 전환 전 구조와 `frontend/`·`backend/` 구조를 판별하며, Windows 전용 `npm.cmd` 대신 `npm`을 사용하도록 수정했다.
- Ubuntu CI가 Full 검증 진입점을 직접 호출하고 Node.js 22와 Java 21을 준비하도록 수정했다.
- 훅이 force push 표기와 `git -C ... reset --hard` 변형을 판별하도록 보강했다.
- 실제 인계는 `docs/codex/handoffs/` 아래의 작업별 파일에 남기고 `SYNC_LOG.md`에는 append하거나 색인을 추가하지 않도록 정리했다.

## 3. 남은 것

- [ ] 팀 리뷰 — 합칠 때 `AGENTS.md` add/add 충돌에서는 이 브랜치의 합성본을 선택하고, Git의 디렉터리 이동 감지가 제안하는 `frontend/scripts/verify.ps1`은 제거한 뒤 검증기를 루트 `scripts/verify.ps1`에 둔다.
- [ ] 원격 CI 확인 — 브랜치를 push한 뒤 Ubuntu GitHub Actions의 Full 검증 종료 코드가 `0`인지 확인한다.
- 막힌 항목과 막힌 이유: 원격 CI는 push 전에는 실행할 수 없다.

## 4. 결정한 것과 이유

| 결정                                                            | 이유·근거                                                            | 영향받는 경로                         | 되돌릴 조건                                         |
| --------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------- |
| 기존 `MarkDown/` 문서를 제품·기술 계약의 source of truth로 유지 | 협업 기록과 현재 구현은 계약을 조용히 덮어쓰면 안 되기 때문          | `AGENTS.md`, `docs/codex/README.md`   | 팀이 기존 계약 문서에서 정책을 명시적으로 변경할 때 |
| Fast와 Full 모두 `scripts/verify.ps1`을 단일 진입점으로 사용    | 로컬과 CI의 검사 순서·실패 판정을 같게 하기 위해                     | `AGENTS.md`, CI, 인계 스킬·템플릿     | 저장소가 다른 단일 검증기를 채택할 때               |
| 인계마다 별도 파일을 생성                                       | 여러 작업자가 한 로그를 수정하며 생기는 충돌을 피하기 위해           | `docs/codex/handoffs/`, `SYNC_LOG.md` | 충돌 없는 외부 기록 시스템을 채택할 때              |
| 훅 차단 범위는 force push, hard reset, 강제 clean으로 제한      | 확인된 사고 위험만 기계적으로 차단하고 정상 Git 흐름은 유지하기 위해 | `.codex/hooks/`                       | 반복 사고가 기록되어 새 차단 항목이 승인될 때       |

## 5. 하지 말 것

- 친구 브랜치의 제품 변경을 이 하네스 수정에 섞지 않는다.
- 제품 코드, 테스트, fixture, Firestore 규칙 또는 검증기를 약화해 통과시키지 않는다.
- 실제 Firebase 프로젝트, secret, 유료 외부 API를 연결하지 않는다.
- 기존 강의자료 원본을 수정하지 않는다.

## 6. 확인 방법

실행 환경:

- Node.js: `22.19.0`
- Java: `21.0.11`
- data source: unit fixture와 Firebase demo Emulator
- 대상 구조: 현재 `root/functions`, 합칠 대상 `frontend/backend`

실행한 명령과 결과:

```powershell
pwsh -File scripts/verify.ps1 -Mode Fast
pwsh -File scripts/verify.ps1 -Mode Full
pwsh -File .codex/hooks/block-dangerous-command.ps1 -TestRawInput
```

- 깨끗한 LF checkout의 현재 `root/functions` 구조: Fast `0`, Full `0`
- `origin/codex/frontend-backend-workspaces`의 `e773cce`와 하네스를 합친 임시 구조: Fast `0`, Full `0`
- 의도적으로 루트 `build` script를 뺀 임시 구조: `1`, `package.json에 필수 script가 없습니다: build`
- 의도적으로 Java를 PATH에서 뺀 Full 실행: `2`, Firebase Emulator Java 전제조건 오류
- 훅 내장 21개 사례: `0`; 직접 JSON 검사에서 `git push -f`, `+HEAD:main`, 줄바꿈 뒤 force push, `git -C ... reset --hard`는 deny, 일반 push와 충돌 해결 checkout은 allow
- 인계 스킬 `quick_validate.py`: `0`, `Skill is valid!`
- 현재 Windows 작업 폴더 자체는 하네스 변경 전 checkout된 여러 파일의 CRLF 때문에 format 단계가 실패한다. 검증 조건을 완화하지 않았고, `.gitattributes`가 적용된 깨끗한 LF checkout 두 곳에서 위 결과를 확인했다.
- 원격 Ubuntu GitHub Actions: 아직 실행하지 않음. workflow는 `npm ci` 뒤 루트 Full 검증기를 호출하고 Node.js 22와 Temurin Java 21을 준비한다.
- 다음 작업자가 가장 먼저 재현할 명령: `pwsh -File scripts/verify.ps1 -Mode Fast`
