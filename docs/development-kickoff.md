# 3인 개발 시작 안내

> 2026-09-14. 사용자 1명이 프론트·공통·통합, 두 팀원이 일정·지도 백엔드와 정산·영수증 백엔드를 맡는다. 기능 ID와 기존 파일·Firestore ID는 유지한다.

## 시작 기준

- 기준 문서: [작업 인덱스](../MarkDown/task/tasks.md), [기술 계약](../MarkDown/tech.md), [현재 API 연결 상태](firebase-api-contract.md).
- 이 문서의 첫 작업들은 **미착수 작업**이다. 공통 Auth·여행 공유 3개 함수, mock 앱과 repository가 준비되어 있으며 검색·지출·OCR 서버는 앞으로 구현한다.
- 첫 통합 목표는 실제 외부 API 없이 Emulator에서 두 사용자가 일정과 수동 지출을 공유하는 것이다. P0 수동 equal/custom 이후 P1 itemized·OCR를 진행한다.
- 새 팀원은 최신 `dev`를 받아 이 안내와 담당 Issue의 완료 기준을 확인하고 첫 작업을 시작한다.

### 준비 변경 검증 (2026-09-14)

- `npm run verify:full` 통과: React 59개, backend 27개, Firebase Emulator 13개 테스트와 build.
- `npm run verify:flutter:full` 통과: Flutter 85개 테스트, 정적 분석·포맷과 Android debug APK build.
- 추가 회귀 검증: 로그인 UID별 개인 금액, 미연결 사용자 안내, 비활성 참여자의 기존 지출, 실제 날짜·윤년·연도 범위·역전된 여행 기간 거부.
- GitHub `main`·`dev` 보호 설정과 기존 팀원 2명의 write 권한을 확인했다. 첫 Issue 3개와 PR #4의 범위는 아래 GitHub 운영 항목에서 확인한다.
- 이 검증은 준비 변경에 대한 결과다. 장소·지출·OCR backend 구현 완료나 실제 서비스 배포를 뜻하지 않는다.

## 담당과 충돌 방지

| 담당                     | 직접 구현할 영역                                                                                                         | 첫 작업                                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| 사용자: 프론트·공통·통합 | 전체 `frontend/`, Dart 정산 엔진·지도 SDK·repository, `backend/src/share`, `backend/src/shared`, 공통 설정·CI·Rules 통합 | TASK-04 Android 일정 CRUD를 mock으로 완성한 뒤 TASK-06 수동 지출 UI·Dart equal/custom과 서버 adapter 연결 |
| 일정·지도 백엔드         | `backend/src/places`, 관련 backend 테스트, 일정·장소·준비 Rules/index 변경안                                             | TASK-03 mock 기반 `searchPlaces`·`parsePlaceLink`                                                         |
| 정산·영수증 백엔드       | `backend/src/settlement`, `backend/src/ocr`, 관련 backend 테스트                                                         | TASK-06 equal/custom validator와 지출 CRUD Callable                                                       |

`backend/src/index.ts`, `firestore.rules`, `firestore.indexes.json`, 공통 모델과 lockfile은 공유 파일이다. 서버 담당이 필요한 변경안을 준비하고 사용자가 통합한다. 서로의 작업을 덮어쓰지 않도록 변경 범위와 반영 순서를 공유한다. 테스트는 각 도메인 파일로 추가하고 기존 공유 테스트를 복사해 대체하지 않는다.

## 처음 한 번 실행

각자 별도 clone을 사용한다. 같은 폴더를 여러 명이 동시에 편집하지 않는다.

```bash
git clone --branch dev https://github.com/jim361/trip-split.git
cd trip-split
node --version
java -version
npm ci
npm run verify:fast
npm run test:emulator
```

Node.js 22·Java 21이 필요하다. 백엔드 담당은 Flutter·Android SDK 없이 위 검증으로 시작할 수 있다. 사용자 환경에는 Flutter 3.47.2·Android SDK도 준비한다.

```bash
cd frontend
flutter pub get
flutter run
```

mock이 기본이다. Android Emulator에서 Firebase를 확인할 때만 별도 터미널의 루트에서 `npm run dev:backend`를 실행하고, `frontend`에서 `flutter run --dart-define-from-file=dart_defines.example.json`을 사용한다. 서버 주소는 `10.0.2.2`, 프로젝트는 `demo-trip-split`이다. React Pages는 `VITE_DATA_SOURCE=mock`을 유지한다.

## 일정·지도 백엔드 첫 작업 — TASK-03

읽을 파일: [장소 Task](../MarkDown/task/task_function3_places.md), `backend/src/shared/callable.ts`, `backend/src/shared/input.ts`, `frontend/lib/features/places/place_provider.dart`.

- [ ] `searchPlaces({ tripId, query }) → PlaceCandidate[]`, `parsePlaceLink({ tripId, url }) → PlaceCandidate`를 구현한다.
- [ ] `requireAuth`·`requireTripMember`와 공통 오류 wire를 재사용한다. 무인증·비멤버는 provider 호출 전에 거부한다.
- [ ] 기존 도쿄 mock의 의미를 공유하는 서버 mock provider로 성공·빈 결과·지원하지 않는 링크·provider 실패를 재현한다.
- [ ] `PlaceCandidate`의 provider/source·이름·좌표 계약을 맞추고 여행의 지도 provider와 혼합하지 않는다.
- [ ] 일반 Google Maps URL의 지원 형식을 명시한다. 임의 URL fetch·무제한 redirect는 구현하지 않고 단축 URL은 지원 정책 확정 전 오류로 돌려준다.
- [ ] Emulator에서 두 멤버 성공, outsider 거부, query/url 오류, 실패 wire를 테스트한다. 실제 Google API는 이 단계에 호출하지 않는다.

인계물: handler·mock·테스트, 실제 JSON 요청/응답 예시, 실패 예시와 Flutter adapter가 연결할 함수 목록. 완료되면 사용자가 Flutter adapter를 붙인다. 다음은 TASK-04 일정·준비 저장 검증이며, 지도 핀·동선·SDK는 사용자 영역이다.

## 정산·영수증 백엔드 첫 작업 — TASK-06

읽을 파일: [정산 Task와 확정 wire](../MarkDown/task/task_function6_settlement.md), `backend/src/shared/callable.ts`, `backend/src/shared/input.ts`, `frontend/lib/domain/models.dart`, `frontend/lib/domain/repositories.dart`.

- [ ] 순수 TypeScript validator로 KRW/JPY 최소 단위 정수, payer=total, 배분 합계·집합·중복·음수 부담액을 검증한다. JavaScript 금액은 `Number.isSafeInteger`도 확인한다.
- [ ] P0 equal/custom의 성공·실패 fixture를 만든다. 10,000/3 → 3,334·3,333·3,333, 1/3 → 1·0·0 예시를 Flutter와 공유한다.
- [ ] `createExpense`, `updateExpense`, `deleteExpense`를 TASK-06 wire대로 구현한다. Auth·멤버·같은 여행의 Participant·장소·일정 참조와 server timestamp를 검증한다.
- [ ] 수정에서는 기존 비활성 참여자를 유지할 수 있고 새 비활성 참여자는 추가할 수 없게 한다. 삭제된 지출 재삭제는 성공 처리한다.
- [ ] P0에서 itemized/OCR draft는 거부한다. 아직 검증하지 않는 형식을 저장하지 않는다.
- [ ] Rules의 지출 직접 쓰기 차단을 유지한다. 두 멤버의 create/update/delete·실시간 읽기, outsider·금액 변조·감사 필드 변조·잘못된 참조를 Emulator로 검증한다.

인계물: validator·handler·테스트, Flutter와 같은 성공/실패 JSON 예시. 사용자가 `FirestoreTripRepositories`의 쓰기 메서드를 Callable로 바꾼다. 다음 작업은 itemized이며 TASK-07 OCR는 그 뒤에 연결한다.

## 사용자 첫 작업 — TASK-04, 다음 TASK-06

- [ ] Android에서 장소 없는 일정도 추가·수정·삭제하고 장소 연결·해제를 지원한다.
- [ ] `planId/date`별 수동 order와 지도 핀 순서를 일치시키고 재정렬은 batch로 저장한다.
- [ ] mock 저장·입력 오류·중복 제출·키보드·뒤로 가기를 Widget 테스트로 확인한다.
- [ ] 다음으로 수동 equal/custom 지출 폼과 Dart validator·개인 계산을 구현한다. 로그인 UID와 정산 Participant ID를 혼용하지 않는다.
- [ ] 백엔드가 인계한 wire로 Callable adapter를 연결한다. expense 직접 쓰기 차단을 해제해 우회하지 않는다.

예약·체크리스트, 내 여행 목록, 참여자 계정 연결, 실제 지도 SDK, 백업과 OCR는 다음 작업 목록이다. 이 기능이 이미 완성됐다고 표시하지 않는다.

## 반영과 완료 기준

1. 작업 전과 push 직전 `git fetch origin dev`로 확인한다. 작업 시작 시 깨끗한 clone에서는 `git pull --ff-only origin dev`로 동기화한다. 로컬 커밋과 원격이 갈라졌으면 강제 덮어쓰지 않고 원격 변경을 통합한 뒤 재검증한다.
2. 한 번에 하나의 TASK 범위로 작업한다. `npm run verify:fast`, 반영 전 `npm run verify:full`을 통과한다. Flutter 변경은 `npm run verify:flutter:full`까지 통과한다.
3. 일반 변경은 최소 한 명에게 공유하고 공통 타입·Firestore 경로는 나머지 두 명도 검토한다. Codex의 commit·push·PR 작업은 AGENTS.md에 정한 명시적 승인을 따른다.
4. `dev`에 직접 반영하고 CI 성공을 확인한다. `dev` 대상 기능 PR은 만들지 않는다. `main`은 검증된 `dev`의 릴리스 PR만 사용한다.
5. 첫 통합은 두 사용자가 같은 여행에서 일정과 equal/custom 지출을 바꾸고 다른 사용자의 화면이 갱신되는 것으로 확인한다. backend 테스트 성공과 Android 연결 완료를 구분한다.

## 팀원에게 전달할 시작 문구

일정·지도 백엔드:

> 최신 dev와 개발 시작 안내를 확인하고 TASK-03의 searchPlaces·parsePlaceLink를 공통 Auth/member guard와 mock provider로 구현해 주세요. 서버 함수·정규화·Emulator 테스트를 맡고 Flutter 화면·지도 SDK·client adapter는 제가 맡습니다. 실제 유료 API는 아직 연결하지 말고 성공·빈 결과·오류 JSON과 검증 결과를 인계해 주세요.

정산·영수증 백엔드:

> 최신 dev와 TASK-06의 확정 wire를 확인하고 equal/custom validator와 지출 CRUD Callable부터 구현해 주세요. 서버 검증·참여자 참조·Emulator 테스트를 맡고 Flutter UI·Dart 엔진·client adapter는 제가 맡습니다. Rules 직접 쓰기 차단은 유지하고 itemized와 OCR는 P0 수동 지출 통합 후 진행합니다.

## GitHub 운영

2026-09-13에 등록한 첫 작업입니다. 담당자 계정 대신 역할을 본문에 기록했으며 최신 `dev`에서 각 Issue 기준으로 시작합니다.

| 담당               | GitHub Issue                                                                     |
| ------------------ | -------------------------------------------------------------------------------- |
| 일정·지도 백엔드   | [#16 TASK-03 검색·링크 Callable](https://github.com/jim361/trip-split/issues/16) |
| 정산·영수증 백엔드 | [#17 TASK-06 검증·지출 저장](https://github.com/jim361/trip-split/issues/17)     |
| 사용자             | [#18 TASK-04 Flutter 일정 CRUD](https://github.com/jim361/trip-split/issues/18)  |

- Issue는 기존 TASK ID를 제목에 사용하고 담당 역할·범위·완료 테스트를 적는다. 같은 TASK에 서버와 프론트 Issue가 있어도 원래 ID를 재번호하지 않는다.
- `main`: PR, 1인 승인, `verify`·`flutter-android` CI 통과, 대화 해결을 요구한다. `dev`: 직접 push를 허용하고 강제 push·브랜치 삭제를 차단한다.
- 기존 PR #4는 `dev → main` 릴리스 PR이다. 개발 중인 기능이 완료됐다고 설명하지 않으며 merge는 출시 판단과 별도 승인 후 수행한다.

### PR #4 제목과 설명

제목: **Flutter Android 개발 기반과 3인 협업 준비**

본문:

> 기존 웹 목업 중심 구조에서 Flutter Android 앱과 Firebase backend 개발 기반으로 전환합니다. React/Vite는 GitHub Pages mock으로 보존합니다. 익명 인증·여행 생성·공유·입장, mock/FlutterFire repository, 일정·지도 표시 모델과 정산·OCR 계약을 포함합니다.
>
> 3인 역할을 프론트·공통·통합 1명과 일정·지도/정산·영수증 백엔드 2명으로 명확히 합니다. 로그인 UID별 개인 정산과 실제 날짜·여행 기간 검증을 수정하고, 지출 API wire·담당별 첫 작업·완료 기준을 정리합니다.
>
> 검증은 `npm run verify:full`과 `npm run verify:flutter:full`로 수행합니다. 장소 검색·지출 CRUD·OCR 서버, Android 도메인 전체 통합과 실제 Firebase 운영 연결은 미완료이며 이 PR을 제품 출시 완료로 간주하지 않습니다. `main` merge는 별도 출시 검토·승인 후 수행합니다.
