# Task Function 9 - Polish And Release

> **[TASK-09 · 마감·출시]** Android 접근성, 권한과 출시 전 품질 검증입니다.

## 목표

MVP를 데모 가능한 품질로 정리한다.

## 담당

플랫폼·통합 담당이 최종 QA와 병합을 소유하고, 정산·영수증 담당과 장소·일정·지도 담당이 각 도메인의 회귀 검증을 맡는다.

## 작업

- [ ] Android API 24 이상 emulator와 최소 한 대 실기기 QA
- [ ] portrait 우선 작은 handset, 가로 회전, 글자 확대와 키보드 inset QA
- [ ] adaptive icon, splash, 앱 이름과 package ID 확인
- [ ] system back, deep link/App Link 경계와 Android share sheet 확인
- [ ] Firestore 캐시, pending write, 동기화 완료·실패와 재접속 상태 확인
- [ ] 빈 상태 문구 정리
- [ ] 로딩 상태 정리
- [ ] 에러 상태 정리
- [ ] 저장 중/저장 완료 상태 정리
- [ ] Firebase 전체 보안 규칙 점검. members·공유·장소 baseline은 완료했고 expense 저장 Callable·validator와 `linkedUid` 연결 Callable은 남음
- [x] Anonymous Auth와 members 보안 규칙 점검
- [ ] Google 로그인 연결 UX 점검
- [x] 공유 코드 만료/비활성 정책 점검
- [ ] Google Maps·Places 키 제한과 호출량·예산 정책 정리
- [ ] OCR·Translation provider 호출량·예산 정책 정리
- [ ] 카메라·Photo Picker·네트워크 권한과 외부 전송 안내 점검
- [x] `tokyo-2026-11` 데모 여행과 강릉 회귀 데이터 준비
- [ ] 개인정보처리방침·Google Play Data Safety 초안과 영수증 임시 처리 정책 점검
- [ ] debug APK 검증. 현재 release build는 임시 debug key를 사용하므로 배포 금지하며, 실제 signing secret과 Play 배포는 별도 승인
- [ ] Flutter Web은 선택적 compile/smoke만 수행하고 Android 완료를 막지 않음
- [x] README 작성
- [x] 배포 체크리스트 작성
- [ ] 팀별 회고 및 다음 기능 정리

## 완료 기준

- 팀원이 설치한 Android 내부 테스트 빌드에서 공유 코드로 데모 여행을 볼 수 있다.
- 팀원이 공유 코드로 같은 Firebase 여행 세션을 실시간 편집할 수 있다.
- 장소, 일정, 지도, 정산, OCR 핵심 흐름이 한 번에 시연된다.
- 알려진 제한 사항이 README에 정리되어 있다.
- Android handset에서 앱 바·하단 내비게이션·modal bottom sheet와 키보드가 겹치지 않는다.
- `flutter analyze`, `flutter test`, debug APK build와 backend/Emulator 검증이 모두 통과한다.
- 백그라운드 위치·Health Connect 권한, 실제 유료 API와 배포 secret은 첫 MVP에 포함되지 않는다.
