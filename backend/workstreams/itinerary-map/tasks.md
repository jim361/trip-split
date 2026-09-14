# 일정·지도 백엔드 작업 목록

> 2026-09-15 · `dev` / `3d9f7e969fb84c008cf35f1802de4254f25e9a06` 반영 후 포맷 후속 수정 · IMB-00~02 완료.
> **IMB-03 서버 구현·검증 및 원격 반영 완료, Flutter 검증 대기.** 첫 CI의 Flutter 포맷 실패를 공식 Dart 3.13.2로 수정했고 87개 파일 재검사가 통과했다. Flutter analyze/test/APK는 후속 CI로 확인하며 실제 Android integration은 미실행이다. IMB-03 전체는 미완료다.

## 시작 상태와 공통 규칙

- 저장소 루트: `C:\Users\Josh\Documents\Codex\2026-09-14\github-dev-dev-x20-x20-flutter\work\trip-split`. `dev/backend`는 `dev` 브랜치의 `backend/`다. 새 브랜치·dev 하위 폴더를 만들지 않는다.
- 시작 시 루트 `AGENTS.md`, `backend/README.md`, [AGENT.md](AGENT.md), [SPEC.md](SPEC.md), [plan.md](plan.md), 최신 `docs/development-kickoff.md`를 읽는다. 이 파일은 현재 상태·실행 근거이며 공통 계약을 대체하지 않는다.
- 먼저 루트에서 `git status --short`, `git fetch origin dev`를 실행한다. IMB-02 결과 파일은 `src/places/places.test.ts`, `tests/emulator/itinerary-map/places.emulator.test.ts`, 이 폴더의 SPEC·tasks다. 반영 SHA는 새 작업의 재개 메시지·Git 로그로 확인한다. 다른 미커밋 변경과 기존 `graphify-out/`도 보존한다. 자동 stash·덮어쓰기 없이 원격 차이를 확인하고 안전한 경우에만 fast-forward한다.
- Astra / `gpt-6-astra`·`xhigh`가 주도한다. 작은 작업은 직접 처리하고 독립적인 병렬 작업만 Terra / `gpt-5.6-terra`·`high`에 맡긴다. 작업자는 재위임하지 않는다. 설명·인계는 한국어로 작성하고 기존 helper·Node 표준 기능·Vitest를 재사용한다.
- 일반 담당 범위에서는 공통·Flutter·정산·OCR 영역을 읽기만 한다. 이번 IMB-03은 사용자의 후속 진행 지시로 필요한 Rules·공통 삭제·정산 참조 쓰기·Flutter repository 변경까지 승인된 예외다. Astra가 통합 검토하며 메시지·팀 공유·원격 반영 완료를 문서 작성만으로 주장하지 않는다.
- 같은 문제의 근거 있는 수정·재검증 **2회 또는 30분** 중 먼저 도달하면 재계획한다. 결정이 필요한 경로만 보류하고 독립적인 검증은 계속한다. 테스트·fixture·수용 기준을 약화하거나 skip하지 않는다. 기존 TASK·IMB ID를 변경하지 않는다.

## 작업 상태

| ID     | 상태·선행                  | 결과 또는 남은 수용 기준                                                                                                                                                                                        |
| ------ | -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IMB-00 | 완료                       | 담당 하네스와 backend 안내 정리. 상세 이력은 보존 사본 참조                                                                                                                                                     |
| IMB-01 | 완료 / IMB-00              | 원본 Node 22·Java 21·의존성·기준선 검증 완료. 복사본·원본·CI 근거는 아래에서 구분                                                                                                                               |
| IMB-02 | 완료 / IMB-01              | 입력·URL·권한·provider·운영 미연결 회귀. 장소 단위 91개·전용 Emulator 6개·전체 검증 통과. 제품 코드 수정 없음                                                                                                   |
| IMB-03 | Flutter 검증 대기 / IMB-02 | 서버 구현·루트 전체 검증 종료 0(단위 181·Emulator 61). 3d9f7e9 원격 반영·CI verify 통과. Dart 3.13.2 포맷 87개 통과. Flutter analyze/test/APK 후속 CI 및 실제 Android integration 대기                          |
| IMB-04 | 미착수 / IMB-02            | 공식 자료로 Places API·필드·결과 수·언어·가격·저장/표시 제약과 환경·secret·timeout·응답 크기·호출량·예산·smoke·URL/redirect 정책을 정한다. IMB-D01/D02 결정자·근거·사용 승인 범위 기록. IMB-03과 독립 조사 가능 |
| IMB-05 | 미착수 / IMB-04            | 승인된 검색 provider 구현과 정상·빈 결과·잘못된 JSON/필수 필드/좌표·통신/timeout/429/설정 오류 mock 회귀. 무효 입력·권한 실패의 외부 호출 0회, 운영 fixture 성공 위장·저장 부작용 없음. 실제 smoke는 IMB-07     |
| IMB-06 | 미착수 / IMB-04·05         | 합의한 일반 URL 확대, 채택한 경우에만 단축 링크의 매 redirect 허용 대상·순환·hop·전체 timeout 검증. 위장 호스트·내부 주소·잘못된 인코딩·해석 불가/모호함·원문 노출 회귀와 기존 사례 유지                        |
| IMB-07 | 미착수 / IMB-03·05·06      | 통합 SHA 뒤 전체 검증, 승인된 실제 검색·링크 smoke와 요청 수/비용, Android 두 기기 갱신·재시작/재접속·복구 증거. wire·오류·재시도·지원 URL·제약 인계. 원격 반영·CI는 별도 승인 범위                             |

IMB-04는 담당 문서만, IMB-05·06은 `src/places/`와 전용 places Emulator 테스트만 쓴다. 실제 API·secret·유료 호출·배포는 단계 착수만으로 승인되지 않는다. IMB-07의 자동 검증·실제 API·Android QA는 각각의 증거가 있어야 완료다.

## IMB-03 — 현재 실행 범위

최초 쓰기 범위는 전용 references 테스트와 담당 문서였다. 후속 진행 지시에 따라 IMB-03 관련 Rules·공통 삭제/정산·Flutter repository·계약·담당 검증으로 확대했다. 기존 places 회귀, package·lockfile·index·검증 설정과 다른 기능은 보존한다.

- [x] 참조 저장과 삭제 경합을 재현하고 참조 중 삭제 거부 정책을 Rules·Callable·정산에 반영했다.
- [x] Flutter 일정·예약 참조 쓰기와 삭제 호출을 같은 계약에 연결했다. 재정렬 권한 오류 재조회는 실제 삭제·이동만 별도 분류하며 조회 실패는 원래 오류를 보존한다.
- [x] 구형 고아 참조 복구·버전 변조·인증·역참조·경합 회귀를 추가했다. 변경 후 전용 Emulator 39개가 통과했다.
- [x] 최종 서버 변경에 대한 루트 `verify:full` 종료 0, 단위 181개·Emulator 61개 통과. Graphify 202개 복원·해시 일치.
- [x] 공식 Dart 3.13.2로 `lib test integration_test test_driver` 87개 파일 포맷을 검사했다. 3개 파일의 줄바꿈 수정 뒤 변경 0개로 통과했다.
- [ ] Flutter analyze/test/APK 후속 CI와 실제 Android SDK integration을 확인한다. 로컬 Flutter SDK와 실행 기기는 아직 확보되지 않았다.
- [x] 사용자 승인으로 `3d9f7e9`를 `origin/dev`에 반영하고 CI를 확인했다. 서버·React verify 통과, Flutter 포맷 실패를 수정하여 후속 반영한다. 기존 push workflow의 Pages mock 배포도 자동 실행됐다.

후속 지시의 목표는 IMB-03 구현·검증과 현재 상태의 Graphify 갱신·commit·dev push다. 미실행 검증이 있으면 IMB-03 전체 완료를 주장하지 않는다. IMB-04 이후 구현·실제 API·수동 배포·PR은 이번 인계에 포함하지 않는다.

## 공통 변경 요청·결정

| ID      | 필요한 결정·영향                                                                      | 현재 상태                                                                                                  |
| ------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| IMB-D01 | Places API·필드·비용·언어·환경·secret·시간/크기/호출 제한. places와 필요 시 공통 설정 | 미제출·미정. 실제 provider 미연결                                                                          |
| IMB-D02 | 일반/단축 URL·redirect·fallback. places와 Flutter 안내                                | 미제출·미정. 현재 q/query 일반 URL만 지원. 표준 HTTPS `:443` 허용, 비표준 포트·단축 링크 거부              |
| IMB-D03 | 같은 여행 장소 참조·참조 중 삭제·동시 연결 정책. Rules·Flutter·정산 참조 영향         | 참조 중 삭제 거부 구현·서버 검증 완료. 3d9f7e9 원격 반영. Dart 포맷 통과, 나머지 Flutter·Android 검증 대기 |

각 요청에 문제·재현 입력·기대/실제·대상 파일·현재/제안 동작·호출자 영향·검증 명령·원하는 결정·공유/합의 날짜·결정자·반영 SHA를 추가한다. 실제 팀 전송과 문서 제안은 구분한다.

### IMB-D03 — 후속 구현과 검증

사용자가 남은 공통 수정·Dart 오류 검증·회귀 설명을 확인한 뒤 **“이어서 진행해”**라고 지시했다. 이 후속 지시를 IMB-03에 필요한 공통 코드와 Flutter 수정·검증의 승인으로 해석하고 진행 상황에 명시했다. 별도 팀 메시지나 통합 담당의 외부 반영을 받은 것은 아니며 commit·push·PR·배포 승인은 아니다. 당시 `e6e7061` 위 변경을 Astra가 통합 검토했고 이후 별도 승인으로 `3d9f7e9`를 반영했다.

**적용 정책:** 장소·일정은 참조 중 삭제를 거부하고 사용자가 먼저 연결을 해제한다. 장소는 일정·지출, 일정은 예약·지출 참조를 검사한다. 데이터/원장의 자동 cascade 삭제는 없다. 참여자 물리 삭제 금지·personal 공유·재정렬 동시 추가 보존은 유지한다.

| 변경                            | 근거·동작                                                                                                                                                                                                                                       | 검증                                                                                            |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Rules·여행 referenceVersion     | 같은 여행 대상 existsAfter, 일정/예약 참조 생성·교체·해제와 연결된 예약 삭제 시 여행 버전 +1 강제. 구형 생략=0, 음수/실수/역행/점프/삭제 거부                                                                                                   | 정상/없는/타 여행 저장, guard 우회, 버전 변조, 기존 고아 참조의 명시적 해제                     |
| deletePlace/deleteItineraryItem | `backend/src/shared/references.ts`. 멤버 재검사·여행 문서 읽기·역참조 limit(1) 조회·버전 증가·삭제를 한 transaction으로 처리. 참조 중 failed-precondition/details.conflict, 없는 대상 멱등 성공. direct delete 차단                             | 연결/삭제 양 순서·병렬·batch, 미인증/비멤버/잘못된 ID, 해제 후 삭제·재삭제                      |
| 정산 양쪽 쓰기                  | `expenses.ts`의 create/update/delete도 같은 여행을 읽고 버전을 증가시킴. 기존 금액·감사·참여자 검사 보존                                                                                                                                        | 참조 중 대상 삭제 거부, 명시적 참조 제거 후 삭제, 지출 생성↔삭제 경합, 원장 삭제 뒤 보호 해제   |
| Flutter repository              | 일정/예약 참조 변경을 위 transaction 계약에 연결, 장소/일정 삭제를 Callable로 변경. 미연결 생성의 기존 직접 저장 경로 유지                                                                                                                      | Flutter 전체 검사와 실제 SDK integration test로 확인                                            |
| 재정렬 오류                     | Raw JS SDK는 삭제-after-read에서 permission-denied/시도1을 반환하며 원자 실패 상태를 엄격 확인. Dart는 권한 오류 때만 server 재조회하여 실제 삭제/이동이 확인되면 notFound/conflict로 안내. 재조회 실패·원인 불명은 원래 오류, 자동 재쓰기 없음 | 기존 실패 진단을 raw SDK와 Dart 검증으로 구분. JS 부분 저장 없음, 실제 Dart 오류·상태 검사 필요 |

여행 하나의 버전으로 참조 쓰기를 직렬화하는 최소 구현이다. 실제 경합이 커지면 대상별 보호 단위로 분리한다는 `ponytail:` 주석을 남겼다. 새 역참조 컬렉션·모델·의존성·검증 설정·index는 추가하지 않았다. `existsAfter`만으로 해결했다고 주장하지 않으며 양쪽 쓰기가 같은 여행 버전에 참여한다. Admin SDK는 Rules를 우회하므로 정산 transaction도 함께 변경했다.

기존 공용 구독 회귀의 장소 연결 fixture 1건은 버전 갱신 batch로 바꿨고 기존 단언을 보존했다. JS 삭제 진단의 잘못된 SDK 자동 재시도 기대는 실제 오류를 엄격 확인하는 검사로 전환하며, Dart notFound 정책은 Flutter의 별도 검사로 유지한다. 고아 예약 일반 수정 거부→해제 복구는 죽은 조건 분기 대신 독립적인 구형 데이터 회귀로 보존했다.

최초 14개 실패 근거·구체적 후보·이전 호출자 분석은 [구현 전 tasks 사본](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/continuation/tasks-before-implementation.md)과 [최초 인계](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/IMB-03-handoff.md)에 보존한다. 현재 계약은 `docs/firebase-api-contract.md`, `docs/frontend-api-handoff.md`, `MarkDown/tech.md`를 갱신했다. 새 Rules·Callable·Flutter를 함께 반영해야 하며 구형 앱의 직접 삭제/버전 없는 연결은 거부된다. 운영 배포는 하지 않았다.

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

### IMB-03 최초 재현 기록 — 구현 전 / `e6e706191c82fc6027331a958a50aff165de9874`

재개 시 `git status --short`는 기존 `graphify-out/`만 미추적이었고 fetch 후 HEAD↔origin/dev는 0/0이었다. 변경은 전용 references 테스트와 이 tasks 문서뿐이다. Node 22.23.2·npm 10.9.8·Java 21.0.11을 세션에만 연결했다. 의존성 존재·lockfile 불변으로 `npm ci`는 생략했다. Graphify는 기존 305d729 그래프를 조회한 뒤 현재 소스로 계약·호출자를 확인했으며 재생성하지 않았다.

| 가설·변경 / 명령                                                                                           | 실제 종료 코드·테스트 수·관찰                                                                                                                                                                                                                         | 다음 판단                                                                                         |
| ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `npm.cmd run dev:backend`                                                                                  | 첫 기동은 Firebase CLI의 로컬 `firebase-tools.json` 읽기 EPERM으로 종료 1. 권한 확장 후 기존 명령 재실행, demo Auth·Firestore·Functions 준비 확인. 상시 프로세스는 Ctrl+C 종료 코드 1, 모든 사용 포트 해제 확인                                       | 설정·프로필·의존성 변경 없이 해결. 실제 외부 API 호출 없음                                        |
| 최초 참조 18건 추가 후 `npm.cmd run test:emulator:run --workspace backend -- tests/emulator/itinerary-map` | 종료 1, 24개 중 실패 13·통과 11(기존 장소 6 포함). 참조 공백 재현                                                                                                                                                                                     | 제품 수정은 소유권·정책 대기. 실패 단언 유지                                                      |
| JS 재정렬 6건·응답/상태 대응 보강 후 같은 명령                                                             | 종료 1, 30개 중 실패 13·통과 17. 예약 병렬에서는 삭제가 먼저 적용되어 참조 거부·정상 상태, JS 삭제 오류는 예상과 다름                                                                                                                                 | 비제어 병렬의 승자는 고정하지 않음. 순서를 고정한 link-first와 batch가 독립적으로 결함을 재현     |
| 삭제 오류 실패 뒤에도 상태를 검사하도록 `expect.soft` 적용, 위 명령에 `--disableConsoleIntercept` 추가     | 종료 1, 30개 중 실패 14·통과 16. 모든 성공/실패 응답 로그 보존. 삭제 오류 단언은 여전히 실패하며 부분 저장 없음까지 확인. 기존 장소 6 통과                                                                                                            | 검증 기준 삭제·skip·완화 없음. 재현 범위·로그 보강이며 공통 결함의 무근거 수정 재시도는 하지 않음 |
| 상시 Emulator 종료 뒤 루트 `npm.cmd run verify:full`                                                       | **종료 1**. 포함된 `verify:fast`의 format·lint·양쪽 타입·단위 181개(프론트 59/백엔드 122), 양쪽 빌드는 통과. 전체 Emulator 4파일·52개 중 **실패 14/통과 38**. 기존 Emulator 28개 전부 통과. 신규 24개 중 10 통과·참조 13건/JS 삭제 오류 진단 1건 실패 | 공통 합의·반영 후 재검증 필요. 별도 verify:fast 중복 실행 없음                                    |
| 전체 검증의 보존·복원                                                                                      | 저장소 밖 검증된 `imb-03/work/graphify-for-verify`로 이동 전 경로·충돌·202개 파일 목록/크기/SHA256 확인. `finally` 복원 뒤 전체 일치. 일회성 Emulator 자동 종료                                                                                       | 공통 제외 설정·Graphify 내용 불변                                                                 |

로그·종료 코드·해시: [IMB-03 검증 폴더](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs), [최종 전용 재현](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/itinerary-map-final.log), [전체 검증](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/verify-full.log). 마지막 코드 변경 뒤 전체 검증을 실행했다. 결과 문서만 갱신한 뒤 담당 파일 Prettier·`git diff --check`와 쓰기 범위를 확인한다. Dart·Flutter 테스트/빌드, Android 두 기기 QA, 실제 Google/API·secret·배포, 이번 결과의 commit·push·PR은 수행하지 않았다.

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

## IMB-03 후속 검증 결과 — 2026-09-15

| 범위·명령                                                                    | 실제 결과                                                                                                                                                      | 판단                                                                              |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 전용 `test:emulator:run --workspace backend -- tests/emulator/itinerary-map` | 첫 구현 36개, 고아 복구·버전 검사 추가 뒤 39개 통과, 각각 종료 0                                                                                               | 기존 places 6개 보존                                                              |
| 최종 서버 변경 뒤 루트 `npm.cmd run verify:full`                             | 종료 0. format·lint·타입·단위 181(React 59/백엔드 122), 양쪽 빌드, Emulator 4파일·61개 통과                                                                    | 참조 신규 33개와 기존 28개 통과. 이후 변경은 Flutter·문서뿐                       |
| Graphify·프로세스 보존                                                       | 202개 파일 경로·크기·SHA256 일치로 finally 복원. 직접 기동한 Emulator Ctrl+C 종료 1, 전체 검증의 일회성 Emulator 정상 종료·포트 해제                           | 설정·index·의존성·lockfile 불변                                                   |
| Flutter 재조회 분류 회귀                                                     | 기존 mapping test에 정상/삭제/날짜·계획 이동/조회 실패/변환 실패 5개 추가. 공개 helper에 reload를 주입하는 단위 검사                                           | 작성만 완료. SDK transaction/mock 검증으로 취급하지 않음                          |
| `npm.cmd run verify:flutter:full`                                            | 종료 1: `dart` 실행 파일 미발견으로 format 이전 중단                                                                                                           | analyze·Flutter test·APK 미실행. ROOT verify:full은 Flutter 검증을 포함하지 않음  |
| Flutter SDK 조사·Android                                                     | PATH·일반 위치·사용자 폴더 실행 파일명 검색에서 SDK 미발견. 사용자도 경로를 모름. 공식 Windows 배포 목록과 확인한 3.47.2 archive 주소는 HTTP 404. 연결 AVD 0대 | SDK를 설치하지 못함. 새 실제 integration 파일은 미실행이며 두 기기 QA 증거가 아님 |

리전 누락 의심은 `index.ts`의 `setGlobalOptions`와 실제 `asia-northeast3` 함수 초기화로 해소되어 중복 설정을 남기지 않았다. 최종 검토에서 재조회 모델 변환을 eager하게 바꾸어 원래 오류를 보존했고, 명시적 null 버전은 생략과 달리 거부한다. 병렬 연결/삭제는 정확히 하나만 성공하도록 검사를 강화했다. 테스트 skip·허용 목록 확대·검증 설정 변경은 없다.

근거와 재개 절차: [후속 결과](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/continuation/IMB-03-result.md), [루트 전체 검증](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/continuation/verify-full.log), [Flutter 환경 조사](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/continuation/flutter-runtime-2026-09-15.log). 기존 첫 재현 로그를 덮지 않았다.

## 다음 세션 인계 — 여섯 칸

1. **목표:** IMB-03의 남은 Flutter 실행 검증을 완료한다. IMB-04 이후로 넘어가지 않는다.
2. **끝난 것:** 참조 중 삭제 거부·버전 보호·Rules·정산·Flutter repository와 회귀 작성. 루트 전체 검증 종료 0, 단위 181·Emulator 61개 통과. Graphify 202개 보존·복원.
3. **남은 것:** Flutter analyze/test/APK 후속 CI 확인, 실제 Android integration 및 읽기 후 삭제 경합의 Dart 오류·최종 상태 검증. 현재 helper 단위 회귀도 미실행이다. 사용자가 승인한 현재 상태의 원격 반영 SHA·CI는 아래 후속 기록으로 확인한다.
4. **결정과 이유:** 사용자의 후속 진행 지시로 필요한 공통 변경을 적용했다. 참조 중 삭제를 거부하며 명시적 해제 후 삭제한다. 여행별 버전으로 양쪽 쓰기를 직렬화하고 원장·다른 문서는 자동 삭제하지 않는다.
5. **하지 말 것:** 다른 변경 덮어쓰기, 실패 검증 약화, IMB-04 이후 구현, 무승인 commit·push·PR·secret·유료 API·배포. SDK 없이 Dart 검증 완료로 표시하지 않는다.
6. **확인 방법:** 원본 dev 작업 트리와 기준 SHA를 확인한다. Flutter SDK를 세션 PATH에 연결해 `npm.cmd run verify:flutter:full`, demo Firebase/기존 AVD에서 `itinerary_references_test.dart`를 실행한다. SDK의 읽기 후 삭제 경합은 추가로 통제하여 확인한다. 서버 코드가 바뀌면 위 Graphify 보존 절차로 루트 전체 검증을 재실행한다.

## 현재 상태의 Graphify·원격 반영 승인 — 2026-09-15

사용자가 Flutter 검증 대기 상태를 확인한 뒤 **“현재 상태까지의 graphify를 업데이트하고 커밋, 푸시해”**라고 지시했다. 이 지시는 현재 IMB-03 변경과 갱신된 Graphify 결과물의 commit·`origin/dev` push 승인이다. 미실행 Flutter 검증을 통과로 바꾸지 않으며 PR·운영 배포·IMB-04 이후는 포함하지 않는다. 기존 `graphify-out/`은 갱신 전 사본을 보존하고 305d729 이후 변경을 증분 추출한다. 생성 캐시·로컬 절대 경로 설정 대신 공유할 그래프 결과물과 재개용 manifest를 반영한다. 시작 fetch 후 HEAD↔origin/dev는 0/0이다. 실제 갱신 규모·검증·commit SHA·push·CI 결과는 [후속 반영 기록](C:/Users/Josh/Documents/Codex/2026-09-14/imb-03/outputs/push/IMB-03-push.md)에 남긴다.
