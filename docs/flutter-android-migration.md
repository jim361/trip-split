# Flutter Android 전환 계획

> **[회의 04 · 플랫폼 전환]** 2026-08-28에 확정한 Android 우선 전환 범위와 실행 순서입니다.

2026-09-14 보정: 현재는 Phase B(P0) 통합 단계다. P1 화면·mock이 먼저 구현돼 있어도 OCR 실제 연결은 B 완료 뒤 C에서 진행한다. 담당별 현재 작업과 단계 통과 조건은 [개발 시작 안내](development-kickoff.md)를 따른다.

## 1. 결정

- 사용자 앱은 Vite·React PWA에서 Flutter stable 기반 Android 앱으로 전환한다.
- 첫 실사용 기준은 2026년 11월 도쿄 여행이며 Google Maps와 JPY를 우선 검증한다.
- 기존 Node.js 22·TypeScript Firebase Functions, Firestore 경로, 보안 규칙과 Emulator 테스트는 유지한다.
- Flutter Web은 같은 Dart 도메인·repository 코드를 재사용하는 후속 보조 채널이다.
- iOS, 백그라운드 경로 기록과 Health Connect는 첫 Android MVP에 포함하지 않는다.

## 2. 전환 당시(2026-08-28)와 목표 상태

| 영역        | 현재 저장소                                                      | 목표                                                                          |
| ----------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 사용자 앱   | Flutter Android scaffold·mock 앱 셸과 임시 React 목업            | `frontend/`의 Flutter·Dart Android 앱                                         |
| 웹 공유본   | React 빌드를 GitHub Pages에 배포                                 | Flutter Web을 별도 수용 기준으로 검증한 뒤 재개                               |
| 백엔드      | `backend/` Node.js·TypeScript Functions와 Rules 테스트           | 그대로 유지하고 Dart 클라이언트 계약만 연결                                   |
| 지도        | Google 스타일 mock과 provider 경계                               | Android `google_maps_flutter`, Places는 서버 또는 제한된 API 경계             |
| 인증·데이터 | FlutterFire client·repository 경계와 임시 React Firebase Web SDK | Android Emulator 수직 검증을 마친 FlutterFire Auth·Firestore·Functions        |
| OCR         | CLOVA 전제와 callable placeholder                                | provider-neutral `parseReceipt`; Document AI/OCR·번역 후보를 backend에서 비교 |

위 표는 전환 당시 기록이다. 현재 주요 Flutter 화면·11개 Callable·itemized/OCR mock 구현은 [화면/API 인계](frontend-api-handoff.md)를 따른다. 기존 React 목업은 Flutter 화면을 검증할 때 참고할 UX 자료이며 GitHub Pages mock으로 보존한다. Flutter 화면을 자동 반영하는 배포본이 아니다.

## 3. 단계별 범위

### Phase A · 전환 기반

- [x] Flutter 프로젝트를 `frontend/`에 생성하고 Android를 기본 실행 대상으로 설정
- [x] Android `minSdk 24`, 현재 Play 요구사항에 맞춘 `targetSdk 36`
- [x] 앱 router, Material 앱 셸과 `일정·지도 / 준비 / 비용` 하단 내비게이션
- [x] 고정 ID `tokyo-2026-11` fixture와 mock repository 주입
- [x] `dart format`, `flutter analyze`, unit/widget test, debug APK build — GitHub Actions 포함 통과
- [x] FlutterFire 설정, Auth·Firestore·Functions service/repository와 Emulator 주소 구성
- [x] Anonymous Auth, `TripSession`, 여행 생성·공유 코드 입장의 Android Emulator 수직 smoke — 2026-08-30 기록. 이후 추가된 전체 도메인의 두 기기 QA는 B에서 별도 검증

Phase A가 끝나기 전에는 실제 Google Maps·OCR·위치 권한을 추가하지 않는다.

### Phase B · Android 핵심 기능(P0), 현재 단계

- 장소·일정 CRUD와 Google Maps 번호 핀·직선 동선
- 예약·체크리스트의 최소 준비 데이터
- 공유 코드·여행 설정과 membership 기반 기본 내 여행 목록. 실제 Google 계정 연결/복구 검증과 구분
- 참여자 관리, 수동 equal/custom 지출과 통화별 paid/owed/net
- 두 익명 사용자의 실시간 공동 편집과 members 기반 Rules 검증
- 핵심 데이터 안정화 뒤 Android 파일 선택기를 이용한 `.trip.json` 내보내기·새 여행 복원, 실제 여행 전 검증

주요 화면·repository·Emulator handler는 구현됐다. 현재 남은 것은 실제 Google 지도/장소 검색, 두 Android 클라이언트 통합·오류 복구와 백업/복원이다. Google Maps/Places는 승인된 환경에서 B에 연결하며 Routes API·이동 시간 자동 계산은 포함하지 않는다.

### Phase C · 영수증과 배포 준비(P1)

B 완료 뒤 시작한다. 선행 구현된 itemized·검토 UI·OCR Emulator handler는 유지하며 외부 provider 비교·연결을 현재 B 작업으로 앞당기지 않는다.

- itemized 정산과 조정 항목
- Android 카메라 또는 시스템 Photo Picker
- 일본어 영수증 원문·한국어 번역·금액/통화 후보를 함께 보여주는 OCR 검토
- 사용자 확정 전 미반영, 수동 fallback, 임시 이미지 폐기 검증
- 선택적 Google 계정 연결 시 UID 유지·여행 접근 복구와 익명 세션 소실 안내 검증
- 실기기 QA, adaptive icon·splash, 접근성, 개인정보·권한 안내
- 승인된 환경에서 OCR·번역 provider를 연결하고 실제 이미지·실패 복구를 확인
- 서명·Play 내부 테스트·운영 배포는 해당 실행 승인 범위에서 진행

### Phase D · 후속

- Flutter Web 계획·검토 화면
- 국내 NAVER adapter와 iOS
- 실제 경로·이동 시간
- 사용자가 명시적으로 시작·종료하는 이동 기록과 Health Connect
- App Links·자동 환율·송금 완료 상태·고급 권한·오프라인 병합, Sheets/CSV 가져오기와 D-day/오늘 일정·Gemini 후보는 별도 채택·범위 확인 뒤 진행

### 별도 병행 작업 · 시트 보고서

사용자가 고정 샘플 양식·미리보기를 B와 병행하고 기존 repository·Dart 정산과 OAuth·새 Google Sheet 생성을 순서대로 연결한다. B/C 필수 완료 조건이나 OCR의 선행 조건으로 추가하지 않으며 `.trip.json` 백업과 구분한다. [시트 인계](sheet-export.md)를 따른다.

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
cd frontend
dart format --output=none --set-exit-if-changed lib test
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

## 8. 검증 운영

기존 Codex 하네스 제안은 Vite 중심 검증을 전제로 해 Flutter 전환 계약과 맞지 않으므로 채택하지 않는다. 별도 대형 검증기 대신 저장소의 기본 명령과 GitHub Actions를 사용한다.

검증은 다음과 같이 단순화한다.

- frontend: Flutter 기본 format/analyze/test/build 명령
- backend: 기존 npm과 Emulator 명령
- `dev` 직접 push: 로컬 검증 후 GitHub Actions에서 같은 검증 재실행
- `main` 반영: 검증된 `dev`의 릴리스 Pull Request

대형 사용자 정의 검증기는 추가하지 않는다. 다만 저장소 로컬의 작은 direct Git command hook으로 직접 실행된 강제 `git push`·`git reset --hard`·강제 `git clean`만 보조적으로 차단한다.
이 hook은 GitHub Actions와 서버 측 보호 규칙을 대체하지 않으며, 셸 wrapper·alias·인코딩 명령의 해석은 범위 밖이다.

## 9. 전환 시 보존할 계약

- `TASK-01`~`TASK-09`와 회의 기능 ID
- Firestore collection path와 Callable 이름
- `TripMember`와 `Participant` 분리
- mock/Firestore repository의 같은 인터페이스
- 화면/Widget에서 Firebase와 외부 API SDK 직접 호출 금지
- 사용자 확정 전 OCR 초안이 정산 원장을 바꾸지 않는 원칙
- 다른 작업자의 변경, fixture와 테스트를 삭제해 통과시키지 않는 원칙

## 10. 전환 작업 단위

1. 문서 계약
2. Flutter scaffold와 mock 세 탭
3. FlutterFire·Emulator·여행 세션
4. 일정·Google 지도
5. 수동 정산
6. 준비·백업
7. itemized·OCR·번역
8. Android 내부 배포 준비

각 작업은 최신 `dev`에서 작은 커밋으로 진행하고 로컬 검증 뒤 `dev`에 직접 푸시한다. 실제 배포, secret과 유료 API 연결은 사용자의 별도 요청이 있을 때만 수행한다.
