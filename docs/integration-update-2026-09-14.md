# 2026-09-14 지도·시트·공통 통합

기준은 GitHub `origin/dev`의 `a5cfb0a`와 최신 `MarkDown/`, `development-kickoff.md`, `sheet-export.md`다. 사용자 요청에 따라 실기기 검증은 이번 범위에서 제외했다. Phase B 전체 완료 또는 운영 연결 완료로 표시하지 않는다.

## 구현한 부분

| 요청                         | 로컬 구현·검증 범위                                                                                           | 아직 확인하지 않은 부분                                           |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Flutter 화면·repository·지도 | 기존 화면 유지, `google_maps_flutter` adapter, 전체 번호 핀·직선 동선·장소 선택·카메라 보존, 실행 설정        | 제한된 실제 Maps 키로 지도 타일 표시, Google Places provider      |
| 두 클라이언트 데이터 갱신    | 세션 재구독·오류 복구, 캐시/쓰기 대기/서버 상태, 서로 다른 Auth UID의 Firestore 구독 통합 테스트              | 두 Android 실기기의 갱신·재시작·오프라인·카메라·Photo Picker·공유 |
| 시트 양식→미리보기→생성      | 전체 서버 조회 사본, 날짜/A·B 옵션, 동일 모델의 미리보기·Sheets 요청, 통화별 정산, OAuth 추가 권한, 실패 복구 | 실제 Google OAuth 동의와 새 문서 생성·열기                        |
| 공통 모델·Rules·export       | Dart 사본·동기화 인터페이스 추가, 기존 경로·11개 Callable·Rules와 회귀 통합                                   | 실제 프로젝트의 Rules/index/Functions 배포                        |

React Pages는 기존 mock을 유지한다. `.trip.json` 복원, OCR 실제 provider, Routes API, Web/iOS는 이번 구현에 추가하지 않았다. PR·배포·secret 등록도 수행하지 않았다. 구현과 검증 기록은 사용자 승인에 따라 `dev`에 함께 반영한다.

## 코드 진입점

- 지도: `frontend/lib/platform/google_map_adapter.dart`. 기능 화면은 `MapViewBuilder`만 받고 SDK는 adapter가 호출한다. 선택 날짜·계획별 카메라를 유지하고 최초에는 전체 핀 범위를 맞춘다. 실제 경로 계산이나 위치 권한 요청은 없다.
- 전체 조회: `TripsRepository.loadTripSnapshot`. Firebase 구현은 trip·participants·places·itinerary·expenses를 모두 서버에서 조회하고 오류·미확정 쓰기가 있으면 내보내기를 차단한다. 기존 화면 목록의 미로딩 값을 빈 배열로 내보내지 않는다.
- 동기화: `TripSyncRepository.watchSyncState`와 `TripSessionController`. 캐시를 최신 서버 데이터로 표시하지 않는다. 서로 다른 collection의 원자적 갱신이나 충돌 병합을 보장하지 않는다. Callable 지출은 자동 생성 재시도·오프라인 큐를 추가하지 않았다.
- 시트: `frontend/lib/features/sheets`. 여행 설정·공유의 **시트 내보내기**에서 옵션→미리보기→생성으로 이어진다. `balancesForCurrency`·`proposeTransfers`를 재사용한다. [출력 양식과 복구 상세](sheet-export.md)를 참고한다.
- Google 인증: `GoogleAccountService`를 Firebase 계정 연결과 Sheets에서 공유한다. SDK 초기화는 한 번이며 Sheets 권한 요청은 Firebase UID를 연결/변경하지 않는다.

## Google 연결 설정

기존 프로젝트의 API·OAuth 환경을 준비한 뒤 `frontend/dart_defines.example.json`을 Git에서 제외된 `frontend/dart_defines.local.json`으로 복사한다. 기본 예제는 Maps와 Sheets 모두 꺼져 있다.

| 로컬 값                     | 용도                                                                 |
| --------------------------- | -------------------------------------------------------------------- |
| `ENABLE_GOOGLE_MAPS=true`   | 실제 지도 adapter 사용                                               |
| `GOOGLE_MAPS_API_KEY`       | Android Maps 키. Gradle이 같은 dart defines에서 읽어 manifest에 주입 |
| `ENABLE_GOOGLE_SHEETS=true` | 사용자가 누르는 Sheets 생성 버튼 활성화                              |
| `GOOGLE_SERVER_CLIENT_ID`   | 기존 Android Google Sign-In 설정에 대응하는 Web OAuth client ID      |
| 기존 `FIREBASE_*`           | 승인된 Firebase 또는 `demo-trip-split` Emulator 연결                 |

Maps SDK for Android와 Sheets API를 사용하는 프로젝트 설정이 필요하다. Maps 키에는 `com.jim361.tripsplit`과 해당 signing SHA 제한을 적용한다. Android OAuth에도 같은 package와 signing 정보를 등록한다. client secret이나 서비스 계정 키를 앱에 넣지 않는다. Maps를 켜고 키를 비워 두면 빌드가 명확히 실패한다.

```powershell
cd frontend
flutter run --dart-define-from-file=dart_defines.local.json
```

참고: [Flutter Google Maps](https://pub.dev/packages/google_maps_flutter), [Google Sign-In 추가 권한](https://pub.dev/packages/google_sign_in#authorization), [Sheets 생성 API](https://developers.google.com/workspace/sheets/api/reference/rest/v4/spreadsheets/create), [Sheets 파일별 권한](https://developers.google.com/workspace/sheets/api/scopes).

## 자동 검증 기록

- Node.js 22.23.2, Java 21.0.2 사용.
- `npm run verify:fast` 통과.
- `npm run verify:full` 통과: React 59개, backend 단위 32개, Firebase Emulator 22개, TypeScript/lint/format/build.
- Flutter 단위·Widget 신규 회귀: 보고서 사본·필터·통화·시간 미정·3일/10일·40건 지출·긴 메모, 원본 74개 일정/87개 지출/귀국편, 생성 유실·ID 복구·중복 차단, 세션 복구, 지도 adapter 전달, 390px/200% 글씨.
- 원본 상세 합산 93,631 JPY를 그대로 검산했다. 원본 요약값과의 불일치는 고치거나 숨기지 않았다. 분담자는 합산 테스트 안에서만 합성하며 실제 원본 정산으로 간주하지 않는다.
- `npm run verify:flutter:full` 통과: Dart format/analyze, Flutter 132개 테스트, Android debug APK 빌드.
- `frontend/build/app/outputs/flutter-apk/app-debug.apk`는 기본 mock이며 Maps/Sheets 외부 연결이 꺼진 검증용 빌드다.

### 최종 확인

- [x] `npm run verify:flutter:full` 전체 테스트·debug APK 완료
- [x] 실제 Flutter 시트 미리보기 캡처와 200% 글씨 확인
- [x] 후속 요청: Android Emulator 두 앱의 공유·일정·지출 갱신, 오프라인·재접속, 강제 종료 후 UID·데이터 유지 — [별도 검증 기록](android-emulator-qa.md)
- [ ] 제한된 Maps 키·Google 계정의 실제 호출 확인
- [ ] Android 두 기기·카메라·공유 확인 — 이번 작업에서 제외

## 기기 준비 후 실행 순서

1. `adb devices -l`로 서로 다른 두 기기를 확인하고 debug APK를 설치한다. Emulator Suite는 `npm run dev:backend`로 실행한다.
2. USB 실기기는 각 기기에 `adb -s <serial> reverse tcp:9099 tcp:9099`, `8080`, `5001`을 적용한다. dart defines의 host는 `127.0.0.1`로 사용한다. AVD의 `10.0.2.2`와 혼동하지 않는다.
3. 각 기기가 서로 다른 익명 UID를 받는지 확인한 뒤 공유 코드로 같은 여행에 들어간다. 각각 다른 Participant를 연결한다.
4. 장소 없는 일정, 날짜/A·B별 재정렬, 장소 연결/해제, 준비 완료, equal/custom 지출 추가·수정·삭제, 여행 설정 변경을 양쪽 방향으로 확인한다. 앱 재시작 후에도 확인한다.
5. 비행기 모드에서 캐시·대기 표시와 재접속을 확인한다. 지출 Callable 실패를 자동 재생성하지 않는지 확인한다.
6. 카메라·Photo Picker 취소/선택, 영수증 외부 전송 고지, 공유 선택기, 외부 지도 URL, Google 지도 확대·번호·직선 동선을 확인한다.
7. Google Sheets는 미리보기와 생성 문서를 대조한다. 권한 취소·생성 응답 유실·내용 저장 실패·앱 재시작 후 같은 문서 복구를 확인한다.

서버 Emulator의 두 인증 클라이언트 성공은 이 실기기 절차를 대체하지 않는다.
