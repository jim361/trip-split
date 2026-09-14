# Android 두 앱 통합 검증

Android Studio의 AVD 두 개에서 실제 Flutter 앱을 실행해 로컬 Firebase Auth·Firestore·Functions와 연결한다. 서버 SDK 테스트와 별개로 화면 입력·버튼·FlutterFire 구독을 검증한다. 실제 Firebase 프로젝트, Google Maps·Sheets·OCR API는 호출하지 않는다.

## 준비

- Node.js 22, Java 21, Flutter, Android SDK와 서로 다른 AVD 두 개.
- 이번 전용 AVD: `TripSplit_Owner_API36` / `TripSplit_Guest_API36`, Android 16(API 36), Pixel 4, x86_64. 통과한 실행은 RAM 3072MB·CPU 2개·software GPU·화면 720×1520/280dpi를 사용했다.
- `adb devices -l`에서 `emulator-5554`, `emulator-5556`이 `device`로 보여야 한다. Android Studio Device Manager에서 기존 AVD를 실행할 수도 있다.
- 새 AVD의 USB 디버깅 확인창을 처리한다. ADB 서버와 Flutter를 같은 사용자 권한으로 실행한다. 검증 도중 ADB 서버를 재시작하면 테스트 연결과 `reverse`가 끊긴다.

## 실행

저장소 루트의 터미널에서 Firebase Emulator를 켜 둔다.

```powershell
npm run dev:backend
```

별도 터미널에서 진행 상태를 주고받는 로컬 테스트 서버를 실행한다. `ADB` 환경 변수는 실제 SDK 경로를 사용한다. 서버는 `127.0.0.1:5877`에만 바인딩하며, 앱 데이터는 저장하지 않는다. 공유 코드·진행 단계만 전달하고 네트워크 끊기는 참여자 전용 AVD에만 적용한다.

```powershell
$env:ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $env:ADB -s emulator-5554 reverse tcp:5877 tcp:5877
& $env:ADB -s emulator-5556 reverse tcp:5877 tcp:5877
node frontend/scripts/android-e2e-coordinator.mjs
```

다른 터미널에서 테스트 APK를 한 번 빌드해 두 앱이 같은 바이너리를 사용하도록 보관한다. 테스트 코드나 앱 코드를 바꿨다면 다시 빌드한다.

```powershell
cd frontend
flutter build apk --debug --target=integration_test/two_device_test.dart --dart-define-from-file=dart_defines.example.json
New-Item -ItemType Directory -Force build/android-e2e | Out-Null
Copy-Item build/app/outputs/flutter-apk/app-debug.apk build/android-e2e/integration.apk
```

같은 `frontend` 폴더의 서로 다른 터미널에서 아래 두 명령을 실행한다. 첫 번째 앱의 `ownerReady`가 진행 상태 서버에 표시된 뒤 두 번째 명령을 실행한다. 두 테스트는 동시에 살아 있어야 한다. 공식 integration driver를 사용하며 VM 연결 포트를 구분한다.

```powershell
flutter drive --driver=test_driver/android_e2e.dart --target=integration_test/two_device_test.dart --use-application-binary=build/android-e2e/integration.apk -d emulator-5554 --no-dds --host-vmservice-port=5880 --keep-app-running
```

```powershell
flutter drive --driver=test_driver/android_e2e.dart --target=integration_test/two_device_test.dart --use-application-binary=build/android-e2e/integration.apk -d emulator-5556 --no-dds --host-vmservice-port=5881 --keep-app-running
```

첫 번째 익명 UID가 소유자, 두 번째 UID가 참여자가 된다. 같은 테스트를 재실행할 때 UID가 바뀌면 실패한다. 재시작 검증을 위해 `--keep-app-running`을 유지한다. 기본 drive 종료 정리는 앱을 삭제할 수 있다. Firebase 데이터 연결은 예제 설정의 `10.0.2.2`를 사용하고, ADB reverse는 네트워크 차단 중에도 살아 있어야 하는 테스트 진행 채널에만 사용한다.

## 검증 시나리오

1. 소유자 화면에서 여행과 일정 생성 → 화면의 공유 코드로 다른 UID가 참여.
2. 참여자 일정이 소유자 앱에 반영됨 확인. 생성자는 첫 참여자에 자동 연결되고, 다른 앱은 별도 참여자를 직접 본인 계정에 연결.
3. 참여자가 3,000 JPY 지출 생성 → 소유자가 3,600 JPY로 수정 → 참여자 구독에 반영.
4. 소유자가 체크리스트 생성 → 참여자 AVD의 Wi-Fi·모바일 데이터 차단 → 캐시 표시 확인.
5. 오프라인 참여자가 완료 체크 → 저장 대기 표시, 소유자에게 아직 반영되지 않음 확인.
6. 소유자가 온라인으로 새 일정 추가 → 오프라인 참여자에는 기존 캐시만 유지됨 확인.
7. 재접속 → 새 일정과 체크리스트 완료가 양쪽으로 전파됨 → 참여자가 지출을 3,000 JPY로 수정 → 소유자 반영과 지출 1건 유지 확인.
8. 두 테스트가 성공하면 앱을 강제 종료하고 같은 명령을 다시 실행. 기존 UID·여행·일정·지출·참여자 연결 유지 확인.

```powershell
& $env:ADB -s emulator-5554 shell am force-stop com.jim361.tripsplit
& $env:ADB -s emulator-5556 shell am force-stop com.jim361.tripsplit
```

진행 상태는 `frontend/build/android-e2e/state.json`, 성공 결과는 같은 폴더의 `owner-flow.json`, `guest-flow.json`, `owner-restart.json`, `guest-restart.json`에 저장한다. 실패한 실행은 exit code와 `Failure Details`로 확인한다. 전체 검증을 새로 시작할 때는 진행 상태 서버를 재시작한다. 기존 여행·계정 데이터를 자동 삭제하지 않는다. 새 실행에서는 해당 실행의 로그·결과 파일 갱신 시각도 함께 확인한다.

네트워크 차단 뒤 테스트를 강제 중단했다면 참여자 AVD의 연결을 복원한다. 테스트 자체는 `finally`에서 복원하며 진행 상태 서버의 Ctrl+C도 복원을 시도한다.

```powershell
& $env:ADB -s emulator-5556 shell svc wifi enable
& $env:ADB -s emulator-5556 shell svc data enable
```

## 2026-09-14 결과

- 소유자·참여자 흐름 각각 통과. 공유 참여, 서로 다른 UID/Participant 연결, 일정 양방향 구독, 3,000→3,600→3,000 JPY 지출 수정, 캐시·쓰기 대기·재접속과 지출 1건 유지를 확인했다.
- 앱 두 개를 `am force-stop`한 뒤 재시작 검증 각각 통과. 이전 UID·여행·3개 일정·지출·2개 참여자 계정 연결을 확인했다.
- `npm run verify:fast`: React 59개·backend 32개, format/lint/typecheck 통과.
- `npm run verify:flutter:full`: Dart format/analyze, Flutter 133개 테스트, 일반 debug APK 빌드 통과. 하단 메뉴 수정 뒤 두 AVD의 재시작·시스템 제스처 영역 검증도 다시 통과했다.
- 화면 캡처에서 Android 제스처 바와 하단 메뉴가 겹치는 문제를 발견했다. `TripShell` 하단 메뉴에 시스템 여백을 적용하고 Widget·Android 테스트에서 메뉴 글자의 실제 위치를 검증한다.
- 초기 실행에서 ADB/DDS 연결 실패가 있었다. AVD를 데이터 유지 상태로 재부팅하고 위의 integration driver 설정으로 실행한 결과를 통과 기록으로 사용한다. 중단된 실행은 성공에 포함하지 않는다.
- demo 설정의 Firebase Installations 토큰 경고는 로그에 남는다. 검증한 업무 경로는 로컬 Auth·Firestore·Functions이며 실제 Google 인증 성공을 의미하지 않는다.

최종 실제 AVD 화면: [소유자](screenshots/2026-09-14/android-emulator-owner-synced.png), [참여자](screenshots/2026-09-14/android-emulator-guest-synced.png). 같은 지출 3,000 JPY를 보며 연결된 Participant에 따라 개인 정산이 다르게 표시된다. [실행 결과 JSON](android-emulator-qa-results.json)은 통과한 네 개 결과와 진행 상태를 보존한다.

## 일반 앱 개발 재개

테스트 완료 후 `lib/main.dart`를 진입점으로 하는 Emulator 연결 APK를 두 AVD에 설치했다. 로컬 파일은 `frontend/build/android-e2e/trip-split-emulator.apk`다. 자동 테스트 APK와 구분하며 실제 Google Maps·Sheets는 꺼져 있다.

검증 후 전용 AVD와 로컬 테스트 서버를 종료했다. AVD 정의·설치된 앱·아래의 Firebase export는 남아 있다.

Android Studio에서 `frontend/`를 열고 Device Manager의 두 AVD를 실행한다. 일반 앱 실행은 다음 명령을 사용한다.

```powershell
cd frontend
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.example.json
```

검증 데이터는 Git에서 제외된 `.firebase/android-e2e-2026-09-14/`에 보존한다. 저장소 루트에서 아래 명령으로 같은 로컬 Auth·Firestore 데이터를 다시 시작할 수 있다. 새 테스트용 초기 데이터가 필요하면 앞의 `npm run dev:backend`를 사용한다.

```powershell
npx firebase emulators:start --project demo-trip-split --only auth,firestore,functions --import .firebase/android-e2e-2026-09-14
```

이 기록은 실기기·실제 Google 서비스 검증을 대체하지 않는다. 카메라·Photo Picker·공유 선택기, 실제 지도·Sheets, 전체 Phase B 완료 체크는 별도 범위다. 이번 Android 시나리오는 equal 지출 생성·수정과 체크리스트를 다룬다. custom·삭제·동시 편집·응답 유실, 예약·장소·A/B 재정렬의 전체 Android QA까지 완료한 것은 아니다.

참고: [Flutter integration_test](https://docs.flutter.dev/testing/integration-tests), [Android AVD 관리](https://developer.android.com/studio/run/managing-avds).
