import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';

// Android에서 실제 화면을 탐색하되 데이터·외부 서비스는 기존 mock을 사용한다.
// 캡처는 시각적 인계 자료이며 외부 API나 전체 기능 QA의 통과 증거가 아니다.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  Future<_Capture> open(WidgetTester tester, String route) async {
    final repo = InMemoryTripRepositories();
    final auth = MockAuthService();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
      await auth.dispose();
    });
    await tester.pumpWidget(
      TripSplitApp(
        repositories: repo,
        authService: auth,
        tripShareService: MockTripShareService(repo),
        dataSourceLabel: 'mock',
        initialRoute: route,
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    return _Capture(tester, binding);
  }

  testWidgets('01 시작·여행 목록·생성·공유 참여', (tester) async {
    final c = await open(tester, '/');
    await c.shot('01-account');
    await c.tapKey('account-continue-guest');
    await c.shot('02-trip-home');
    await c.visible(find.text('새 해외여행'));
    await c.shot('03-trip-create');
    await c.enter('trip-title', '');
    await c.tapKey('create-trip');
    await c.visible(find.text('새 해외여행'));
    await c.shot('04-trip-create-error');
  });

  testWidgets('02 공유 코드 입력·오류', (tester) async {
    final c = await open(tester, '/trips?join=true');
    await c.visible(find.text('공유 코드로 참여'));
    await c.shot('05-trip-join');
    await c.enter('share-code', 'BADCODE');
    await c.tapKey('join-trip');
    expect(find.byKey(const Key('trip-action-error')), findsOneWidget);
    await c.visible(find.text('공유 코드로 참여'));
    await c.shot('06-trip-join-error');
  });

  testWidgets('03 일정·지도·편집·빈 일정', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/itinerary');
    await c.shot('07-itinerary-map');
    await c.visible(
      find.byKey(const Key('itinerary-row-${TokyoFixtureIds.arrival}')),
    );
    await c.shot('49-itinerary-list');
    await c.tap(find.byTooltip('지도 확대'));
    await c.shot('08-map-expanded');
    await c.tap(find.byTooltip('지도 접기'));
    await c.tapKey('itinerary-row-${TokyoFixtureIds.arrival}');
    await c.shot('09-itinerary-edit');
    await c.tap(find.text('보관함에서 장소 추가·선택'));
    await c.shot('10-itinerary-place-selection');
    await c.back();
    await c.tap(find.byTooltip('편집 닫기'));
    await c.tapKey('itinerary-add');
    await c.shot('11-itinerary-add');
    await c.tap(find.byTooltip('편집 닫기'));
    await c.tapKey('itinerary-plan-B');
    await c.shot('12-itinerary-plan-b');
    await c.tapKey('itinerary-day-2026-11-27');
    await c.visible(find.byKey(const Key('itinerary-day-empty-2026-11-27')));
    await c.shot('13-itinerary-empty');
  });

  testWidgets('04 장소 검색·링크·직접 입력·편집', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/itinerary');
    await c.tap(find.text('장소 보관함'));
    await c.shot('14-places');
    await c.enter('place-query', '센소지');
    await c.tap(find.byTooltip('검색 실행'));
    expect(find.text('검색 결과 1개'), findsOneWidget);
    await c.shot('15-place-search');
    await c.enter('place-query', '없는검색어');
    await c.tap(find.byTooltip('검색 실행'));
    expect(find.text('검색 결과 0개'), findsOneWidget);
    await c.shot('16-place-search-empty');
    await c.tap(find.text('지도 링크'));
    await c.enter('place-query', 'https://example.com/invalid');
    await c.tap(find.byTooltip('검색 실행'));
    expect(find.text('지원하는 Google Maps URL을 확인해 주세요.'), findsOneWidget);
    await c.shot('17-place-link-error');
    await c.tapKey('place-manual-add');
    await c.enter('place-field-name', '호텔 로비');
    await c.shot('18-place-add');
    await c.tapKey('form-save');
    await c.tapKey('place-${tokyoTripFixture.places.first.id}');
    await c.shot('19-place-edit');
  });

  testWidgets('05 준비·예약·체크리스트', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/preparation');
    await c.shot('20-preparation-empty');
    await c.tapKey('reservation-add');
    await c.enter('preparation-title', '우에노 숙소');
    await c.tap(find.text('항공'));
    await c.tap(find.text('숙소').last);
    await c.enter('reservation-url', 'https://example.com/booking');
    await c.shot('21-reservation-edit');
    await c.tapKey('form-save');
    await c.tapKey('checklist-add');
    await c.enter('preparation-title', '여권과 카드 챙기기');
    await c.shot('22-checklist-edit');
    await c.tapKey('form-save');
    await c.tap(find.byType(Checkbox).first);
    await c.shot('23-preparation-saved');
  });

  testWidgets('06 비용·지출 입력·배분·저장·삭제 확인', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/settlement');
    await c.shot('24-settlement');
    await c.tapKey('expense-add');
    await c.enter('expense-title', '우에노 점심');
    await c.enter('expense-totalAmount', '10000');
    await c.shot('25-expense-entry');
    await c.tapKey('expense-next');
    await c.shot('26-expense-equal');
    await c.tap(find.text('직접 입력'));
    await c.enter('expense-amount-${TokyoFixtureIds.participantMe}', '5000');
    await c.enter(
      'expense-amount-${TokyoFixtureIds.participantFriend1}',
      '3000',
    );
    await c.enter(
      'expense-amount-${TokyoFixtureIds.participantFriend2}',
      '2000',
    );
    await c.shot('27-expense-custom');
    await c.tapKey('expense-save');
    await c.shot('28-expense-detail-saved');
    await c.tapKey('expense-delete');
    await c.shot('29-expense-delete-confirm');
  });

  testWidgets('07 참여자·개인 소비·송금', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/settlement');
    await c.tap(find.text('정산 참여자 관리'));
    await c.shot('30-participants');
    await c.tapKey('participant-add');
    await c.enter('participant-name', '새 동행');
    await c.shot('31-participant-add');
    await c.tapKey('form-save');
    await c.tapKey('participant-${TokyoFixtureIds.participantMe}');
    await c.shot('32-participant-edit');
    await c.back();
    await c.back();
    await c.tap(find.text('개인 소비·정산'));
    await c.shot('33-personal-settlement');
    await c.tap(find.text('KRW · 원'));
    await c.shot('34-personal-empty');
  });

  testWidgets('08 영수증 선택·원문·항목·배분·저장', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/receipts');
    await c.shot('35-receipts');
    await c.tapKey('receipt-sample');
    await c.shot('36-receipt-sample');
    await c.tapKey('receipt-recognize');
    await c.shot('37-receipt-review');
    await c.tap(find.text('원문·번역 확인'));
    await c.shot('38-receipt-translation');
    await c.tap(find.text('원문·번역 확인'));
    await c.visible(find.byKey(const Key('receipt-row-receipt-item-1')));
    await c.tapKey('receipt-row-receipt-item-1');
    await c.shot('39-receipt-item');
    await c.tapKey('form-save');
    await c.visible(find.byKey(const Key('form-save')));
    await c.shot('40-receipt-allocations');
    await c.tapKey('form-save');
    await c.shot('41-receipt-saved');
  });

  testWidgets('09 여행 설정·시트 옵션·두 탭 미리보기', (tester) async {
    final c = await open(tester, '/trips/$tokyoTripId/itinerary');
    await c.tap(find.byTooltip('여행 설정·공유'));
    await c.shot('42-trip-settings');
    await c.tapKey('share-code-regenerate');
    await c.shot('43-share-code-confirm');
    await c.tap(find.text('취소'));
    await c.tap(find.text('시트 내보내기'));
    await c.shot('44-sheet-options');
    await c.tapKey('sheet-preview');
    await c.shot('45-sheet-itinerary');
    await c.tap(find.text('지출·정산'));
    await c.shot('46-sheet-settlement');
  });

  testWidgets('10 없는 여행·없는 경로', (tester) async {
    final c = await open(tester, '/trips/missing/itinerary');
    await c.shot('47-trip-not-found');
    Navigator.of(tester.element(find.byType(Scaffold))).pushNamed('/missing');
    await tester.pumpAndSettle();
    await c.shot('48-route-not-found');
  });
}

class _Capture {
  _Capture(this.tester, this.binding);
  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;

  Future<void> visible(Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await visible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(String key) => tap(find.byKey(ValueKey(key)));

  Future<void> enter(String key, String value) async {
    final finder = find.byKey(ValueKey(key));
    await visible(finder);
    // unfocus한 같은 필드도 실제 탭으로 새 입력 연결을 연다.
    // tester.showKeyboard는 focusedEditable이 같으면 연결을 다시 열지 않는다.
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(finder, value);
    await tester.pump(const Duration(milliseconds: 300));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: finder, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      value,
      reason: '캡처에 표시할 입력값: $key',
    );
  }

  Future<void> back() async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Future<void> shot(String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: name);
    await binding.takeScreenshot(name);
    debugPrint('CAPTURE $name');
  }
}
