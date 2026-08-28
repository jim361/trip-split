# Task Function 8 - Backup Export

> **[TASK-08 · 백업·내보내기]** 안정화된 여행 데이터를 백업하고 복원하는 후속 기능입니다.

## 목표

Firebase 여행 세션 데이터를 `.trip.json` 파일로 내보내고 가져올 수 있게 한다. 이 기능은 핵심 공유 수단이 아니라 백업, 복원, 데모 데이터, 데이터 이전용이다.

schema v1은 항상 새 여행으로 복원한다. 여행 설정, 참여자, 장소, 일정과 지출은 포함하지만 사용자 프로필·member uid·기존 owner/shareCode와 audit uid·timestamp는 제외하고 복원 시 새 값으로 만든다. 기존 여행 병합과 Flutter Web 파일 adapter는 MVP 이후다.

## 담당

플랫폼·통합 담당

## 작업

- [x] export JSON schema 정의
- [x] schemaVersion 필드 정의
- [ ] 여행 전체 데이터 조회 함수 구현
- [x] members, places, itinerary, expenses 포함 범위 결정
- [x] 사용자 개인정보 export 범위 결정
- [ ] Android Storage Access Framework 또는 시스템 파일 저장 UI로 `.trip.json` 내보내기 구현
- [ ] Android share sheet로 내보낸 파일 공유
- [ ] 파일명 규칙 구현
- [ ] 시스템 파일 선택기와 content URI로 `.trip.json` 가져오기 구현
- [x] JSON 파싱 에러 처리
- [x] schemaVersion 검증 구현
- [x] 필수 필드 검증 구현
- [ ] 새 여행으로 가져오기 구현
- [ ] 가져온 여행의 새 shareCode 생성 구현
- [x] 기존 여행에 병합할지 여부는 MVP 이후로 둘지 결정
- [ ] 광범위한 저장소 권한을 요청하지 않고 앱 cache의 임시 export 파일을 정리
- [x] Flutter Web의 download/upload adapter는 후속 범위로 분리

## 완료 기준

- 현재 여행 세션을 `.trip.json`으로 저장할 수 있다.
- `.trip.json` 파일을 가져와 새 Firebase 여행으로 복원할 수 있다.
- 가져온 여행은 기존 공유 코드와 분리된다.
- 잘못된 파일을 업로드하면 명확한 에러를 보여준다.
- Android 10 이상 기기에서 전체 저장소 권한 없이 내보내기·가져오기가 동작한다.
