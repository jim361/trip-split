# 일정·지도 백엔드 작업 목록

> 2026-09-14 · `dev` / `9437ef29cc02ad7c06f491884fb04993af6cf0b6` · IMB-00~02 완료.
> 다음 작업은 **IMB-03**이다. 사용자 후속 요청으로 IMB-02·문서 압축의 commit·dev push를 먼저 수행하고 새 작업을 재개한다. IMB-03의 후속 commit·push·PR·배포는 별도 승인 범위다.

## 시작 상태와 공통 규칙

- 저장소 루트: `C:\Users\Josh\Documents\Codex\2026-09-14\github-dev-dev-x20-x20-flutter\work\trip-split`. `dev/backend`는 `dev` 브랜치의 `backend/`다. 새 브랜치·dev 하위 폴더를 만들지 않는다.
- 시작 시 루트 `AGENTS.md`, `backend/README.md`, [AGENT.md](AGENT.md), [SPEC.md](SPEC.md), [plan.md](plan.md), 최신 `docs/development-kickoff.md`를 읽는다. 이 파일은 현재 상태·실행 근거이며 공통 계약을 대체하지 않는다.
- 먼저 루트에서 `git status --short`, `git fetch origin dev`를 실행한다. IMB-02 결과 파일은 `src/places/places.test.ts`, `tests/emulator/itinerary-map/places.emulator.test.ts`, 이 폴더의 SPEC·tasks다. 반영 SHA는 새 작업의 재개 메시지·Git 로그로 확인한다. 다른 미커밋 변경과 기존 `graphify-out/`도 보존한다. 자동 stash·덮어쓰기 없이 원격 차이를 확인하고 안전한 경우에만 fast-forward한다.
- Astra / `gpt-6-astra`·`xhigh`가 주도한다. 작은 작업은 직접 처리하고 독립적인 병렬 작업만 Terra / `gpt-5.6-terra`·`high`에 맡긴다. 작업자는 재위임하지 않는다. 설명·인계는 한국어로 작성하고 기존 helper·Node 표준 기능·Vitest를 재사용한다.
- 공통·Flutter·정산·OCR 영역은 읽기만 한다. 공통 변경은 재현·대상 파일·현재/제안 동작·호출자 영향·검증안 → 합의 → 통합 담당 반영 → SHA 확인·재검증 순서다. 메시지·팀 공유 완료를 문서 작성만으로 주장하지 않는다.
- 같은 문제의 근거 있는 수정·재검증 **2회 또는 30분** 중 먼저 도달하면 재계획한다. 결정이 필요한 경로만 보류하고 독립적인 검증은 계속한다. 테스트·fixture·수용 기준을 약화하거나 skip하지 않는다. 기존 TASK·IMB ID를 변경하지 않는다.

## 작업 상태

| ID     | 상태·선행             | 결과 또는 남은 수용 기준                                                                                                                                                                                        |
| ------ | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IMB-00 | 완료                  | 담당 하네스와 backend 안내 정리. 상세 이력은 보존 사본 참조                                                                                                                                                     |
| IMB-01 | 완료 / IMB-00         | 원본 Node 22·Java 21·의존성·기준선 검증 완료. 복사본·원본·CI 근거는 아래에서 구분                                                                                                                               |
| IMB-02 | 완료 / IMB-01         | 입력·URL·권한·provider·운영 미연결 회귀. 장소 단위 91개·전용 Emulator 6개·전체 검증 통과. 제품 코드 수정 없음                                                                                                   |
| IMB-03 | 착수 승인 / IMB-02    | 아래 참조·동시 변경 재현과 IMB-D03 합의·반영 SHA·회귀가 필요. 아직 재현·합의 완료가 아님                                                                                                                        |
| IMB-04 | 미착수 / IMB-02       | 공식 자료로 Places API·필드·결과 수·언어·가격·저장/표시 제약과 환경·secret·timeout·응답 크기·호출량·예산·smoke·URL/redirect 정책을 정한다. IMB-D01/D02 결정자·근거·사용 승인 범위 기록. IMB-03과 독립 조사 가능 |
| IMB-05 | 미착수 / IMB-04       | 승인된 검색 provider 구현과 정상·빈 결과·잘못된 JSON/필수 필드/좌표·통신/timeout/429/설정 오류 mock 회귀. 무효 입력·권한 실패의 외부 호출 0회, 운영 fixture 성공 위장·저장 부작용 없음. 실제 smoke는 IMB-07     |
| IMB-06 | 미착수 / IMB-04·05    | 합의한 일반 URL 확대, 채택한 경우에만 단축 링크의 매 redirect 허용 대상·순환·hop·전체 timeout 검증. 위장 호스트·내부 주소·잘못된 인코딩·해석 불가/모호함·원문 노출 회귀와 기존 사례 유지                        |
| IMB-07 | 미착수 / IMB-03·05·06 | 통합 SHA 뒤 전체 검증, 승인된 실제 검색·링크 smoke와 요청 수/비용, Android 두 기기 갱신·재시작/재접속·복구 증거. wire·오류·재시도·지원 URL·제약 인계. 원격 반영·CI는 별도 승인 범위                             |

IMB-04는 담당 문서만, IMB-05·06은 `src/places/`와 전용 places Emulator 테스트만 쓴다. 실제 API·secret·유료 호출·배포는 단계 착수만으로 승인되지 않는다. IMB-07의 자동 검증·실제 API·Android QA는 각각의 증거가 있어야 완료다.

## IMB-03 — 다음 세션의 실행 범위

쓰기: `backend/tests/emulator/itinerary-map/references.emulator.test.ts`와 `backend/workstreams/itinerary-map/`만. 기존 places 회귀는 보존한다. Rules·index·shared·공용 테스트·모델·계약·package·lockfile·검증 설정과 Dart 변경은 통합 담당 소유다.

- [ ] 장소 없는 일정, 정상 장소 연결/해제, 없는 장소·다른 여행 장소 연결의 허용/거부를 Rules에서 재현한다.
- [ ] 장소 연결↔삭제, 일정 삭제↔예약 저장, 체크리스트 담당 참여자 참조와 대상 삭제/동시 변경의 각 응답·최종 저장 상태를 검증한다. `personal`은 비공개 권한이 아니다.
- [ ] 재정렬 중 동시 추가·삭제·날짜/A·B 이동을 분석한다. 기존 Dart transaction의 호출 방향과 정책을 소스로 확인하고 Firestore 재현·Dart 실행·Android 두 기기 QA의 검증 경계를 나눈다. `Promise.allSettled()`의 종료만으로 성공을 판정하지 않는다.
- [ ] 결함별 재현 입력·기대/실제·영향·최소 변경안·검증안·필요한 결정을 IMB-D03에 기록한다. 참조 중 삭제 거부/명시적 연결 해제 등의 정책을 독단 확정하지 않는다. 단순 `exists()` 추가가 동시 삭제까지 해결한다고 가정하지 않는다.
- [ ] 합의된 정책이 통합 담당에게 반영된 뒤 SHA를 확인하고 회귀를 재실행한다. **미합의 결함은 결정 대기**로 남긴다. 잘못된 허용 동작을 정상 요구사항으로 고정하거나 실패 회귀를 skip해 완료 처리하지 않는다.

착수 목표는 재현·변경안 작성까지 자율 진행하는 것이다. 공통 결정 전에는 해당 경로만 보류하고 IMB-03 전체 완료를 주장하지 않는다. IMB-04 이후 구현·실제 API·배포·commit·push·PR은 이번 인계에 포함하지 않는다.

## 공통 변경 요청·결정

| ID      | 필요한 결정·영향                                                                      | 현재 상태                                                                                     |
| ------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| IMB-D01 | Places API·필드·비용·언어·환경·secret·시간/크기/호출 제한. places와 필요 시 공통 설정 | 미제출·미정. 실제 provider 미연결                                                             |
| IMB-D02 | 일반/단축 URL·redirect·fallback. places와 Flutter 안내                                | 미제출·미정. 현재 q/query 일반 URL만 지원. 표준 HTTPS `:443` 허용, 비표준 포트·단축 링크 거부 |
| IMB-D03 | 같은 여행 장소 참조·참조 중 삭제·동시 연결 정책. Rules·Flutter·정산 참조 영향         | 미제출·미정. 정적 코드에서 검증 공백 확인, Emulator 재현 전                                   |

각 요청에 문제·재현 입력·기대/실제·대상 파일·현재/제안 동작·호출자 영향·검증 명령·원하는 결정·공유/합의 날짜·결정자·반영 SHA를 추가한다. 실제 팀 전송과 문서 제안은 구분한다.

## 검증 근거 요약

모든 결과는 **2026-09-14의 해당 기준 코드**에 대한 것이며 다음 변경의 검증을 대신하지 않는다.

| 범위·기준                                                        | 실제 결과                                                                                                                                                                                                                                                               |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IMB-01 검증 복사본 / `8317a73` 커밋 후보                         | `npm ci`, `verify:full` 종료 0. 단위 91·Emulator 21·Git guard 자체 검사 29개. 원본 실행과 별개                                                                                                                                                                          |
| IMB-01 원본 / `8317a73`                                          | Node 22.23.2·npm 10.9.8·Java 21.0.11, `npm ci`, `verify:fast`, `test:emulator`와 후속 `verify:full` 각각 종료 0. 단위 91·Emulator 21개. 완료 기록은 `305d729`로 commit·push·CI 성공(이전 세션)                                                                          |
| IMB-02 동기화 / `305d729 → 9437ef2`                              | 루트 fetch·fast-forward 성공. npm lockfile 불변·의존성 존재로 `npm ci` 생략. 새 원격의 공용·Flutter 변경 보존                                                                                                                                                           |
| IMB-02 / `npm.cmd test --workspace backend -- src/places`        | 종료 0, 1개 파일·91개. 실제 handler·공통 validator, Firestore 읽기 mock, 외부 fetch 0회. 타입·길이·인증/멤버 순서·provider·운영 unavailable/retryable=false 검증                                                                                                        |
| IMB-02 / 루트 `npm.cmd run dev:backend` 후 별도 터미널 전용 회귀 | `demo-trip-split` Auth·Firestore·Functions 준비 뒤 `npm.cmd run test:emulator:run --workspace backend -- tests/emulator/itinerary-map`: 종료 0, 6개. 경계 길이·단축 URL 보강 후 재실행도 6개 통과. 상시 서버 종료 코드 미관측, 직접 기동한 프로세스 종료·포트 해제 확인 |
| IMB-02 / `npm.cmd run verify:full`                               | 종료 0. 포함된 `verify:fast`의 format·lint·타입·단위 181개(프론트 59·백엔드 122), 양쪽 빌드, Emulator 3개 파일·28개. 별도 fast 중복 실행 없음                                                                                                                           |
| IMB-02 보존·최종 검토                                            | Graphify 202개 파일의 목록·크기·SHA256을 임시 이동·finally 복원 전후 대조해 일치. 포트 해제, Prettier·`git diff --check` 종료 0. 제품 코드·공통 설정 수정 없음                                                                                                          |

IMB-02의 정확한 후보·빈 검색/not-found·URL 인코딩/허용/거부·오류 details/원문 비노출은 두 테스트에 고정했다. 운영 미연결은 handler 단위 검증이며 실제 Google 연결이나 Android QA가 아니다. 추가 commit·push·PR·CI 실행은 없었다.

해결된 실행 문제: 최초 의존성 부재의 검사 실패는 IMB-01 설치로 해결했다. IMB-02에서 Graphify CLI 지연은 JSON 직접 조회, PowerShell의 `HEAD@{1}` 해석·초기 경로/폴더 오류는 명령 수정으로 해결했다. 제품 테스트 실패·재시도 상한 도달은 없었다. 기존 npm audit 36건과 빌드 chunk 크기·firebase-functions 갱신 권고는 공통 담당 후속 검토이며 임의 수정하지 않았다.

근거: [IMB-01 원본 로그](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone>), [IMB-01 후속 전체 검증](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-push/verify-full.log>), [IMB-02 로그·종료 코드·해시](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-02>), [IMB-02 전체 검증](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-02/verify-full.log>), [8317a73 push CI](https://github.com/jim361/trip-split/actions/runs/34839539658), [8317a73 PR CI](https://github.com/jim361/trip-split/actions/runs/34839544057).

중복 이력을 압축하기 전 [tasks.md 원문](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/tasks-compaction-2026-09-14/tasks-before.md>)을 저장소 밖에 해시 일치로 보존했다. 과거 명령·실패·변경 과정이 필요할 때만 열고 매 세션 전체를 다시 읽지 않는다.

### 후속 반영 승인

사용자가 IMB-03 착수보다 IMB-02·문서 압축의 commit·push를 먼저 요청했다. 새 작업은 파일 수정·Emulator 기동 없이 대기함을 확인했다. 원격 `dev`는 `9437ef2`와 같았으며, Node 22·Java 21의 `npm.cmd run verify:full`을 재실행해 종료 0(단위 181·Emulator 28개), Git guard 자체 검사도 종료 0(29개)을 확인했다. Graphify 202개 파일의 목록·크기·해시를 대조해 복원했다. 검증 기록 갱신 뒤 Prettier·diff를 확인하고 담당 네 파일만 반영한다. 실제 커밋 SHA·푸시·CI 결과는 [후속 반영 로그](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-02-push>)와 IMB-03 재개 메시지에 남긴다. 이는 위 최초 IMB-02 실행 당시의 미커밋 기록과 구분한다.

## 런타임·검증·기록

아래 명령은 모두 **원본 저장소 루트**에서 실행한다. 시스템/사용자 환경 변수·프로필·전역 npm 설정은 변경하지 않는다.

```powershell
$nodeDir = (Resolve-Path -LiteralPath '..\validation-tools\node-v22.23.2-win-x64').Path
$env:JAVA_HOME = 'C:\Users\Josh\.jdks\jbr-21.0.11'
$env:PATH = "$nodeDir;$env:JAVA_HOME\bin;$env:PATH"
node --version
npm.cmd --version
java -version
# 의존성이 없거나 npm lockfile이 바뀐 경우에만 npm ci를 실행한다.
# 터미널 A: npm.cmd run dev:backend
# 준비 뒤 터미널 B:
npm.cmd run test:emulator:run --workspace backend -- tests/emulator/itinerary-map
# 상시 Emulator 종료 후 실행한다. verify:fast가 포함된다.
npm.cmd run verify:full
```

- `demo-trip-split`만 사용하며 Emulator 두 개를 동시에 띄우지 않는다. 테스트가 0개면 통과가 아니다. 실패를 무시하고 다음 검증으로 넘어가지 않는다.
- Graphify는 `305d729` 기준이다. 필요한 관계부터 조회하되 CLI가 지연되면 `graphify-out/graph.json`을 직접 읽고 계약·호출 방향은 현재 소스로 확인한다. 전체 인덱스·그림 재생성은 필요 없다.
- 전체 검사 때만 `graphify-out/`을 저장소 밖 임시 경로에 보관한다. 이동 전 원본·대상 절대 경로/충돌 확인, 파일 목록·SHA256 보존, `finally` 복원·해시 대조가 필수다. 공통 제외 설정을 바꾸지 않는다.
- 실행 기록은 `IMB ID / 기준 SHA / 가설·변경 / 명령·종료 코드·테스트 수·관찰 / 다음 판단`으로 짧게 추가한다. 긴 로그·원문은 저장소 밖에 두고 링크한다. 공통 결정 대기는 재현·독립 검증·전체 완료 여부를 구분한다.

## 다음 세션 인계 — 여섯 칸

1. **목표:** 위 IMB-03 체크리스트의 재현·변경안을 진행한다.
2. **끝난 것:** IMB-00~02와 위 검증. IMB-02 반영 커밋을 새 작업의 기준으로 삼는다.
3. **남은 것:** IMB-03 재현·IMB-D03 정책 합의·통합 SHA와 회귀. 실제 API·Android QA는 미실행이다.
4. **결정과 이유:** 기존 clone/dev 직접 사용, 전용 references 테스트와 담당 문서만 수정. 공통 정책은 통합 담당이 결정·반영한다.
5. **하지 말 것:** 다른 변경 덮어쓰기, 공통 파일 독단 수정, 실패 검증 약화, IMB-04 이후 구현, 무승인 원격 반영·secret·유료 호출·배포.
6. **확인 방법:** 위 환경·검증 절차를 따르고 각 응답과 최종 Firestore 상태를 확인한다. 공통 합의·반영 전에는 IMB-03을 완료로 표시하지 않는다.
