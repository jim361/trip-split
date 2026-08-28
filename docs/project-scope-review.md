# Trip Split Flutter 전환 범위 점검

> **[회의 03 · 프로젝트 범위 점검]** 현재 React 목업과 확정된 Flutter Android 범위, 남은 제품 선택을 구분합니다.

기준일은 2026-08-28이다. Flutter Android 우선, 도쿄·Google 우선과 Web 후속 결정은 `MarkDown/` 계약에 반영했다. 이 문서는 현재 코드와 남은 회의 항목을 확인하는 보조 자료이며 계약과 충돌하면 `MarkDown/`이 우선한다.

[논의 홈](README.md) · [일정·지도 상세](itinerary-map.md) · [정산·영수증 상세](settlement-receipts.md) · [반응형 목업](https://jim361.github.io/trip-split/)

## 1. 지금 구분해서 볼 세 가지

### 현재 코드

`frontend/`의 제품 앱은 Flutter Android scaffold이고 React/Vite는 GitHub Pages 목업을 위해 임시 보존한다. `backend/`는 Node.js·TypeScript Firebase 기반이다. Flutter mock 앱과 client 경계는 구현됐지만 실기기·Android Emulator 수직 검증까지 완료된 것으로 보지 않는다.

### 확정한 제품 방향

- 솔로 여행의 일정·개인 지출과 단체 여행의 공동 계획·정산을 같은 여행 모델에서 다룬다.
- 주요 메뉴를 `일정·지도 / 준비 / 비용` 세 영역으로 두고 영수증·OCR은 비용 안에서 연다.
- 2026년 11월 도쿄 여행을 첫 실제 사용 목표로 삼아 Google 장소·지도와 JPY 흐름을 먼저 검토한다.
- 클라이언트는 Flutter Android로 전환하고 Flutter Web·iOS·국내 NAVER는 후속으로 둔다.
- 수동 일정·공유·정산을 먼저 만들고 OCR·번역은 P1, 걸음·경로 기록은 P2로 둔다.

### 다음 회의에서 할 일

`준비`의 최소 저장 범위, 혼합 통화 정책, Google Maps URL 지원 범위와 OCR benchmark 합격 기준을 정한다. Flutter 선택과 Google 우선 여부는 다시 논의할 열린 항목이 아니다.

## 2. 현재 구현 상태

| 영역          | 지금 확인할 수 있는 것                                                                                       | 아직 구현되지 않았거나 확인할 것                                                                              |
| ------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| 프로젝트 기반 | Flutter Android scaffold·세 탭 mock·Dart 검증과 CI debug APK, 임시 React Pages 목업                          | Android 실기기 QA와 Flutter client→Firebase Emulator 수직 검증                                                |
| 인증·공유     | Flutter 익명 인증·Google 연결 service 경계, `TripSession`, 세 Callable과 members 규칙                        | Console provider 활성화, 코드 재생성 UI, Participant 연결 Callable, 내 여행 목록과 익명 세션 소실 안내        |
| 여행 생성     | Flutter mock과 Firebase Callable이 새 여행·초기 Participant를 생성한다                                       | 국내/해외·국가·통화·provider·time zone 선택 UI, 여행 수정·목록·삭제                                           |
| 데이터 연결   | Dart canonical 모델, mock/Firestore repository, `TripSession` Stream, 도쿄 fixture와 강릉 React 회귀 fixture | 실제 운영 데이터 migration, 준비 repository와 Android 백업 복원                                               |
| 일정·지도     | 일정 편집 core, 날짜·순서·ID 기반 지도 render model, 상단 mock 지도와 확대 route                             | CRUD Widget, 실제 Google 검색·지도 SDK·URL adapter. NAVER는 후속                                              |
| 준비          | 미배치 장소 후보, 예약과 체크리스트 정적 목업                                                                | `Reservation`·`ChecklistItem` 타입, repository, 저장·공유·편집                                                |
| 비용          | Participant·Expense 모델, mock CRUD, equal 순수 엔진, KRW·JPY 분리 표시와 Firestore 읽기                     | 참여자 관리 UI, custom/itemized·net, runtime validator와 서버 저장 Callable. 그전까지 Firebase 직접 쓰기 차단 |
| 영수증        | bytes 기반 `parseReceipt` 요청·mock 응답 경계와 검토 placeholder                                             | 이미지 선택, OCR Function/provider, 오류 appCode mapping, 수정·배분·확정 저장                                 |
| 백업·오프라인 | `.trip.json` schema v1 codec와 Android backup 제외 정책, React 정적 앱 셸 캐시                               | Android 파일 선택기, Firebase import, Firestore cache·pending write UI                                        |

GitHub Pages 화면은 **전환 전 React 반응형 기능 목업**이고 제품 코드는 Flutter Android다. Flutter에도 mock 세 탭은 있지만 실제 지도 SDK, 준비 저장, 완성된 정산과 OCR은 아직 없다.

## 3. 공통 데이터 경계와 아직 확인할 가정

| 경계             | 현재 사실                                                                                             | 회의에서 확인할 점                                                                                |
| ---------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| 여행 모델        | 현재 `Trip` 타입은 솔로·단체를 별도 타입으로 나누지 않는다.                                           | Participant가 한 명일 때 같은 원장을 개인 소비 중심 UI로 보여줄지                                 |
| 멤버와 정산 인원 | `TripMember.uid`와 `Participant.id`는 분리되어 있고 `linkedUid`로 연결할 수 있다.                     | 입장한 멤버가 기존 Participant를 안전하게 선택·연결하는 방법                                      |
| 인원 생명주기    | Dart repository는 비활성화만 제공하고 Firestore Rules도 Participant 물리 삭제를 거부한다.             | 비활성 인원을 새 지출 선택지에서 제외하면서 과거 원장에는 유지하는 UI·validator                   |
| 장소             | Google·NAVER·직접 입력 결과를 공통 `Place`로 정규화하는 타입과 provider 경계가 있다.                  | provider 원문 보관 범위, 중복 판정 기준과 국내 NAVER 연결 시점                                    |
| 일정             | 장소 없는 일정과 사용자 `order`를 표현할 수 있다.                                                     | 수동 `order`를 canonical로 할지, 시간순 정렬은 보조 action으로 둘지                               |
| 지도             | 번호 핀·직선 동선 render model과 확대 query가 있고 실제 경로·시간 계산은 외부 지도로 보낼 수 있다.    | 선택 날짜만 표시할지, 전체 여행 보기까지 넣을지. 실제 adapter 주입과 SDK는 아직 없다              |
| 비용 원장        | 한 `Expense`에서 결제자와 소비자를 표현하므로 개인·공동 비용을 같은 모델에 담을 수 있다.              | 배분 합계, 소비자 집합, 중복·비활성 Participant, itemized 합계를 저장 전에 어떤 계층에서 검증할지 |
| 통화             | 계약은 ISO 통화별 최소 단위 정수와 통화별 계산을 요구하며 현재 React 타입은 KRW·JPY만 허용한다.       | 첫 Android UI에서 여행당 한 통화만 허용할지, 지출별 통화를 허용할지                               |
| OCR              | 계약은 provider-neutral `parseReceipt`와 일본어 원문·한국어 번역을 요구하고 실제 provider는 미정이다. | fixture 정확도·가격·보관 정책의 합격 기준                                                         |
| 오프라인 경계    | Android Firestore persistence는 마지막 데이터와 pending write를 제공한다.                             | pending 표시 UX와 외부 장소·OCR 온라인 실패 처리                                                  |

## 4. 도쿄 여행 전 범위 제안

범위를 한 번에 모두 약속하지 않고 실제 여행에 필요한 최소선부터 검증한다.

### 전환 첫 세로 기능 조각

P0 전체를 한 번에 만들지 않는다. 먼저 Flutter Android 셸, `tokyo-2026-11` mock, 세 탭, Anonymous Auth, `createTrip`·공유 코드 입장과 Emulator 연결까지만 완성한다. 이 조각에서 format/analyze/test/debug APK와 두 익명 사용자 입장이 통과한 뒤 일정·Google 지도와 수동 정산으로 넘어간다.

### P0 · 여행에서 반드시 작동할 최소선

#### 공통·여행 세션

- 여행 이름, 기간과 예상 인원을 입력한다. 첫 배포에 국내 여행도 포함할 때만 국내/해외를 선택하게 한다.
- 도쿄 템플릿에는 Google·JPY를 기본값으로 제안하되 통화는 사용자가 확인·변경한다. 일반 해외여행의 국가·통화·time zone 입력 범위는 회의에서 정한다.
- Anonymous Auth로 바로 시작하고 MVP에서는 공유 코드로 같은 여행에 참여한다. Android App Links는 후속이다.
- 입장한 사용자는 기존 정산 명단에서 자신을 선택해 연결하고, 한 Participant에 중복 `linkedUid`가 생기지 않게 한다.
- 모든 멤버는 첫 배포에서 editor로 두고 세부 권한은 추가하지 않는다.

#### 일정·지도

- 합의한 형식의 Google Maps URL 붙여넣기, Google 장소 검색과 직접 입력 fallback을 제공한다.
- 장소 보관함은 전체 `Place`를 유지한다. ‘미배치 장소’는 별도 entity가 아니라 일정 연결 여부로 파생한 필터·요약이다.
- 날짜별 장소·일정을 추가·수정·삭제하고 수동 순서를 바꾼다. 드래그앤드롭 없이 위·아래 이동으로 구현해도 완료로 본다.
- 장소 없는 항공편·체크인·휴식 일정도 허용한다.
- 선택 날짜의 번호 핀·직선 동선을 같은 화면에서 확대하고 이동 구간은 외부 Google Maps 길찾기로 연다.
- 좌표 없는 일정은 삭제하지 않고 지도에서 제외 이유와 장소 수정 action을 보여준다.
- 실제 Routes API, 이동 시간 계산과 자동 동선 최적화는 넣지 않는다.

#### 비용·정산

- 참여자 추가·이름 수정·제외·재포함과 멤버 연결을 지원한다.
- 여행 전 예약비와 현지 지출을 같은 원장에 수동으로 추가·수정·삭제한다.
- 전체 균등과 참여자별 직접 금액 분할을 먼저 구현한다.
- 배분 합계와 총액, consumer/allocation 집합, 중복·존재하지 않는 Participant, 비활성 Participant의 신규 선택을 저장 전에 검증한다.
- 결제액·부담액·net과 개인 소비 내역을 결정적으로 계산한다. 혼합 통화를 채택하면 모든 결과와 송금 문구를 통화별로 분리한다.
- 솔로 여행에서는 송금 영역을 숨기고 카테고리·날짜별 개인 소비를 강조한다.

#### 안전망

- Android handset에서 하단 세 탭, system back, 키보드와 `SafeArea`를 검증한다.
- 실제 여행 전에 `.trip.json` 내보내기와 최소 복원 검증을 완료한다.
- Firestore cache·pending write와 서버 동기화 상태를 구분하고 외부 API 오류는 사용자가 재시도할 수 있게 한다.

### P1 · P0가 안정된 뒤 선택할 확장

- `준비` 탭을 유지한다면 예약의 제목·상태·링크·메모와 단순 공동 체크리스트만 저장한다.
- 항목별 분할은 수동 equal/custom과 원장 validator가 안정된 뒤 연결한다.
- 영수증 검토 UI와 수동 총액 fallback을 만든 뒤 실제 OCR을 연결한다.
- 일본어 fixture로 Document AI Expense Parser, 일반 OCR·Translation과 필요한 대체 provider를 정확도·비용·보관 정책 기준으로 비교한다.
- Google 연결 사용자에게 membership 기반 내 여행 목록을 제공하고 익명 사용자는 기기·앱 데이터 소실 가능성을 안내한다.
- Flutter Web은 일정·준비·비용 검토용 보조판으로만 별도 검증하고 Android 기능 동등성을 완료 조건으로 두지 않는다.

## 5. 추가로 검토할 기능 후보

이 표는 상세 문서의 기존 기능 ID를 요약한다. 새 기능 ID는 해당 영역 문서의 `추가 제안` 표에서만 배정한다.

| 기능                                | 관련 기존 ID     | 기대 효과와 최소 구현                                                                             | 권장 시점      |
| ----------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------- | -------------- |
| Google Sheets·CSV 가져오기          | `IT-L05`         | 기존 여행 계획을 다시 입력하지 않는다. 우선 고정 CSV 형식 한 개만 지원한다.                       | P0 이후        |
| 여행 복제·템플릿                    | `IT-L05`         | 이전 여행 구조를 새 일정의 출발점으로 재사용한다.                                                 | 후속           |
| 캘린더 `.ics` 내보내기              | `IT-L05`         | 항공·예약·일정을 휴대폰 캘린더에서 확인한다.                                                      | 후속           |
| 선택 날짜·지도 상태 URL 보존        | `IT-04`, `IT-08` | 링크를 열었을 때 같은 날짜와 지도 확대 상태를 복원한다.                                           | P0 후보        |
| 장소 정확 일치 중복 방지            | `IT-03`          | 같은 `provider + providerPlaceId` 또는 정규화 URL의 중복만 막는다. 이름·좌표 유사도 판정은 후속.  | P0 후보        |
| 개인/공동 체크리스트와 담당자       | `PREP-02`        | 공동 작업과 개인 준비물을 구분한다. 마감·알림·첨부는 넣지 않는다.                                 | P1 범위 조정   |
| 예약과 선결제 지출 연결             | 새 ID 검토 필요  | 숙소·항공 예약에서 연결된 비용을 바로 확인한다. 일정은 시간의 기준, 예약은 상태·링크·메모로 둔다. | 후속           |
| 예산 대비 실제 지출                 | `ST-L05`         | 날짜·카테고리별 예산과 실제 소비 차이를 확인한다.                                                 | 수동 원장 이후 |
| 비용 CSV 내보내기                   | 새 ID 검토 필요  | 여행 후 Sheets에서 원장과 개인 소비를 추가 분석한다.                                              | 백업 이후      |
| 한국어·일본어 OCR fixture benchmark | `OCR-01`         | provider를 이름이 아니라 항목 정확도·가격·보관 정책으로 검증한다.                                 | OCR 연결 전    |
| 읽기 전용 오프라인 여행 팩          | 새 ID 검토 필요  | 마지막 동기화 일정·예약·체크를 확인한다. 데이터 최신 시각을 함께 표시한다.                        | P1 후보        |

## 6. 첫 배포 제외 권장안

아래 항목은 회의 전 권장안이며, 채택 후 상세 문서의 상태를 `제외` 또는 `후속`으로 변경한다.

- 한 여행에서 Google과 NAVER provider 혼합 또는 사용자의 수동 provider 전환
- 앱 내부 실제 도로·대중교통 경로, 이동 시간과 자동 일정 최적화
- NAVER 비공개 내부 API 기반 저장 목록 import
- Google/NAVER 계정의 저장 목록 자동 동기화
- 이름·좌표 유사도를 이용한 퍼지 장소 중복 감지
- 자동 환율 환산과 근거 없는 서로 다른 통화 합산
- 지출당 복수 결제자, 환불 원장, 정산 확정 snapshot과 송금 완료 상태
- OCR 결과 자동 확정, 영수증 이미지 영구 보관, 여러 장 비동기 OCR
- owner/editor/viewer 세부 권한, 활동 피드, 변경 이력과 되돌리기
- 여권 사본과 민감한 예약 문서 보관
- 완전한 오프라인 편집과 충돌 병합
- 승인 없는 실제 Firebase 배포, 유료 API 호출과 secret 등록

## 7. 구현 전에 남은 제품 선택

Flutter·Android·Google 우선과 구현 순서는 확정됐다. 아래 선택만 코드 모델이나 UX를 고정하기 전에 결정한다.

| 우선순위 | 질문                                              | 권장 기본값                                                                       |
| -------- | ------------------------------------------------- | --------------------------------------------------------------------------------- |
| P0       | 공유 입장자를 Participant와 어떻게 연결할까?      | 입장 직후 기존 정산 명단에서 자신을 선택하고 중복 `linkedUid`를 막는다.           |
| P0       | 어떤 Google Maps URL을 지원할까?                  | 일반 장소·검색 URL부터 지원하고 단축 URL은 서버 비용·abuse 제한 확인 뒤 추가한다. |
| P0       | `준비`의 최소 저장 범위는 어디까지인가?           | 예약 제목·유형·상태·URL·메모와 공동/개인 체크리스트까지만 저장한다.               |
| P0       | 한 여행에서 KRW와 JPY를 함께 쓸까?                | 지출별 통화를 허용한다면 모든 합계·net·송금안을 통화별로 분리한다.                |
| P0       | Participant 제외와 과거 지출을 어떻게 다룰까?     | 물리 삭제하지 않고 `isActive: false`로 두며 과거 지출 참조는 유지한다.            |
| P1       | 예약비의 `expenseDate`는 결제일인가 이용일인가?   | 결제일로 통일하고 이용일은 연결된 일정에서 확인한다.                              |
| P1       | OCR provider benchmark의 합격 기준은 무엇인가?    | 일본어 항목·총액 정확도, 번역 이해도, 처리 비용과 보관 정책을 수치로 정한다.      |
| P1       | 앱 삭제·익명 세션 소실을 어떻게 안내할까?         | Google 연결과 `.trip.json` 백업을 제공하되 강제 로그인은 하지 않는다.             |
| P1       | Firestore offline write를 UI에서 어떻게 표시할까? | 로컬 반영, 동기화 대기, 서버 완료와 실패를 구분한다.                              |

## 8. 첫 배포 성공 기준

- 익명 사용자 두 명이 공유 코드로 같은 여행의 member가 되고 각자의 Participant를 중복 없이 연결한다.
- 두 사용자가 장소·일정을 추가·수정하면 상대 화면에 반영되고 앱 재시작 뒤에도 유지된다.
- 선택 날짜와 지도 확대 상태가 Android router에서 복원되며 외부 길찾기를 열 수 있다.
- 좌표 없는 일정은 일정에 남고 지도 제외 이유와 수정 action이 보인다.
- 수동 equal/custom 지출의 유효·무효 입력이 validator를 통과·거부하고 같은 원장에서 항상 같은 계산 결과가 나온다.
- 혼합 통화를 채택하면 KRW와 JPY의 합계·net·송금 문구가 서로 합산되지 않는다.
- 예약과 체크 완료 상태가 두 사용자 사이에서 저장·반영된다.
- `.trip.json`을 내보내고 테스트 여행으로 복원할 수 있다.
- Android handset에서 하단 세 탭, system back, 키보드와 `SafeArea`가 정상 동작한다.
- Flutter format/analyze/test, debug APK와 backend Emulator 검증이 통과한다.

## 9. 회의 후 계약 정리 체크리스트

- [x] 제품·요구사항·기술·구조·디자인 계약을 Flutter Android와 도쿄·Google 우선으로 정리한다.
- [x] 메뉴를 `일정·지도 / 준비 / 비용`으로 맞추고 영수증을 비용 하위로 둔다.
- [x] Task 3·5를 Google 우선, Task 6을 통화별 최소 단위, Task 7을 provider-neutral OCR·번역으로 정리한다.
- [x] `Reservation`, `ChecklistItem`의 최소 wire 계약과 Firestore 경로를 문서화한다.
- [x] 핵심 Flutter Dart 모델과 mock/Firestore repository 계약을 구현한다. 준비 모델은 후속이다.
- [x] Flutter 금액 타입을 `CurrencyAmount`로 정의한다. React `KrwAmount`는 legacy 목업 종료 때 제거한다.
- [x] Flutter `Trip`에 국가·time zone·지도 provider·기본 통화를 반영한다.
- [x] Participant 물리 삭제를 repository와 Firestore Rules에서 막고 비활성화만 제공한다.
- [ ] 새 독립 기능은 상세 문서의 `추가 제안` 표에서 ID를 먼저 배정한다.
- [ ] 채택한 기존 기능 ID만 `TASK-01`~`TASK-09` 체크리스트와 완료 조건에 반영한다.

## 10. 담당별 다음 구현 묶음

| 담당           | 첫 구현 묶음                                                                                 | 통합 전 확인                                              |
| -------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| 플랫폼·통합    | Flutter client→Emulator 수직 검증, 멤버-Participant 연결 Callable, Android 백업 파일 adapter | Dart 모델·Firestore 경로·보안 규칙·Emulator               |
| 장소·일정·지도 | Google place provider와 링크 fallback, 장소·일정 CRUD, 수동 순서·날짜·지도 갱신              | NAVER가 같은 `Place`·`MapAdapter` 경계를 사용할 수 있는지 |
| 정산·영수증    | runtime validator, 수동 equal/custom, paid/owed/net, 이후 itemized와 영수증 검토 UI          | 통화별 결정성, 비활성 인원, 사용자 확정 전 미반영         |

다음 회의에서는 남은 P0 질문을 먼저 결정하고 추가 후보는 첫 Android 배포 일정에 영향을 주지 않는 범위에서만 채택한다.
