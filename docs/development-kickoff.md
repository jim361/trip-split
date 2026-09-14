# 3인 개발 시작 안내

> 2026-09-14. 사용자 요청으로 화면·mock·필요 서버 함수까지 한 번에 구현한 인계 기준이다. 기존 TASK/기능 ID와 Firestore ID는 유지한다.

## 먼저 확인할 것

- [화면·API 인계](frontend-api-handoff.md): 화면 제작 순서, 구현된 11개 Callable, 준비 데이터 wire, 오류와 재시도.
- [Firebase 연결 감사](firebase-api-contract.md): 구현/Emulator와 실제 외부 연결 구분.
- [시트 내보내기](sheet-export.md): 고정 일정·지출 샘플과 Flutter 중심 출력 방향. 현재 샘플·문서 준비 단계다.
- [작업 인덱스](../MarkDown/task/tasks.md), [기술 계약](../MarkDown/tech.md), [작업 공유·캡처](development-update-2026-09-14.md).
- 일정 CRUD·길게 끌어 재정렬, 수동 비용, 장소, 준비, 참여자, 개인 정산, 여행 설정·공유, itemized/OCR 검토까지 Flutter에 연결했다. 동일 기능을 처음부터 다시 만들지 않고 최신 dev의 구현을 읽고 이어서 작업한다.

## 담당과 지금 시작할 작업

| 담당                      | 소유 범위                                                                                       | 다음 작업                                                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| 사용자 · 프론트/공통/통합 | 전체 Flutter, Dart 정산·repository·지도 adapter, backend/share·shared, CI·공통 Rules/index 통합 | 두 Android 클라이언트 교차 QA, 실기기 촬영·사진·지도·공유, SDK/운영 연결 조율, TASK-08 백업                             |
| 일정·지도 백엔드          | backend/src/places, 도메인 테스트, 장소·일정·준비 Rules/index 변경안                            | 기존 TASK-03 검색/링크 handler 인계 검토, URL 성공/실패 fixture 보강, 준비·일정 동시 변경 검증, 승인 후 Google provider |
| 정산·영수증 백엔드        | backend/src/settlement, backend/src/ocr, 도메인 테스트                                          | equal/custom/itemized validator 교차 검토, 금액·조정·비활성 참여자 회귀 보강, OCR provider benchmark/연결 준비          |

공통 모델, backend/src/index.ts, firestore.rules/indexes, lockfile은 사용자가 최종 통합한다. 필요한 변경을 담당별로 공유하고 서로의 코드를 덮어쓰지 않는다. 이번 일괄 구현은 역할 분담 변경이 아니다.

2026-09-14 추가 작업인 Google Sheets 보고서는 사용자가 기존 Flutter repository·Dart 정산을 재사용해 담당한다. 고정 샘플로 양식과 미리보기를 먼저 만들고 Google OAuth·Sheets 생성을 연결한다. 두 백엔드 담당에게 시트용 서버를 추가하지 않는다. D-day/오늘 일정 카드·Gemini 브리핑은 후속 논의다.

## 처음 실행

각자 별도 clone을 사용한다. Node.js 22·Java 21이 필요하며 백엔드 담당은 Flutter SDK 없이 시작할 수 있다.

```bash
git clone --branch dev https://github.com/jim361/trip-split.git
cd trip-split
npm ci
npm run verify:fast
npm run test:emulator
```

프론트 담당은 Flutter 3.47.2와 Android SDK 환경에서 실행한다.

```bash
cd frontend
flutter pub get
flutter run
```

기본은 mock이다. Firebase Emulator를 확인할 때는 루트의 별도 터미널에서 `npm run dev:backend`를 켜고 `frontend`에서 `flutter run --dart-define-from-file=dart_defines.example.json`을 실행한다. Android host는 10.0.2.2, 프로젝트는 demo-trip-split이다. Google/OCR 유료 API·운영 secret·배포는 아직 연결하지 않는다. React Pages는 VITE_DATA_SOURCE=mock이다.

## 일정·지도 인계 — TASK-03/04/05

읽을 코드: `backend/src/places/places.ts`, `backend/tests/emulator/domain-flows.emulator.test.ts`, `backend/firestore.rules`, Flutter place provider/places_page와 itinerary_page.

- [x] searchPlaces/parsePlaceLink의 Auth·member guard, query string·URL 검증, Emulator 후보 반환과 Flutter adapter.
- [x] 일정 편집·optional 장소·A/B/날짜별 원자적 순서 저장, 시간 정렬, 외부 지도 열기.
- [x] 예약·체크리스트 모델/CRUD/Rules, 개인 항목도 여행 멤버에게 보이는 분류 정책.
- [ ] 실제 Google 검색·장소 링크 지원 범위 확대와 provider 실패/timeout/할당량 처리. 구현 전 사용할 환경·비용과 URL 정책 공유.
- [ ] 참조 중 장소 삭제를 서버에서 원자적으로 막을 필요가 있는지 검토. 현재 화면 검사와 동시 삭제 복구를 무결성 보장으로 오인하지 않기.
- [ ] 두 Android 기기에서 일정/장소/준비 실시간 갱신 검증에 참여.

## 정산·영수증 인계 — TASK-06/07

읽을 코드: `backend/src/settlement/expenseValidation.ts`, `expenses.ts`, `backend/src/ocr/receipts.ts`, domain-flows Emulator 테스트, Flutter ExpenseDraft와 receipt_review_page.

- [x] equal/custom/itemized 전체 validator, 안전한 정수·금액 합계·집합·나머지·부호·참조 확인.
- [x] 지출 CRUD Callable과 Flutter 호출 연결. client 직접 쓰기 차단은 유지.
- [x] 기존 비활성 참여자 이력 유지, 새 비활성 참여자 거부, 생성 감사 정보 보존, 멱등 삭제.
- [x] stateless OCR Emulator 샘플과 항목 검토·할인/봉사료·재정렬·명시적 저장 UI.
- [ ] 일본어 실제 영수증 fixture로 외부 OCR·번역 provider 정확도/비용/보관 정책 비교 후 연결안 공유.
- [ ] 실제 provider 전 전체 이미지 디코딩, timeout·rate limit·오류/언어 fallback 보강.
- [ ] 두 Android 기기 정산 갱신 검증에 참여. 신규 생성 응답 유실은 자동 재생성하지 않고 원장 확인 후 재시도하는 계약 유지.

## 공통 계약 변경 주의

- 신규 listMyTrips는 members.uid collection-group index가 필요하다. 구형 멤버는 재참여하면 같은 문서 ID에 uid를 보정한다. 운영 backfill은 별도 결정한다.
- linkMyParticipant는 본인만 연결/해제하며 다른 계정으로 uid를 전달하는 API가 아니다.
- 준비 문서는 최상위 필드 wire다. personal은 비공개 권한이 아니다.
- Google/OCR는 Emulator 샘플이며 실제 서비스 미연결을 unavailable로 반환한다.
- 지출 총액 분할은 source=manual/빈 receiptItems, itemized는 검토된 행과 일치하는 집계 배분을 저장한다.

## 반영·완료 기준

1. 작업 전과 push 직전 `git fetch origin dev`. 깨끗한 clone은 `git pull --ff-only origin dev`. 원격 새 변경이 있으면 통합하고 담당 검증을 다시 실행한다.
2. 작업 중 `npm run verify:fast`, 반영 전 `npm run verify:full`. Flutter는 `npm run verify:flutter:full`까지 실행한다.
3. dev에 직접 반영하고 CI를 확인한다. 기능 브랜치/dev PR은 만들지 않는다. main은 검증한 dev의 릴리스 PR만 사용한다.
4. Codex commit/push/PR 작업은 각각 사용자 승인 범위를 따른다. 이번 요청은 commit/push를 포함하며 main merge·배포는 포함하지 않는다.
5. 테스트와 캡처는 기능/계약에 맞게 인계한다. 서버 Emulator 통과와 두 Android 기기·실제 외부 API 통합 완료를 구분한다.

## GitHub 작업 연결

기존 [#16 TASK-03](https://github.com/jim361/trip-split/issues/16), [#17 TASK-06](https://github.com/jim361/trip-split/issues/17), [#18 TASK-04](https://github.com/jim361/trip-split/issues/18)은 최초 구현 범위 추적용이다. 이번에 기반 구현이 추가됐으므로 이 문서의 현재 상태를 먼저 보고 담당 검토 후 Issue 상태를 정리한다. 이번 작업은 Issue 종료나 PR 편집을 수행하지 않는다.

2026-09-13 확인 기록: main은 PR·1인 승인·verify/flutter-android CI·대화 해결, dev는 직접 push 허용과 force push/삭제 차단. PR #4 `dev → main`은 기존 **Flutter Android 개발 기반과 3인 협업 준비** 릴리스 PR이다. 신규 코드가 dev에 반영되더라도 main merge와 설명 갱신은 별도 승인 범위다.
