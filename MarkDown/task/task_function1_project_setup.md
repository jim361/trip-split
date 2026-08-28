# Task Function 1 - Project Setup

> **[TASK-01 · 프로젝트 기반]** 앱 셸, 공통 계약, Firebase와 테스트 기반을 준비합니다.

## 목표

Flutter stable·Dart 기반 Android 프로젝트를 만들고 mock과 FlutterFire를 교체 가능한 공통 기반에 연결한다.

## 담당

플랫폼·통합 담당이 구현을 소유하고, 정산·영수증 담당과 장소·일정·지도 담당이 공통 계약과 개발 환경을 함께 검토한다.

## 작업

- [x] 기존 React 목업의 보존 범위를 기록한 뒤 `frontend/`에 Flutter 프로젝트 생성
- [x] Android를 첫 실행 대상으로 설정하고 `minSdk 24`, `targetSdk 36` 구성
- [x] Git 기본 브랜치와 작업 규칙 정리
- [x] `flutter_lints`와 `analysis_options.yaml` 설정
- [x] Dart format check와 unit/widget test 기반 설정
- [x] Flutter SDK와 Dart dependency 버전 고정
- [ ] Firebase 프로젝트 생성 절차 문서화. 실제 프로젝트 생성은 별도 승인 후 수행
- [ ] FlutterFire Android 설정과 생성된 `firebase_options.dart` 관리 방식 정리
- [ ] Firebase Authentication 설정
- [ ] Anonymous Auth 활성화
- [ ] 선택적 계정 연결용 Google Provider 활성화
- [ ] Firestore 설정
- [x] Cloud Functions 초기화
- [x] `frontend/.env.example`과 `backend/.env.example`의 현재 용도 작성
- [x] API 키와 환경변수 관리 방식 정리
- [x] Flutter router에 일정·지도, 준비, 비용 route와 receipts 하위 route 구성
- [x] 기존 `/trips/:tripId/map` deep link를 확대 일정·지도 상태로 연결할 호환 규칙 정의
- [ ] Android `NavigationBar`, `SafeArea`, system back과 키보드 inset을 처리하는 `TripShell` 구현. 내비게이션·SafeArea는 완료했고 system back·키보드 실기기 검증은 남음
- [x] Firebase Auth 상태와 여행 세션을 분리한 `TripSession` controller/provider 구현
- [x] Auth, Firestore, Functions Emulator 설정
- [ ] Android Emulator에서 host 주소 `10.0.2.2` 연결 검증
- [x] 공통 ID·timestamp·`AppError`·repository 인터페이스 정의
- [x] `Stream` 조회와 `Future` 명령을 구현하는 mock/Firestore repository 주입 구조
- [x] 고정 ID `tokyo-2026-11` Dart fixture 추가, 기존 React 강릉 fixture는 KRW 회귀용으로 보존
- [x] Material Theme 초안 작성
- [x] backend Node.js 22·TypeScript와 Firestore Rules/Emulator 구조 보존
- [x] Flutter Web을 첫 완료 게이트와 배포에서 제외

## 완료 기준

- `flutter run`으로 Android Emulator에서 앱이 실행된다.
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter build apk --debug`가 통과한다.
- Functions 로컬 개발 구조가 준비되어 있다.
- Anonymous Auth 기반 uid를 앱에서 확인할 수 있다.
- 기본 홈과 여행 route가 존재한다.
- mock repository로 `일정·지도 / 준비 / 비용` 세 탭과 영수증 하위 placeholder를 외부 API 없이 열 수 있다.
- Widget에서 Firebase와 외부 API SDK를 직접 호출하지 않는다.
