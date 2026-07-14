# Trip Split Task Index

이 문서는 3인 협업의 작업 인덱스이자 통합 규칙이다. 실제 구현 체크리스트는 기능별 task 파일에서 관리하고, 공통 데이터 계약과 공유 파일 변경은 이 문서의 규칙을 따른다.

## 1. 역할과 소유 영역

| 역할 | 주 소유 영역 | 관련 Task |
| --- | --- | --- |
| 플랫폼·통합 담당 | Vite/Firebase 기반, 익명 인증과 선택적 Google 연결, 여행 생성·공유·멤버, 앱 셸·라우팅·공통 UI, PWA, 보안 규칙 통합, 백업, 최종 QA·병합 | 1, 2, 8, 9 |
| 정산·영수증 담당 | `Participant`, `Expense`, `ReceiptItem`, 분할·정산 엔진, 개인 소비 화면, 지출 UI, `parseReceipt`, CLOVA OCR, 영수증 검토·등록 | 6, 7 |
| 장소·일정·지도 담당 | `Place` 정규화, 네이버 장소 검색·링크 파싱·직접 입력, 장소 보관함, 일정 편집, 지도 어댑터, 번호 핀·직선 동선 | 3, 4, 5 |

- 플랫폼·통합 담당이 제품 계약과 병합의 최종 책임자다. 다른 담당자는 공통 타입이나 Firestore 경로를 단독 확정하지 않고 변경 제안 PR을 올린다.
- OCR은 정산 원장과 한 흐름으로 연결되므로 정산·영수증 담당이 소유한다.
- 장소 보관함과 네이버 API는 일정 및 지도 입력의 일부이므로 장소·일정·지도 담당이 소유한다.
- 각 담당자는 동시에 하나의 구현 작업만 진행한다. 리뷰 대기 작업은 WIP에서 제외할 수 있다.

## 2. 구현 전 공통 계약

첫 기능 PR 전에 `tech.md`, `structure.md`와 이 문서에서 다음을 세 명이 확인한다.

- `TripMember`는 Firebase Auth `uid`를 가진 공동 편집 사용자이고, `Participant`는 비용의 결제자 또는 소비자다. 필요할 때만 `Participant.linkedUid`로 연결한다.
- 정산 원장은 `Expense`, `ReceiptItem`, `payer`, `consumers`, `allocationMethod`, `allocatedAmounts`를 기준으로 한다.
- 모든 KRW 금액은 원 단위 정수다. 균등 분할의 1원 나머지는 화면에 표시된 소비자 순서대로 배분한다.
- 장소 API 응답은 앱 내부 `Place`로 정규화한다. 지도는 `Place` 좌표와 `ItineraryItem.order`만 입력받고 실제 도로 경로를 계산하지 않는다.
- 여행 내부 주요 내비게이션은 `일정·지도`, `정산`, `영수증` 세 개와 동일한 순서로 고정한다. 지도는 일정 상단에서 확대할 수 있고 장소 보관함은 통합 화면 안의 패널 또는 바텀시트다.
- Cloud Function 소유권은 플랫폼의 여행 생성·공유 코드·참여, 정산의 `parseReceipt`, 지도의 장소 검색·장소 링크 파싱으로 나눈다.
- 공통 오류는 `code`, `message`, `retryable`, 선택적 `field`와 `details`를 갖는 한 형식으로 변환한다. 문서 ID 생성 방식, Firebase server timestamp, repository의 구독/CRUD 인터페이스도 기능 구현 전에 고정한다.
- 동일한 강릉 fixture를 화면, 순수 함수 테스트, repository 통합 테스트에 사용한다. fixture 변경은 공통 계약 변경으로 취급한다.

## 3. 기능별 Task 파일

1. [task_function1_project_setup.md](task_function1_project_setup.md)
   - 앱 셸, 라우팅, 공통 UI, Firebase 클라이언트·에뮬레이터, 테스트 기반

2. [task_function2_trip_share.md](task_function2_trip_share.md)
   - 익명 인증, 선택적 Google 계정 연결, 여행 생성, 공유 코드·초대 링크, 멤버 세션

3. [task_function3_places.md](task_function3_places.md)
   - 장소 보관함, 네이버 장소 검색, 장소 링크 붙여넣기, 직접 입력, `Place` 정규화

4. [task_function4_itinerary.md](task_function4_itinerary.md)
   - 날짜별 타임라인, 장소 연결, 일정 순서 관리

5. [task_function5_map.md](task_function5_map.md)
   - 네이버 지도, 일정 순서 기반 번호 핀, 날짜별 색상과 직선 동선

6. [task_function6_settlement.md](task_function6_settlement.md)
   - 정산 원장, 균등·항목별·직접 입력 분할, 개인 소비 내역, 최종 송금 계산

7. [task_function7_ocr.md](task_function7_ocr.md)
   - 로컬 이미지 선택, stateless CLOVA OCR, 수정 가능한 초안, 항목 분할, 사용자 확정 저장

8. [task_function8_backup_export.md](task_function8_backup_export.md)
   - 데이터 모델 안정화 이후 `.trip.json` 백업·복원·데모 데이터

9. [task_function9_polish_release.md](task_function9_polish_release.md)
   - 모바일 우선 PWA, PC 확장 레이아웃, 빈 상태·오류 상태, 접근성, 출시 QA

## 4. 구현 및 통합 순서

### 단계 A — Git과 공통 계약 준비

- 작업 시작 전에 정상 clone 또는 기존 Git 메타데이터를 확인한다. 이력이 불명확한 폴더에서 새로 `git init`하지 않는다.
- 사람과 AI 작업자는 각각 별도 clone 또는 `git worktree`를 사용하고 같은 작업 폴더를 동시에 편집하지 않는다.
- 공통 타입, Firestore 경로, repository 인터페이스, 오류 형식, 강릉 fixture를 먼저 확정한다.

### 단계 B — 플랫폼 기반과 mock 병렬 개발

- 플랫폼·통합 담당: 앱 셸과 세 개 주요 라우트 및 `/map` 호환 redirect, Firebase 클라이언트·에뮬레이터, Auth, Trip Context를 준비한다.
- 정산·영수증 담당: Firebase와 분리된 순수 정산 엔진과 mock repository를 만든다.
- 장소·일정·지도 담당: mock place provider와 mock repository를 만든다.

### 단계 C — 도메인별 구현

- 정산·영수증: 순수 계산 함수와 테스트 → 수동 지출·개인 소비 UI → Firestore 실시간 연결 → OCR 순서로 구현한다.
- 장소·일정·지도: place provider mock → 일정 UI → 지도 표시 → 네이버 API 연결 순서로 구현한다.
- 플랫폼·통합: 여행 생성·참여·공유 → 실시간 세션 → PWA → 데이터 모델 안정화 후 `.trip.json` 순서로 구현한다.
- 외부 API는 mock 흐름과 실패 상태가 완성된 뒤 연결한다.

### 단계 D — 통합 체크포인트

1. mock 데이터로 네 화면 이동, 핵심 CRUD, 로딩·빈 상태·오류 상태를 확인한다.
2. Firebase Emulator에서 익명 사용자 두 명이 같은 여행에 들어와 장소·일정·지출 변경을 실시간으로 확인한다.
3. 네이버 장소·지도 API와 CLOVA OCR을 각각 실제 환경에서 확인하되, 외부 API 실패가 앱의 수동 입력 흐름을 막지 않는지 검증한다.
4. 390px 모바일 PWA와 PC에서 동일한 네 개 내비게이션, 지정된 화면 순서, 백업·복원, 전체 회귀 테스트를 확인한다.

## 5. 공유 파일과 변경 승인

다음 파일은 플랫폼·통합 담당이 최종 병합한다.

- `package.json`과 lockfile
- 앱 라우트와 전역 App/Trip Context 진입점
- Firebase 클라이언트·Functions 진입점과 환경변수 예시
- Firestore/Storage 보안 규칙과 Emulator 설정
- 공통 타입 export, 오류 형식, 공통 fixture

공유 파일 변경이 필요한 담당자는 자신의 기능 PR에 변경 이유, 영향받는 기능, 마이그레이션 여부를 적는다. Firestore 경로·정산 불변식·공통 타입 변경 PR은 나머지 두 명 모두가 검토한 뒤 병합한다.

## 6. 브랜치와 PR 원칙

- `main`에 직접 커밋하지 않고 1~3일 안에 리뷰 가능한 작은 기능 PR을 만든다.
- 권장 브랜치:
  - 정산·영수증: `feat/settlement-domain`, `feat/receipt-ocr`
  - 장소·일정·지도: `feat/place-provider`, `feat/itinerary`, `feat/map-view`
  - 플랫폼·통합: `feat/app-shell-auth`, `feat/trip-share`, `feat/pwa-backup`
- 일반 PR은 최소 한 명이 검토한다. 데이터 계약이나 Firestore 경로 변경은 나머지 두 명의 승인이 필요하다.
- PR 본문에는 구현 범위, 로딩·빈 상태·오류 상태, 모바일/PC 캡처, 테스트 결과, 공통 계약 변경 여부를 기록한다.
- 매일 `완료 / 오늘 / 막힌 점 / 계약 변경` 네 항목으로만 진행 상황을 공유한다.

## 7. 공통 완료 게이트

- typecheck, lint, unit test, build가 통과한다.
- repository와 보안 규칙 변경은 Firebase Emulator 통합 테스트가 통과한다.
- 정산은 전체 균등·항목별·직접 금액·조정 배분과 결제액/부담액/net 테스트가 통과한다.
- 일정 순서를 바꾸면 핀 번호와 직선 동선도 같은 순서로 갱신된다.
- OCR은 항목 수정·수동 추가·배분·합계 검증·인식 실패 시 총액 수동 등록을 지원하며, 이미지를 영구 저장하지 않는다.
- 390px 모바일과 PC에서 `일정·지도 / 정산 / 영수증`의 동일한 정보 구조와 키보드·터치 조작을 확인한다.
