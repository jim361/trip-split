# Firebase/API 계약 및 연결 감사

> 2026-09-14. Flutter Android의 구현 상태와 외부 연결 여부를 구분한다. 상세 wire·화면별 호출은 [화면·API 인계](frontend-api-handoff.md), 팀원 작업은 [개발 시작 안내](development-kickoff.md)를 따른다.

## 현재 상태

- 기존 9개와 신규 공통 2개, 총 11개 Callable을 export한다. `backend/src/index.ts`가 진입점이다.
- Flutter의 지출 create/update/delete는 Callable을 사용한다. Rules의 expense 직접 쓰기 거부는 유지한다.
- 예약·체크리스트 모델, mock/Firestore repository와 Rules를 구현했다. 기본 mock은 메모리 데이터이며 다른 프로세스와 공유되지 않는다.
- 장소 검색·링크와 OCR는 인증·권한·입력 검증 후 Emulator에서만 샘플을 반환한다. 외부 Google Places/OCR 서비스는 연결되지 않았으며 Emulator 밖에서는 unavailable이다.
- Flutter 내부 지도는 mock 표시 모델이고 외부 지도 URL 열기는 Android adapter로 연결했다. 실제 Google Maps SDK는 후속이다.
- 실제 Firebase 운영 프로젝트·secret 등록·Rules/Functions/index 배포는 이번 작업에 포함하지 않는다.

## Firestore 경로와 쓰기 주체

| 경로                               | 읽기        | 쓰기·제약                                                                                             |
| ---------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------- |
| users/{uid}                        | 본인        | 본인 프로필, 서버 시간                                                                                |
| shareCodes/{code}                  | client 금지 | 공유 Callable의 Admin transaction                                                                     |
| trips/{tripId}                     | member      | 생성·코드는 Callable, client는 title/startDate/endDate만 수정                                         |
| trips/{tripId}/members/{uid}       | member      | createTrip/joinTrip 생성, 본인은 제한된 profile/lastActive 수정. uid는 서버가 문서 ID와 동일하게 기록 |
| trips/{tripId}/participants/{id}   | member      | 이름·색상·활성 상태 CRUD, 물리 삭제 금지. linkedUid는 linkMyParticipant만 수정                        |
| trips/{tripId}/places/{id}         | member      | 직접 CRUD, 좌표·provider/source·감사 정보 Rules                                                       |
| trips/{tripId}/itinerary/{id}      | member      | 직접 CRUD, 날짜/time/order Rules. 그룹 순서는 Flutter transaction                                     |
| trips/{tripId}/reservations/{id}   | member      | 직접 CRUD, 준비 wire·참조·감사 정보 Rules                                                             |
| trips/{tripId}/checklistItems/{id} | member      | 직접 CRUD, personal도 여행 멤버에게 공유                                                              |
| trips/{tripId}/expenses/{id}       | member      | 지출 Callable만 생성·수정·삭제, client write 전부 금지                                                |

`listMyTrips`는 members.uid collection-group query를 사용한다. 인덱스를 함께 반영해야 한다. uid가 없는 구형 멤버는 기존 코드로 재참여하면 보정된다. 운영 배포 전 별도 backfill/재참여 계획이 필요하며 기존 문서 ID는 바꾸지 않는다.

장소 참조 중 삭제 제한은 화면의 현재 데이터 기준 안내다. 서버는 원자적 참조 무결성 삭제를 보장하지 않는다. 참조 대상 삭제와 동시 변경에 대한 UI 재선택·해제 처리를 유지한다.

## Callable와 Flutter 연결

| 함수                                        | Flutter 경계              | 서버 상태                                              |
| ------------------------------------------- | ------------------------- | ------------------------------------------------------ |
| createTrip, createShareCode, joinTrip       | FirebaseTripShareService  | 구현, Auth·공유 transaction                            |
| listMyTrips, linkMyParticipant              | FirestoreTripRepositories | 구현, 본인 목록·유일한 계정 연결                       |
| searchPlaces, parsePlaceLink                | FirebasePlaceProvider     | 구현, Emulator 샘플 / 외부 provider 미연결             |
| createExpense, updateExpense, deleteExpense | FirestoreTripRepositories | 구현, equal/custom/itemized validator·참조 transaction |
| parseReceipt                                | FirebaseReceiptParser     | 구현, stateless Emulator 샘플 / 외부 OCR 미연결        |

응답 Timestamp는 epoch milliseconds, Firestore 저장 시간은 server timestamp다. Auth UID와 Participant ID는 구분하고 요청의 감사 정보를 신뢰하지 않는다. 각 함수의 JSON과 오류는 [인계 명세](frontend-api-handoff.md#3-callable-목록)를 따른다.

## React 목업과의 차이

`frontend/src`와 `public`은 GitHub Pages 참고 목업으로 보존하며 `VITE_DATA_SOURCE=mock`을 유지한다. 이번 Flutter 화면과 서버 연결을 React에 자동 이식하지 않았다.

- React의 expense 직접 쓰기·participant 물리 삭제·linkedUid 직접 입력은 실제 Rules와 맞지 않는 전환기 메서드다. Pages mock 이외를 제품 기준으로 사용하지 않는다.
- React OCR는 legacy merchantName/item.name, Flutter는 original/translated를 분리한 canonical 응답이다.
- React와 Flutter Tokyo fixture의 의미·JPY 4,500 기준은 유지하며 stable ID는 치환하지 않는다. `frontend/src/test/fixtures/tokyoTrip.ts`의 tokyoFlutterIdMap을 사용한다.
- 강릉 React fixture는 KRW/NAVER/itemized 회귀 자료이며 Firebase seed가 아니다.
- React 날짜×시간 일정 폼의 optional null은 mock의 키 제거와 Firestore deleteField로 변환한다. 그 기존 동작은 유지한다.

## 로컬 실행과 검증 범위

Node.js 22·Java 21에서 루트 `npm run dev:backend`, Android에서 `flutter run --dart-define-from-file=dart_defines.example.json`을 사용한다. demo-trip-split, Auth/Firestore/Functions와 Android host 10.0.2.2다. 기본 `flutter run`은 mock이다.

`npm run verify:full`은 포맷·lint·TypeScript·React/backend 단위·build·Emulator를, `npm run verify:flutter:full`은 Dart 포맷·analyze·Widget/단위 테스트·debug APK를 검증한다. 새 domain-flows Emulator 테스트는 두 사용자 쓰기/읽기, outsider 거부, 계정 연결 경쟁, 준비 Rules, 지출 변조 거부, OCR 후보만 반환하는 동작을 확인한다.

### 과거 Android smoke 기록 — 2026-08-30

기존 API 36 AVD에서 익명 Auth → createTrip/joinTrip → trip 구독을 두 사용자로 확인한 기록은 유지한다. 당시 createShareCode 재생성 화면은 없었다. 이번에는 그 화면을 추가했지만 **새 도메인 전체를 두 Android 기기로 교차 검증한 결과는 아직 아니다.**

Android Firebase SDK가 emulator에서도 API key 형식을 확인하므로 `dart_defines.example.json`에는 외부 프로젝트 권한이 없는 39자 더미 값을 사용한다. 운영에는 실제 앱 설정을 승인된 비공개 경계로 주입한다.

## 다음 연결 작업

1. 팀원들이 신규 handler·검증·Rules와 계약을 인계받아 회귀 검증하고 예외 사례를 보강한다.
2. 사용자 담당으로 Android 두 클라이언트의 전체 생성·편집·재정렬·정산 흐름과 카메라·사진·공유·지도 Intent를 확인한다.
3. 승인된 환경에서 Google Places/Maps와 OCR·번역 provider, timeout·오류·보관 정책을 연결한다. 외부 검색/OCR 장애에도 직접 입력 경로를 유지한다.
4. 운영 프로젝트·Auth/SHA/OAuth 설정·비용 한도·배포 승인을 확인한 뒤 Functions/Rules/index를 배포한다. `.trip.json`과 출시 QA는 TASK-08/09 후속이다.
