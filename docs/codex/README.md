# Codex 협업 문서 안내

`docs/codex/`는 Trip Split 작업을 넘겨받거나 중단할 때 필요한 짧은 작업 기록과 반복 방지 규칙을 모아 두는 곳이다. 제품 요구사항이나 구현 계약을 새로 정의하는 곳은 아니다. 기존 `MarkDown/` 문서가 제품·기술 계약의 source of truth이며, 이 디렉터리는 그 계약을 대신하지 않는다.

## 문서 지도

| 문서                                                     | 용도                                      | 언제 갱신하는가                  |
| -------------------------------------------------------- | ----------------------------------------- | -------------------------------- |
| [`README.md`](README.md)                                 | 협업 문서의 위치와 충돌 해결 순서         | 문서 체계가 바뀔 때              |
| [`HANDOFF_TEMPLATE.md`](HANDOFF_TEMPLATE.md)             | 작업 인계 기록                            | 작업을 넘기거나 재개할 때        |
| [`STOP_CONTRACT_TEMPLATE.md`](STOP_CONTRACT_TEMPLATE.md) | 한 번의 자율 작업이 멈출 조건             | 반복 작업을 시작하기 전          |
| [`RATCHET.md`](RATCHET.md)                               | 실패를 재발 방지 규칙으로 올리는 기록     | 같은 실패가 반복될 때            |
| [`CHANGELOG.md`](CHANGELOG.md)                           | 협업 문서 또는 계약에 영향을 준 변경 요약 | 의미 있는 변경을 마칠 때         |
| [`SYNC_LOG.md`](SYNC_LOG.md)                             | 공유 로그를 쓰지 않는 동기화 기록 정책    | 기록 정책이 바뀔 때              |
| [`handoffs/`](handoffs/)                                 | 작업별로 채운 실제 인계 문서              | 다른 세션이나 담당자에게 넘길 때 |

실제 인계는 `handoffs/` 아래에 작업별 파일로 저장한다. 파일명은
`YYYY-MM-DD-task-owner.md`를 기본으로 하고, 같은 날짜·작업·담당자가 다시 생기면
`YYYY-MM-DD-HHmm-task-owner.md`처럼 시각을 덧붙여 충돌을 피한다. `SYNC_LOG.md`에
작업 진행 내용을 이어 쓰지 않는다.

## 규칙의 다섯 자리

| 판단 질문                                   | 둘 자리             | 이 저장소의 진입점                                        |
| ------------------------------------------- | ------------------- | --------------------------------------------------------- |
| 항상 지켜야 하는 짧고 판정 가능한 사실인가? | 프로젝트 지침       | [`AGENTS.md`](../../AGENTS.md)                            |
| 가끔 읽는 긴 배경이나 계약인가?             | 제품·협업 문서      | `MarkDown/`, `docs/`, 이 디렉터리                         |
| 반복되는 절차인가?                          | 저장소 스킬         | `.agents/skills/trip-split-handoff/SKILL.md`              |
| 어기면 기계적으로 잡거나 막아야 하는가?     | 검증 진입점·훅·CI   | `scripts/verify.ps1`, `.codex/hooks.json`, GitHub Actions |
| 되돌리기 어렵거나 외부 상태를 바꾸는가?     | 실행 직전 사람 확인 | 실제 배포, secret 등록, 유료 API 호출                     |

같은 지시를 여러 자리에 복사하지 않는다. 지침 파일은 지도와 불변식만 유지하고, 상세 설명은 문서, 반복 순서는 스킬, 결정적 실패는 검증기나 훅에 둔다.

## 저장소 루트 검증

저장소 루트에서 다음 한 줄을 사용한다. 검증기는 필요한 루트 `npm` scripts를 순서대로 실행하고 어느 단계가 실패했는지 출력한다.

```powershell
# 작업 중: format, lint, typecheck, unit/UI 테스트
pwsh -File scripts/verify.ps1 -Mode Fast

# PR 전: Fast 범위 + production build + Firebase Emulator/rules 테스트
pwsh -File scripts/verify.ps1 -Mode Full
```

공통 전제조건은 `.nvmrc`와 `package.json`에 고정한 Node.js 22 및 `npm ci`이며, Full 모드는 Java 21과 Firebase Emulator를 사용한다. 검증기는 `frontend/`·`backend/` workspace만 허용하고 폐기한 root `src/`·`functions/` 디렉터리가 남으면 실패한다. typecheck, test, build는 두 workspace에서 각각 실행하며, README가 안내하는 같은 이름의 루트 script도 두 workspace에 정확히 위임해야 한다. GitHub Actions도 훅 자체 테스트와 Full 검증기를 실행한다.

현재 CI 트리거는 `dev`·`main` 대상 Pull Request와 수동 `workflow_dispatch`다. 기능 브랜치의 일반 push만으로는 CI가 실행되지 않으므로 원격 검증 증거가 필요하면 Pull Request를 만들거나 Actions에서 수동 실행한다.

`.gitattributes`가 Prettier의 `endOfLine=lf` 계약을 Windows에서도 유지한다. 이 파일이 생기기 전에 받은 기존 checkout에서 전체 파일이 CRLF라면 검증 조건을 완화하지 말고, 변경을 보존한 뒤 LF checkout에서 다시 확인한다.

## 저장소 스킬과 훅

- 자연스러운 인계 요청에는 `.agents/skills/trip-split-handoff/SKILL.md`가 여섯 칸 인계 형식과 실행 증거를 적용한다.
- `.codex/hooks.json`의 `PreToolUse` 훅은 강제 push, `reset --hard`, 강제 clean을 실행 전에 차단한다.
- 프로젝트 훅은 저장소를 신뢰한 뒤 Codex의 `/hooks` 화면에서 정의를 검토하고 신뢰해야 실제 세션에 적용된다.
- 훅은 일부 로컬 도구 경로에만 적용되는 guardrail이며 완전한 보안·강제 경계가 아니다. Firebase 배포나 secret 같은 외부 작업의 사람 확인을 대신하지 않는다.

## 실제 프로젝트 문서 지도

| 경로                                                                 | 기준                                                                 |
| -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| [`README.md`](../../README.md)                                       | 저장소 사용법, 검증 명령, 현재 공개 mockup의 진입 경로               |
| [`docs/platform-handoff.md`](../platform-handoff.md)                 | 현재 구현 경계, provider/repository 주입, Callable, 보안·온라인 경계 |
| [`docs/mockup-review.md`](../mockup-review.md)                       | 2026-08-27 해외여행 중심 mockup 흐름과 현재 화면 검토 경계           |
| [`MarkDown/tech.md`](../../MarkDown/tech.md)                         | 데이터·repository·오류·외부 연동의 기술 계약 기준                    |
| [`MarkDown/structure.md`](../../MarkDown/structure.md)               | 라우트, 모듈 경계, 도메인 불변식, 협업 규칙 기준                     |
| [`MarkDown/requirements.md`](../../MarkDown/requirements.md)         | MVP 요구사항 기준                                                    |
| [`MarkDown/task/`](../../MarkDown/task/)                             | 기능별 완료 조건과 테스트 항목                                       |
| [`MarkDown/decision_history.md`](../../MarkDown/decision_history.md) | 날짜가 있는 제품·구조 결정의 이력                                    |
| `frontend/`, `backend/`, `backend/tests/`                            | 실제 구현과 검증 코드                                                |

## 문서가 충돌할 때

다음 순서로 판단하고, 판단 결과를 인계나 변경 로그에 남긴다.

1. 관련된 기존 `MarkDown/` 문서를 먼저 확인한다. 이 문서가 제품·기술 계약의 source of truth다.
2. `MarkDown/decision_history.md`에서 가장 최신 날짜의 결정을 확인한다. 이 저장소의 결정 로그 파일명은 `decision_history.md`이다.
3. `README.md`와 `docs/`의 현재 인계·mockup 문서를 확인하되, 계약을 대신 정의하는 근거로 삼지 않는다.
4. `frontend/`, `backend/`, `backend/tests/`는 구현·검증 상태를 확인하는 증거로 사용한다. 계약과 어긋나면 코드·테스트를 조용히 우선하지 말고 충돌과 필요한 결정을 기록한다.
5. 어느 쪽도 결정하지 못하면 임의로 계약을 바꾸지 말고 충돌과 필요한 결정을 기록한다.

특히 초기 문서의 국내/KRW/네이버 전용 흐름과 4개 메뉴 설명은 최신 도쿄·JPY mockup 계약과 다를 수 있다. `MarkDown/decision_history.md` 안의 최신 합의를 확인하고, 어느 계약이 유효한지 불명확하면 구현으로 추정하지 말고 결정을 요청한다.

## 기록 원칙

- 기록에는 날짜, 작업 범위, 영향을 받은 경로, 실행한 검증 명령과 결과를 남긴다.
- “완료”라고 쓰려면 해당 범위의 검증 방법과 결과를 함께 적는다.
- 초안·미연결 기능·실험 기능을 구현 완료로 표현하지 않는다.
- 문서만 바뀐 경우에도 제품 계약 변경인지, 협업 기록 변경인지 구분한다.
