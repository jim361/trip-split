# 최신 dev 통합과 하네스 보강

## 1. 목표

- 작업명: `feature/codex-harness`에 최신 `dev` 구조와 하네스 안전 장치 합성
- 이번 작업에서 끝내려는 관찰 가능한 결과: `frontend/`·`backend/` 전용 검증, 위험 Git 훅 회귀 테스트, Node.js 22·Java 21 Full 검증이 모두 통과한다.
- 범위에 포함하지 않은 것: Pull Request 생성·merge, 실제 Firebase 배포·secret·유료 API
- 관련 문서·결정: `AGENTS.md`, `MarkDown/`, `scripts/verify.ps1`, `.codex/hooks.json`, `.github/workflows/ci.yml`

## 2. 끝난 것

- `origin/dev`의 `52a8eb8`을 일반 merge로 합성하고 `AGENTS.md`, CI, 검증기 위치 충돌을 수동으로 해결했다.
- 검증기는 폐기한 root `src/`·`functions/` 디렉터리 자체를 거부하고 typecheck, test, build를 frontend와 backend에서 각각 실행한다. README가 안내하는 루트 script도 두 workspace에 정확히 위임해야 한다.
- Windows에서는 `npm.cmd`를 우선하고, Node.js major 22와 Full 모드 Java major 21을 실제 버전 출력으로 검사한다.
- 훅은 Git long-option의 유효한 고유 약어, `push --mirror`, POSIX shell·PowerShell·cmd 래퍼를 실행하지 않고 분석한다. `git clean`의 exclude 인자와 `bash -lc`·`sh -xc` 묶음 옵션도 구분한다.
- CI는 Ubuntu에서 Node.js 22, Java 21, 훅 자체 테스트와 Full 검증기를 실행한다.
- `.nvmrc`와 루트 `package.json`에 Node.js 22를 필수 버전으로 고정했다.
- 사용자가 2026-08-28에 merge commit과 `feature/codex-harness` 일반 push를 명시적으로 승인했다.
- merge commit `6cf7b54`를 일반 push했고 원격 브랜치는 `dev`보다 0 commit 뒤·3 commit 앞이다.
- 사용자가 같은 날 리뷰 보강분의 commit과 `feature/codex-harness` 일반 push도 명시적으로 요청했다.

## 3. 남은 것

- [ ] `dev` 대상 Pull Request — 사용자가 생성을 별도로 요청한 뒤 GitHub Actions Full 검증이 `success`인지 확인한다.
- 막힌 항목과 막힌 이유: 기술적 막힘은 없다. Pull Request 생성·merge는 별도 요청이 없어 수행하지 않는다.

## 4. 결정한 것과 이유

| 결정                                                  | 이유·근거                                                                              | 영향받는 경로                           | 되돌릴 조건                                            |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------- | --------------------------------------- | ------------------------------------------------------ |
| 최신 `dev`를 rebase가 아닌 일반 merge로 합성          | 이미 공개된 브랜치 이력을 force rewrite하지 않기 위해                                  | Git 이력, 충돌 파일                     | 브랜치가 비공개이고 팀이 rebase를 명시적으로 합의할 때 |
| `MarkDown/`을 제품·기술 계약의 source of truth로 유지 | 구현·테스트가 계약을 조용히 덮어쓰지 않게 하기 위해                                    | `AGENTS.md`, `docs/codex/README.md`     | 팀이 계약 문서에서 기준을 명시적으로 바꿀 때           |
| workspace 검증은 루트 위임 script와 분리              | 루트 wrapper에서 backend 위임이 빠져도 조용히 통과하지 않게 하기 위해                  | `scripts/verify.ps1`                    | 저장소가 다른 단일 검증 체계를 채택할 때               |
| 훅을 guardrail로만 설명                               | OpenAI 공식 문서상 일부 도구 경로는 훅을 우회할 수 있어 완전한 강제 경계가 아니기 때문 | `.codex/hooks/`, `docs/codex/README.md` | Codex 공식 실행 모델이 바뀔 때                         |

## 5. 하지 말 것

- force push, `reset --hard`, 강제 clean으로 공개 브랜치 이력을 다시 쓰지 않는다.
- 기존 문서 기능 ID, `task_function1`~`task_function9`, Firestore path ID와 Callable 이름을 충돌 해결 중 임의로 바꾸지 않는다.
- root `src/`·`functions/` 구조를 검증기의 허용 경로로 되살리지 않는다.
- 테스트, fixture, 훅 사례 또는 검증 조건을 약화하거나 삭제해 통과시키지 않는다.
- 실제 Firebase 프로젝트, secret, 유료 외부 API를 연결하지 않는다.

## 6. 확인 방법

실행 환경:

- Node.js: `22.19.0`
- Java: `21.0.10`
- data source: fixture와 `demo-trip-split` Firebase Emulator
- 운영체제: Windows 로컬 검증, CI 대상은 Ubuntu

실행한 명령과 결과:

```powershell
npm ci
pwsh -NoProfile -File .codex/hooks/block-dangerous-command.ps1 -TestRawInput
pwsh -NoProfile -File scripts/verify.ps1 -Mode Fast
pwsh -NoProfile -File scripts/verify.ps1 -Mode Full
```

- `npm ci`: 종료 코드 `0`, 1,219 packages 설치
- 훅 자체 테스트: PowerShell 7과 Windows PowerShell 5.1 모두 종료 코드 `0`, 52/52 사례 통과
- Fast: 종료 코드 `0`, frontend 20개·backend 7개 테스트 통과
- Full: 종료 코드 `0`, 두 workspace build와 Emulator 8개 테스트 통과
- 의도적으로 Node.js 24에서 실행: 종료 코드 `2`, Node.js major 22 전제조건 실패
- 의도적으로 루트 `typecheck`를 `echo ok`로 변경: 종료 코드 `1`, 루트 workspace 위임 계약 검사 실패
- 의도적으로 `src/rogue.ts`와 `functions/src/index.ts` 생성: 각각 종료 코드 `1`, 폐기 디렉터리 검사 실패
- 일반 push 후 GitHub 확인: 원격 브랜치는 `dev`보다 0 commit 뒤·3 commit 앞이며, `dev` 대상 Pull Request와 원격 Actions 실행은 각각 0개. CI는 일반 push가 아니라 Pull Request 또는 수동 실행에서 시작한다.
- 다음 작업자가 가장 먼저 재현할 명령: `pwsh -NoProfile -File scripts/verify.ps1 -Mode Fast`
