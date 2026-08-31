# Task Function 5 - Map

> **[TASK-05 · 지도]** 일정 순서에 맞는 핀, 동선과 지도 adapter 기능입니다.

## 목표

Android Google 지도 위에 타임테이블 기반 번호 핀과 날짜별 직선 동선을 표시한다.

## 담당

장소·일정·지도 담당이 구현을 소유하고 플랫폼·통합 담당이 앱 셸과 외부 설정 변경을 검토·최종 확인한다.

## 작업

- [x] 정규화된 `Place[]`와 `ItineraryItem[]`를 지도 입력 계약으로 고정
- [x] 저장용 `MapPlace`를 만들지 않고 입력에서 `MapPin`과 `MapRouteSegment` 화면 모델을 파생
- [x] `tokyo-2026-11` fixture로 핀 번호, 날짜별 색상과 직선 segment를 만드는 순수 Dart 변환 함수와 단위 테스트 구현
- [ ] mock map adapter로 로딩·빈 상태·좌표 누락·일정 재정렬 화면 검증
- [ ] `google_maps_flutter`를 감싼 Android `MapAdapter` 구현
- [ ] Android package 제한 Maps 키와 backend Places 키의 환경 경계 분리
- [ ] 지도 Widget과 controller lifecycle 구현
- [x] 독립 지도 페이지 대신 일정 화면의 선택 날짜 주 지도와 같은 화면 내 확대 상태 구현
- [ ] 지도 초기 중심과 줌 설정 구현
- [ ] 장소 좌표 기반 마커 표시 구현
- [ ] 일정 순서 번호가 들어간 커스텀 마커 구현
- [ ] 날짜별 마커 색상 적용
- [ ] 같은 날짜 일정 항목을 직선 polyline으로 연결
- [ ] 날짜별 polyline 색상 적용
- [ ] 지도 bounds 자동 맞춤 구현
- [ ] 축소·확대 전환 뒤 `GoogleMapController` 상태와 bounds 재계산
- [ ] 지도 범례 구현
- [ ] 일정 변경 시 마커와 polyline 업데이트 구현
- [ ] Firestore 구독 데이터 변경에 따른 지도 갱신 검증
- [ ] 좌표 없는 장소 처리 UI 구현
- [ ] 선택 구간을 외부 Google Maps 길찾기로 여는 URL 생성
- [ ] 실제 Routes API·자동 동선 최적화가 호출되지 않는지 검증
- [ ] Flutter Web 추가 시 Android와 다른 `MapCapabilities`를 표현할 경계 정의

## 완료 기준

- 타임테이블에 연결된 장소가 지도에 번호 핀으로 표시된다.
- 날짜별 장소가 타임테이블 순서대로 직선으로 연결된다.
- 실제 도로 경로 계산 없이도 이동 순서가 시각적으로 이해된다.
- 장소나 일정이 다른 참여자에 의해 수정되어도 지도에 반영된다.
- 실제 Google SDK 연결 전에는 mock adapter로 모든 Widget 테스트가 통과한다.
