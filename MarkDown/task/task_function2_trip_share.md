# Task Function 2 - Auth, Trip And Share Session

## 목표

사용자-facing 로그인 장벽 없이 여행을 만들고, 공유 코드 또는 초대 링크로 같은 Firebase 여행 세션에 참여할 수 있게 한다.

## 담당

플랫폼·통합 담당

## 작업

- [ ] Firebase Anonymous Auth 자동 진입 구현
- [ ] `UserProfile` 타입 정의
- [ ] `TripMember` 타입 정의
- [ ] `ShareCode` 타입 정의
- [ ] `Trip` 타입에 ownerUid, shareCode 반영
- [ ] `users/{uid}` 생성/갱신 로직 구현
- [ ] 선택적 Google 계정 연결 UX 구현
- [ ] Google Provider를 익명 계정에 link해 기존 uid와 여행 접근 권한 유지
- [ ] 여행 생성 폼 구현
- [ ] 여행 제목, 시작일, 종료일 입력 구현
- [ ] 국내 여행 기본값 설정
- [ ] 확정된 Firestore `trips`와 `members` 계약 적용
- [ ] 여행, 생성자 member, 첫 공유 코드를 원자적으로 만드는 `createTrip` Callable Function 구현
- [ ] 공유 코드를 추가·재생성하는 `createShareCode` Callable Function 구현
- [ ] 코드를 검증하고 `trips/{tripId}/members/{uid}`에 등록하는 `joinTrip` Callable Function 구현
- [ ] 초대 링크 생성 로직 구현
- [ ] 공유 코드로 여행 참여 구현
- [ ] 초대 링크 접속 시 여행 참여 구현
- [ ] 여행 기본 정보 수정 구현
- [ ] 여행 데이터 실시간 구독 구현
- [ ] members 기반 Firestore 보안 규칙 초안 작성

## 완료 기준

- 사용자는 로그인 화면 없이 여행을 만들 수 있다.
- 앱 내부에서 Firebase uid로 사용자가 구분된다.
- 공유 코드 또는 링크로 같은 여행 세션에 들어갈 수 있다.
- 참여자는 `trips/{tripId}/members/{uid}`에 등록된다.
- 여행 기본 정보가 Firestore에 저장되고 실시간 반영된다.
