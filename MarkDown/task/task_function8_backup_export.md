# Task Function 8 - Backup Export

## 목표

Firebase 여행 세션 데이터를 `.trip.json` 파일로 내보내고 가져올 수 있게 한다. 이 기능은 핵심 공유 수단이 아니라 백업, 복원, 데모 데이터, 데이터 이전용이다.

## 담당

플랫폼·통합 담당

## 작업

- [ ] export JSON schema 정의
- [ ] schemaVersion 필드 정의
- [ ] 여행 전체 데이터 조회 함수 구현
- [ ] members, places, itinerary, expenses 포함 범위 결정
- [ ] 사용자 개인정보 export 범위 결정
- [ ] `.trip.json` 다운로드 구현
- [ ] 파일명 규칙 구현
- [ ] `.trip.json` 업로드 구현
- [ ] JSON 파싱 에러 처리
- [ ] schemaVersion 검증 구현
- [ ] 필수 필드 검증 구현
- [ ] 새 여행으로 가져오기 구현
- [ ] 가져온 여행의 새 shareCode 생성 구현
- [ ] 기존 여행에 병합할지 여부는 MVP 이후로 둘지 결정

## 완료 기준

- 현재 여행 세션을 `.trip.json`으로 저장할 수 있다.
- `.trip.json` 파일을 가져와 새 Firebase 여행으로 복원할 수 있다.
- 가져온 여행은 기존 공유 코드와 분리된다.
- 잘못된 파일을 업로드하면 명확한 에러를 보여준다.
