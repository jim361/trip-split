# Trip Split Task Index

> **[작업 00 · 작업 인덱스]** 역할, 기능별 구현 순서와 공통 완료 게이트입니다.

이 문서는 3인 협업의 작업 인덱스이자 통합 규칙이다. 실제 구현 체크리스트는 기능별 task 파일에서 관리하고, 공통 데이터 계약과 공유 파일 변경은 이 문서의 규칙을 따른다.

구현 전 기능 후보의 유지·추가·제외 논의는 [기능 범위 회의 문서](../../docs/README.md)에서 진행한다. 회의에서 채택된 기능만 이 인덱스와 기능별 task의 구현 체크리스트로 옮긴다.

## 1. 역할과 소유 영역

| 역할 | 주 작업 경로 | 주 소유 영역 | 관련 Task |
| --- | --- | --- | --- |
| 플랫폼·통합 담당 | 루트, `frontend/lib/app`, `frontend/lib/data`, `backend/src/share` | Flutter/Firebase 기반, 인증, 여행 생성·공유·멤버, 앱 셸, 보안 규칙 통합, 백업, Android QA·통합 | `TASK-01`, `TASK-02`, `TASK-08`, `TASK-09` |
| 정산·영수증 담당 | `frontend/lib/features/settlement`, `frontend/lib/features/receipts`, `backend/src/settlement`, `backend/src/ocr` | `Participant`, `Expense`, `ReceiptItem`, 순수 Dart 정산 엔진, 개인 소비 화면, 지출 Callable, `parseReceipt`, OCR·번역 검토 | `TASK-06`, `TASK-07` |
| 장소·일정·지도 담당 | `frontend/lib/features/places`, `itinerary`, `map`, `preparation`, `backend/src/places` | `Place` 정규화, Google 장소·URL·직접 입력, 일정·준비 편집, 지도 adapter | `TASK-03`, `TASK-04`, `TASK-05` |

- 플랫폼·통합 담당이 제품 계약과 통합의 최종 책임자다. 다른 담당자는 공통 타입이나 Firestore 경로를 단독 확정하지 않고 변경 전에 팀에 영향 범위를 공유한다.
- OCR은 정산 원장과 한 흐름으로 연결되므로 정산·영수증 담당이 소유한다.
- 장소 보관함, 준비와 Google API는 일정 및 지도 입력에 결합되므로 장소·일정·지도 담당이 소유한다.
- 두 도메인 담당은 backend만이 아니라 자신의 Flutter feature, 순수 Dart 로직, repository와 Function을 세로로 함께 소유한다.
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

### 단계 A — Git과 공통 계약 준비

- 작업 시작 전에 정상 clone 또는 기존 Git 메타데이터를 확인한다. 이력이 불명확한 폴더에서 새로 `git init`하지 않는다.
- 동시 작업자는 각각 별도 clone을 사용하고 같은 작업 폴더를 동시에 편집하지 않는다. 모두 같은 `dev`에 직접 반영하므로 하나의 clone에서 여러 worktree가 동시에 `dev`를 checkout하는 방식은 사용하지 않는다.
- Dart 공통 모델, Firestore 경로, repository 인터페이스, 오류 형식과 도쿄 fixture를 먼저 확정한다.

### 단계 B — 플랫폼 기반과 mock 병렬 개발

- 플랫폼·통합 담당: Flutter 앱 셸과 세 탭 route, `/map` 호환 규칙, FlutterFire Emulator, Auth와 `TripSession`을 준비한다.
- 정산·영수증 담당: Firebase와 분리된 순수 정산 엔진과 mock repository를 만든다.
- 장소·일정·지도 담당: mock place provider와 mock repository를 만든다.

### 단계 C — 도메인별 구현

- 정산·영수증: 순수 Dart equal/custom → validator·개인 소비 UI → Firestore Stream → itemized → OCR·번역 순서로 구현한다.
- 장소·일정·지도: place provider mock → 일정·준비 UI → 지도 mock → Google API 연결 순서로 구현한다.
- 플랫폼·통합: Flutter scaffold → 여행 생성·참여·공유 → 실시간 세션 → 데이터 모델 안정화 후 Android `.trip.json` 순서로 구현한다.
- 외부 API는 mock 흐름과 실패 상태가 완성된 뒤 연결한다.

### 단계 D — 통합 체크포인트

1. Android Emulator에서 mock 데이터로 세 탭과 영수증 하위 화면 이동, 로딩·빈 상태·오류 상태를 확인한다.
2. Firebase Emulator에서 익명 사용자 두 명이 같은 여행에 들어와 장소·일정·지출 변경을 실시간으로 확인한다.
3. Google 장소·지도와 선택한 OCR·번역 provider를 승인된 환경에서 확인하되 외부 API 실패가 직접 입력과 수동 지출을 막지 않는지 검증한다.
4. Android emulator·실기기에서 세 탭, 키보드·뒤로 가기, 백업·복원과 전체 회귀 테스트를 확인한다.

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
- 정산은 전체 균등·항목별·직접 금액·조정 배분과 결제액/부담액/net 테스트가 통과한다.
- 일정 순서를 바꾸면 핀 번호와 직선 동선도 같은 순서로 갱신된다.
- OCR은 항목 수정·수동 추가·배분·합계 검증·인식 실패 시 총액 수동 등록을 지원하며, 이미지를 영구 저장하지 않는다.
- Android handset에서 `일정·지도 / 준비 / 비용`의 정보 구조, system back, 키보드·터치 조작을 확인한다.
- Flutter Web과 iOS, 백그라운드 위치·Health Connect는 Android MVP 완료 게이트에 포함하지 않는다.
