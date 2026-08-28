# Flutter Android 전환 계획

> **[회의 04 · 플랫폼 전환]** 2026-08-28에 확정한 Android 우선 전환 범위와 실행 순서입니다.

## 1. 결정

- 사용자 앱은 Vite·React PWA에서 Flutter stable 기반 Android 앱으로 전환한다.
- 첫 실사용 기준은 2026년 11월 도쿄 여행이며 Google Maps와 JPY를 우선 검증한다.
- 기존 Node.js 22·TypeScript Firebase Functions, Firestore 경로, 보안 규칙과 Emulator 테스트는 유지한다.
- Flutter Web은 같은 Dart 도메인·repository 코드를 재사용하는 후속 보조 채널이다.
- iOS, 백그라운드 경로 기록과 Health Connect는 첫 Android MVP에 포함하지 않는다.

## 2. 현재와 목표 상태

| 영역        | 현재 저장소                                            | 목표                                                                          |
| ----------- | ------------------------------------------------------ | ----------------------------------------------------------------------------- |
| 사용자 앱   | Flutter Android scaffold·mock 앱 셸과 임시 React 목업  | `frontend/`의 Flutter·Dart Android 앱                                         |
| 웹 공유본   | React 빌드를 GitHub Pages에 배포                       | Flutter Web을 별도 수용 기준으로 검증한 뒤 재개                               |
| 백엔드      | `backend/` Node.js·TypeScript Functions와 Rules 테스트 | 그대로 유지하고 Dart 클라이언트 계약만 연결                                   |
| 지도        | Google 스타일 mock과 provider 경계                     | Android `google_maps_flutter`, Places는 서버 또는 제한된 API 경계             |
| 인증·데이터 | Firebase Web SDK                                       | FlutterFire Auth·Firestore·Functions                                          |
| OCR         | CLOVA 전제와 callable placeholder                      | provider-neutral `parseReceipt`; Document AI/OCR·번역 후보를 backend에서 비교 |

기존 React 목업은 Flutter 화면을 검증할 때 참고할 UX 자료다. Flutter 세로 기능 조각이 대체되기 전까지 삭제하지 않으며 React와 Flutter를 장기 이중 제품으로 운영하지 않는다.

## 3. 단계별 범위

### Phase A · 전환 기반

- [x] Flutter 프로젝트를 `frontend/`에 생성하고 Android를 기본 실행 대상으로 설정
- [x] Android `minSdk 24`, 현재 Play 요구사항에 맞춘 `targetSdk 36`
- [x] 앱 router, Material 앱 셸과 `일정·지도 / 준비 / 비용` 하단 내비게이션
- [x] 고정 ID `tokyo-2026-11` fixture와 mock repository 주입
- [ ] `dart format`, `flutter analyze`, unit/widget test, debug APK build — 로컬 앞 세 항목 통과, APK는 CI 확인 중
- FlutterFire 설정과 Auth·Firestore·Functions Emulator 연결
- Anonymous Auth, `TripSession`, 여행 생성·공유 코드 입장의 세로 기능 조각

Phase A가 끝나기 전에는 실제 Google Maps·OCR·위치 권한을 추가하지 않는다.

### Phase B · Android 핵심 기능

- 장소·일정 CRUD와 Google Maps 번호 핀·직선 동선
- 예약·체크리스트의 최소 준비 데이터
- 참여자 관리, 수동 equal/custom 지출과 통화별 paid/owed/net
- 두 익명 사용자의 실시간 공동 편집과 members 기반 Rules 검증
- Android 파일 선택기를 이용한 `.trip.json` 내보내기·복원

### Phase C · 영수증과 배포 준비

- itemized 정산과 조정 항목
- Android 카메라 또는 시스템 Photo Picker
- 일본어 영수증 원문·한국어 번역·금액/통화 후보를 함께 보여주는 OCR 검토
- 사용자 확정 전 미반영, 수동 fallback, 임시 이미지 폐기 검증
- 실기기 QA, adaptive icon·splash, 접근성, 개인정보·권한 안내
- 요청이 있을 때만 서명·Play 내부 테스트 또는 실제 외부 API를 연결

### Phase D · 후속

- Flutter Web 계획·검토 화면
- 국내 NAVER adapter와 iOS
- 실제 경로·이동 시간
- 사용자가 명시적으로 시작·종료하는 이동 기록과 Health Connect

## 4. Flutter Web 수용 기준

Flutter Web은 구현 가능하지만 Android 출시의 완료 조건은 아니다.

| 공유 가능                                        | 플랫폼별 구현 필요                                        | Web 제외                       |
| ------------------------------------------------ | --------------------------------------------------------- | ------------------------------ |
| Dart 도메인 모델·정산 엔진·repository 인터페이스 | Google 로그인, 파일/카메라 입력, 지도 capability, 공유 UI | 백그라운드 GPS, Health Connect |
| Auth·Firestore·Callable 계약                     | Web 캐시 활성화, URL/deep link, 배포와 접근성             | Android foreground service     |
| 일정·준비·비용 Widget의 대부분                   | `dart:io` 없는 bytes 기반 파일 처리                       | Android 전용 권한 UX           |

웹에서는 Google Maps의 내 위치 버튼, 회전·기울기, 실내 지도 등 일부 기능이 Android와 다르다. Flutter Web 앱 셸의 완전한 오프라인 실행은 자동 제공되지 않으므로 별도 service worker 전략 없이는 약속하지 않는다.

## 5. 저장과 오프라인 계약

- Firestore가 공동 데이터의 canonical 원장이다.
- Android의 Firestore 영속 캐시는 마지막 동기화 데이터와 latency-compensated write를 제공한다.
- UI는 캐시 데이터, 동기화 대기와 실패를 구분해 표시한다.
- 여러 기기의 같은 문서 충돌은 Firestore의 last-write-wins를 기본으로 받아들이며 고급 병합 UI는 후속이다.
- 장소 검색, URL 해석과 OCR Callable은 온라인에서만 실행한다.
- 캐시는 백업이 아니며 `.trip.json`과 계정 연결 정책을 별도로 유지한다.

## 6. Emulator와 로컬 개발

- FlutterFire는 Auth·Firestore·Functions 인스턴스를 처음 사용하기 전에 Emulator로 연결한다.
- Android Emulator가 호스트 Firebase Emulator에 접근할 때 기본 주소는 `10.0.2.2`다.
- Firestore Rules 검증은 기존 `@firebase/rules-unit-testing` 기반 Node 테스트를 유지한다.
- Maps와 Document AI는 Firebase Emulator 대상이 아니므로 mock adapter와 고정 fixture로 테스트한다.
- 실제 Firebase 프로젝트 생성, secret 등록, 지도/OCR 유료 호출과 배포는 별도 승인 전에는 하지 않는다.

## 7. 권장 검증 게이트

### Flutter

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

### Backend

```bash
npm run format:check
npm run typecheck
npm run lint
npm test
npm run build
npm run test:emulator
```

CI는 Flutter와 backend job을 분리한다. Node.js 22는 Functions용으로 유지하고 Flutter·backend job은 JDK 21을 사용한다. Android 소스·Kotlin bytecode target은 생성된 scaffold의 Java 17을 유지하며 Flutter SDK 3.47.2를 CI에 고정한다.

## 8. 하네스 영향

현재 `feature/codex-harness`의 검증기는 `frontend/package.json`, Vite build와 frontend npm 테스트를 강제하므로 Flutter 전환 계약과 맞지 않는다. 해당 브랜치는 현 상태로 병합하지 않는다.

Flutter scaffold PR에서 다음과 같이 단순화한다.

- frontend: Flutter 기본 format/analyze/test/build 명령
- backend: 기존 npm과 Emulator 명령
- 위험 Git 훅: 직접적인 force push, hard reset, 강제 clean 정도만 경고
- 실제 강제 정책: GitHub의 `dev`·`main` branch protection과 필수 CI

654줄 검증기와 850줄 훅에 Flutter 예외를 계속 추가하지 않는다.

## 9. 전환 시 보존할 계약

- `TASK-01`~`TASK-09`와 회의 기능 ID
- Firestore collection path와 Callable 이름
- `TripMember`와 `Participant` 분리
- mock/Firestore repository의 같은 인터페이스
- 화면/Widget에서 Firebase와 외부 API SDK 직접 호출 금지
- 사용자 확정 전 OCR 초안이 정산 원장을 바꾸지 않는 원칙
- 다른 작업자의 변경, fixture와 테스트를 삭제해 통과시키지 않는 원칙

## 10. 전환 PR 경계

1. 문서 계약 PR
2. Flutter scaffold와 mock 세 탭 PR
3. FlutterFire·Emulator·여행 세션 PR
4. 일정·Google 지도 PR
5. 수동 정산 PR
6. 준비·백업 PR
7. itemized·OCR·번역 PR
8. Android 내부 배포 준비 PR

각 PR은 `dev`를 대상으로 하며 commit, push, PR 생성, 실제 배포는 사용자의 별도 요청이 있을 때 수행한다.
