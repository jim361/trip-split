# Codex 협업 하네스 인계

## 1. 목표

- 작업명: Claude 기반 바이브코딩 강의 기법을 Trip Split의 Codex 협업 환경에 적용
- 관찰 가능한 결과: 새 Codex 세션이 저장소 지침과 스킬을 발견하고, 단일 검증 명령과 위험 명령 훅이 판정 가능한 결과를 냄
- 범위에 포함하지 않은 것: 제품 코드 변경, 실제 Firebase 배포, secret 등록, 유료 API 연결, 플러그인 번들 제작
- 관련 문서·결정: `docs/codex/README.md`, `MarkDown/decision_history.md`의 2026-08-27 결정, `docs/platform-handoff.md`

## 2. 끝난 것

- 루트 `AGENTS.md`를 짧고 판정 가능한 규칙으로 다이어트했다.
- 긴 배경과 문서 충돌 판정은 `docs/codex/`로 분리했다.
- `.agents/skills/trip-split-handoff/SKILL.md`를 만들고 형식 검사와 자연 호출을 확인했다.
- `scripts/verify.ps1`에 Fast/Full 모드와 종료 코드 `0`·`1`·`2`를 구현했다.
- `.codex/hooks.json`과 PowerShell 훅으로 제한된 위험 Git 명령을 실행 전에 차단했다.
- `.gitattributes`로 기존 Prettier의 LF 계약을 Windows checkout에도 명시했다.
- 제품 코드는 변경하지 않았다.

## 3. 남은 것

- [ ] 팀원이 새 Codex 세션에서 `/hooks`를 열어 프로젝트 훅 정의를 검토하고 신뢰한다.
- [ ] PR 전에 실제 팀 checkout에서 `pwsh -File scripts/verify.ps1 -Mode Full`이 종료 코드 `0`인지 다시 확인한다.
- [ ] 이 브랜치의 리뷰가 끝나면 대상 브랜치를 `dev`로 지정한다.
- 막힌 항목: 없음
- 후속 정정 (2026-08-27): 기존 `MarkDown/` 문서가 제품·기술 계약의 기준이며, `MarkDown/decision_history.md`의 최신 결정을 그 안에서 우선한다. `frontend/`, `backend/`, `backend/tests/`는 구현·검증 증거로 확인하고 계약과 어긋나면 충돌을 기록한다. 합치기 전 수정 기록은 [`2026-08-27-harness-merge-fixes-codex.md`](2026-08-27-harness-merge-fixes-codex.md)에서 관리한다.

## 4. 결정한 것과 이유

| 결정                                                            | 이유·근거                                                                                             | 영향받는 경로                       | 되돌릴 조건                                 |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------- | ------------------------------------------- |
| 기존 `MarkDown/` 계약을 기준으로 삼고, 그 안에서 최신 결정 우선 | 국내/KRW/네이버 중심 과거 문서와 도쿄/JPY/Google mock 구현이 충돌할 때 계약과 구현 증거를 분리해야 함 | `AGENTS.md`, `docs/codex/README.md` | 팀이 새 결정 기록으로 계약 기준을 변경할 때 |
| 별도 플러그인 번들을 만들지 않음                                | 이 저장소에 필요한 스킬 1개와 훅 1개는 직접 경로가 더 단순함                                          | `.agents/`, `.codex/`               | 여러 저장소에 배포할 묶음이 생길 때         |
| Prettier 검사를 완화하지 않고 LF를 Git에서 고정                 | Windows `core.autocrlf=true`가 기존 `endOfLine=lf` 계약을 깨뜨림                                      | `.gitattributes`                    | 저장소가 줄바꿈 계약을 공식 변경할 때       |
| 훅은 force push, hard reset, 강제 clean만 차단                  | 사고 가능성이 명확한 최소 범위부터 시작                                                               | `.codex/hooks/`                     | 실제 사고 기록에 따라 한 항목씩 추가할 때   |

## 5. 하지 말 것

- 제품 코드, 테스트, fixture, Firestore 규칙을 이 하네스 검증을 통과시키기 위해 약화하지 않는다.
- 실제 Firebase 프로젝트, secret, 유료 외부 API를 연결하지 않는다.
- 기존 강의자료 원본은 수정하지 않는다.
- 한 개 저장소 스킬과 훅을 이유 없이 플러그인으로 포장하지 않는다.

## 6. 확인 방법

실행 환경:

- Node.js: `22.19.0`
- Java: `21.0.11`
- data source: 검증은 기존 unit fixture와 Firebase demo Emulator 사용
- Firebase Emulator 프로젝트: `demo-trip-split`, auth·firestore·functions

실행 명령과 확인된 결과:

```powershell
pwsh -File scripts/verify.ps1 -Mode Full
```

- LF 임시 checkout에서 종료 코드 `0`
- unit/UI/Functions 테스트: 27개 통과
- Emulator 경계 테스트: 8개 통과
- Java를 PATH에서 제외한 의도적 Full 실행: 종료 코드 `2`, Java 전제조건 오류
- 훅 직접 검사: `git status` 허용, `git clean -fd` deny JSON, 검사 종료 코드 `0`
- 스킬 형식 검사: `quick_validate.py` 종료 코드 `0`
- 새 Codex 읽기 전용 세션의 이름 없는 인계 요청: `trip-split-handoff` 자동 선택
- `codex debug prompt-input`: 루트 `AGENTS.md`와 저장소 스킬 경로 확인

다음 작업자가 가장 먼저 실행할 명령:

```powershell
pwsh -File scripts/verify.ps1 -Mode Fast
```
