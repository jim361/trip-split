# Trip Split Graphify 갱신 — IMB-03 현재 상태

2026-09-15 · 기준 `dev` / `3d9f7e969fb84c008cf35f1802de4254f25e9a06` 위 현재 작업 트리.
서버 구현·검증 및 `3d9f7e9`의 origin/dev 반영은 완료됐다. 첫 CI의 verify는 통과했고 Flutter 포맷 실패는 공식 Dart 3.13.2로 수정해 87개 파일 재검사가 통과했다. Flutter analyze/test/APK의 후속 CI와 실제 Android integration은 아직 확인 전이다.

전체 327개 입력(코드 197·문서 50·이미지 79 및 Firestore Rules)을 대상으로, 변경 코드 46·문서 16·이미지 52와 Rules 경계를 갱신했다. JSON 설정/QA 기록 3개는 구조 기호 대신 근거 노드로 추가했다.
결과 3,080개 노드·4,777개 관계·158개 군집. 대표 노드 coverage는 문서·이미지 전부를 포함하지만 모든 문장을 완전히 추출했다는 뜻은 아니다.

[전체 그래프](graph.html) · [일정·지도 그래프](itinerary-map.html) · [원본 추출](extraction.raw.json) · [진단](diagnostics.txt)

- 장소·일정 직접 삭제는 거부된다. 삭제 Callable은 역참조를 검사하고 참조 중이면 conflict를 반환한다.
- 일정·예약 참조 변경과 서버 정산 쓰기는 여행 referenceVersion을 공유한다. 같은 여행 대상 존재와 동시 연결·삭제를 보호한다.
- 루트 전체 검증은 단위 181개·Emulator 61개 통과다. Flutter 검증은 포함하지 않는다.
- 화면 캡처는 보이는 상태의 근거다. 과거 Android QA 기록과 이번 Flutter 검증 대기는 별개다.
- 기존 무방향 그래프를 유지한다. raw 진단에는 연결 대상 누락 260개·자기 연결 9개·동일 끝점 병합 후보 809개가 있다. 외부/미해결 기호와 반복 관계를 포함하므로 아래 순위를 정확한 호출 횟수로 해석하지 않는다. raw와 표시 그래프를 모두 보존했다.
- 토큰 실측값은 제공되지 않았다. 아래 0과 cost.json의 0은 호환 placeholder이며 무료 사용이나 실제 0 토큰을 뜻하지 않는다.

후속 증분 갱신: Dart 3개 파일의 AST와 수동 소스 위치, tasks.md 상태를 현재 내용으로 갱신했다. 노드·관계 구조가 동일함을 확인해 기존 군집·레이블과 benchmark를 유지했다. 비용 토큰은 미측정이다.

---

# Graph Report - trip-split  (2026-09-15)

## Corpus Check
- 327 files · ~324,357 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3080 nodes · 4777 edges · 158 communities (125 shown, 27 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 127 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3d9f7e96`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- 서버 Callable 입력 검증
- Emulator 인증 도메인 테스트
- React 도메인 저장소 계약
- React 경로 여행 셸
- Vite 환경 타입 선언
- React Firestore 데이터 변환
- React Firebase 인증 초기화
- React 여행 기능 화면
- React 강릉 회귀 샘플
- React 메모리 저장소 구현
- React 여행 기능 화면
- React 도쿄 회귀 샘플
- React 일정 시간표 구현
- React 여행 저장소 계약
- IMB-03 참조 Emulator 회귀
- Android 촬영 공유 연동
- React 일정 시간표 구현
- React Firebase 인증 초기화
- Emulator 인증 도메인 테스트
- React 공통 도메인 식별자
- React mock 장소 후보
- React 목업 빌드 의존성
- Android 동시 검사 조율
- React 도쿄 회귀 샘플
- Flutter 공통 데이터 모델
- Flutter 인증 게이트 테스트
- Flutter mock 인증 서비스
- 지도 핀 동선 모델
- 루트 npm 검증 명령
- 체크리스트 담당자 Rules
- 일정 A안 B안 선택
- 백엔드 개발 테스트 의존성
- 백엔드 빌드 Emulator 명령
- 지도 렌더링 빌더 계약
- 일정 편집 화면 테스트
- 공통 코드 포맷 설정
- Flutter mock 인증 서비스
- Git 위험 명령 보호
- Pages 호환 파일 준비
- Flutter 앱 의존성 조립
- 수동 지출 편집 화면
- Android 통합 검사 드라이버
- 프론트 컴파일 참조 설정
- Flutter 인증 진입 게이트
- Flutter 공통 데이터 모델
- Flutter 공통 데이터 모델
- Flutter 공통 데이터 모델
- Flutter 공통 데이터 모델
- Flutter 저장소 인터페이스 연결
- Android 두 기기 통합 검사
- Flutter 저장소 인터페이스 연결
- Flutter 저장소 인터페이스 연결
- Flutter 공통 데이터 모델
- Flutter 저장소 인터페이스 연결
- Flutter 저장소 인터페이스 연결
- Flutter 저장소 인터페이스 연결
- Flutter 저장소 인터페이스 연결
- 지출 상세 조회 화면
- Flutter 화면 경로 테스트
- Flutter repository 입력 계약
- 일정 상세 편집 화면
- 여행 전체 시간표
- 영수증 파싱 입력 계약
- 영수증 검토 저장 화면
- 지출 등록 흐름 테스트
- 지도 핀 동선 모델
- 예약 체크리스트 화면
- Flutter 여행 공유 서비스
- Flutter 메모리 저장소
- Flutter 도메인 회귀 테스트
- 준비 데이터 입력 모델
- 장소 검색 편집 화면
- Flutter 비용 원장 화면
- 시트 출력 및 촬영 회귀
- 영수증 항목 편집 화면
- Flutter 도쿄 고정 샘플
- Flutter Firestore 데이터 변환
- 참여자 계정 연결 화면
- Flutter 테마 디자인 토큰
- 영수증 이미지 선택 화면
- Flutter 앱 시작 구성
- Flutter 실행 환경 설정
- Flutter 개발 흐름 테스트
- Flutter 장소 후보 계약
- Google Sheets 생성 서비스
- Flutter 여행 구독 세션
- Flutter 앱 의존성 조립
- Flutter 일정 지도 화면
- 시트 옵션 및 미리보기
- Google 지도 플랫폼 어댑터
- Flutter 표시 위젯 연결
- React TypeScript 컴파일 설정
- Flutter 화면 경로 테스트
- Flutter 인증 진입 게이트
- Dart 정산 계산 엔진
- 공통 편집 이탈 처리
- 루트 npm 검증 명령
- 여행 백업 직렬화
- Flutter 상태 위젯 연결
- 여행 설정 공유 화면
- Flutter 계정 진입 화면
- Flutter 참조 통합 검사
- 백엔드 npm 실행 환경
- 여행 생성 목록 화면
- 백엔드 TypeScript 컴파일 설정
- Flutter mock 장소 검색
- Flutter 화면 카탈로그 촬영
- 루트 npm 검증 명령
- Flutter 장소 OCR Callable
- Flutter Firebase 오류 변환
- Flutter 여행 탭 셸
- 여행 세션 구독 회귀
- Flutter Firebase 클라이언트 초기화
- Flutter Firebase 인증 서비스
- Flutter 경로 선택 상태
- Flutter repository 입력 계약
- 일정 시트 보고서 생성
- Android 플랫폼 액션 경계
- 여행 백업 검증 테스트
- Vite Node 컴파일 설정
- 체크리스트 담당자 Rules
- Flutter 인증 서비스 계약
- Google 계정 연결 서비스
- 시트 미리보기 화면 캡처
- 일정 지도 화면 캡처
- 일정 편집 화면 캡처
- 예약 체크리스트 화면 캡처
- 여행 설정 공유 화면
- 지출 정산 화면 캡처
- 영수증 정산 화면 캡처
- 계정 및 여행 시작 화면
- 장소 보관함 화면 캡처
- Flutter 패키지 구조 설정
- Flutter 전환 범위 문서
- Flutter 전환 범위 문서
- Android 기본 런처 아이콘
- 디자인 토큰 시각 계약
- 목업 프롬프트 리뷰 문서
- 일정 지도 확대 목업
- React Pages 배포 셸
- 웹 브랜드 벡터 아이콘
- 도쿄 일정 지도 목업
- 서버 Callable 입력 검증
- 시트 보고서 백업 설계
- Android 검증 및 화면 인계
- 최신 구현 API 인계
- 일정·지도 실행과 검증
- Android 출시 검증 문서
- 최신 구현 API 인계
- 기존 두 기기 QA 기록
- mock 화면 촬영 기록
- Flutter Emulator 설정 예제

## God Nodes (most connected - your core abstractions)
1. `_` - 101 edges
2. `_` - 50 edges
3. `EntityId` - 49 edges
4. `InMemoryTripRepositories` - 39 edges
5. `_` - 39 edges
6. `appError()` - 28 edges
7. `createAppError()` - 21 edges
8. `compilerOptions` - 21 edges
9. `scripts` - 21 edges
10. `TripRepositories` - 20 edges

## Surprising Connections (you probably didn't know these)
- `TASK-07 영수증 OCR 및 번역 초안 검토` --references--> `parseReceipt`  [EXTRACTED]
  MarkDown/task/task_function7_ocr.md → backend/src/ocr/receipts.ts
- `플랫폼·통합 기반 및 세션 주입 구조` --references--> `TripSessionController`  [EXTRACTED]
  docs/platform-handoff.md → frontend/lib/app/trip_session.dart
- `플랫폼·통합 기반 및 세션 주입 구조` --references--> `AuthSessionGate`  [EXTRACTED]
  docs/platform-handoff.md → frontend/lib/app/auth_session_gate.dart
- `saveReservation` --shares_data_with--> `Firestore reservations`  [EXTRACTED]
  frontend/lib/data/firebase/firestore_trip_repositories.dart → backend/firestore.rules
- `watchReservations` --shares_data_with--> `Firestore reservations`  [EXTRACTED]
  frontend/lib/data/firebase/firestore_trip_repositories.dart → backend/firestore.rules

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **IMB-03 참조 무결성 및 삭제 보호 경계 (Rules·버전·Callable)** — backend_workstreams_itinerary_map_tasks_imb_03, backend_firestore_places_member_delete, backend_firestore_itinerary_placeid_validation, backend_src_shared_references_deleteplace [EXTRACTED 1.00]
- **영수증 촬영부터 항목 분할 및 정산 원장 저장 흐름** — docs_screenshots_2026_09_14_07_receipt_image_ocr_flow, docs_screenshots_2026_09_14_08_receipt_review_item_split, docs_screenshots_2026_09_14_10_receipt_allocations_reconciliation, docs_screenshots_2026_09_14_11_saved_expense_expense_detail, docs_screenshots_2026_09_14_12_personal_settlement_ledger_summary [INFERRED 0.85]
- **여행 일정 편성과 출발 전 장소·예약 준비 흐름** — docs_mockups_itinerary_map_mobile_timeline_view, docs_mockups_tokyo_preparation_mobile_prep_hub, docs_screenshots_2026_09_14_01_places_search_place_box, docs_screenshots_2026_09_14_03_preparation_checklist_reservations [INFERRED 0.85]
- **Android AVD 두 기기 검증 및 Flutter 화면 목록 체계** — docs_android_emulator_qa_two_device_spec, docs_flutter_screen_catalog_screen_catalog, docs_development_kickoff_kickoff_status [INFERRED 0.85]
- **장소·일정·지도 연계 파이프라인** — markdown_task_task_function3_places_places_service, markdown_task_task_function4_itinerary_timetable, markdown_task_task_function5_map_map_adapter [INFERRED 0.95]

## Communities (158 total, 27 thin omitted)

### Community 0 - "서버 Callable 입력 검증"
Cohesion: 0.07
Nodes (70): Allocation, ExpenseDraft, ReceiptItem, NormalizedCreateTripInput, ShareCodeCollisionError, AppErrorCode, AppErrorOptions, CallableAuth (+62 more)

### Community 102 - "Emulator 인증 도메인 테스트"
Cohesion: 0.24
Nodes (7): client(), create(), setup(), apps, saveReservation, watchReservations, Firestore reservations

### Community 11 - "React 도메인 저장소 계약"
Cohesion: 0.09
Nodes (27): InMemoryRepositoriesOptions, MockEntityKind, Subscriber, CreateExpenseInput, CreateItineraryItemInput, CreateParticipantInput, CreatePlaceInput, ExpensesRepository (+19 more)

### Community 113 - "React 경로 여행 셸"
Cohesion: 0.25
Nodes (4): NavigationIconProps, TripNavigationProps, TripNavigation(), navigationItems

### Community 14 - "React Firestore 데이터 변환"
Cohesion: 0.15
Nodes (40): FirestoreRecord, FirestoreRepositoriesOptions, ItineraryCategory, ItineraryPlanId, allocationsField(), asRecord(), booleanField(), createFirestoreTripRepositories() (+32 more)

### Community 16 - "React Firebase 인증 초기화"
Cohesion: 0.11
Nodes (22): DataSource, AuthErrorListener, AuthService, AuthStateListener, AuthUser, FirebaseClient, FirebaseConfigKey, FirebaseAuthService (+14 more)

### Community 18 - "React 여행 기능 화면"
Cohesion: 0.10
Nodes (23): AuthContextValue, AuthStatus, TripShellProps, App(), AuthProvider(), useAuth(), PlatformServicesProvider(), usePlatformServices() (+15 more)

### Community 33 - "React 강릉 회귀 샘플"
Cohesion: 0.10
Nodes (23): PlatformServices, gangneungTripFixture, block(), edit(), renderWorksheet(), createInMemoryTripRepositories(), createdAt, expenses (+15 more)

### Community 34 - "React 메모리 저장소 구현"
Cohesion: 0.29
Nodes (6): InMemoryTripRepositories, TripRepositorySeed, EntityId, clone(), notFound(), sortById()

### Community 35 - "React 여행 기능 화면"
Cohesion: 0.14
Nodes (23): FeaturePlaceholderProps, PlaceholderPanelProps, CurrencyCode, useTripContext(), buildTransitUrl(), enumerateDates(), formatDate(), ItineraryPage() (+15 more)

### Community 53 - "React 도쿄 회귀 샘플"
Cohesion: 0.13
Nodes (10): CreateTripCommand, CreateTripResult, FirebaseTripSessionService, JoinTripResult, MockTripSessionService, TripSessionService, call(), invalidArgument() (+2 more)

### Community 63 - "React 일정 시간표 구현"
Cohesion: 0.17
Nodes (14): Editor, ItineraryWorksheetProps, ScheduleDraft, TimedItineraryItem, formatDate(), formatHour(), ItineraryWorksheet(), toDraft() (+6 more)

### Community 66 - "React 여행 저장소 계약"
Cohesion: 0.13
Nodes (9): TripContextValue, TripDataState, PlannerMapPreviewProps, ItineraryRepository, PlacesRepository, ItineraryItem, Place, EMPTY_DATA (+1 more)

### Community 69 - "IMB-03 참조 Emulator 회귀"
Cohesion: 0.19
Nodes (12): client(), audit(), checklist(), create(), expectIntegrity(), itinerary(), reservation(), response() (+4 more)

### Community 76 - "Android 촬영 공유 연동"
Cohesion: 0.25
Nodes (8): MainActivity, Bundle, ByteArray, FlutterActivity, FlutterEngine, Intent, MethodChannel, Uri?

### Community 80 - "React 일정 시간표 구현"
Cohesion: 0.20
Nodes (10): MapAdapter, MapPin, MapPolyline, MapRenderModel, PositionedPin, createMapRenderModel(), buildGoogleMapsUrl(), clamp() (+2 more)

### Community 87 - "React Firebase 인증 초기화"
Cohesion: 0.22
Nodes (8): AppError, AppErrorCode, EpochMillis, normalizeCode(), epochMillisFromDate(), isEpochMillis(), CODE_MAP, MESSAGES

### Community 88 - "Emulator 인증 도메인 테스트"
Cohesion: 0.17
Nodes (6): CreateTripResult, JoinTripResult, TestClient, apps, apps, @firebase/rules-unit-testing

### Community 92 - "React 공통 도메인 식별자"
Cohesion: 0.17
Nodes (9): ParticipantId, AllocationMethod, ExpensePayer, KrwAmount, LocalDate, MoneyAllocation, OcrItemCandidate, ReceiptItem (+1 more)

### Community 99 - "React mock 장소 후보"
Cohesion: 0.20
Nodes (3): MockPlaceProvider, PlaceCandidate, PlaceProvider

### Community 10 - "React 목업 빌드 의존성"
Cohesion: 0.04
Nodes (44): dependencies, firebase, react, react-dom, react-router-dom, devDependencies, jsdom, @testing-library/jest-dom (+36 more)

### Community 118 - "Android 동시 검사 조율"
Cohesion: 0.47
Nodes (5): network(), output, run, server, state

### Community 67 - "React 도쿄 회귀 샘플"
Cohesion: 0.15
Nodes (14): createdAt, expenses, itinerary, members, participantColors, participants, places, shareCodes (+6 more)

### Community 1 - "Flutter 공통 데이터 모델"
Cohesion: 0.02
Nodes (83): addedBy, address, allocatedAmounts, allocationMethod, amount, AppErrorCode, authProvider, capturedAt (+75 more)

### Community 100 - "Flutter 인증 게이트 테스트"
Cohesion: 0.18
Nodes (10): authStateChanges, _changes, dispose, ensureAnonymousSession, ensureCalls, expireSession, linkGoogleAccount, main (+2 more)

### Community 101 - "Flutter mock 인증 서비스"
Cohesion: 0.20
Nodes (9): auth_service.dart, AuthUser, authStateChanges, _changes, dispose, ensureAnonymousSession, linkGoogleAccount, _user (+1 more)

### Community 103 - "지도 핀 동선 모델"
Cohesion: 0.20
Nodes (9): currentDate, currentPlan, nextOrder, normalizeItineraryOrders, sorted, unmodifiable, _withOrder, LocalDate? (+1 more)

### Community 104 - "루트 npm 검증 명령"
Cohesion: 0.20
Nodes (10): devDependencies, eslint, @eslint/js, eslint-plugin-react-hooks, eslint-plugin-react-refresh, firebase-tools, globals, prettier (+2 more)

### Community 106 - "체크리스트 담당자 Rules"
Cohesion: 0.25
Nodes (9): saveChecklist, setChecklistCompleted, watchChecklist, Firestore Rules 저장 권한, Firestore checklistitems, Firestore expenses, Firestore 여행 멤버 검증, Firestore participants (+1 more)

### Community 112 - "일정 A안 B안 선택"
Cohesion: 0.25
Nodes (7): build, itineraryCategoryStyle, ItineraryPlanSelector, onSelected, selected, shared/theme/app_theme.dart, ValueChanged

### Community 114 - "백엔드 개발 테스트 의존성"
Cohesion: 0.29
Nodes (7): devDependencies, firebase, @firebase/rules-unit-testing, firebase-tools, @types/node, typescript, vitest

### Community 115 - "백엔드 빌드 Emulator 명령"
Cohesion: 0.29
Nodes (7): scripts, build, emulators, preemulators, test, test:emulator:run, typecheck

### Community 119 - "지도 렌더링 빌더 계약"
Cohesion: 0.40
Nodes (4): MapViewBuilder, map_render_model.dart, package:flutter/widgets.dart, typedef

### Community 12 - "일정 편집 화면 테스트"
Cohesion: 0.05
Nodes (43): auth, createCalls, createGate, createItineraryItem, deleteItineraryItem, drag, _dragItem, ensureVisible (+35 more)

### Community 120 - "공통 코드 포맷 설정"
Cohesion: 0.40
Nodes (4): printWidth, semi, singleQuote, trailingComma

### Community 121 - "Flutter mock 인증 서비스"
Cohesion: 0.50
Nodes (4): AuthService, FirebaseAuthService, MockAuthService, _RestartingAuthService

### Community 122 - "Git 위험 명령 보호"
Cohesion: 0.83
Nodes (3): Get-Block(), Get-Reason(), Get-Tokens()

### Community 128 - "Pages 호환 파일 준비"
Cohesion: 0.50
Nodes (3): fallbackUrl, indexUrl, noJekyllUrl

### Community 129 - "Flutter 앱 의존성 조립"
Cohesion: 0.67
Nodes (3): FirebaseReceiptParser, MockReceiptParser, ReceiptParser

### Community 13 - "수동 지출 편집 화면"
Cohesion: 0.05
Nodes (42): amount, _amounts, _back, _basicFields, build, _busy, _changed, _checkLedger (+34 more)

### Community 15 - "Android 두 기기 통합 검사"
Cohesion: 0.05
Nodes (41): Checkbox, addItinerary, back, barrier, binding, _checklist, client, enter (+33 more)

### Community 17 - "지출 상세 조회 화면"
Cohesion: 0.05
Nodes (39): ../../app/trip_session.dart, ChangeNotifier, expense_detail_page.dart, expense_edit_page.dart, TripSessionController, build, _busy, createState (+31 more)

### Community 19 - "Flutter 화면 경로 테스트"
Cohesion: 0.07
Nodes (34): authService, main, pumpAndSettle, _pumpRoute, pumpWidget, repositories, textScaleFactor, main (+26 more)

### Community 2 - "Flutter repository 입력 계약"
Cohesion: 0.02
Nodes (83): abstract interface class TripRepositories, ExpensePayer, _, address, allocatedAmounts, allocationMethod, category, checkItem (+75 more)

### Community 21 - "일정 상세 편집 화면"
Cohesion: 0.05
Nodes (39): _addPlace, build, _busy, _category, _changed, clampDate, _close, _confirm (+31 more)

### Community 22 - "여행 전체 시간표"
Cohesion: 0.05
Nodes (38): build, byDate, byOrder, _compareItinerary, createState, date, dateIndex, _dateLabel (+30 more)

### Community 23 - "영수증 파싱 입력 계약"
Cohesion: 0.05
Nodes (38): _, amount, _bytes, confidence, currencyCandidate, expenseDate, fileName, _imageBase64 (+30 more)

### Community 25 - "영수증 검토 저장 화면"
Cohesion: 0.05
Nodes (36): Expense?, build, _changed, _checkLedger, _consumers, _controller, createState, _currency (+28 more)

### Community 26 - "지출 등록 흐름 테스트"
Cohesion: 0.06
Nodes (35): Completer, auth, createCalls, createExpense, createGate, deleteExpense, ensureVisible, enterExpense (+27 more)

### Community 27 - "지도 핀 동선 모델"
Cohesion: 0.06
Nodes (36): EntityId, _, colorByDate, colorHex, coordinate, date, _dateColors, dates (+28 more)

### Community 28 - "예약 체크리스트 화면"
Cohesion: 0.06
Nodes (34): ../../domain/preparation.dart, _assignee, booking, build, _busy, _changed, _checklist, createState (+26 more)

### Community 29 - "Flutter 여행 공유 서비스"
Cohesion: 0.06
Nodes (34): _call, countryCode, createShareCode, createTrip, CreateTripCommand, CreateTripResult, defaultCurrency, displayName (+26 more)

### Community 3 - "Flutter 메모리 저장소"
Cohesion: 0.03
Nodes (71): actorDisplayName, actorUid, _changes, _checklist, close, _copyShareCode, _copyTrip, createExpense (+63 more)

### Community 30 - "Flutter 도메인 회귀 테스트"
Cohesion: 0.08
Nodes (27): AppError, dart:async, draft, friend1, friend2, main, me, _legacy (+19 more)

### Community 31 - "준비 데이터 입력 모델"
Cohesion: 0.06
Nodes (32): assigneeParticipantId, ChecklistDraft, ChecklistItem, deleteChecklist, deleteReservation, draft, fromJson, isDone (+24 more)

### Community 32 - "장소 검색 편집 화면"
Cohesion: 0.07
Nodes (29): build, _busy, candidate, _coordinate, createState, _delete, _dirty, dispose (+21 more)

### Community 36 - "Flutter 비용 원장 화면"
Cohesion: 0.07
Nodes (27): CurrencyCode, CurrencyAmount, amount, balance, build, currency, currentUserUid, date (+19 more)

### Community 37 - "시트 출력 및 촬영 회귀"
Cohesion: 0.07
Nodes (25): dart:io, create, directory, integrationDriver, main, names, bodies, createStatus (+17 more)

### Community 38 - "영수증 항목 편집 화면"
Cohesion: 0.07
Nodes (27): _allocations, _amount, build, _changed, _consumers, _controller, createState, _custom (+19 more)

### Community 39 - "Flutter 도쿄 고정 샘플"
Cohesion: 0.07
Nodes (26): arrival, asakusa, checkIn, _createdAt, dinnerExpense, expenses, hotel, itinerary (+18 more)

### Community 4 - "Flutter Firestore 데이터 변환"
Cohesion: 0.03
Nodes (66): class, firebase_error_mapper.dart, 0, _allocation, _allocationJson, _call, _classifyReorderPermissionDenied, createExpense (+58 more)

### Community 40 - "참여자 계정 연결 화면"
Cohesion: 0.08
Nodes (26): _active, build, _busy, _color, createState, currentUid, dispose, _edit (+18 more)

### Community 41 - "Flutter 테마 디자인 토큰"
Cohesion: 0.07
Nodes (26): appBarHeight, AppTheme, buttonCornerRadius, _buttonRadius, _buttonShape, canvas, controlCornerRadius, _controlRadius (+18 more)

### Community 42 - "영수증 이미지 선택 화면"
Cohesion: 0.08
Nodes (25): ReceiptImageInput, build, _busy, createState, currentUid, dispose, _error, _image (+17 more)

### Community 43 - "Flutter 앱 시작 구성"
Cohesion: 0.08
Nodes (24): app/app.dart, data/firebase/firebase_client.dart, data/firebase/firestore_trip_repositories.dart, data/mock/in_memory_trip_repositories.dart, features/places/firebase_place_provider.dart, features/places/place_provider.dart, features/receipts/firebase_receipt_parser.dart, features/sheets/google_sheets_service.dart (+16 more)

### Community 44 - "Flutter 실행 환경 설정"
Cohesion: 0.08
Nodes (24): bool get, AppConfig, AppDataSource, authEmulatorPort, dataSource, _emptyToNull, emulatorHost, enableGoogleMaps (+16 more)

### Community 45 - "Flutter 개발 흐름 테스트"
Cohesion: 0.08
Nodes (23): dart:convert, dart:typed_data, ensureVisible, friend, main, me, pumpAndSettle, pumpPage (+15 more)

### Community 46 - "Flutter 장소 후보 계약"
Cohesion: 0.08
Nodes (24): domain/repositories.dart, double?, FirebasePlaceProvider, MockPlaceProvider, address, fromPlace, lat, lng (+16 more)

### Community 47 - "Google Sheets 생성 서비스"
Cohesion: 0.08
Nodes (24): _busy, _check, client, complete, create, creationUncertain, _error, hasPending (+16 more)

### Community 48 - "Flutter 여행 구독 세션"
Cohesion: 0.08
Nodes (23): AppError? get, dispose, _disposed, error, _errors, expenses, isLoading, itinerary (+15 more)

### Community 49 - "Flutter 앱 의존성 조립"
Cohesion: 0.08
Nodes (23): auth_session_gate.dart, ../features/auth/account_entry_page.dart, ../features/map/map_adapter.dart, features/places/mock_place_provider.dart, features/receipts/mock_receipt_parser.dart, ../features/trips/trip_home_page.dart, authService, build (+15 more)

### Community 5 - "Flutter 일정 지도 화면"
Cohesion: 0.03
Nodes (64): Color, CustomPainter, ItineraryItem, Place, ItineraryOrderDraft, build, createState, date (+56 more)

### Community 50 - "시트 옵션 및 미리보기"
Cohesion: 0.09
Nodes (23): GoogleSheetsService, ReportSheet, TripSheetReport, build, _busy, createState, _data, _dates (+15 more)

### Community 51 - "Google 지도 플랫폼 어댑터"
Cohesion: 0.09
Nodes (22): CameraPosition?, dart:math, ../features/map/map_render_model.dart, build, _cameras, _controller, createState, dispose (+14 more)

### Community 52 - "Flutter 표시 위젯 연결"
Cohesion: 0.09
Nodes (23): _DestinationCell, _LoadState, _MobileDestinationBar, TripShell, _DaySchedule, _DayScheduleRow, _DayTabs, _ItineraryHeading (+15 more)

### Community 54 - "React TypeScript 컴파일 설정"
Cohesion: 0.09
Nodes (22): compilerOptions, allowJs, allowSyntheticDefaultImports, esModuleInterop, forceConsistentCasingInFileNames, isolatedModules, jsx, lib (+14 more)

### Community 55 - "Flutter 화면 경로 테스트"
Cohesion: 0.10
Nodes (19): Container, dart:ui, FilledButton, TripDataSnapshot, SheetsResponse, main, data, loadTripSnapshot (+11 more)

### Community 56 - "Flutter 인증 진입 게이트"
Cohesion: 0.10
Nodes (20): authService, AuthSessionGate, _AuthSessionGateState, build, child, createState, dispose, _ensureSession (+12 more)

### Community 57 - "Dart 정산 계산 엔진"
Cohesion: 0.10
Nodes (20): allocateEqually, balancesForCurrency, baseAmount, c, creditors, currencies, debtors, join (+12 more)

### Community 58 - "공통 편집 이탈 처리"
Cohesion: 0.10
Nodes (20): action, actionError, build, busy, children, _close, confirmAction, _confirming (+12 more)

### Community 59 - "루트 npm 검증 명령"
Cohesion: 0.10
Nodes (21): scripts, build, build:pages, dev, dev:backend, dev:frontend, format, format:check (+13 more)

### Community 6 - "여행 백업 직렬화"
Cohesion: 0.03
Nodes (64): _allocationJson, _allocationSchema, _boolean, _byExpenseDate, _byId, _byItineraryOrder, _byReceiptOrder, _collection (+56 more)

### Community 61 - "Flutter 상태 위젯 연결"
Cohesion: 0.14
Nodes (20): TripRouteHost, _TripRouteHostState, AccountEntryPage, _AccountEntryPageState, ItineraryPage, _ItineraryPageState, PlaceEditPage, _PlaceEditPageState (+12 more)

### Community 62 - "여행 설정 공유 화면"
Cohesion: 0.10
Nodes (19): Trip, build, _busy, createState, dispose, _end, _error, _field (+11 more)

### Community 64 - "Flutter 계정 진입 화면"
Cohesion: 0.12
Nodes (16): ../../app/auth_session_gate.dart, anonymous, build, _continueWithGoogle, createState, _EntryActions, _EntryIntroduction, _error (+8 more)

### Community 65 - "Flutter 참조 통합 검사"
Cohesion: 0.12
Nodes (15): ArgumentError, Exception, data, _itinerary, main, _referenceVersion, trip, AppError (+7 more)

### Community 68 - "백엔드 npm 실행 환경"
Cohesion: 0.12
Nodes (15): dependencies, firebase-admin, firebase-functions, engines, node, main, name, private (+7 more)

### Community 7 - "여행 생성 목록 화면"
Cohesion: 0.04
Nodes (55): FormState, _addParticipant, anonymous, build, _buildPage, _busy, _controlWidgets, _createFormKey (+47 more)

### Community 70 - "백엔드 TypeScript 컴파일 설정"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, forceConsistentCasingInFileNames, lib, module, moduleResolution, noUnusedLocals, noUnusedParameters (+7 more)

### Community 71 - "Flutter mock 장소 검색"
Cohesion: 0.12
Nodes (14): ../data/mock/tokyo_trip_fixture.dart, domain/models.dart, _candidates, _ensureAvailable, _fixtureCandidates, isAvailable, _requireTripId, resolvePlaceLink (+6 more)

### Community 74 - "Flutter 화면 카탈로그 촬영"
Cohesion: 0.12
Nodes (15): EditableText, back, binding, _Capture, enter, main, open, shot (+7 more)

### Community 75 - "루트 npm 검증 명령"
Cohesion: 0.16
Nodes (14): engines, node, name, private, type, version, workspaces, eslint (+6 more)

### Community 77 - "Flutter 장소 OCR Callable"
Cohesion: 0.16
Nodes (12): ../data/firebase/firebase_error_mapper.dart, FirebaseFunctions, candidate, functions, placeCandidateFromData, resolvePlaceLink, searchPlaces, functions (+4 more)

### Community 79 - "Flutter Firebase 오류 변환"
Cohesion: 0.15
Nodes (12): FirebaseFunctionsException, _appErrorCodeFromWire, _defaultRetryable, _fallbackMessage, false, mapFirebaseError, null, main (+4 more)

### Community 8 - "Flutter 여행 탭 셸"
Cohesion: 0.04
Nodes (53): BorderSide, ../features/itinerary/itinerary_page.dart, ../features/preparation/preparation_page.dart, ../features/receipts/receipts_page.dart, ../features/settlement/expense_detail_page.dart, ../features/settlement/expense_edit_page.dart, ../features/settlement/participants_page.dart, ../features/settlement/personal_settlement_page.dart (+45 more)

### Community 81 - "여행 세션 구독 회귀"
Cohesion: 0.14
Nodes (13): inner, listens, main, noSuchMethod, places, _Repositories, watchExpenses, watchItinerary (+5 more)

### Community 83 - "Flutter Firebase 클라이언트 초기화"
Cohesion: 0.15
Nodes (12): FirebaseApp, FirebaseAuth, app, auth, _emulatorsConnected, FirebaseClient, firestore, functions (+4 more)

### Community 84 - "Flutter Firebase 인증 서비스"
Cohesion: 0.15
Nodes (12): FirebaseFirestore, _auth, authStateChanges, ensureAnonymousSession, _firestore, _googleAccount, googleServerClientId, linkGoogleAccount (+4 more)

### Community 85 - "Flutter 경로 선택 상태"
Cohesion: 0.15
Nodes (12): defaultTripId, destination, forDestination, mapExpanded, selectedDate, selectedPlan, toggleMap, TripDestination (+4 more)

### Community 86 - "Flutter repository 입력 계약"
Cohesion: 0.15
Nodes (13): FirestoreTripRepositories, InMemoryTripRepositories, ExpensesRepository, ItineraryRepository, MembersRepository, ParticipantsRepository, PlacesRepository, TripRepositories (+5 more)

### Community 9 - "일정 시트 보고서 생성"
Cohesion: 0.04
Nodes (46): DateTime, bold, buildTripSheetReport, capturedAt, _categoryColors, color, columns, count (+38 more)

### Community 91 - "Android 플랫폼 액션 경계"
Cohesion: 0.17
Nodes (11): features/receipts/receipt_parser.dart, AndroidActions, captureReceipt, _channel, loadSheetRecovery, openUrl, pickReceipt, _receipt (+3 more)

### Community 93 - "여행 백업 검증 테스트"
Cohesion: 0.17
Nodes (11): _encodedFixture, expenses, fixture, fromDomain, itineraryItems, main, now, participants (+3 more)

### Community 94 - "Vite Node 컴파일 설정"
Cohesion: 0.17
Nodes (11): compilerOptions, lib, module, moduleResolution, noEmit, skipLibCheck, strict, target (+3 more)

### Community 95 - "체크리스트 담당자 Rules"
Cohesion: 0.18
Nodes (11): createItineraryItem, createPlace, reorderItineraryItems, updateItineraryItem, updatePlace, watchItinerary, watchPlaces, Firestore itinerary (+3 more)

### Community 97 - "Flutter 인증 서비스 계약"
Cohesion: 0.18
Nodes (10): AuthService, authStateChanges, AuthUser, displayName, email, ensureAnonymousSession, isAnonymous, linkGoogleAccount (+2 more)

### Community 98 - "Google 계정 연결 서비스"
Cohesion: 0.18
Nodes (10): authenticate, authorizeSheets, GoogleAccountService, _initialization, _initialize, serverClientId, _sheetsToken, _signIn (+2 more)

### Community 108 - "시트 미리보기 화면 캡처"
Cohesion: 0.36
Nodes (4): 시트 미리보기 일정 및 지출 표 화면, 시트 내보내기 옵션 선택 화면, 시트 미리보기 일정 표 화면, 시트 미리보기 지출 및 정산 표 화면

### Community 109 - "일정 지도 화면 캡처"
Cohesion: 0.29
Nodes (4): 일정 및 동선 지도 화면, 지도 확대 보기 화면, 일정 B안 탭 및 빈 지도 화면, 일정 없는 날짜 빈 화면

### Community 110 - "일정 편집 화면 캡처"
Cohesion: 0.32
Nodes (4): 기존 일정 편집 폼 화면, 일정 연결 장소 선택 화면, 새 일정 추가 폼 화면, 일정 하단 카드 목록 화면

### Community 111 - "예약 체크리스트 화면 캡처"
Cohesion: 0.32
Nodes (4): 출발 전 준비 빈 화면, 예약 정보 입력 폼 화면, 체크리스트 항목 입력 폼 화면, 준비 항목 저장 목록 화면

### Community 20 - "지출 정산 화면 캡처"
Cohesion: 0.06
Nodes (20): 여행 비용 대시보드 화면, 지출 추가 기본 정보 입력 화면, 지출 참여자 균등 분할 배분 화면, 지출 참여자 직접 입력 배분 화면, 저장된 지출 상세 화면, 지출 삭제 확인 다이얼로그 화면, 정산 참여자 목록 화면, 새 참여자 추가 폼 화면 (+12 more)

### Community 24 - "영수증 정산 화면 캡처"
Cohesion: 0.07
Nodes (19): 장소 보관함 및 키워드 검색, 장소 수동 입력 및 편집 폼, 출발 전 예약 및 체크리스트 관리, 예약 정보 상세 입력 폼, 정산 참여자 및 계정 바인딩, 여행 메타데이터 및 공유 코드, 영수증 이미지 촬영 및 OCR 진입, 영수증 항목 검토 및 배분 설정 (+11 more)

### Community 73 - "계정 및 여행 시작 화면"
Cohesion: 0.16
Nodes (8): 계정 시작 및 로그인 선택 화면, 내 여행 전체 일정표 화면, 새 여행 생성 입력 화면, 여행 생성 필수 입력 오류 화면, 공유 코드 여행 참여 화면, 공유 코드 오류 메시지 화면, 여행 없음 오류 화면, 페이지 없음 경로 오류 화면

### Community 90 - "장소 보관함 화면 캡처"
Cohesion: 0.23
Nodes (6): 장소 보관함 목록 화면, 장소 검색 결과 화면, 장소 검색 결과 없음 화면, 지도 링크 형식 오류 화면, 장소 직접 입력 폼 화면, 저장된 장소 편집 화면

### Community 105 - "Flutter 패키지 구조 설정"
Cohesion: 0.22
Nodes (5): 3인 역할 분담 규칙, Flutter 정적 분석 린트 설정, Flutter Android 앱 패키지 및 의존성 매니페스트, Flutter-Backend 모노레포 구조 및 3인 역할 경계, 아키텍처 경계 및 불변 ID 규칙

### Community 107 - "Flutter 전환 범위 문서"
Cohesion: 0.29
Nodes (5): Flutter Android 전환 계획 (Phase A~D), 플랫폼·통합 기반 및 세션 주입 구조, 2026-08-28 Flutter Android 전환 결정 및 Tokyo JPY 우선, 현재 범위: docs/flutter-android-migration.md, 현재 범위: docs/platform-handoff.md

### Community 116 - "Flutter 전환 범위 문서"
Cohesion: 0.38
Nodes (4): 일정·지도 기능 후보와 IT/PREP 기능 ID, TASK-04 날짜별 일정 시간표, 순서 및 장소 연결, TASK-05 지도 핀, 동선 및 지도 adapter, 현재 범위: MarkDown/task/task_function4_itinerary.md

### Community 117 - "Android 기본 런처 아이콘"
Cohesion: 0.60
Nodes (6): Android Flutter 기본 런처 아이콘, ic_launcher.png (hdpi), ic_launcher.png (mdpi), ic_launcher.png (xhdpi), ic_launcher.png (xxhdpi), ic_launcher.png (xxxhdpi)

### Community 60 - "서버 Callable 입력 검증"
Cohesion: 0.11
Nodes (11): 정산·영수증 기능 논의 (ST/OCR 기능 ID, 단일 원장), TASK 이슈 템플릿 (TASK-01~TASK-09), TASK-01 프로젝트 기반 및 앱 셸 구축, TASK-07 영수증 OCR 및 번역 초안 검토, 현재 범위: MarkDown/task/task_function8_backup_export.md, TASK-08 백업 .trip.json 및 Google Sheets 보고서, 작업 인덱스 및 단계별 통합 순서, 현재 범위: MarkDown/task/task_function2_trip_share.md (+3 more)

### Community 72 - "시트 보고서 백업 설계"
Cohesion: 0.15
Nodes (10): 도쿄 2025 여행 시트 탭1 고정 테스트 샘플, Trip Split Flutter 전환 범위 점검 (코드 vs 방향 vs 회의 항목), 현재 범위: docs/sheet-export.md, Google Sheets 여행 보고서 내보내기 구현 및 권한 분리, 일정·지도·준비·정산 통합 여행 세션 제품 정의, MVP 2단계 목표 (P0 기반/일정/수동정산, P1 itemized/OCR), 제품 기술 발전 이력 (강릉 HTML → React/PWA → Flutter Android), 현재 범위: docs/project-scope-review.md (+2 more)

### Community 78 - "Android 검증 및 화면 인계"
Cohesion: 0.15
Nodes (8): 로컬 e2e coordinator 서버 및 adb reverse, Android 두 기기 AVD 통합 검증 절차, Flutter 19개 화면 및 49장 AVD 캡처 갤러리, 현재 범위: docs/README.md, 기능 범위 회의 인덱스 및 결정 관리, Flutter Android 프론트엔드 구조 및 실행 가이드, CI 워크플로우 (dev 검증 및 main PR 게이트), 프로젝트 시작 안내 및 빠른 검증 명령

### Community 82 - "최신 구현 API 인계"
Cohesion: 0.21
Nodes (9): 현재 범위: backend/README.md, 백엔드 Callable Functions 및 에뮬레이터 가이드, Google Places Emulator·운영 미연결 경계, Firebase 연결 감사 (13개 Callable, Firestore 컬렉션 및 쓰기 제약), 현재 범위: docs/firebase-api-contract.md, Flutter 화면 제작 순서 및 13개 Callable 요청/응답 Wire 규격, 현재 범위: docs/frontend-api-handoff.md, 기술 계약 (Flutter 3.47.2·Dart 3.13.2·Firebase) (+1 more)

### Community 89 - "일정·지도 실행과 검증"
Cohesion: 0.17
Nodes (12): IMB-00 — 담당 하네스 작성 — 완료, IMB-01 — 실행 환경과 기준선 — 완료, IMB-02 — 기존 검색·링크 경계 회귀 — 완료, IMB-04 — Google 연결·링크 정책 확정 — 미착수, IMB-05 — 실제 장소 검색 경로 구현 — 미착수, IMB-06 — 지도 링크 지원 확대 — 미착수, IMB-07 — 실제 연결·프론트 인계·dev 반영 — 미착수, 원본 clone Node 22·Java 21 검증 완료 (+4 more)

### Community 96 - "Android 출시 검증 문서"
Cohesion: 0.22
Nodes (7): Android 내부 테스트·출시 점검 항목, 현재 범위: docs/development-kickoff.md, 2026-09-14 3인 개발 인계 (Callable 13개 구현, 외부 연동 미완료), Google Maps 어댑터·시트 내보내기·동기화 통합 기록, TASK-09 Android 접근성, 권한 및 마감 품질, 현재 범위: docs/android-release-checklist.md, 현재 범위: MarkDown/task/task_function9_polish_release.md

## Knowledge Gaps
- **1850 isolated node(s):** `Allocation`, `ExpenseDraft`, `ReceiptItem`, `NormalizedCreateTripInput`, `AppErrorCode` (+1845 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2104 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **27 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `firebase-functions` connect `React Firebase 인증 초기화` to `백엔드 npm 실행 환경`, `IMB-03 참조 Emulator 회귀`, `Emulator 인증 도메인 테스트`, `React 도쿄 회귀 샘플`, `Emulator 인증 도메인 테스트`?**
  _High betweenness centrality (0.247) - this node is a cross-community bridge._
- **Why does `Firestore itinerary` connect `체크리스트 담당자 Rules` to `Emulator 인증 도메인 테스트`, `체크리스트 담당자 Rules`, `Emulator 인증 도메인 테스트`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **Why does `Firestore checklistitems` connect `체크리스트 담당자 Rules` to `Emulator 인증 도메인 테스트`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **What connects `Allocation`, `ExpenseDraft`, `ReceiptItem` to the rest of the system?**
  _1850 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `서버 Callable 입력 검증` be split into smaller, more focused modules?**
  _Cohesion score 0.06545114539504442 - nodes in this community are weakly interconnected._
- **Should `React 도메인 저장소 계약` be split into smaller, more focused modules?**
  _Cohesion score 0.09468599033816426 - nodes in this community are weakly interconnected._
- **Should `React Firestore 데이터 변환` be split into smaller, more focused modules?**
  _Cohesion score 0.14950166112956811 - nodes in this community are weakly interconnected._