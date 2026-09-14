# 일정·지도 백엔드 작업 목록

> 마지막 갱신: 2026-09-14. 담당: 일정·지도 백엔드. 기준: `dev` / `8317a73`.
> **IMB-01 완료.** 원본 개발 clone의 Node 22·Java 21 연결, 의존성 설치와 기준선 검증을 마쳤다. IMB-02는 미착수이며 이번 요청에 포함하지 않는다.

## 작업 규칙

`IMB-*`는 이 담당 폴더 안의 실행 ID다. 팀 공통 TASK/기능 ID를 바꾸지 않는다. 각 작업은 아래 파일 경계와 선행 조건을 따른다. 별도 표시가 없는 한 [SPEC.md](SPEC.md)의 다른 담당·공통 경로는 읽기만 한다. 상태는 미착수·진행·결정 대기·검증 대기·완료 중 실제 상태로 기록한다.

## IMB-00 — 담당 하네스 작성

- [x] 최신 `origin/dev`를 fetch하고 변경 문서를 확인한 뒤 로컬 `dev`를 fast-forward했다.
- [x] 참조 작업 **하네스**와 기존 장소 함수·Flutter 호출자·Rules·테스트 구성을 확인했다.
- [x] `backend/workstreams/itinerary-map/`에 요청한 네 문서를 작성했다.
- 상태: 문서 작성 완료. 제품 테스트·외부 연결·commit·push 완료를 뜻하지 않는다.

## IMB-01 — 실행 환경과 기준선

- [x] 커밋 후보 검증 복사본에서 Node 22·Java 21을 확인하고 루트의 `npm ci`를 실행했다.
- [x] 검증 복사본에서 `npm run verify:full`을 통과했다. `verify:fast`와 `test:emulator`가 포함되며 기준과 결과는 아래 기록을 따른다.
- [x] 원본 개발 clone에서 기존 Node 22.23.2·Java 21.0.11을 실행 세션의 `PATH`·`JAVA_HOME`에 연결하고 루트의 `npm ci`를 종료 0으로 완료했다.
- [x] 원본 개발 clone의 `npm run verify:fast`와 `npm run test:emulator`가 각각 종료 0으로 완료됐다. 검증 복사본·기존 CI와 실행 근거를 따로 기록했다.
- 상태: 완료. 영구 환경 설정은 변경하지 않았으며 새 PowerShell 세션에서는 아래 런타임 연결 명령을 다시 실행한다.
- 선행: IMB-00. 쓰기: 설치 산출물과 이 문서의 실행 기록. package·lockfile·검증 설정을 바꾸지 않는다.
- 완료: 두 검증이 종료 0. 기존 실패나 환경 부족은 경로·메시지·명령을 남기고 미완료로 유지한다.

## IMB-02 — 기존 검색·링크 경계 회귀

- [ ] 정상·빈 검색 결과, 길이 경계, 잘못된 요청 타입과 provider 불일치를 검증한다.
- [ ] 일반 Google URL의 인코딩·빈 검색어·잘못된 도메인·사용자 정보·HTTP·포트·단축 링크 거부를 검증한다.
- [ ] 두 Callable의 미인증·비멤버 거부, 오류 details와 외부 미연결 동작을 확인한다.
- 선행: IMB-01. 쓰기: `backend/src/places/places.test.ts`, 필요 시 같은 폴더의 최소 수정, `backend/tests/emulator/itinerary-map/places.emulator.test.ts`.
- 완료: 의미·경계 테스트가 실제 실행되고 `npm test --workspace backend -- src/places`, `npm run verify:fast`, 해당 Emulator 회귀가 종료 0.

## IMB-03 — 일정·장소·준비 참조와 동시 변경

- [ ] 장소 없는 일정·정상 장소 연결/해제·없는/타 여행 장소 참조를 재현한다.
- [ ] 장소 연결과 삭제, 일정 삭제와 예약 저장, 체크리스트 담당 참여자 참조의 최종 상태를 검증한다.
- [ ] 재정렬 중 동시 추가·삭제·날짜/A·B 이동 시나리오를 정리하고 프론트 담당과 Dart/두 기기 검증 경계를 나눈다.
- [ ] 발견한 결함과 최소 변경안을 IMB-D03으로 공유하고 합의·통합 SHA를 기록한다.
- 선행: IMB-02. 쓰기: `backend/tests/emulator/itinerary-map/references.emulator.test.ts`, 이 폴더의 변경안. Rules·Dart 수정은 통합 담당 소유.
- 완료: 합의된 참조·삭제 정책의 회귀가 통과하고 통합 SHA가 있음. 미합의 결함은 열린 항목으로 남기며 테스트를 skip해 완료 처리하지 않는다.

## IMB-04 — Google 연결·링크 정책 확정

- [ ] Places API·필수 field mask·결과 수·언어·가격·저장/표시 조건을 공식 자료로 확인한다.
- [ ] 환경·secret 관리·timeout·응답 크기·호출 제한·예산과 실제 smoke 범위를 구체화한다.
- [ ] 지원 일반 URL과 단축 링크 목록·redirect 정책·오류 fallback을 공유한다.
- 선행: IMB-02. IMB-03과 독립적으로 조사 가능. 쓰기: SPEC·plan·tasks. 실제 유료 호출·secret 등록·배포는 이 조사에 포함하지 않는다.
- 완료: IMB-D01/D02에 결정 내용·결정자·근거·사용 승인 범위를 기록. 대기 중이면 provider 구현 완료로 표시하지 않는다.

## IMB-05 — 실제 장소 검색 경로 구현

- [ ] 기존 `searchPlaces` 계약과 공통 helper를 재사용하여 승인된 provider 경로를 구현한다.
- [ ] 외부 성공·빈 결과·잘못된 JSON/필수 필드/좌표·통신 실패·timeout·429·설정 오류를 mock으로 검증한다.
- [ ] 미인증/비멤버/유효하지 않은 입력에서 외부 호출 0회, 실패 시 fixture 성공 위장 없음, 저장 부작용 없음을 검증한다.
- 선행: IMB-04의 정책 결정. 쓰기: `backend/src/places/`, 전용 places Emulator 테스트. 새 구현 파일은 필요할 때만 생성한다.
- 완료: SPEC의 응답·오류 기준과 담당 검증 통과. 실제 API smoke는 IMB-07에서 따로 기록한다.

## IMB-06 — 지도 링크 지원 확대

- [ ] 합의한 일반 URL을 실제 입력 fixture로 추가하고 기존 URL 회귀를 유지한다.
- [ ] 단축 URL이 채택되면 매 redirect의 허용 대상·순환·hop 상한·전체 timeout을 검증한다.
- [ ] 위장 호스트·내부 주소·잘못된 인코딩·해석 불가·모호한 장소와 원문 노출을 검증한다.
- 선행: IMB-04·IMB-05. 쓰기: `backend/src/places/`, 전용 places Emulator 테스트.
- 완료: 합의된 URL 표의 성공/실패 사례와 기존 회귀 통과. 채택하지 않은 형식은 거부·직접 입력 경로를 명시한다.

## IMB-07 — 실제 연결·프론트 인계·dev 반영

- [ ] 통합 담당의 공통 변경을 반영하고 최신 dev에서 `npm run verify:full`을 실행한다.
- [ ] 승인된 환경에서 실제 검색·링크 후보와 오류를 확인하고 요청 수·비용 확인 범위를 기록한다.
- [ ] 프론트 담당과 두 Android 기기의 일정·장소·준비 갱신, 재시작·재접속·실패 복구 결과를 확인한다.
- [ ] 입력/반환 예시·지원 URL·오류·재시도·남은 제약·검증 SHA를 인계한다.
- [ ] 현재 승인 범위에 commit·push가 있으면 푸시 직전 원격 확인·필요한 재검증 후 `dev`에 반영하고 CI 결과를 확인한다.
- 선행: IMB-03·IMB-05·IMB-06. 쓰기: 전용 문서와 자신의 검증된 수정. 원격 반영은 별도 실행 권한을 따른다.
- 완료: 자동 검증, 실제 API, 두 기기 QA 증거가 각각 있고 승인된 반영 결과가 기록됨. 배포·main merge는 포함하지 않는다.

## 공통 변경 요청·결정 기록

| ID      | 문제·제안                                            | 관련 경로·담당 영향                                                    | 상태·근거                                         |
| ------- | ---------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------- |
| IMB-D01 | Places 연결 방식·비용·시간/호출 제한 확정            | `src/places`, 필요 시 `.env.example`·Functions 설정. 통합 담당 확인    | 미제출. 현재 실제 provider 미연결                 |
| IMB-D02 | 일반/단축 링크 지원과 fallback 합의                  | `src/places`, Flutter 안내. 통합 담당 확인                             | 미제출. 현재 query/q 일반 URL만 지원              |
| IMB-D03 | 일정 placeId의 실제 참조 검사·참조 중 삭제 경합 정책 | `firestore.rules`, Flutter repository·모델, 정산의 장소/일정 참조 영향 | 미제출. 정적 코드에서 공백 확인, Emulator 재현 전 |

변경 요청 시 문제·재현 입력·기대/실제·제안 diff 범위·검증 명령·결정자를 추가한다. 공유한 날짜와 합의 내용을 실제로 받은 뒤 기록한다. 대화 중 제안 작성과 팀에 전달 완료를 구분한다.

## 싱크·검증 기록

| 날짜       | 항목                      | 실제 결과                                                                                                      |
| ---------- | ------------------------- | -------------------------------------------------------------------------------------------------------------- |
| 2026-09-14 | 원격 동기화               | `git fetch origin dev` 성공 후 `git merge --ff-only origin/dev` 성공. `0146945 → a5cfb0a`, 인계 문서 19개 갱신 |
| 2026-09-14 | 기존 그래프 확인          | 코드 관계 조회 후 원본 확인. 그래프는 `0146945` 기준이므로 새 단계·역할은 `a5cfb0a`의 문서를 직접 읽음         |
| 2026-09-14 | 환경 확인                 | `node --version`: v24.17.0. Java는 PATH에서 찾지 못함. 이 clone에 `node_modules` 없음                          |
| 2026-09-14 | `npm run verify:fast`     | 종료 1. format 단계에서 `prettier` 명령을 찾지 못함. lint·typecheck·단위 테스트에 도달하지 못함                |
| 2026-09-14 | Emulator·실제 API·Android | 이번 문서 작성에서는 실행하지 않음. IMB-01/07의 남은 검증                                                      |

최초 문서 작성 시 기존 로컬 설치의 Prettier 3.9.5로 네 파일 `--check`를 실행해 종료 0을 확인했다. 당시 로컬 링크 12개와 작업 ID 8개의 고유성도 확인했다. 이는 의존성이 없는 현재 clone의 `verify:fast` 통과를 대신하지 않는다. 최초 작성 시점에는 tracked 파일 변경 없이 새 문서 네 파일만 추가했다.

2026-09-14 후속 요청으로 `backend/README.md`를 공통 진입점으로 정리했다. 담당별 코드·문서·새 테스트 위치, 공용 파일 조율 절차와 일정·지도 `AGENT.md`의 적용 범위를 명시하고, 미구현으로 남아 있던 서버 설명을 현재 11개 Callable 기준으로 수정했다. SPEC의 오래된 README 설명도 갱신했다. 정산 담당의 예정 폴더·빈 문서나 테스트는 생성하지 않았으며 제품 코드·공통 API 계약은 변경하지 않았다. 관련 문서 5개의 Prettier 검사와 로컬 링크 33개, 현재 export 11개와 README의 일치 확인은 통과했다. README 정리 시점의 `npm run verify:fast`는 의존성 미설치로 `prettier`를 찾지 못해 종료 1이었으며, 당시 제품 테스트·commit·push는 수행하지 않았다.

2026-09-14 사용자에게 문서 다섯 파일의 commit·dev push 승인을 받았다. 최신 `origin/dev`가 `a5cfb0a`와 일치함을 확인하고, staged tree `69b7db524ea3802f3123e0e5bc011f0f0b1bbaca`를 별도 검증 폴더에 추출했다. `graphify-out/`은 커밋·검증 복사본에 포함하지 않았다. 공식 SHA256을 확인한 Node 22.23.2와 로컬 Java 21.0.11을 사용해 `npm ci`, `npm run verify:full`이 종료 0으로 완료됐다. 단위 테스트 91개(프론트 59·백엔드 32), Emulator 테스트 21개와 Git guard 자체 검사 29개가 통과했다. 이 결과 기록을 후속으로 갱신하고 문서 형식을 다시 검사했다. 실제 Google API·Flutter 실기기 QA는 실행하지 않았다. 당시 원본 clone의 `node_modules` 설치와 런타임 PATH 연결은 남아 있었으며, 아래 원본 실행으로 별도 완료했다.

문서 커밋 `8317a7342d12cf458fc1fe525beaa8ca86526078`의 기존 [push CI](https://github.com/jim361/trip-split/actions/runs/34839539658)와 [PR CI](https://github.com/jim361/trip-split/actions/runs/34839544057)는 모두 성공했다. `verify`와 `flutter-android` 작업의 성공을 이번 세션에서 읽기 전용으로 재확인했다. 이 CI 결과와 앞선 검증 복사본의 `verify:full`은 원본 clone의 설치·검증 기록을 대신하지 않는다. IMB-01 완료를 확인한 당시 세션에서는 새 CI 실행·commit·push·PR 변경을 하지 않았다.

### 2026-09-14 / IMB-01 / 원본 clone 실행

- 기준 SHA: `8317a7342d12cf458fc1fe525beaa8ca86526078`. `git fetch origin dev` 종료 0, `HEAD...origin/dev`의 앞섬·뒤처짐이 `0 / 0`이어서 추가 병합은 필요하지 않았다. 시작 시 tracked·staged 변경은 없고 기존 미추적 `graphify-out/`만 있었다.
- 실행 위치: `C:\Users\Josh\Documents\Codex\2026-09-14\github-dev-dev-x20-x20-flutter\work\trip-split`. 앞선 복사본은 이 경로의 형제 폴더 `../push-validation/repo`다.
- 원인·조치: 기본 PATH의 Node 24와 Java 미연결·의존성 미설치를 해소하기 위해 준비된 런타임을 재사용했다. 제품 코드·package·lockfile·검증 설정은 수정하지 않았고 추적 파일 변경은 이 `tasks.md`뿐이다.

| 명령·확인                                          | 종료 코드·실제 결과                                                                                                                                                     |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `node --version`, `npm --version`, `java -version` | 모두 0. Node 22.23.2, npm 10.9.8, JBR OpenJDK 21.0.11                                                                                                                   |
| `npm ci`                                           | 0. 원본에 1,233개 패키지 설치. `package-lock.json` SHA256은 설치 전후 `5039FD409365148F959101A6AEB4A2E78D785D1CD4B92FA3D56F368748E69947`로 동일                         |
| `npm run verify:fast`                              | 0. format·lint·frontend/backend typecheck 통과, 단위 테스트 91개(프론트 59·백엔드 32) 통과                                                                              |
| `npm run test:emulator`                            | 0. backend 빌드와 Auth·Firestore·Functions의 2개 파일·21개 테스트 통과. `demo-trip-split` 사용, Functions의 `Using node@22 from host` 확인. 종료 후 사용 포트 해제 확인 |
| 로컬 분석 산출물 보존                              | 검증 동안 `graphify-out/`을 형제 경로 `../imb-01-graphify-out`에 임시 보관하고 `finally`에서 원위치 복원. 172개 파일의 상대 경로·SHA256이 모두 일치                     |
| 영구 환경 확인                                     | User/Machine의 `PATH`·`JAVA_HOME` 해시가 실행 전후 동일. 설정은 각 검증 프로세스에만 적용                                                                               |

로컬 근거: [환경·런타임](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone/environment-before.log>), [설치 로그](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone/npm-ci.log>), [verify:fast 로그](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone/verify-fast.log>), [Emulator 로그](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone/test-emulator.log>), [종료 코드](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone/verification-results.log>), [산출물 복원](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-original-clone/graph-preservation.log>). 앞선 복사본 로그는 `../push-validation/npm-ci.log`, `../push-validation/verify-full.log`, `../push-validation/git-guard.log`에 그대로 보존했다.

설치 시 npm audit가 기존 lockfile 기준 취약점 36건(moderate 25·high 11)을 보고했고, Emulator는 `firebase-functions` 업데이트를 권고했다. 설치·검증 실패는 아니며 의존성 변경은 공통 담당의 별도 검토 항목이다. `npm audit fix`나 package 갱신은 실행하지 않았다.

최초 원본 검증에서는 IMB-01에 필요한 `verify:fast`·`test:emulator`를 실행했다. `verify:full`·Git guard 자체 검사는 최초 원본 실행에 포함하지 않았으며 앞선 복사본·기존 CI의 성공 기록과 구분한다. Flutter 로컬 검증·Android 기기 QA·실제 Google API도 실행하지 않았다. 당시에는 IMB-02 구현과 추가 commit·push 없이 IMB-01에서 종료했다.

### 2026-09-14 / IMB-01 / 후속 commit·push 승인과 전체 검증

사용자가 IMB-01 완료 기록의 commit·dev push와 Graphify 갱신을 후속으로 승인했다. 최신 `origin/dev`와 원본 `HEAD`가 `8317a73`으로 일치함을 확인한 뒤, 같은 로컬 Node 22.23.2·Java 21.0.11로 원본의 `npm run verify:full`을 실행해 종료 0을 확인했다. format·lint·타입 검사, 단위 테스트 91개, frontend/backend 빌드와 Emulator 테스트 21개가 통과했다. [전체 검증 로그](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-push/verify-full.log>)와 [종료 코드](<C:/Users/Josh/Documents/ChatGPT/Trip Spilt/outputs/imb-01-push/verification-results.log>)를 별도 보존했다.

검증 중 임시 보관한 `graphify-out/`은 172개 파일의 해시를 대조해 복원했다. 이후 승인된 그래프 갱신은 로컬 분석 산출물에만 반영하며, 커밋 대상은 이 `tasks.md` 한 파일이다. IMB-02 구현·전역 환경 설정·package·lockfile 변경은 포함하지 않는다. 최종 커밋 SHA와 원격·CI 결과는 반영 후 결과 보고 및 로컬 그래프 갱신 기록에서 확인한다.

### 다음 PowerShell 세션의 런타임 연결

원본 저장소 루트에서 다음을 실행한다. 기존 설치를 재사용하며 PowerShell 프로필·사용자/시스템 환경 변수·전역 npm 설정을 바꾸지 않는다. 별도 실행 스크립트도 추가하지 않는다.

```powershell
$nodeDir = (Resolve-Path -LiteralPath '..\validation-tools\node-v22.23.2-win-x64').Path
$env:JAVA_HOME = 'C:\Users\Josh\.jdks\jbr-21.0.11'
$env:PATH = "$nodeDir;$env:JAVA_HOME\bin;$env:PATH"
node --version
npm.cmd --version
java -version
```

`graphify-out/`은 저장소의 공통 format·lint 제외 설정에 등록되지 않은 로컬 분석 산출물이다. 위 기준선 검사처럼 저장소 밖에 임시 보관한 상태로 검증하고 종료 후 복원한다. 산출물에 맞춰 공통 검사 설정을 바꾸거나 산출물을 포맷하지 않는다.

추가 실행은 `날짜 / IMB ID / 기준 SHA / 가설·변경 파일 / 명령 / 종료 코드·관찰 / 다음 조치` 순서로 기록한다. 긴 로그는 팀이 확인할 수 있는 산출물 경로를 연결하며 개인정보·키를 포함하지 않는다.

## 다음 세션 인계 — 여섯 칸

1. **목표:** Phase B 일정·지도 백엔드의 검색·링크와 참조·동시 변경을 안정화한다.
2. **끝난 것:** 담당 하네스·공통 backend README, 검증 복사본의 전체 검증과 `8317a73` 기존 CI 성공. IMB-01 원본 clone의 런타임 연결·`npm ci`·`verify:fast`·Emulator 검증 완료. 제품 코드 수정 없음.
3. **남은 것:** 후속 요청에서 IMB-02부터 진행한다. 이번 요청에서는 착수하지 않는다. Google 환경·URL 정책·장소 삭제 정책은 미정이며 팀에 전달하지 않았다. npm audit의 기존 의존성 취약점은 공통 담당 검토가 남아 있다.
4. **결정과 이유:** 별도 clone의 dev 직접 작업, 기존 `src/places` 재사용, 새 Emulator 테스트는 전용 하위 폴더. 공용 테스트·공통 모델 변경 충돌을 줄인다.
5. **하지 말 것:** 다른 백엔드와 Flutter 코드 덮어쓰기, 공통 계약 독단 변경, 운영 fixture 반환, 테스트 약화, 무승인 원격 반영·유료 호출·secret 등록·배포.
6. **확인 방법:** 저장소 루트에서 위 런타임 연결 명령을 적용하고, `graphify-out/`을 임시 보관한 상태에서 아래 명령을 각각 실행한다. 실패를 무시하고 다음 명령을 계속하지 않으며 종료 후 산출물을 복원한다.

```powershell
git status --short
git fetch origin dev
git log --oneline HEAD..origin/dev
node --version
java -version
# 의존성이 없거나 lockfile이 바뀐 경우에만 npm ci를 다시 실행한다.
npm run verify:fast
npm run test:emulator
```

새 작업에서는 먼저 [AGENT.md](AGENT.md)를 명시적으로 읽고 이 인계의 미완료 항목부터 이어간다. `graphify-out/`은 기존 로컬 분석 산출물이며 제품 변경과 함께 stage하지 않는다.
