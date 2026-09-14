# Task Function 8 - Backup Export

> **[TASK-08 · 백업·내보내기]** 안정화된 여행 데이터를 백업하고 복원하는 후속 기능입니다.

단계: `.trip.json`은 핵심 원장 안정화 뒤 Phase B 마감에서 실제 여행 전 파일 저장·새 여행 복원을 검증한다. Sheets 보고서는 사용자의 별도 병행 작업으로 샘플·양식·미리보기부터 진행하며 B/C 필수 게이트에 추가하지 않는다. 시트 출력과 앱으로 가져오기, 백업 복원을 구분한다. [단계별 안내](../../docs/development-kickoff.md)를 따른다.

## 목표

Firebase 여행 세션 데이터를 `.trip.json` 파일로 내보내고 가져올 수 있게 한다. 이 기능은 핵심 공유 수단이 아니라 백업, 복원, 데모 데이터, 데이터 이전용이다.

schema v1은 항상 새 여행으로 복원한다. 여행 설정, 참여자, 장소, 일정과 지출은 포함하지만 사용자 프로필·member uid·기존 owner/shareCode와 audit uid·timestamp는 제외하고 복원 시 새 값으로 만든다. 기존 여행 병합과 Flutter Web 파일 adapter는 MVP 이후다. 실제 Firebase import를 열기 전에는 Android adapter의 파일·entity 개수 제한과 Task 6 지출 validator를 같은 경계에서 적용한다.

## 담당

사용자 · Flutter/플랫폼·통합 담당

## 추가 범위 — Google Sheets 여행 보고서

2026-09-14 사용자 요청으로 일정·지출을 참고 양식에 맞춰 Google Sheets로 내보내는 작업을 추가한다. 기존 repository와 Dart 정산 결과를 재사용하고 Flutter service에서 시트 값·서식을 구성한다. 사용자 OAuth 권한으로 새 문서를 만들며 시트용 신규 Firebase Callable은 만들지 않는다. 두 백엔드 담당의 소유 영역은 유지한다.

이는 사람이 읽는 보고서다. 아래 `.trip.json` 백업·복원 스키마와 기존 작업 ID는 유지한다. Flutter 생성·실패 복구 코드를 구현했으며 실제 계정·기기 검증은 남아 있다. [시트 내보내기 인계](../../docs/sheet-export.md)에 화면 흐름·연결 경계·완료 기준을 둔다.

- [x] 첫 번째 탭에서 고정 일정·지출 샘플 추출 및 원본/검산값 보존
- [x] Flutter 중심 출력과 기존 repository·Dart 정산 재사용 방향 정리
- [x] 날짜·일정·지출 개수에 맞춘 보고서 배치·서식 생성
- [x] 내보내기 옵션·미리보기·저장·실패 상태
- [x] 필요한 여행 데이터 전체 조회 및 통화별 합계·정산 연결
- [x] Google OAuth 추가 권한과 Sheets 생성 service 코드·요청 대역 검증
- [ ] Android에서 새 시트 생성·열기 및 취소·중복 제출·실패 복구 검증

## 기존 백업·복원 작업

- [x] export JSON schema 정의
- [x] schemaVersion 필드 정의
- [ ] 여행 전체 데이터 조회 함수 구현
- [x] participants, places, itinerary, expenses 포함 범위와 members 제외 결정
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
