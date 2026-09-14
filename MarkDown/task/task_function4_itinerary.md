# Task Function 4 - Itinerary

> **[TASK-04 · 일정]** 날짜별 일정 작성, 순서와 장소 연결 기능입니다.

## 목표

날짜별 시간표를 만들고, 장소 보관함의 장소를 일정 항목에 연결한다.

Flutter의 `ItineraryItemDraft`와 React 일정 form이 입력을 먼저 검증하고, repository와 Firestore Rules가 최종 저장 경계를 담당한다. 두 클라이언트는 `ItineraryItem`의 날짜·시간·제목·장소·메모·planId·category·order 의미를 공유한다. legacy 문서의 planId/category 누락은 읽기 경계에서 A/other로 해석한다.

## 담당

사용자(플랫폼·통합)는 Flutter 일정·준비 화면, 입력 검증·재정렬과 client repository를 구현한다. 일정·지도 백엔드 담당은 Firestore Rules·인덱스·Emulator 검증과 준비 저장 계약을 맡는다. 일정 CRUD는 기존 Firestore 직접 쓰기를 사용하며 별도 Callable을 추가하지 않는다. 공통 모델과 경로 변경은 함께 검토한다.

## 작업

- [x] `ItineraryItem` 타입 정의
- [x] Firestore itinerary 구조 설계
- [ ] `Reservation`, `ChecklistItem` 최소 계약과 Firestore 경로 설계
- [x] ItineraryItem에 updatedBy, updatedAt 반영
- [x] 날짜별 탭 또는 섹션 구현
- [x] `/trips/:tripId/itinerary`의 선택 날짜 지도와 아래 compact 일정 row를 하나의 스크롤 흐름으로 구성
- [x] React/Vite 날짜×시간 grid와 하단 form에서 일정 추가 구현
- [x] block 선택 후 같은 form에서 일정 수정·삭제 구현
- [x] 날짜·시작·종료·제목·메모·유형 입력과 유형별 색상 구현
- [x] form에서 장소 선택·연결·해제 구현
- [x] 웹·Flutter의 A/B안 전환과 선택 안의 지도·요약 필터 구현
- [x] A/B·유형의 mock/Firestore/Rules 검증과 legacy 기본값 호환
- [x] Flutter Android에서 같은 일정 CRUD에 도달하는 compact 입력 흐름 구현
- [x] 장소 없는 항공편·체크인·휴식 일정 허용
- [x] 일정 순서 변경 구현
- [ ] 수동 `order`를 canonical로 저장하고 시간순 정렬은 명시적 보조 action으로 제공
- [ ] 일정·예약·체크리스트 데이터를 FlutterFire repository `Stream`으로 구독
- [x] 일정 순서 변경을 원자적 transaction으로 저장 (tech.md의 batch/transaction 계약)
- [ ] 다른 참여자의 변경 사항이 즉시 반영되는지 검증
- [x] router state에 선택 날짜와 지도 확대 상태를 유지하면서 일정 편집이 가능한지 검증
- [ ] 예약 제목·유형·상태·URL·메모의 최소 CRUD 구현
- [ ] 공동·개인 체크리스트와 완료 상태의 최소 CRUD 구현
- [ ] 민감한 여권·결제 문서가 준비 데이터에 저장되지 않는지 검증

React/Vite 기본값인 `VITE_DATA_SOURCE=mock`에서는 편집 결과가 브라우저 실행 안에서만 유지된다. `firebase` 또는 Emulator mode에서 같은 trip을 선택한 경우에만 React 편집과 Flutter 요약이 같은 Firestore itinerary를 구독한다.

## 2026-09-14 Flutter 일정 편집 인계

- 일정 추가와 행 선택으로 편집 화면을 열고 날짜·A/B안·유형·선택 시간·장소·메모를 저장한다. 장소 없음과 연결 해제를 지원한다.
- 새 일정과 날짜·계획을 옮긴 일정은 대상 그룹의 마지막 순서에 추가한다. 같은 그룹을 편집할 때는 기존 수동 순서를 유지한다.
- 일정 행을 길게 눌러 위·아래로 끌어 순서를 바꾼다. 화면 끝에서는 자동 스크롤하며 짧게 누르면 편집한다. 저장 중 중복 이동을 막고 목록·지도에 이동 결과를 표시하며, 실패하면 저장된 순서로 복구한다. `reorderItineraryItems(tripId, ItineraryOrderDraft)`는 날짜·계획·순서대로 나열한 일정 ID를 받아 `order`, `updatedBy`, `updatedAt`만 한 transaction으로 갱신한다. 날짜·계획 이동 또는 삭제를 감지하면 전부 거부한다. 동시 추가된 다른 일정은 수정하지 않으며 동률은 기존 ID 정렬로 결정한다.
- 추가·편집 폼은 날짜/계획, 시작/종료 시간, 유형/연결 장소를 두 칸씩 배치한다. 제목·메모는 전체 폭을 사용하며 좁은 화면이나 큰 글씨에서는 한 칸 배치로 전환한다.
- 시간순 정렬 보조 action은 확인 후 시간 있는 항목 우선·동률 기존 순서·시간 없는 항목 끝 순서로 구현했다. 시간 입력은 기존 HH:mm 계약을 유지하며 여행 기간 밖 날짜와 자정 경계 정책을 새로 제한하지 않는다.
- 편집은 현재 일정 route 위에 열린다. 저장·취소 후 날짜·A/B안·지도 확대 상태를 유지하고, 지도 토글 route는 `day`, `plan=B`, `map=expanded`를 보존한다. 기존 A안·호환 URL은 유지한다.
- 입력 오류와 저장 실패 시 입력을 보존한다. 저장 중 중복 제출·뒤로 가기를 막고, 미저장 상태에서 나가기와 삭제는 확인한다. 기존 저장 알림은 편집 진입 때 닫아 버튼을 가리지 않게 한다.
- Widget/mock 검증과 Firestore Rules Emulator 검증을 구분한다. 두 Android 클라이언트를 연결한 동시 편집 확인과 예약·체크리스트는 후속 작업이다.
- 2026-09-14 검증: `npm run verify:full` 통과(React 59, backend 27, Emulator 14), `npm run verify:flutter:full` 통과(Flutter 94, 분석·포맷·Android debug APK). 변경은 로컬 구현 상태이며 dev 반영은 별도다.
- 같은 날 UI 피드백 반영: 길게 누르기 정렬·자동 스크롤·저장 실패 복구와 두 칸/큰 글씨 폼 검증을 포함해 Flutter 96개 테스트와 Android debug APK 빌드, `npm run verify:fast`를 통과했다.

## 완료 기준

- 여행 선택 화면에서 작은 전체 시간표를 보고 일정 화면에서 일차별 순서 목록을 확인할 수 있다.
- 각 일정 항목에 장소를 연결할 수 있다.
- 일정 순서가 변경되면 지도 표시용 순서 데이터도 바뀐다.
- 다른 참여자가 추가한 일정이 실시간으로 반영된다.
- `준비` 탭에서 최소 예약과 체크리스트가 저장·동기화된다.


## 2026-09-14 준비 기능 구현 인계

예약·체크리스트 생성/편집/삭제, 완료 상태·진행 집계, 일정/담당자 연결을 Flutter에 구현했다. domain/preparation.dart, mock/Firestore repository와 Rules를 함께 추가했다. personal은 여행 내 공유되는 분류다. 필드·enum·감사 정보·권한은 [준비 wire](../../docs/frontend-api-handoff.md#4-준비-데이터-wire)를 따른다. 두 Android 기기 교차 QA는 별도다.
