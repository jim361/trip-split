# Task Function 1 - Project Setup

## 목표

Vite + React + TypeScript 기반 웹/PWA 프로젝트를 만들고, Firebase와 디자인 기반을 연결한다.

## 담당

플랫폼·통합 담당이 구현을 소유하고, 정산·영수증 담당과 장소·일정·지도 담당이 공통 계약과 개발 환경을 함께 검토한다.

## 작업

- [ ] Vite + React + TypeScript 프로젝트 생성
- [ ] Git 기본 브랜치와 작업 규칙 정리
- [ ] ESLint 설정
- [ ] Prettier 설정
- [ ] Vitest 또는 테스트 도구 설정
- [ ] Firebase 프로젝트 생성
- [ ] Firebase Hosting 설정
- [ ] Firebase Authentication 설정
- [ ] Anonymous Auth 활성화
- [ ] 선택적 계정 연결용 Google Provider 활성화
- [ ] Firestore 설정
- [ ] Cloud Functions 초기화
- [ ] `.env.example` 작성
- [ ] API 키와 환경변수 관리 방식 정리
- [ ] PWA manifest 기본 파일 추가
- [ ] `/trips/:tripId/itinerary`, `/trips/:tripId/settlement`, `/trips/:tripId/receipts` 공통 라우팅과 `/trips/:tripId/map` 호환 redirect 구성
- [ ] 모바일 고정 하단 내비게이션과 PC 확장 표현을 가진 앱 레이아웃 shell 구현
- [ ] Firebase Auth 상태 Provider 구현
- [ ] Auth, Firestore, Functions Emulator 설정
- [ ] 공통 ID·timestamp·`AppError`·repository 인터페이스 정의
- [ ] 세 도메인이 함께 쓰는 고정 ID 강릉 fixture 추가
- [ ] Airbnb DESIGN.md 설치 또는 디자인 토큰 초안 작성

## 완료 기준

- `npm run dev`로 앱이 실행된다.
- Firebase Hosting 배포 준비가 되어 있다.
- Functions 로컬 개발 구조가 준비되어 있다.
- Anonymous Auth 기반 uid를 앱에서 확인할 수 있다.
- 기본 홈 화면과 여행 화면 라우트가 존재한다.
- mock repository로 네 개 여행 화면을 외부 API 없이 열 수 있다.
