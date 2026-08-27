# Codex 협업 문서 안내

`docs/codex/`는 Trip Split 작업을 넘겨받거나 중단할 때 필요한 짧은 작업 기록과 반복 방지 규칙을 모아 두는 곳이다. 제품 요구사항이나 구현 계약을 새로 정의하는 곳은 아니다. 현재 제품·데이터 계약은 저장소의 기존 문서를 따른다.

## 문서 지도

| 문서                                                     | 용도                                      | 언제 갱신하는가                  |
| -------------------------------------------------------- | ----------------------------------------- | -------------------------------- |
| [`README.md`](README.md)                                 | 협업 문서의 위치와 충돌 해결 순서         | 문서 체계가 바뀔 때              |
| [`HANDOFF_TEMPLATE.md`](HANDOFF_TEMPLATE.md)             | 작업 인계 기록                            | 작업을 넘기거나 재개할 때        |
| [`STOP_CONTRACT_TEMPLATE.md`](STOP_CONTRACT_TEMPLATE.md) | 한 번의 자율 작업이 멈출 조건             | 반복 작업을 시작하기 전          |
| [`RATCHET.md`](RATCHET.md)                               | 실패를 재발 방지 규칙으로 올리는 기록     | 같은 실패가 반복될 때            |
| [`CHANGELOG.md`](CHANGELOG.md)                           | 협업 문서 또는 계약에 영향을 준 변경 요약 | 의미 있는 변경을 마칠 때         |
| [`SYNC_LOG.md`](SYNC_LOG.md)                             | 작업 단위별 진행·검증·인계 로그           | 작업 단위가 끝날 때              |
| [`handoffs/`](handoffs/)                                 | 날짜·작업별로 채운 실제 인계 문서         | 다른 세션이나 담당자에게 넘길 때 |

## 규칙의 다섯 자리

| 판단 질문                                   | 둘 자리             | 이 저장소의 진입점                                        |
| ------------------------------------------- | ------------------- | --------------------------------------------------------- |
| 항상 지켜야 하는 짧고 판정 가능한 사실인가? | 프로젝트 지침       | [`AGENTS.md`](../../AGENTS.md)                            |
| 가끔 읽는 긴 배경이나 계약인가?             | 제품·협업 문서      | `MarkDown/`, `docs/`, 이 디렉터리                         |
| 반복되는 절차인가?                          | 저장소 스킬         | `.agents/skills/trip-split-handoff/SKILL.md`              |
| 어기면 기계적으로 잡거나 막아야 하는가?     | 검증 진입점·훅·CI   | `scripts/verify.ps1`, `.codex/hooks.json`, GitHub Actions |
| 되돌리기 어렵거나 외부 상태를 바꾸는가?     | 실행 직전 사람 확인 | 실제 배포, secret 등록, 유료 API 호출                     |

같은 지시를 여러 자리에 복사하지 않는다. 지침 파일은 지도와 불변식만 유지하고, 상세 설명은 문서, 반복 순서는 스킬, 결정적 실패는 검증기나 훅에 둔다.

## 단일 검증 진입점

저장소 루트에서 다음 두 명령만 사용한다.

```powershell
pwsh -File scripts/verify.ps1 -Mode Fast
pwsh -File scripts/verify.ps1 -Mode Full
```

- `Fast`: 정적 문법·설정 검사, 포맷, lint, typecheck, unit/UI/Functions 테스트
- `Full`: Fast 전체와 production build, Firebase Auth·Firestore·Functions Emulator 테스트
- 종료 코드 `0`: 통과, `1`: 검증 실패, `2`: Node·의존성·Java 같은 전제조건 실패
- 공통 전제조건: Node.js 22와 `npm ci`
- Full 전제조건: PATH에서 실행 가능한 Java

`.gitattributes`가 Prettier의 `endOfLine=lf` 계약을 Windows에서도 유지한다. 이 파일이 생기기 전에 받은 기존 checkout에서 전체 파일이 CRLF라면 검증 조건을 완화하지 말고, 변경을 보존한 뒤 LF checkout에서 다시 확인한다.

## 저장소 스킬과 훅

- 자연스러운 인계 요청에는 `.agents/skills/trip-split-handoff/SKILL.md`가 여섯 칸 인계 형식과 실행 증거를 적용한다.
- `.codex/hooks.json`의 `PreToolUse` 훅은 강제 push, `reset --hard`, 강제 디렉터리 clean을 실행 전에 차단한다.
- 프로젝트 훅은 저장소를 신뢰한 뒤 Codex의 `/hooks` 화면에서 정의를 검토하고 신뢰해야 실제 세션에 적용된다.
- 훅은 일부 로컬 도구 경로에만 적용되는 guardrail이다. Firebase 배포나 secret 같은 외부 작업의 사람 확인을 대신하지 않는다.

## 실제 프로젝트 문서 지도

| 경로                                                                 | 기준                                                                 |
| -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| [`README.md`](../../README.md)                                       | 저장소 사용법, 검증 명령, 현재 공개 mockup의 진입 경로               |
| [`docs/platform-handoff.md`](../platform-handoff.md)                 | 현재 구현 경계, provider/repository 주입, Callable, 보안·온라인 경계 |
| [`docs/mockup-review.md`](../mockup-review.md)                       | 2026-08-27 해외여행 중심 mockup 흐름과 현재 화면 검토 경계           |
| [`MarkDown/tech.md`](../../MarkDown/tech.md)                         | 데이터·repository·오류·외부 연동의 기술 계약 초안                    |
| [`MarkDown/structure.md`](../../MarkDown/structure.md)               | 라우트, 모듈 경계, 도메인 불변식, 협업 규칙 초안                     |
| [`MarkDown/requirements.md`](../../MarkDown/requirements.md)         | MVP 요구사항 초안                                                    |
| [`MarkDown/task/`](../../MarkDown/task/)                             | 기능별 완료 조건과 테스트 항목                                       |
| [`MarkDown/decision_history.md`](../../MarkDown/decision_history.md) | 날짜가 있는 제품·구조 결정의 이력                                    |
| `src/`, `functions/`, `tests/`                                       | 실제 구현과 검증 코드                                                |

## 문서가 충돌할 때

다음 순서로 판단하고, 판단 결과를 인계나 변경 로그에 남긴다.

1. 현재 `src/`, `functions/`, `tests/`의 구현과 통과하는 검증 결과를 확인한다.
2. `MarkDown/decision_history.md`에서 가장 최신 날짜의 결정을 확인한다. 이 저장소의 결정 로그 파일명은 `decision_history.md`이다.
3. `README.md`와 `docs/`의 현재 인계·mockup 문서를 확인한다.
4. 오래된 요구사항·작업 초안보다 최신 결정과 실제 구현을 우선한다.
5. 어느 쪽도 결정하지 못하면 임의로 계약을 바꾸지 말고 충돌과 필요한 결정을 기록한다.

특히 초기 문서의 국내/KRW/네이버 전용 흐름과 4개 메뉴 설명은 최신 도쿄·JPY mockup 계약과 다를 수 있다. 날짜가 명시된 최신 결정과 현재 구현을 확인하지 않고 과거 문장을 규칙으로 복사하지 않는다.

## 기록 원칙

- 기록에는 날짜, 작업 범위, 영향을 받은 경로, 실행한 검증 명령과 결과를 남긴다.
- “완료”라고 쓰려면 해당 범위의 검증 방법과 결과를 함께 적는다.
- 초안·미연결 기능·실험 기능을 구현 완료로 표현하지 않는다.
- 문서만 바뀐 경우에도 제품 계약 변경인지, 협업 기록 변경인지 구분한다.
