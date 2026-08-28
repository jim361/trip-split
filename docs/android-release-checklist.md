# Android 내부 테스트·출시 체크리스트

> **[TASK-09 · 마감·출시]** 첫 MVP는 Android 내부 테스트까지를 대상으로 하며 Play 배포, signing secret, 실제 유료 API 연결은 별도 승인 항목이다.

## 1. 변경 통합

- [ ] 기능 PR이 `dev`를 대상으로 하고 선행 stacked PR이 순서대로 반영되었는지 확인한다.
- [ ] `main`에는 `dev` 검증이 끝난 뒤 release PR로만 반영한다.
- [ ] `MarkDown/` 계약, Flutter 모델, Firestore Rules와 Callable 요청·응답이 같은지 확인한다.
- [ ] 알려진 제한 사항과 미완료 외부 연동을 README와 PR에 기록한다.

## 2. 자동 검증

저장소 루트:

```bash
npm ci
npm run format:check
npm run typecheck
npm run lint
npm test
npm run build
npm run test:emulator
```

`frontend/`:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

- [ ] CI의 `verify`와 `flutter-android`가 모두 성공한다.
- [ ] 실제 Firebase 프로젝트가 아닌 `demo-trip-split` Emulator로 공유 코드 다중 사용자 테스트가 통과한다.
- [ ] APK artifact의 package ID가 `com.jim361.tripsplit`인지 확인한다.

## 3. Android 기기 QA

- [ ] API 24 이상 Emulator와 실제 기기 한 대에 debug APK를 설치한다.
- [ ] 390px급 portrait, 가로 회전, 글자 확대, 키보드 표시 상태를 확인한다.
- [ ] system back, 하단 내비게이션, deep link 호환 경로를 확인한다.
- [ ] 익명 사용자 두 명이 공유 코드로 같은 여행에 들어가 변경을 실시간 확인한다.
- [ ] 비행기 모드·재접속에서 캐시 데이터, pending write, 실패 복구 문구를 확인한다.
- [ ] 카메라·Photo Picker는 필요한 순간에만 권한 또는 시스템 선택기를 사용하고, 영수증 외부 전송 고지가 먼저 보이는지 확인한다.

## 4. 외부 서비스와 개인정보

- [ ] Android Maps 키는 package/SHA 제한, backend Places·OCR·번역 키는 서버 API 제한을 적용한다.
- [ ] Firebase budget alert와 Maps·Places·OCR·Translation quota를 정한다.
- [ ] `dart_defines.local.json`, Firebase 설정, Functions secret과 signing 자료가 Git에 포함되지 않았는지 확인한다.
- [ ] OCR 이미지·원문·임시 초안이 Storage, Firestore, 로그와 분석 이벤트에 남지 않는지 확인한다.
- [ ] 개인정보처리방침과 Google Play Data Safety 초안을 팀이 검토한다.

## 5. 배포 승인

- [ ] 버전과 변경 내역을 확정한다.
- [ ] 서명되지 않은 release build를 검증한다.
- [ ] signing key와 Play Console 업로드는 소유자의 별도 승인을 받는다.
- [ ] 내부 테스트 설치 링크와 rollback 대상 commit을 기록한다.
