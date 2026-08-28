# Task Function 3 - Places

> **[TASK-03 · 장소 보관함·검색]** 장소 검색, 링크 해석과 공통 `Place` 변환 경계입니다.

## 목표

장소 보관함을 만들고 Google 장소 검색, Google Maps URL과 직접 입력으로 장소를 추가한다.

## 담당

장소·일정·지도 담당이 구현을 소유하고 플랫폼·통합 담당이 공통 Firebase 계약을 검토·병합한다.

## 작업

- [x] `Place` 타입 정의
- [x] `PlaceProvider` 인터페이스와 Google/직접 입력 응답을 `Place`로 바꾸는 정규화 함수 정의
- [x] Firestore places 구조 설계
- [x] Place에 addedBy, createdAt, updatedAt 반영
- [x] 공통 `tokyo-2026-11` fixture로 동작하는 mock place provider와 mock places repository 구현
- [ ] 장소 보관함 UI 구현
- [ ] 장소 직접 입력 폼 구현
- [x] mock 검색 성공·빈 결과·링크 파싱 실패 상태로 장소 보관함 흐름 검증
- [ ] Google Places 검색 Cloud Function 구현
- [ ] 장소 검색 결과 UI 구현
- [ ] 검색 결과 선택 후 장소 저장 구현
- [ ] Google Maps URL 붙여넣기 UI 구현
- [ ] 합의한 일반 장소·검색 URL 해석 구현
- [ ] 단축 URL은 서버 redirect 비용과 abuse 제한을 검증한 뒤 지원 여부 결정
- [ ] Google Maps URL에서 장소 ID/이름/주소/좌표 추출 시도
- [ ] 링크 파싱 실패 시 검색 후보 표시
- [ ] 링크 파싱 실패 시 직접 입력 fallback 구현
- [ ] 장소 삭제 구현
- [ ] 장소 메모 수정 구현
- [ ] 장소 변경 실시간 구독 구현

## 완료 기준

- 사용자가 검색으로 장소를 추가할 수 있다.
- 사용자가 지원하는 Google Maps URL로 장소를 추가할 수 있다.
- 실패 시 직접 입력으로 장소를 저장할 수 있다.
- 저장된 장소가 여행별 장소 보관함에 표시된다.

## 후속 후보

- [ ] 국내 NAVER `PlaceProvider`와 지도 adapter
- [ ] Google/NAVER 계정 저장 목록 자동 import는 공식 API와 약관이 확인될 때만 검토
- [ ] 앱 키와 서버 키의 package/API 제한, 예산·quota 정책
