# 일정·지도 백엔드 실행 계획

> 범위와 계약은 [SPEC.md](SPEC.md), 현재 진행 상태와 기록은 [tasks.md](tasks.md)를 따른다. 이 문서를 만든 것은 제품 구현·유료 호출·commit·push 승인이나 완료를 뜻하지 않는다.

## 1. dev 직접 작업 방식

3명이 각자 별도 clone을 사용하고 파일 소유권을 지키는 현재 팀에서는 `dev` 직접 반영이 가능하다. 같은 브랜치를 쓰더라도 같은 로컬 작업 폴더를 공유하지 않는다. 공통 파일과 공개 계약은 한 명이 최종 통합하고, 각 담당자는 작고 검증된 변경만 반영한다. 기능 브랜치·dev PR을 추가하지 않으며 `main`은 릴리스 PR로 관리한다.

저장소 루트에서 시작한다. 각 명령의 결과를 확인하고 실패하면 다음 단계로 진행하지 않는다.

```powershell
git status --short
git branch --show-current
git fetch origin dev
git log --oneline HEAD..origin/dev
git diff --name-status HEAD..origin/dev
```

브랜치는 `dev`여야 한다. 로컬 변경·앞선 커밋이 없는 상태에서 `git merge --ff-only origin/dev`로 동기화한다. 변경이 있으면 덮어쓰거나 자동 stash하지 않고 먼저 소유자를 확인한다. 로컬의 미푸시 커밋과 원격이 갈라졌다면 양쪽 diff를 읽어 통합한다. 공유된 커밋은 재작성하지 않고, 본인의 미푸시 커밋만 재배치하거나 원격을 merge하는 방식을 상태에 맞게 선택한다.

푸시 직전에도 fetch·원격 diff 확인을 반복한다. 새 변경이 있으면 통합 후 `npm run verify:full`을 다시 실행한다. 일반 push가 non-fast-forward로 거부되면 같은 절차로 돌아간다. force push·`reset --hard`·강제 clean은 사용하지 않는다.

commit과 push는 각각 현재 사용자가 승인한 범위에서만 한다. 승인 후에도 구체적인 파일 경로로 stage하고 `git diff --cached`로 확인한다. `git add .`나 `git add -A`로 다른 작업·`graphify-out/`·비밀값을 섞지 않는다. 반영한 commit SHA와 실제 CI 결과를 기록한다.

## 2. 하네스 배치와 시작 방법

```text
backend/
  workstreams/itinerary-map/
    SPEC.md     요구사항·수용 기준·파일 소유권
    plan.md     순서·검증 명령·공통 변경 절차
    tasks.md    작은 작업·상태·싱크·실패·핸드오프 기록
    AGENT.md    이 담당자의 짧은 실행 지침
  src/places/   기존 구현·단위 테스트 유지
  tests/emulator/itinerary-map/   새 테스트가 필요할 때 생성
```

참조한 Codex 작업 **하네스**(`01a07a09-4e3a-7eb2-bc26-1e1b08171da3`)에서 SPEC → plan → tasks, 짧은 지침, 소유권, 검증 센서, 정지 계약과 여섯 칸 인계를 적용했다. 강의의 Claude 전용 훅·설정·자동 commit은 복제하지 않는다. 기존 npm 검증 진입점이 있어 별도 `verify.ps1`이나 플러그인도 만들지 않는다.

요청한 파일명 `AGENT.md`는 일반 문서다. Codex 기본 발견 이름은 `AGENTS.md`이며, 폴더 안에 두었다는 이유만으로 자동 적용되지 않는다. 루트 공통 지침이나 전역 fallback 설정을 바꾸지 않고 새 작업에서 아래 문구로 명시적으로 읽힌다. 근거: [공식 AGENTS.md 문서](https://learn.chatgpt.com/docs/agent-configuration/agents-md), 2026-09-14 확인.

```text
이 저장소의 일정·지도 백엔드 작업이다. 루트 AGENTS.md와
backend/workstreams/itinerary-map/AGENT.md, SPEC.md, plan.md, tasks.md를 읽어라.
원격 dev와 로컬 상태를 확인한 뒤 tasks.md의 다음 미완료 작업을 진행하라.
쓰기 범위는 SPEC.md의 전용 경로를 따르고 공통 변경은 제안으로 먼저 공유하라.
이번 요청에서 승인된 작업 범위를 확인하고, 실제 실행 결과와 다음 할 일을 tasks.md에 남겨라.
```

시작 확인은 읽은 지침 경로, 선택한 IMB ID, 허용 파일, 검증 명령을 짧게 보고하는 것으로 한다. 문서만으로 자동 발견·강제 차단을 시험한 것으로 기록하지 않는다.

## 3. 구현 순서

1. **기준선 재현 — IMB-01.** Node 22·Java 21을 준비하고 루트에서 `npm ci`, `npm run verify:fast`, `npm run test:emulator`를 실행한다. 기존 실패는 변경 전 실패로 기록한다.
2. **기존 경계 회귀 — IMB-02.** `places.ts`의 모든 호출자와 기존 테스트를 읽는다. URL·입력·권한·빈 결과·미연결 오류의 성공/실패 fixture부터 보강한다. 정상 입력→후보→Flutter 변환을 첫 연결 경로로 유지한다.
3. **무결성 재현·합의 — IMB-03.** 전용 Emulator 파일에서 장소 참조, 준비 참조, 두 클라이언트 경합을 재현한다. 잘못된 참조를 허용하는 현상을 정상 요구사항으로 고정하지 않는다. 재현 결과와 최소 Rules/계약 변경안을 먼저 기록한다.
4. **연결 정책 확정 — IMB-04.** 사용할 Google Places API·필드·언어·결과 수·가격·저장/표시 제약·환경·키 관리·할당량을 공식 자료로 확인하고 통합 담당과 결정한다. API 선택과 구체적인 제한 값은 아직 확정되지 않았다.
5. **검색 연결 — IMB-05.** 기존 handler 안의 샘플/provider 경계를 최소 변경한다. Google 성공·빈 결과·잘못된 응답·장애·timeout·quota를 mock 응답으로 검증한다. 외부 연결 승인 전에는 실제 호출하지 않는다.
6. **링크 확대 — IMB-06.** 지원이 합의된 일반 장소 URL부터 구현하고 단축 URL은 허용 호스트와 redirect 제한이 확정된 경우에만 구현한다. SSRF·모호한 장소 선택·redirect 실패를 같은 테스트에 포함한다.
7. **통합·완료 검증 — IMB-07.** 공통 변경의 반영 SHA를 받은 뒤 회귀를 재실행한다. 승인된 환경의 Google smoke와 프론트 담당의 두 Android 기기 QA를 함께 확인하고, 승인된 범위에서 dev 반영·CI 결과를 기록한다.

한 번에 한 IMB 작업을 진행한다. 외부 환경 결정을 기다리는 동안 기존 입력·URL 회귀 등 독립 작업은 계속할 수 있다. Rules 변경안과 Google 연결안의 결정은 별개로 관리한다.

## 4. 검증 명령과 판정

아래 명령은 모두 저장소 루트에서 실행한다. package에 이미 있는 script만 사용하며 전용 테스트 경로는 기존 Vitest glob이 재귀적으로 발견한다. 해당 테스트 파일을 만든 뒤 좁은 명령을 사용한다. 테스트가 0개인 실행은 통과로 기록하지 않는다.

| 목적              | 명령                                         | 통과 기준                                           |
| ----------------- | -------------------------------------------- | --------------------------------------------------- |
| 환경              | `node --version`, `java -version`            | Node 22.x·Java 21                                   |
| 최초 설치         | `npm ci`                                     | 종료 0, lockfile 변경 없음                          |
| 장소 단위 회귀    | `npm test --workspace backend -- src/places` | 의도한 테스트가 실행되고 종료 0                     |
| backend 타입      | `npm run typecheck --workspace backend`      | 종료 0                                              |
| 작업 중 공통 검사 | `npm run verify:fast`                        | format·lint·typecheck·전체 단위 테스트 종료 0       |
| 전체 Emulator     | `npm run test:emulator`                      | backend 빌드와 Auth·Firestore·Functions 회귀 종료 0 |
| dev 반영 전       | `npm run verify:full`                        | 빠른 검사·빌드·Emulator 모두 종료 0                 |
| 프론트 통합 증거  | `npm run verify:flutter:full`                | 프론트 담당의 실행 결과·대상 SHA 확인               |

전용 Emulator 회귀를 빠르게 볼 때는 두 터미널에서 실행한다. 전체 반영 검증을 대체하지 않는다.

```powershell
# 터미널 A: 기존 script가 backend 빌드 후 demo-trip-split Emulator를 시작한다.
npm run dev:backend
```

```powershell
# 터미널 B: A의 기동 완료 후 실행한다.
npm run test:emulator:run --workspace backend -- tests/emulator/itinerary-map
```

두 Emulator 실행을 동시에 띄우지 않는다. 기존 테스트가 `demo-trip-split` 데이터를 초기화하므로 개발용 데이터도 재사용하지 않는다. 실제 Firebase 프로젝트를 테스트 대상으로 지정하지 않는다.

문법 센서는 format·lint·typecheck, 의미 센서는 알려진 입력의 정확한 후보·오류·저장 결과, 경계 센서는 비멤버·잘못된 URL·quota·timeout·경합 결과다. `Promise.allSettled()`의 종료 여부만 보지 않고 최종 저장 상태와 각 응답을 확인한다. Dart 코드 실행 없이 Flutter의 동작까지 검증했다고 쓰지 않는다.

실패한 테스트를 삭제·skip하거나 validator·fixture를 약화하지 않는다. 결함 재현으로 빨간 테스트가 생기면 관련 수정과 함께 통과시켜 반영한다. 공통 변경이 아직 합의되지 않았다면 실패 근거를 기록하고 그 작업의 완료·push를 보류한다.

## 5. 공통 변경 제안과 정지 계약

공통 파일은 고치기 전에 `tasks.md`의 변경 요청란에 다음을 기록한다: 문제·재현, 대상 경로, 현재/제안 동작, Flutter와 다른 백엔드 영향, 검증 명령, 원하는 결정. 통합 담당과 관련 담당의 합의 후 담당자가 해당 변경을 반영하고 SHA를 공유한다. 이 문서 작성은 실제 팀 메시지 전송을 대신하지 않는다.

각 구현 작업의 정지 계약은 다음과 같다.

- **달성:** 해당 IMB 수용 기준과 검증 명령이 통과하고 실제 결과가 기록됨. 미실행 검사는 남은 작업으로 표시.
- **상한:** 같은 문제는 근거 있는 수정·재검증 2회 또는 해당 시도 30분 중 먼저 도달하는 시점에 원인·남은 선택지를 정리하고 재계획. 무기한 반복하지 않음.
- **즉시 공유:** 소유권·공개 계약·무결성 정책 결정이 필요하거나 접근·환경·정보가 없을 때. 외부 결정을 기다리는 경로만 멈추고 독립 작업은 계속 가능.
- **보호:** SPEC의 다른 담당/공통 영역, 비밀값, 운영 데이터, 기존 테스트 기준, 원격 히스토리. 이미 합의된 변경은 해당 합의 범위에서 진행.
- **기록:** IMB ID, 가설, 바꾼 파일, 명령·종료 코드, 의미 검증 결과, 남은 불확실성. 같은 실패가 반복되면 컨텍스트·검증 체계·구현 추론 중 원인을 분류하고 필요한 규칙 한 줄이나 회귀 하나만 추가.

## 6. 초기 결정 대기

| ID      | 결정할 내용                                                       | 담당·반영 조건                                                          |
| ------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------- |
| IMB-D01 | 실제 Places API·필드·비용·언어·환경·secret 방식·timeout·호출 제한 | 일정·지도 담당 제안 → 통합 담당과 공유, 실제 환경 사용은 승인 범위 확인 |
| IMB-D02 | 일반/단축 링크 지원 목록, redirect hop·응답 크기·전체 시간 제한   | 일정·지도 담당 제안 → 프론트의 안내·fallback과 일치시킴                 |
| IMB-D03 | 장소 참조 검사와 참조 중 삭제·동시 연결 정책                      | 일정·지도 담당 재현 → 통합 담당 최종 결정, 지출 영향은 정산 담당 확인   |

세 항목은 미정이며 수용 기준을 축소하기 위한 예외가 아니다. 결정 후 SPEC·tasks의 관련 항목을 함께 갱신한다.
