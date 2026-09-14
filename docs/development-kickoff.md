# 3인 개발 시작 안내

> 2026-09-14 단계 재점검. 현재 팀의 착수 범위는 Phase B(P0)다. 화면·mock·서버 함수의 선행 구현과 해당 단계의 실기기·외부 연결 완료를 구분한다. 기존 TASK/기능 ID와 Firestore ID는 유지한다.

## 먼저 확인할 것

- [화면·API 인계](frontend-api-handoff.md): 화면 제작 순서, 구현된 13개 Callable, 준비 데이터 wire, 오류와 재시도.
- [Firebase 연결 감사](firebase-api-contract.md): 구현/Emulator와 실제 외부 연결 구분.
- [시트 내보내기](sheet-export.md): 고정 샘플, 구현된 Flutter 출력·미리보기·OAuth 생성·복구 코드와 실제 연결 전 검증 항목.
- [2026-09-14 추가 통합](integration-update-2026-09-14.md): Google 지도 adapter·시트 출력·구독 상태와 공통 계약 검증. 실기기 QA는 사용자 요청으로 이번 작업에서 제외했다.
- [Android 두 앱 검증](android-emulator-qa.md): 실제 Flutter 앱 두 개의 공유·일정·equal 지출 갱신·오프라인·재접속·재시작 통과 기록과 재현 절차. 전체 도메인·실기기 QA와 구분한다.
- [작업 인덱스](../MarkDown/task/tasks.md), [기술 계약](../MarkDown/tech.md), [작업 공유·캡처](development-update-2026-09-14.md).
- 일정 CRUD·길게 끌어 재정렬, 수동 비용, 장소, 준비, 참여자, 개인 정산, 여행 설정·공유, itemized/OCR 검토까지 Flutter에 연결했다. 동일 기능을 처음부터 다시 만들지 않고 최신 dev의 구현을 읽고 이어서 작업한다.

## 개발 단계와 현재 위치

제품의 P0/P1/P2는 기능 우선순위이고 Phase A~D는 실행 순서다. [요구사항](../MarkDown/requirements.md)과 [작업 인덱스](../MarkDown/task/tasks.md)를 기준으로 기존 Android 전환 단계의 의미를 통일한다. 과거 문서의 `MVP` 표시는 채택 여부이며 지금 모두 착수하거나 구현이 완료됐다는 뜻이 아니다.

| 단계                           | 범위                                                                                                             | 현재 상태와 다음 단계 조건                                                                                                                                                    |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Phase A · 개발 기반            | TASK-01과 TASK-02의 앱 셸·mock·Auth·여행 생성/공유·Emulator                                                      | 기반 구현과 2026-08-30 Android 여행 생성/참여 smoke 기록이 있다. 새 담당자는 로컬 실행을 재현하고 B로 합류한다. 전체 도메인 두 기기 QA 기록은 아니다.                         |
| Phase B · 핵심 여행 기능(P0)   | TASK-02~06의 공유·설정·기본 내 여행 목록·장소·일정·지도·최소 준비·수동 equal/custom 정산, 안정화 뒤 TASK-08 백업 | **현재 단계.** 주요 코드·Emulator 검증은 있으며 실제 Google 지도/검색, 두 Android 클라이언트 전체 QA와 백업/복원은 남아 있다. 아래 B 완료 조건을 함께 확인한 뒤 C에 착수한다. |
| Phase C · 확장과 출시 품질(P1) | TASK-06 itemized·조정, TASK-07 촬영·OCR·번역, TASK-02 Google 계정 연결/복구 검증, TASK-09 출시 품질              | 일부 화면·validator·OCR 샘플은 선행 구현됐다. 회귀는 유지하되 실제 OCR 비교·연결을 현재 담당자의 필수 작업으로 배정하지 않는다.                                               |
| Phase D · 후속(P2/미채택 후보) | Web·iOS·NAVER·실제 경로/이동 시간·활동 기록·고급 정산·가져오기, D-day/오늘 일정·Gemini 후보                      | 기능별 채택과 범위를 다시 정한 뒤 시작한다. 날짜 카드와 LLM을 같은 필수 기능으로 묶지 않는다.                                                                                 |

실제 Firebase·Google API 설정, secret·유료 호출·배포는 단계에 도달했다는 이유로 자동 승인되지 않는다. 개발은 mock/Emulator로 진행하고 실제 연결에 필요한 환경·범위를 먼저 공유한다. **Google 지도·장소 검색은 B, OCR·번역은 C**이므로 둘을 한 묶음의 다음 작업으로 지시하지 않는다.

### Phase B 완료 조건

- [ ] 두 Android 클라이언트가 서로 다른 익명 UID로 같은 여행에 참여하고 본인 Participant를 중복 없이 연결한다.
- [ ] 장소 없는 일정·장소 연결/해제·날짜/A·B별 드래그 순서를 저장하고 상대 화면과 지도 번호·직선 동선에서 같은 순서를 확인한다. 편집 후 날짜·A/B·지도 확대 상태가 유지된다.
- [ ] 최소 예약·체크리스트와 참여자·여행 설정 변경이 상대 기기에 반영되고 앱 재시작 뒤에도 유지된다. `personal`은 멤버 공유 분류이며 비공개 기능이 아니다.
- [ ] equal/custom 지출 CRUD, 금액·배분·참조·권한 검증과 통화별 paid/owed/net·송금 문구가 일치한다. 비활성 참여자의 과거 내역은 유지한다. Dart 계산은 사용자, 서버 검증은 정산 담당이 맡는다.
- [ ] 저장 실패·응답 유실·중복 제출·동시 수정과 비행기 모드/재접속을 확인한다. 캐시·대기·서버 완료·실패를 구분하고 Callable 지출 생성에 오프라인 큐나 자동 재생성을 약속하지 않는다.
- [ ] 승인된 환경에서 실제 Google 장소 검색과 Android 지도 adapter를 확인한다. 검색/링크 실패 시 직접 입력을 유지하고 Routes API·이동 시간 자동 계산은 추가하지 않는다. 연결 전에는 B 완료로 표시하지 않는다.
- [ ] 핵심 데이터 계약 안정화 뒤 TASK-08의 `.trip.json` 파일 저장·선택·새 여행 복원을 검증한다. 지원하는 schema v1 범위와 미포함 데이터를 안내하며 기존 원장을 덮어쓰지 않는다. 실제 Firebase 복원 검증은 승인된 환경에서 한다.
- [ ] Node 22·Java 21의 `npm run verify:full`과 `npm run verify:flutter:full`을 통과하고 Android Emulator·실기기 확인 결과를 남긴다. 자동 테스트 통과만으로 두 기기 QA를 완료 처리하지 않는다.

### Phase C 완료 조건

- [ ] B 완료 기록을 먼저 확인한다. 기존 itemized·OCR mock·검토 화면은 삭제하거나 테스트를 약화하지 않고 이어서 사용한다.
- [ ] itemized 소비자 배분, 할인·봉사료·조정 합계와 저장 후 정산을 Android 두 클라이언트에서 확인한다.
- [ ] 일본어 fixture로 OCR·번역 provider의 정확도·비용·보관 정책 기준을 정하고 승인된 환경에서 비교·연결한다. CLOVA나 특정 Google 모델로 미리 고정하지 않는다.
- [ ] 카메라·Photo Picker, 이미지 디코딩·크기·timeout·호출 제한, 원문/번역 검토와 오류 시 수동 총액 입력을 확인한다. 확인 전 저장하지 않고 이미지·미확정 초안은 영구 저장하지 않는다.
- [ ] 선택적 Google 계정 연결의 UID 유지·여행 접근 복구와 익명 세션 소실 안내를 검증한다. 기본 내 여행 목록은 B에 이미 구현된 기능이며 다시 만들지 않는다.
- [ ] TASK-09의 접근성·권한·아이콘·서명/내부 테스트 준비를 확인한다. Play 공개 배포·main merge는 별도 실행 범위다.

### 병행 가능 · Google Sheets 보고서

사용자 담당으로 고정 샘플 → 출력 양식 → 옵션·미리보기를 B와 병행할 수 있다. 사용자도 한 번에 한 구현 작업을 진행하며 공통 계약/통합 확인이 필요하면 이를 먼저 처리한다. 이후 기존 repository 전체 조회·Dart 정산 결과를 연결하고 Google OAuth·새 시트 생성을 별도 검증한다. 시트 완료를 B/C의 필수 통과 조건으로 추가하지 않는다.

시트는 사람이 읽는 보고서이며 `.trip.json` 복원을 대체하지 않는다. 기존 Google Sheet/CSV를 앱으로 가져오는 기능은 별도 후속 후보다. 시트용 새 Callable·서버 집계·자동 환율·양방향 동기화·LLM은 추가하지 않는다. [시트 인계](sheet-export.md)를 따른다.

## 담당과 지금 시작할 작업 — Phase B

| 담당                      | 소유 범위                                                                                       | 다음 작업                                                                                                                  |
| ------------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 사용자 · 프론트/공통/통합 | 전체 Flutter, Dart 정산·repository·지도 adapter, backend/share·shared, CI·공통 Rules/index 통합 | 두 Android 클라이언트의 P0 QA·오류 복구, Google 지도 adapter·공유, 안정화 뒤 TASK-08 백업. 시트 양식·미리보기 병행 가능    |
| 일정·지도 백엔드          | backend/src/places, 도메인 테스트, 장소·일정·준비 Rules/index 변경안                            | 기존 검색/링크 handler 검토 → URL·참조·동시 변경 테스트 → 승인된 Google Places 연결·실패/timeout/할당량 처리               |
| 정산·영수증 백엔드        | backend/src/settlement, backend/src/ocr, 도메인 테스트                                          | 기존 equal/custom CRUD·금액·권한·참여자 검증 → 수정/삭제·응답 유실 회귀 → 두 기기 정산 QA. OCR 신규 비교·연결은 C에서 시작 |

공통 모델, backend/src/index.ts, firestore.rules/indexes, lockfile은 사용자가 최종 통합한다. 필요한 변경을 담당별로 공유하고 서로의 코드를 덮어쓰지 않는다. 이번 일괄 구현은 역할 분담 변경이 아니다.

다음 단계에서 사용자는 itemized·영수증 입력/검토·계정 복구·출시 UI를, 정산 백엔드는 itemized 검증과 OCR·번역 provider를, 일정·지도 백엔드는 검색·링크·동시 변경 회귀 및 출시 장애 검증을 맡는다. 일정·지도 담당에게 P2 Routes/NAVER를 미리 배정하지 않는다. 먼저 끝난 담당은 현재 B의 코드 리뷰·두 기기 QA를 지원하며 소유 영역 변경은 함께 조율한다.

## 처음 실행

각자 별도 clone을 사용한다. Node.js 22·Java 21이 필요하며 백엔드 담당은 Flutter SDK 없이 시작할 수 있다.

```bash
git clone --branch dev https://github.com/jim361/trip-split.git
cd trip-split
npm ci
npm run verify:fast
npm run test:emulator
```

프론트 담당은 Flutter 3.47.2와 Android SDK 환경에서 실행한다.

```bash
cd frontend
flutter pub get
flutter run
```

기본은 mock이다. Firebase Emulator를 확인할 때는 루트의 별도 터미널에서 `npm run dev:backend`를 켜고 `frontend`에서 `flutter run --dart-define-from-file=dart_defines.example.json`을 실행한다. Android host는 10.0.2.2, 프로젝트는 demo-trip-split이다. Google/OCR 유료 API·운영 secret·배포는 아직 연결하지 않는다. React Pages는 VITE_DATA_SOURCE=mock이다.

## 일정·지도 인계 — TASK-03/04/05

읽을 코드: `backend/src/places/places.ts`, `backend/tests/emulator/domain-flows.emulator.test.ts`, `backend/firestore.rules`, Flutter place provider/places_page와 itinerary_page.

- [x] searchPlaces/parsePlaceLink의 Auth·member guard, query string·URL 검증, Emulator 후보 반환과 Flutter adapter.
- [x] 일정 편집·optional 장소·A/B/날짜별 원자적 순서 저장, 시간 정렬, 외부 지도 열기.
- [x] 예약·체크리스트 모델/CRUD/Rules, 개인 항목도 여행 멤버에게 보이는 분류 정책.
- [ ] 실제 Google 검색·장소 링크 지원 범위 확대와 provider 실패/timeout/할당량 처리. 구현 전 사용할 환경·비용과 URL 정책 공유.
- [x] IMB-03 후속에서 장소·일정 참조 중 삭제 거부와 참조 저장/삭제의 공통 버전을 구현했다. 검증·로컬 반영 상태는 [담당 기록](../backend/workstreams/itinerary-map/tasks.md)을 확인하며 운영 배포·Android 전체 도메인 QA와 구분한다.
- [ ] 두 Android 기기에서 일정/장소/준비 실시간 갱신 검증에 참여.

## 정산·영수증 구현 이력 — 현재 B / OCR 착수 C

읽을 코드: `backend/src/settlement/expenseValidation.ts`, `expenses.ts`, `backend/src/ocr/receipts.ts`, domain-flows Emulator 테스트, Flutter ExpenseDraft와 receipt_review_page.

- [x] equal/custom/itemized 전체 validator, 안전한 정수·금액 합계·집합·나머지·부호·참조 확인.
- [x] 지출 CRUD Callable과 Flutter 호출 연결. client 직접 쓰기 차단은 유지.
- [x] 기존 비활성 참여자 이력 유지, 새 비활성 참여자 거부, 생성 감사 정보 보존, 멱등 삭제.
- [x] stateless OCR Emulator 샘플과 항목 검토·할인/봉사료·재정렬·명시적 저장 UI.
- [ ] **B 현재 작업:** equal/custom 금액·권한·참조와 수정/삭제·동시 변경 회귀를 검토하고 두 Android 기기 정산 갱신 검증에 참여. 신규 생성 응답 유실은 자동 재생성하지 않고 원장 확인 후 재시도하는 계약 유지.
- [ ] **C 후속 작업:** 일본어 실제 영수증 fixture로 외부 OCR·번역 provider 정확도/비용/보관 정책 비교 후 연결안 공유.
- [ ] **C 후속 작업:** 실제 provider 전 전체 이미지 디코딩, timeout·rate limit·오류/언어 fallback 보강.

## 공통 계약 변경 주의

- 신규 listMyTrips는 members.uid collection-group index가 필요하다. 구형 멤버는 재참여하면 같은 문서 ID에 uid를 보정한다. 운영 backfill은 별도 결정한다.
- linkMyParticipant는 본인만 연결/해제하며 다른 계정으로 uid를 전달하는 API가 아니다.
- 준비 문서는 최상위 필드 wire다. personal은 비공개 권한이 아니다.
- Google/OCR는 Emulator 샘플이며 실제 서비스 미연결을 unavailable로 반환한다.
- 지출 총액 분할은 source=manual/빈 receiptItems, itemized는 검토된 행과 일치하는 집계 배분을 저장한다.

## 반영·완료 기준

1. 작업 전과 push 직전 `git fetch origin dev`. 깨끗한 clone은 `git pull --ff-only origin dev`. 원격 새 변경이 있으면 통합하고 담당 검증을 다시 실행한다.
2. 작업 중 `npm run verify:fast`, 반영 전 `npm run verify:full`. Flutter는 `npm run verify:flutter:full`까지 실행한다.
3. dev에 직접 반영하고 CI를 확인한다. 기능 브랜치/dev PR은 만들지 않는다. main은 검증한 dev의 릴리스 PR만 사용한다.
4. Codex commit/push/PR 작업은 각각 해당 요청의 사용자 승인 범위를 따른다. 과거 구현·푸시 승인이나 단계 진입을 새 PR 편집·main merge·배포 승인으로 간주하지 않는다.
5. 테스트와 캡처는 기능/계약에 맞게 인계한다. 서버 Emulator 통과와 두 Android 기기·실제 외부 API 통합 완료를 구분한다.

## GitHub 작업 연결

기존 [#16 TASK-03](https://github.com/jim361/trip-split/issues/16), [#17 TASK-06](https://github.com/jim361/trip-split/issues/17), [#18 TASK-04](https://github.com/jim361/trip-split/issues/18)은 최초 구현 범위 추적용이다. 이번에 기반 구현이 추가됐으므로 이 문서의 현재 상태를 먼저 보고 담당 검토 후 Issue 상태를 정리한다. 이번 작업은 Issue 종료나 PR 편집을 수행하지 않는다.

2026-09-13 확인 기록: main은 PR·1인 승인·verify/flutter-android CI·대화 해결, dev는 직접 push 허용과 force push/삭제 차단. PR #4 `dev → main`은 기존 **Flutter Android 개발 기반과 3인 협업 준비** 릴리스 PR이다. 신규 코드가 dev에 반영되더라도 main merge와 설명 갱신은 별도 승인 범위다.

## 이번 점검에서 바로잡은 지시

| 혼동된 지시                                          | 현재 기준                                                                                      |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| OCR 연결을 정산 담당의 즉시 할 일로 공지             | B는 수동 equal/custom 안정화, itemized·OCR·번역은 C. 선행 구현은 유지                          |
| 최소 준비를 P1 또는 미구현으로 표시                  | 예약·체크리스트는 B(P0), 코드/Rules는 구현됐고 두 기기 QA가 남음                               |
| 내 여행 목록을 P1 또는 새로 만들 기능으로 표시       | 최신 화면 결정에 따라 기본 목록은 B에 포함·구현됨. Google 계정 연결/복구의 실기기 검증은 C     |
| 지도와 OCR를 모두 막연히 후속으로 표시               | Google Maps/Places는 B에 필요한 실제 연결, OCR는 C. 실제 경로 계산은 D                         |
| P1까지 포함한 전체 완료 조건을 P0 통과 조건으로 적용 | B/C 완료 조건을 분리하되 이미 존재하는 전체 자동 회귀는 계속 실행                              |
| 시트 출력·시트 가져오기·백업을 같은 작업으로 취급    | 출력은 사용자 병행 작업, 가져오기는 후속 후보, `.trip.json`은 핵심 안정화 뒤 실제 여행 전 백업 |
| backend 담당에게 Dart 계산·화면·지도 SDK까지 배정    | Flutter 전체는 사용자. backend는 각 handler·검증·Emulator 테스트 소유                          |
| 초기 체크리스트/회의 표를 최신 구현 상태로 해석      | 날짜별 구현 기록·화면/API 인계와 함께 확인. Widget·Emulator 통과와 실기기·운영 검증을 구분     |
