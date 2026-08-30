# Task Function 4 - Itinerary

> **[TASK-04 · 일정]** 날짜별 일정 작성, 순서와 장소 연결 기능입니다.

## 목표

날짜별 시간표를 만들고, 장소 보관함의 장소를 일정 항목에 연결한다.

Flutter의 `ItineraryItemDraft`와 React 일정 form이 입력을 먼저 검증하고, repository와 Firestore Rules가 최종 저장 경계를 담당한다. 두 클라이언트는 `ItineraryItem`의 날짜·시간·제목·장소·메모·planId·category·order 의미를 공유한다. legacy 문서의 planId/category 누락은 읽기 경계에서 A/other로 해석한다.

## 담당

장소·일정·지도 담당이 구현을 소유하고 플랫폼·통합 담당이 공통 라우트와 Firebase 계약을 검토·최종 확인한다.

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
- [ ] Flutter Android에서 같은 일정 CRUD에 도달하는 compact 입력 흐름 구현
- [x] 장소 없는 항공편·체크인·휴식 일정 허용
- [ ] 일정 순서 변경 구현
- [ ] 수동 `order`를 canonical로 저장하고 시간순 정렬은 명시적 보조 action으로 제공
- [ ] 일정·예약·체크리스트 데이터를 FlutterFire repository `Stream`으로 구독
- [ ] 일정 순서 변경 시 batch write 적용
- [ ] 다른 참여자의 변경 사항이 즉시 반영되는지 검증
- [ ] router state에 선택 날짜와 지도 확대 상태를 유지하면서 일정 편집이 가능한지 검증
- [ ] 예약 제목·유형·상태·URL·메모의 최소 CRUD 구현
- [ ] 공동·개인 체크리스트와 완료 상태의 최소 CRUD 구현
- [ ] 민감한 여권·결제 문서가 준비 데이터에 저장되지 않는지 검증

React/Vite 기본값인 `VITE_DATA_SOURCE=mock`에서는 편집 결과가 브라우저 실행 안에서만 유지된다. `firebase` 또는 Emulator mode에서 같은 trip을 선택한 경우에만 React 편집과 Flutter 요약이 같은 Firestore itinerary를 구독한다.

## 완료 기준

- 여행 선택 화면에서 작은 전체 시간표를 보고 일정 화면에서 일차별 순서 목록을 확인할 수 있다.
- 각 일정 항목에 장소를 연결할 수 있다.
- 일정 순서가 변경되면 지도 표시용 순서 데이터도 바뀐다.
- 다른 참여자가 추가한 일정이 실시간으로 반영된다.
- `준비` 탭에서 최소 예약과 체크리스트가 저장·동기화된다.
