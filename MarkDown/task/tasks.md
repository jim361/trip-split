# Trip Split Task Index

> **[작업 00 · 작업 인덱스]** 역할, 기능별 구현 순서와 공통 완료 게이트입니다.

이 문서는 3인 협업의 작업 인덱스이자 통합 규칙이다. 실제 구현 체크리스트는 기능별 task 파일에서 관리하고, 공통 데이터 계약과 공유 파일 변경은 이 문서의 규칙을 따른다.

구현 전 기능 후보의 유지·추가·제외 논의는 [기능 범위 회의 문서](../../docs/README.md)에서 진행한다. 회의에서 채택된 기능만 이 인덱스와 기능별 task의 구현 체크리스트로 옮긴다.

## 1. 역할과 소유 영역

| 역할 | 주 작업 경로 | 주 소유 영역 | 관련 Task |
| --- | --- | --- | --- |
| 플랫폼·통합 담당 (사용자: 프론트·공통) | 루트, 전체 `frontend/`, `backend/src/share`, `backend/src/shared` | 모든 Flutter 화면·Dart 정산 계산·mock/FlutterFire repository·지도 adapter, 인증·여행 공유, 공통 계약, 백업·CI·Android QA | `TASK-01`~`TASK-09`의 프론트·공통·통합 |
| 정산·영수증 백엔드 담당 | `backend/src/settlement`, `backend/src/ocr`, 관련 backend 테스트 | 지출 runtime validator·저장 Callable, 참여자 참조·배분 검증, OCR·번역 서버 adapter | `TASK-06`, `TASK-07`의 서버 |
| 일정·지도 백엔드 담당 | `backend/src/places`, 관련 backend 테스트, 일정·장소·준비 Rules/index 변경안 | 장소 검색·링크 해석·정규화, 일정 저장 규칙·재정렬 검증, 예약·체크리스트 저장 계약 | `TASK-03`, `TASK-04`, `TASK-05`의 서버·데이터 |

- 플랫폼·통합 담당이 제품 계약과 통합의 최종 책임자다. 다른 담당자는 공통 타입이나 Firestore 경로를 단독 확정하지 않고 변경 전에 팀에 영향 범위를 공유한다.
- OCR은 정산 원장과 한 흐름으로 연결되므로 정산·영수증 담당이 소유한다.
- 장소·일정·준비의 서버 데이터 검증과 Google Places API는 일정·지도 백엔드가 소유하고, 해당 Flutter 화면·repository와 Android 지도 SDK는 사용자가 소유한다.
- 2026-09-13 결정: 두 도메인 담당은 백엔드를 맡고, Flutter feature·순수 Dart 로직·repository·지도 SDK는 사용자가 맡는다. 정산 백엔드는 서버 불변식과 공통 계산 예시를 제공하고 사용자가 Dart 엔진에 같은 결과를 검증한다.
- 일정 CRUD는 현재 Firestore 직접 쓰기와 Rules로 처리한다. 별도 일정 Callable을 임의로 추가하지 않는다. 준비 데이터 모델·repository·Rules는 2026-09-14 구현했고 일정·지도 백엔드가 후속 검증을 소유한다.
- 즉시 착수할 작업과 인계 조건은 [개발 시작 안내](../../docs/development-kickoff.md)를 따른다.
- 각 담당자는 동시에 하나의 구현 작업만 진행한다. 리뷰 대기 작업은 WIP에서 제외할 수 있다.

## 2. 구현 전 공통 계약

첫 기능 구현 전에 `tech.md`, `structure.md`와 이 문서에서 다음을 세 명이 확인한다.

- `TripMember`는 Firebase Auth `uid`를 가진 공동 편집 사용자이고, `Participant`는 비용의 결제자 또는 소비자다. 필요할 때만 `Participant.linkedUid`로 연결한다.
- 정산 원장은 `Expense`, `ReceiptItem`, `payer`, `consumers`, `allocationMethod`, `allocatedAmounts`를 기준으로 한다.
- 금액은 ISO 통화별 최소 단위 정수다. MVP는 KRW와 JPY를 지원하며, 서로 다른 통화는 분리하고 균등 분할의 최소 단위 나머지는 화면에 표시된 소비자 순서대로 배분한다.
- 장소 API 응답은 앱 내부 `Place`로 정규화한다. 지도는 `Place` 좌표와 `ItineraryItem.order`만 입력받고 실제 도로 경로를 계산하지 않는다.
- Android 여행 내비게이션은 `일정·지도`, `준비`, `비용` 세 개로 고정한다. 지도는 일정 상단에서 확대하고 영수증/OCR은 비용의 하위 흐름이다.
- Cloud Function 소유권은 플랫폼의 여행 생성·공유 코드·참여, 정산의 `createExpense`·`updateExpense`·`deleteExpense`·`parseReceipt`, 지도의 `searchPlaces`·`parsePlaceLink`로 나눈다.
- 공통 오류는 `code`, `message`, `retryable`, 선택적 `field`와 `details`를 갖는 한 형식으로 변환한다. 문서 ID 생성 방식, Firebase server timestamp, repository의 구독/CRUD 인터페이스도 기능 구현 전에 고정한다.
- `tokyo-2026-11` fixture를 화면, 순수 함수와 repository 테스트에 사용하고 기존 강릉 fixture는 회귀용으로 보존한다. canonical fixture 변경은 공통 계약 변경으로 취급한다.

## 3. 기능별 Task 파일

`TASK-01`부터 `TASK-09`까지는 고정 작업 ID다. 숫자 suffix가 같은 `task_function1_*.md`부터 `task_function9_*.md`까지에 1:1 대응하며 기존 ID와 파일명을 재번호·재사용·변경·삭제하지 않는다.

1. [`TASK-01 · 프로젝트 기반`](task_function1_project_setup.md)
   - 앱 셸, 라우팅, 공통 UI, Firebase 클라이언트·에뮬레이터, 테스트 기반

2. [`TASK-02 · 인증·여행·공유`](task_function2_trip_share.md)
   - 익명 인증, 선택적 Google 계정 연결, 여행 생성, 공유 코드, 멤버 세션

3. [`TASK-03 · 장소 보관함·검색`](task_function3_places.md)
   - 장소 보관함, Google 장소 검색, Maps URL, 직접 입력과 `Place` 정규화 (국내 NAVER provider는 같은 계약의 후속 범위)

4. [`TASK-04 · 일정`](task_function4_itinerary.md)
   - 날짜별 타임라인, 장소 연결, 일정 순서, 예약과 체크리스트

5. [`TASK-05 · 지도`](task_function5_map.md)
   - Google 지도, 일정 순서 기반 번호 핀, 날짜별 색상과 직선 동선 (국내 NAVER adapter는 후속 범위)

6. [`TASK-06 · 정산`](task_function6_settlement.md)
   - 정산 원장, 균등·항목별·직접 입력 분할, 개인 소비 내역, 최종 송금 계산

7. [`TASK-07 · 영수증 OCR`](task_function7_ocr.md)
   - Android 이미지 선택, provider-neutral OCR·번역, 수정 가능한 초안, 항목 분할, 사용자 확정 저장

8. [`TASK-08 · 백업·내보내기`](task_function8_backup_export.md)
   - 데이터 모델 안정화 이후 `.trip.json` 백업·복원·데모 데이터

9. [`TASK-09 · 마감·출시`](task_function9_polish_release.md)
   - Android 접근성·권한·동기화 상태, APK와 내부 배포 전 QA

## 4. 구현 및 통합 순서

Phase A~D는 [Android 전환 계획](../../docs/flutter-android-migration.md)과 같은 실행 단계다. 기능 ID와 TASK 번호는 작업 식별자이며 실행 순서나 완료율이 아니다. 자세한 담당별 다음 작업과 통과 조건은 [개발 시작 안내](../../docs/development-kickoff.md)를 따른다.

### Phase A — Git·공통 계약·개발 기반

- 작업 시작 전에 정상 clone 또는 기존 Git 메타데이터를 확인한다. 이력이 불명확한 폴더에서 새로 `git init`하지 않는다.
- 동시 작업자는 각각 별도 clone을 사용하고 같은 작업 폴더를 동시에 편집하지 않는다. 모두 같은 `dev`에 직접 반영하므로 하나의 clone에서 여러 worktree가 동시에 `dev`를 checkout하는 방식은 사용하지 않는다.
- Dart 공통 모델, Firestore 경로, repository 인터페이스, 오류 형식과 도쿄 fixture를 먼저 확정한다.
- 플랫폼·통합 담당: Flutter 앱 셸과 세 탭 route, `/map` 호환 규칙, FlutterFire Emulator, Auth와 `TripSession`을 준비한다.
- 정산·영수증 백엔드 담당: 외부 API 없이 지출 validator와 Callable의 Emulator 검증을 만든다.
- 일정·지도 백엔드 담당: mock provider를 주입하는 검색·링크 Callable과 권한·오류 테스트를 만든다.
- 사용자: 두 서버 작업과 병렬로 Flutter mock 입력 화면과 Dart 계산을 완성한다.
- 기준: mock 실행·자동 검증과 서로 다른 익명 UID의 여행 생성/공유 코드 입장 수직 검증. 2026-08-30 smoke 기록이 있으며 새로운 개발자는 로컬 실행을 재현한다.

### Phase B — 핵심 여행 기능(P0), 현재 단계

- 정산·영수증 백엔드: 기존 equal/custom validator·지출 CRUD 검토 → 금액·권한·참조·수정/삭제·동시 변경 회귀 → 두 기기 정산 갱신 검증. 현재 외부 OCR 비교/연결을 새로 시작하지 않는다.
- 일정·지도 백엔드: 기존 검색·링크 handler 검토 → 일정·장소·최소 준비 Rules/동시 변경 검증 → 승인된 Google Places 연결과 실패·timeout·할당량 처리.
- 플랫폼·통합: 이미 구현된 일정·장소·예약/체크리스트·참여자·수동 정산·기본 내 여행/공유/설정의 mock/Emulator 흐름을 검토한다. 두 Android 클라이언트와 실제 지도 adapter를 연결·검증하고, 핵심 데이터가 안정되면 TASK-08 파일 백업/새 여행 복원을 실제 여행 전에 검증한다.
- 각 화면 흐름은 진입·입력·저장·실패 상태, 실제 Flutter 캡처와 API 요청·응답·오류 예시를 묶어 인계한다. 현재 구현 목록과 확정한 추가 wire는 [Flutter 화면 완성·API 인계 명세](../../docs/frontend-api-handoff.md)를 따른다. 제안은 공통 모델·Rules 합의 전 확정 계약으로 취급하지 않는다.
- B의 외부 연결은 Google Maps/Places이며 OCR·번역이나 실제 Routes API가 아니다. mock·오류 흐름 완성과 실제 환경 승인 후 연결한다.
- 기준: 두 기기의 핵심 CRUD·권한·순서/지도·통화별 계산·재시작/재접속, 실제 Google 지도/검색과 백업/복원, 전체 자동 검증. 실제 연결·기기 증거가 없으면 B 완료로 표시하지 않는다.

### Phase C — 항목별 정산·영수증·출시 품질(P1)

- B 완료 뒤 기존 itemized·조정 validator와 검토 UI를 이어서 검증한다. 미리 구현됐다고 실제 OCR 작업의 우선순위를 당기지 않는다.
- 정산 백엔드는 일본어 fixture로 provider 기준을 정하고 승인된 OCR·번역 연결, 이미지 디코딩·timeout·호출 제한·오류를 검증한다.
- 사용자는 촬영·Photo Picker·원문/번역 검토·명시적 저장·수동 fallback, Google 계정 연결/복구와 TASK-09 실기기·출시 품질을 맡는다. 일정·지도 담당은 자기 도메인의 장애·회귀 검증을 지원한다.
- 기준: 원장 합계와 항목 배분 일치, 확정 전 미반영, 임시 이미지 폐기와 Android 실기기 전체 QA. main merge·서명 secret·Play 배포는 별도 승인 범위다.

### Phase D — P2와 별도 채택 후보

- Flutter Web·iOS·NAVER, 실제 경로/이동 시간·활동 기록, 자동 환율·송금 완료·정산 snapshot·고급 권한·오프라인 병합은 현재 착수 범위가 아니다.
- Google Sheets/CSV 가져오기와 D-day/오늘 일정·Gemini는 별도 후보로 유지한다. 후속 목록에 있다는 이유만으로 모두 채택된 기능으로 보지 않는다.

### 사용자 병행 작업 — Google Sheets 보고서

- 고정 샘플 → 양식/미리보기 → 기존 repository·Dart 정산 연결 → 승인된 Google OAuth·새 시트 생성 순서다. TASK-08에서 별도로 추적하고 B/C 필수 통과 조건으로 추가하지 않는다.
- 시트용 서버·LLM·양방향 동기화를 추가하거나 `.trip.json` 백업을 대체하지 않는다. 각 담당은 한 번에 한 작업을 진행하고, 공통 계약·통합 확인을 우선한다.

## 5. 공유 파일과 변경 승인

다음 파일은 플랫폼·통합 담당이 최종 확인한다.

- `frontend/pubspec.yaml`·`pubspec.lock`, backend `package.json`·lockfile
- Flutter router와 전역 App/`TripSession` 진입점
- Firebase 클라이언트·Functions 진입점과 환경변수 예시
- Firestore/Storage 보안 규칙과 Emulator 설정
- 공통 타입 export, 오류 형식, 공통 fixture

공유 파일 변경이 필요한 담당자는 푸시 전에 변경 이유, 영향받는 기능과 마이그레이션 여부를 팀에 공유한다. Firestore 경로·정산 불변식·공통 타입 변경은 나머지 두 명 모두가 검토한 뒤 `dev`에 반영한다.

## 6. `dev` 직접 통합 원칙

- 장기 운영 브랜치는 `dev`와 `main`만 사용하며 기능 브랜치를 따로 만들지 않는다.
- 작업 전과 push 직전에 최신 `origin/dev`를 동기화한다. 원격 변경이 있으면 충돌을 해결하고 영향받는 검증을 다시 실행한 뒤, 한 번에 한 작업만 작은 커밋으로 `dev`에 직접 반영한다.
- 푸시 전 담당 검증을 로컬에서 실행하고, 푸시 뒤 GitHub Actions 결과를 확인한다.
- 일반 변경은 최소 한 명에게 변경 내용을 공유한다. 데이터 계약이나 Firestore 경로 변경은 나머지 두 명의 확인이 필요하다.
- 공유 내용에는 구현 범위, 로딩·빈 상태·오류 상태, Android 확인 결과, 테스트 결과와 공통 계약 변경 여부를 기록한다.
- `main`에는 직접 커밋하지 않고 검증된 `dev`의 릴리스 Pull Request로만 반영한다.
- 매일 `완료 / 오늘 / 막힌 점 / 계약 변경` 네 항목으로만 진행 상황을 공유한다.

## 7. 공통 완료 게이트

- typecheck, lint, unit test, build가 통과한다.
- Flutter는 format check, `flutter analyze`, `flutter test`와 debug APK build가 통과한다.
- repository와 보안 규칙 변경은 Firebase Emulator 통합 테스트가 통과한다.
- P0 정산 완료는 equal/custom·결제액/부담액/net, P1 완료는 itemized·조정 배분까지 기기에서 확인한다. 이미 존재하는 모든 자동 회귀는 단계와 무관하게 계속 통과해야 한다.
- 일정 순서를 바꾸면 핀 번호와 직선 동선도 같은 순서로 갱신된다.
- P1 OCR은 항목 수정·수동 추가·배분·합계 검증·인식 실패 시 총액 수동 등록을 지원하며, 이미지를 영구 저장하지 않는다. P0 완료를 OCR 외부 연결에 종속시키지 않는다.
- Android handset에서 `일정·지도 / 준비 / 비용`의 정보 구조, system back, 키보드·터치 조작을 확인한다.
- Flutter Web과 iOS, 백그라운드 위치·Health Connect는 Android MVP 완료 게이트에 포함하지 않는다.

## 2026-09-14 인계 상태

사용자 승인으로 P0 주요 Flutter 화면·서버 함수와 P1 itemized·영수증 mock 검토를 함께 구현했고 총 11개 Callable을 export한다. 현재 단계는 B이며 P1 코드의 존재는 B/C 완료를 뜻하지 않는다. B에는 실제 Android 지도/Google Places, 두 기기 핵심 QA와 TASK-08 백업이, C에는 실제 OCR/번역과 계정 복구·출시 품질이 남아 있다. 시트는 별도 병행 작업이다. 기존 Task ID와 역할은 유지하며 최신 착수 작업은 [개발 시작 안내](../../docs/development-kickoff.md)를 따른다.
