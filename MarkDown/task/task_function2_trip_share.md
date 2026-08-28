# Task Function 2 - Auth, Trip And Share Session

> **[TASK-02 · 인증·여행·공유]** 익명 인증, 여행 생성과 공유 코드 참여 흐름입니다.

## 목표

사용자-facing 로그인 장벽 없이 여행을 만들고, MVP에서는 공유 코드로 같은 Firebase 여행 세션에 참여할 수 있게 한다. Android App Links 초대는 후속 범위다.

## 담당

플랫폼·통합 담당

## 작업

- [x] Firebase Anonymous Auth 자동 진입 구현
- [x] `UserProfile` 타입 정의
- [x] `TripMember` 타입 정의
- [x] `ShareCode` 타입 정의
- [x] `Trip` 타입에 ownerUid, shareCode 반영
- [x] `users/{uid}` 생성/갱신 로직 구현
- [x] 선택적 Google 계정 연결 UX 구현
- [x] Android Google Sign-In credential을 익명 계정에 link해 기존 uid와 여행 접근 권한 유지
- [x] 여행 생성 폼 구현
- [x] 여행 제목, 시작일, 종료일, 예상 인원 입력 구현
- [x] 국가·time zone·기본 통화·지도 provider 입력 계약 정의
- [x] 첫 도쿄 flow는 Google·JPY·Asia/Tokyo 기본값 사용
- [x] 예상 인원 수만큼 이름을 수정할 수 있는 Participant 초안을 `createTrip`에서 원자적으로 생성
- [x] 확정된 Firestore `trips`와 `members` 계약 적용
- [x] 여행, 생성자 member, 첫 공유 코드를 원자적으로 만드는 `createTrip` Callable Function 구현
- [x] 공유 코드를 추가·재생성하는 `createShareCode` Callable Function 구현
- [x] 코드를 검증하고 `trips/{tripId}/members/{uid}`에 등록하는 `joinTrip` Callable Function 구현
- [ ] 공유 코드 복사와 Android share sheet 구현
- [ ] Android App Links 기반 초대 링크는 공유 코드 흐름이 안정된 뒤 별도 단계로 구현
- [x] 공유 코드로 여행 참여 구현
- [ ] 초대 링크 접속 시 여행 참여 구현
- [ ] 여행 기본 정보 수정 구현
- [x] 여행 데이터 실시간 구독 구현
- [x] members 기반 Firestore 보안 규칙 초안 작성

## 완료 기준

- 사용자는 로그인 화면 없이 여행을 만들 수 있다.
- 앱 내부에서 Firebase uid로 사용자가 구분된다.
- 공유 코드 또는 링크로 같은 여행 세션에 들어갈 수 있다.
- 참여자는 `trips/{tripId}/members/{uid}`에 등록된다.
- 여행 기본 정보가 Firestore에 저장되고 실시간 반영된다.
- 여행 생성 시 입력한 예상 인원 기준 Participant가 만들어지고 이후 추가·비활성화할 수 있다.
- 첫 공유 코드는 만료·횟수 제한 없이 생성되며 재생성 시 기존 코드가 비활성화된다.
- Auth·Firestore·Functions Emulator에서 서로 다른 익명 uid 두 명이 같은 여행 member가 된다.
