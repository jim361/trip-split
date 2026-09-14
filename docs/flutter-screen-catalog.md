# Flutter Android 화면 목록

2026-09-14 현재 구현된 **19개 페이지 Widget과 공통 오류 화면, 총 49장**을 모았다. 페이지 목록은 현재 코드의 화면 단위이며, 번호는 이 문서의 사진 번호다. 기존 TASK·기능 ID와 별개다.

[API 인계](frontend-api-handoff.md) · [개발 시작 안내](development-kickoff.md) · [Android 두 앱 검증](android-emulator-qa.md) · [시트 내보내기](sheet-export.md)

## 촬영 기준

- 실제 Android AVD에서 현재 Flutter Widget을 실행하고, 공식 integration_test 스크린샷 API로 앱 표면을 캡처했다. React Pages 목업이나 디자인 이미지가 아니다. Android 시스템 상태바·키보드·공유 선택기는 촬영 대상에 포함하지 않았다.
- AVD: TripSplit_Owner_API36 / Pixel 4 / Android 16(API 36), 화면 720×1520, 280dpi, RAM 3072MB, software GPU. Flutter 3.47.2 / Dart 3.13.2.
- 기준 코드: dev의 `305d729` + 촬영 시점의 미커밋 Flutter 구현. 해당 커밋만 checkout하면 같은 UI가 재현된다는 뜻은 아니다. [촬영 결과 JSON](screenshots/2026-09-14/android-catalog/capture-result.json)에 전체 기준 SHA·미커밋 여부·실행 시각·파일 목록을 남긴다.
- 데이터: 기존 `tokyo-2026-11` fixture와 InMemoryTripRepositories, MockAuthService·MockPlaceProvider·MockReceiptParser. 각 시나리오를 새 메모리 repository로 시작하므로 시나리오 사이의 추가 지출·동행은 누적되지 않는다.
- 로그인 UID·공유 코드·여행·예약 링크·영수증은 샘플이다. 실제 Firebase, Google Maps/Places, Google OAuth/Sheets, OCR 서버를 호출하지 않았다. 지도는 번호 핀·직선 동선 자리 표시이며 Sheets 생성 버튼은 연결 설정이 없어 비활성이다.
- 한 장은 그때 보이는 영역이다. 일정 목록·영수증 검토는 아래 영역을 추가로 담았고, 시트는 가로·세로 스크롤되는 표의 현재 영역을 담았다.

## 화면별 진입과 연결

표의 저장 경계는 Firebase 모드 또는 외부 서비스 활성화 시 연결되는 코드 계약이다. 이번 사진은 모두 mock 실행 결과다. named route가 없는 하위 페이지는 버튼으로 이동하는 MaterialPageRoute다.

| 화면 / 구현                                                                                                   | 진입 경로                                                | 사진             | TASK           | 저장·서비스 경계                                                                                | 남은 검증                                     |
| ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ---------------- | -------------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------- |
| 시작<br>[AccountEntryPage](../frontend/lib/features/auth/account_entry_page.dart)                             | `/` · 앱 실행                                            | 01               | TASK-02        | AuthService: 익명 세션·Google 연결                                                              | Google 계정 연결·복구 실환경 검증             |
| 내 여행·생성·참여<br>[TripHomePage](../frontend/lib/features/trips/trip_home_page.dart)                       | `/trips`, `/trips?join=true` · 시작 → 게스트 / 공유 참여 | 02–06            | TASK-02        | listMyTrips, createTrip, joinTrip                                                               | 실계정 목록·기존 사용자 복구 검증             |
| 일정·지도<br>[ItineraryPage](../frontend/lib/features/itinerary/itinerary_page.dart)                          | `/trips/{id}/itinerary` · 하단 일정·지도                 | 07–08, 12–13, 49 | TASK-04/05     | itinerary·places 구독, order transaction, MapViewBuilder                                        | 실제 Google 지도·좌표·핀·카메라 상태 검증     |
| 일정 추가·편집<br>[ItineraryEditPage](../frontend/lib/features/itinerary/itinerary_edit_page.dart)            | 일정 추가 / 일정 행·지도 핀 선택                         | 09, 11           | TASK-04        | itinerary CRUD + Rules                                                                          | A/B·재정렬·동시 변경 Android 전체 QA          |
| 장소 검색·선택<br>[PlacesPage](../frontend/lib/features/places/places_page.dart)                              | 장소 보관함 / 일정 편집 → 보관함에서 장소 추가·선택      | 10, 14–17        | TASK-03        | searchPlaces, parsePlaceLink, places 구독                                                       | 실제 Places 결과·할당량·실패 처리 검증        |
| 장소 추가·편집<br>[PlaceEditPage](../frontend/lib/features/places/places_page.dart)                           | 직접 입력 / 검색 후보 / 저장 장소 선택                   | 18–19            | TASK-03        | places CRUD + Rules                                                                             | 삭제·연결 경합과 실제 링크 형태 검증          |
| 준비 목록<br>[PreparationPage](../frontend/lib/features/preparation/preparation_page.dart)                    | `/trips/{id}/preparation` · 하단 준비                    | 20, 23           | TASK-04        | reservations·checklistItems 구독/CRUD                                                           | 예약·담당자·삭제의 Android 전체 QA            |
| 예약·체크리스트 입력<br>[PreparationEditPage](../frontend/lib/features/preparation/preparation_page.dart)     | 예약 추가 / 항목 추가 / 기존 행 선택                     | 21–22            | TASK-04        | saveReservation, saveChecklist                                                                  | URL·삭제된 참조·다른 기기 편집 검증           |
| 비용 목록<br>[SettlementPage](../frontend/lib/features/settlement/settlement_page.dart)                       | `/trips/{id}/settlement` · 하단 비용                     | 24               | TASK-06        | expenses·participants 구독, Dart 정산                                                           | 혼합 통화·동시 수정의 Android 전체 QA         |
| 지출 입력·배분<br>[ExpenseEditPage](../frontend/lib/features/settlement/expense_edit_page.dart)               | 비용 → 지출 추가 / 상세 → 지출 수정                      | 25–27            | TASK-06        | createExpense, updateExpense                                                                    | custom·응답 유실·중복 제출 실환경 검증        |
| 지출 상세<br>[ExpenseDetailPage](../frontend/lib/features/settlement/expense_detail_page.dart)                | 비용 행 / 지출 저장 완료                                 | 28–29, 41        | TASK-06/07     | expense 구독, deleteExpense                                                                     | 삭제·동시 변경·itemized 전체 QA               |
| 정산 참여자<br>[ParticipantsPage](../frontend/lib/features/settlement/participants_page.dart)                 | 비용 → 정산 참여자 관리                                  | 30               | TASK-02/06     | participants 구독, linkMyParticipant                                                            | 계정 재연결·비활성 참여자 실환경 검증         |
| 참여자 입력<br>[ParticipantEditPage](../frontend/lib/features/settlement/participants_page.dart)              | 참여자 추가 / 참여자 행 선택                             | 31–32            | TASK-06        | participants CRUD + Rules                                                                       | 기존 지출 보존·비활성 전환 Android 검증       |
| 개인 소비·정산<br>[PersonalSettlementPage](../frontend/lib/features/settlement/personal_settlement_page.dart) | 비용 → 개인 소비·정산                                    | 33–34            | TASK-06        | 원장 구독·Dart 통화별 계산·Clipboard                                                            | 필터·혼합 통화·복사와 큰 글씨 검증            |
| 영수증 입력<br>[ReceiptsPage](../frontend/lib/features/receipts/receipts_page.dart)                           | `/trips/{id}/receipts` · 비용 → 영수증으로 등록          | 35–36            | TASK-07        | AndroidActions → ReceiptParser / parseReceipt                                                   | 실기기 카메라·Photo Picker·실제 OCR은 Phase C |
| 영수증 검토·배분<br>[ReceiptReviewPage](../frontend/lib/features/receipts/receipt_review_page.dart)           | 이미지 선택 → 인식하고 검토하기                          | 37–38, 40        | TASK-07/06     | 인식 후보 → Dart 배분 → 지출 Callable                                                           | 실제 OCR·번역 신뢰도·실패·통화 확인 검증      |
| 영수증 항목 편집<br>[ReceiptItemEditPage](../frontend/lib/features/receipts/receipt_item_edit_page.dart)      | 검토 → 항목 행 / 누락 항목·할인·봉사료 추가              | 39               | TASK-07/06     | 로컬 초안·Dart 배분, 확인 저장 때 원장 반영                                                     | 할인·조정·항목 순서·부분 소비자 Android QA    |
| 여행 설정·공유<br>[TripSettingsPage](../frontend/lib/features/trips/trip_settings_page.dart)                  | 여행 상단 톱니바퀴                                       | 42–43            | TASK-02        | trip update, createShareCode, AndroidActions                                                    | 시스템 공유·기간 변경·코드 재생성 실기기 검증 |
| 시트 옵션·미리보기<br>[TripSheetsPage](../frontend/lib/features/sheets/trip_sheets_page.dart)                 | 여행 설정 → 시트 내보내기 → 미리보기                     | 44–46            | TASK-08 (병행) | loadTripSnapshot → 보고서 → GoogleSheetsService                                                 | 실제 OAuth·Sheets 생성·재시작 복구 검증       |
| 공통 여행 오류 / 경로 오류                                                                                    | 없는 여행 ID / 정의되지 않은 route                       | 47–48            | TASK-01/09     | [TripRouteHost](../frontend/lib/app/trip_shell.dart), [앱 라우터](../frontend/lib/app/app.dart) | 권한·네트워크 재시도·실환경 시작 설정 오류    |

## 캡처 갤러리

각 묶음을 펼친 뒤 이미지를 누르면 PNG 원본을 연다. 현재 화면을 논의할 때 “사진 27 · 직접 배분”처럼 사진 번호와 상태를 함께 적는다.

<details>
<summary>시작·내 여행·공유 · 6장</summary>

| 화면                                                                                                                                                                                   | 화면                                                                                                                                                                                                             |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 01 · 계정 시작<br>[<img src="screenshots/2026-09-14/android-catalog/01-account.png" width="260" alt="계정 시작">](screenshots/2026-09-14/android-catalog/01-account.png)               | 02 · 내 여행·전체 일정표<br>[<img src="screenshots/2026-09-14/android-catalog/02-trip-home.png" width="260" alt="내 여행·전체 일정표">](screenshots/2026-09-14/android-catalog/02-trip-home.png)                 |
| 03 · 여행 생성<br>[<img src="screenshots/2026-09-14/android-catalog/03-trip-create.png" width="260" alt="여행 생성">](screenshots/2026-09-14/android-catalog/03-trip-create.png)       | 04 · 여행 이름 검증 오류<br>[<img src="screenshots/2026-09-14/android-catalog/04-trip-create-error.png" width="260" alt="여행 이름 검증 오류">](screenshots/2026-09-14/android-catalog/04-trip-create-error.png) |
| 05 · 공유 코드 참여<br>[<img src="screenshots/2026-09-14/android-catalog/05-trip-join.png" width="260" alt="공유 코드 참여">](screenshots/2026-09-14/android-catalog/05-trip-join.png) | 06 · 없는 공유 코드 오류<br>[<img src="screenshots/2026-09-14/android-catalog/06-trip-join-error.png" width="260" alt="없는 공유 코드 오류">](screenshots/2026-09-14/android-catalog/06-trip-join-error.png)     |

</details>

<details>
<summary>일정·지도 · 8장</summary>

| 화면                                                                                                                                                                                                                                     | 화면                                                                                                                                                                                                       |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 07 · 일정·지도 기본<br>[<img src="screenshots/2026-09-14/android-catalog/07-itinerary-map.png" width="260" alt="일정·지도 기본">](screenshots/2026-09-14/android-catalog/07-itinerary-map.png)                                           | 49 · 일정 목록 아래 영역<br>[<img src="screenshots/2026-09-14/android-catalog/49-itinerary-list.png" width="260" alt="일정 목록 아래 영역">](screenshots/2026-09-14/android-catalog/49-itinerary-list.png) |
| 08 · 지도 확대<br>[<img src="screenshots/2026-09-14/android-catalog/08-map-expanded.png" width="260" alt="지도 확대">](screenshots/2026-09-14/android-catalog/08-map-expanded.png)                                                       | 09 · 기존 일정 편집<br>[<img src="screenshots/2026-09-14/android-catalog/09-itinerary-edit.png" width="260" alt="기존 일정 편집">](screenshots/2026-09-14/android-catalog/09-itinerary-edit.png)           |
| 10 · 일정에 연결할 장소 선택<br>[<img src="screenshots/2026-09-14/android-catalog/10-itinerary-place-selection.png" width="260" alt="일정에 연결할 장소 선택">](screenshots/2026-09-14/android-catalog/10-itinerary-place-selection.png) | 11 · 새 일정 입력<br>[<img src="screenshots/2026-09-14/android-catalog/11-itinerary-add.png" width="260" alt="새 일정 입력">](screenshots/2026-09-14/android-catalog/11-itinerary-add.png)                 |
| 12 · B안 선택<br>[<img src="screenshots/2026-09-14/android-catalog/12-itinerary-plan-b.png" width="260" alt="B안 선택">](screenshots/2026-09-14/android-catalog/12-itinerary-plan-b.png)                                                 | 13 · 빈 날짜 일정<br>[<img src="screenshots/2026-09-14/android-catalog/13-itinerary-empty.png" width="260" alt="빈 날짜 일정">](screenshots/2026-09-14/android-catalog/13-itinerary-empty.png)             |

</details>

<details>
<summary>장소 · 6장</summary>

| 화면                                                                                                                                                                                                 | 화면                                                                                                                                                                                                 |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 14 · 장소 보관함<br>[<img src="screenshots/2026-09-14/android-catalog/14-places.png" width="260" alt="장소 보관함">](screenshots/2026-09-14/android-catalog/14-places.png)                           | 15 · 장소 검색 결과<br>[<img src="screenshots/2026-09-14/android-catalog/15-place-search.png" width="260" alt="장소 검색 결과">](screenshots/2026-09-14/android-catalog/15-place-search.png)         |
| 16 · 빈 검색 결과<br>[<img src="screenshots/2026-09-14/android-catalog/16-place-search-empty.png" width="260" alt="빈 검색 결과">](screenshots/2026-09-14/android-catalog/16-place-search-empty.png) | 17 · 지도 링크 오류<br>[<img src="screenshots/2026-09-14/android-catalog/17-place-link-error.png" width="260" alt="지도 링크 오류">](screenshots/2026-09-14/android-catalog/17-place-link-error.png) |
| 18 · 장소 직접 입력<br>[<img src="screenshots/2026-09-14/android-catalog/18-place-add.png" width="260" alt="장소 직접 입력">](screenshots/2026-09-14/android-catalog/18-place-add.png)               | 19 · 저장 장소 편집<br>[<img src="screenshots/2026-09-14/android-catalog/19-place-edit.png" width="260" alt="저장 장소 편집">](screenshots/2026-09-14/android-catalog/19-place-edit.png)             |

</details>

<details>
<summary>준비 · 4장</summary>

| 화면                                                                                                                                                                                               | 화면                                                                                                                                                                                                                         |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 20 · 빈 준비 목록<br>[<img src="screenshots/2026-09-14/android-catalog/20-preparation-empty.png" width="260" alt="빈 준비 목록">](screenshots/2026-09-14/android-catalog/20-preparation-empty.png) | 21 · 예약 정보 입력<br>[<img src="screenshots/2026-09-14/android-catalog/21-reservation-edit.png" width="260" alt="예약 정보 입력">](screenshots/2026-09-14/android-catalog/21-reservation-edit.png)                         |
| 22 · 체크리스트 입력<br>[<img src="screenshots/2026-09-14/android-catalog/22-checklist-edit.png" width="260" alt="체크리스트 입력">](screenshots/2026-09-14/android-catalog/22-checklist-edit.png) | 23 · 예약 저장·체크리스트 완료<br>[<img src="screenshots/2026-09-14/android-catalog/23-preparation-saved.png" width="260" alt="예약 저장·체크리스트 완료">](screenshots/2026-09-14/android-catalog/23-preparation-saved.png) |

</details>

<details>
<summary>비용·수동 지출 · 6장</summary>

| 화면                                                                                                                                                                                                             | 화면                                                                                                                                                                                                             |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 24 · 여행 비용<br>[<img src="screenshots/2026-09-14/android-catalog/24-settlement.png" width="260" alt="여행 비용">](screenshots/2026-09-14/android-catalog/24-settlement.png)                                   | 25 · 지출 기본 정보<br>[<img src="screenshots/2026-09-14/android-catalog/25-expense-entry.png" width="260" alt="지출 기본 정보">](screenshots/2026-09-14/android-catalog/25-expense-entry.png)                   |
| 26 · 균등 배분<br>[<img src="screenshots/2026-09-14/android-catalog/26-expense-equal.png" width="260" alt="균등 배분">](screenshots/2026-09-14/android-catalog/26-expense-equal.png)                             | 27 · 직접 배분<br>[<img src="screenshots/2026-09-14/android-catalog/27-expense-custom.png" width="260" alt="직접 배분">](screenshots/2026-09-14/android-catalog/27-expense-custom.png)                           |
| 28 · 저장한 지출 상세<br>[<img src="screenshots/2026-09-14/android-catalog/28-expense-detail-saved.png" width="260" alt="저장한 지출 상세">](screenshots/2026-09-14/android-catalog/28-expense-detail-saved.png) | 29 · 지출 삭제 확인<br>[<img src="screenshots/2026-09-14/android-catalog/29-expense-delete-confirm.png" width="260" alt="지출 삭제 확인">](screenshots/2026-09-14/android-catalog/29-expense-delete-confirm.png) |

</details>

<details>
<summary>참여자·개인 정산 · 5장</summary>

| 화면                                                                                                                                                                                                     | 화면                                                                                                                                                                                                                 |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 30 · 정산 참여자<br>[<img src="screenshots/2026-09-14/android-catalog/30-participants.png" width="260" alt="정산 참여자">](screenshots/2026-09-14/android-catalog/30-participants.png)                   | 31 · 참여자 추가<br>[<img src="screenshots/2026-09-14/android-catalog/31-participant-add.png" width="260" alt="참여자 추가">](screenshots/2026-09-14/android-catalog/31-participant-add.png)                         |
| 32 · 참여자 편집<br>[<img src="screenshots/2026-09-14/android-catalog/32-participant-edit.png" width="260" alt="참여자 편집">](screenshots/2026-09-14/android-catalog/32-participant-edit.png)           | 33 · 개인 소비·송금 제안<br>[<img src="screenshots/2026-09-14/android-catalog/33-personal-settlement.png" width="260" alt="개인 소비·송금 제안">](screenshots/2026-09-14/android-catalog/33-personal-settlement.png) |
| 34 · 지출 없는 KRW 정산<br>[<img src="screenshots/2026-09-14/android-catalog/34-personal-empty.png" width="260" alt="지출 없는 KRW 정산">](screenshots/2026-09-14/android-catalog/34-personal-empty.png) |                                                                                                                                                                                                                      |

</details>

<details>
<summary>영수증 · 7장</summary>

| 화면                                                                                                                                                                                                         | 화면                                                                                                                                                                                                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 35 · 영수증 이미지 선택 진입<br>[<img src="screenshots/2026-09-14/android-catalog/35-receipts.png" width="260" alt="영수증 이미지 선택 진입">](screenshots/2026-09-14/android-catalog/35-receipts.png)       | 36 · 샘플 영수증<br>[<img src="screenshots/2026-09-14/android-catalog/36-receipt-sample.png" width="260" alt="샘플 영수증">](screenshots/2026-09-14/android-catalog/36-receipt-sample.png)                 |
| 37 · 영수증 검토<br>[<img src="screenshots/2026-09-14/android-catalog/37-receipt-review.png" width="260" alt="영수증 검토">](screenshots/2026-09-14/android-catalog/37-receipt-review.png)                   | 38 · 원문·번역<br>[<img src="screenshots/2026-09-14/android-catalog/38-receipt-translation.png" width="260" alt="원문·번역">](screenshots/2026-09-14/android-catalog/38-receipt-translation.png)           |
| 39 · 항목·조정 편집<br>[<img src="screenshots/2026-09-14/android-catalog/39-receipt-item.png" width="260" alt="항목·조정 편집">](screenshots/2026-09-14/android-catalog/39-receipt-item.png)                 | 40 · 전체 항목 배분<br>[<img src="screenshots/2026-09-14/android-catalog/40-receipt-allocations.png" width="260" alt="전체 항목 배분">](screenshots/2026-09-14/android-catalog/40-receipt-allocations.png) |
| 41 · 영수증 지출 저장 결과<br>[<img src="screenshots/2026-09-14/android-catalog/41-receipt-saved.png" width="260" alt="영수증 지출 저장 결과">](screenshots/2026-09-14/android-catalog/41-receipt-saved.png) |                                                                                                                                                                                                            |

</details>

<details>
<summary>설정·시트 · 5장</summary>

| 화면                                                                                                                                                                                                         | 화면                                                                                                                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 42 · 여행 설정·공유<br>[<img src="screenshots/2026-09-14/android-catalog/42-trip-settings.png" width="260" alt="여행 설정·공유">](screenshots/2026-09-14/android-catalog/42-trip-settings.png)               | 43 · 공유 코드 변경 확인<br>[<img src="screenshots/2026-09-14/android-catalog/43-share-code-confirm.png" width="260" alt="공유 코드 변경 확인">](screenshots/2026-09-14/android-catalog/43-share-code-confirm.png) |
| 44 · 시트 출력 옵션<br>[<img src="screenshots/2026-09-14/android-catalog/44-sheet-options.png" width="260" alt="시트 출력 옵션">](screenshots/2026-09-14/android-catalog/44-sheet-options.png)               | 45 · 일정·지출 미리보기<br>[<img src="screenshots/2026-09-14/android-catalog/45-sheet-itinerary.png" width="260" alt="일정·지출 미리보기">](screenshots/2026-09-14/android-catalog/45-sheet-itinerary.png)         |
| 46 · 지출·정산 미리보기<br>[<img src="screenshots/2026-09-14/android-catalog/46-sheet-settlement.png" width="260" alt="지출·정산 미리보기">](screenshots/2026-09-14/android-catalog/46-sheet-settlement.png) |                                                                                                                                                                                                                    |

</details>

<details>
<summary>공통 오류 · 2장</summary>

| 화면                                                                                                                                                                                   | 화면                                                                                                                                                                                     |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 47 · 없는 여행<br>[<img src="screenshots/2026-09-14/android-catalog/47-trip-not-found.png" width="260" alt="없는 여행">](screenshots/2026-09-14/android-catalog/47-trip-not-found.png) | 48 · 없는 경로<br>[<img src="screenshots/2026-09-14/android-catalog/48-route-not-found.png" width="260" alt="없는 경로">](screenshots/2026-09-14/android-catalog/48-route-not-found.png) |

</details>

## 촬영 범위 밖의 상태

- 캐시·저장 대기·재접속은 [두 Android 앱 검증](android-emulator-qa.md)에서 별도로 확인했다. 이번 mock 갤러리에 오프라인 상태를 연출하지 않았으며, 실제 서버 반영 상태 사진은 [소유자](screenshots/2026-09-14/android-emulator-owner-synced.png)·[참여자](screenshots/2026-09-14/android-emulator-guest-synced.png)를 본다.
- 실기기 촬영/사진 선택/공유 선택기, 실제 Google 계정 연결·지도·검색·Sheets 생성 성공 및 복구, 모든 권한/timeout/동시 편집 상태의 캡처는 남아 있다. 화면 캡처 완료를 Phase B/C 완료나 외부 연결 검증으로 취급하지 않는다.
- 시작 설정 오류·인증 재시도 같은 일시적 상태와 날짜/시간 선택기의 모든 변형은 이번 목록에 전부 담지 않았다. 오류 경계 코드는 [main](../frontend/lib/main.dart), [AuthSessionGate](../frontend/lib/app/auth_session_gate.dart)에 있다.
- `.trip.json` 파일 저장·복원은 아직 완성된 제품 페이지가 없어 이 갤러리에 없다. [TASK-08](../MarkDown/task/task_function8_backup_export.md)의 후속 작업이다.

## 다시 촬영하기

2026-09-14 검증: Android 캡처 시나리오 10개 통과, 49장 생성. PNG 크기 720×1520·중복 없음과 문서의 로컬 참조 134개를 확인했다. `npm run verify:fast`의 React 59개·backend 32개, `npm run verify:flutter:fast`의 Flutter 133개 테스트도 통과했다. 캡처 중 발견한 재입력·화면 전환 대기 문제는 캡처 도구에서 보완했으며 제품 코드는 변경하지 않았다.

Android Studio Device Manager에서 AVD를 실행하고 `adb devices -l`에 device로 보이는지 확인한다. 이전 두 앱 검증의 AVD 설정은 [실행 안내](android-emulator-qa.md)를 따른다. 이 캡처에는 Firebase Emulator나 Google 설정 파일이 필요하지 않다.

`frontend/`에서 아래 명령을 실행한다. 아래 대상 serial은 실제 실행 중인 AVD에 맞춘다. 사진 저장 폴더는 새 촬영 날짜로 바꾼다. `--keep-app-running`은 drive 종료 시 기존 설치 앱의 데이터가 삭제되는 정리를 피하기 위해 유지한다.

```powershell
New-Item -ItemType Directory -Force build/screen-catalog | Out-Null
flutter build apk --debug --target=integration_test/screen_catalog_test.dart --dart-define=DATA_SOURCE=mock
Copy-Item build/app/outputs/flutter-apk/app-debug.apk build/screen-catalog/capture.apk
$env:SCREENSHOT_DIR = '../docs/screenshots/2026-09-14/android-catalog'
flutter drive --driver=test_driver/screen_catalog.dart --target=integration_test/screen_catalog_test.dart --use-application-binary=build/screen-catalog/capture.apk -d emulator-5554 --no-dds --host-vmservice-port=5880 --keep-app-running
npx prettier --write "$env:SCREENSHOT_DIR/capture-result.json"
```

[캡처 시나리오](../frontend/integration_test/screen_catalog_test.dart)와 [PNG 저장 driver](../frontend/test_driver/screen_catalog.dart)는 기존 integration_test를 사용한다. 실행 종료 코드와 capture-result.json의 passed를 확인하고, 파일 수·중복·한글·입력값·스크롤 위치를 직접 검토한다. 시나리오는 일반 flutter test 대상 밖에 있으므로 Android에서 별도로 실행한다.

이 APK의 진입점은 캡처 테스트다. 일반 개발을 재개할 때는 `flutter run -d emulator-5554` 또는 [Firebase Emulator용 실행 명령](android-emulator-qa.md)을 사용해 일반 앱을 다시 설치한다. 이번 촬영 후에는 이전 일반 개발 APK로 복원했다.

## 문서 갱신 규칙

1. 화면이나 중요한 상태가 바뀌면 해당 사진과 목록 행을 함께 갱신하고 촬영 날짜·데이터 출처·코드 기준을 기록한다.
2. 샘플 캡처와 실환경 검증 사진은 폴더·설명으로 구분한다. 기존 사진은 비교 이력으로 보존한다.
3. GitHub에 반영할 때 이 문서·PNG·촬영 결과·재현 코드를 함께 포함한다. 코드 기준은 촬영 당시의 상태를 보존하며, Git 반영 뒤에도 촬영 결과 JSON의 미커밋 표기를 소급 변경하지 않는다.
