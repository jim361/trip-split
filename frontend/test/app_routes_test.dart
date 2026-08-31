import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/app/router.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

void main() {
  test('기본·호환 경로를 canonical 여행 위치로 해석한다', () {
    expect(TripLocation.tryParse('/')?.tripId, tokyoTripId);

    final legacyMap = TripLocation.tryParse('/trips/$tokyoTripId/map');
    expect(legacyMap?.destination, TripDestination.itinerary);
    expect(legacyMap?.mapExpanded, isTrue);
    expect(
      legacyMap?.canonicalPath,
      '/trips/$tokyoTripId/itinerary?map=expanded',
    );
    final selectedDay = TripLocation.tryParse(
      '/trips/$tokyoTripId/itinerary?map=expanded&day=2026-11-26',
    );
    expect(selectedDay?.selectedDate, '2026-11-26');
    expect(
      selectedDay?.canonicalPath,
      '/trips/$tokyoTripId/itinerary?map=expanded&day=2026-11-26',
    );
    expect(TripLocation.tryParse('/unknown'), isNull);
  });

  testWidgets('390px에서 세 탭과 영수증 하위 화면을 이동한다', (tester) async {
    await _pumpRoute(
      tester,
      size: const Size(390, 844),
      initialRoute: '/trips/$tokyoTripId/itinerary',
    );

    expect(find.text('01 / ITINERARY MAP'), findsOneWidget);
    expect(find.byKey(const Key('trip-mobile-navigation')), findsOneWidget);
    expect(find.text('일정·지도'), findsOneWidget);
    expect(find.text('준비'), findsOneWidget);
    expect(find.text('비용'), findsOneWidget);
    expect(find.text('나리타 공항 도착'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('itinerary-row-${TokyoFixtureIds.arrival}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.arrival}')),
      findsOneWidget,
    );
    expect(find.text('Google 지도 연동 예정 · 동선 2구간'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('여행 선택')).shortestSide,
      greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
    );
    expect(
      tester.getSize(find.byTooltip('공유 코드 TKY26JP 복사')).shortestSide,
      greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
    );
    expect(
      tester.getSize(find.byTooltip('지도 확대')).shortestSide,
      greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('itinerary-day-2026-11-25')))
          .height,
      greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
    );
    final selectedDestination = tester.getSemantics(
      find
          .ancestor(of: find.text('일정·지도'), matching: find.byType(Semantics))
          .first,
    );
    expect(
      selectedDestination,
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel(RegExp('Google 지도 자리')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('itinerary-day-2026-11-26')));
    await tester.pumpAndSettle();
    expect(find.text('아사쿠사 산책'), findsOneWidget);
    expect(find.text('나리타 공항 도착'), findsNothing);
    expect(
      find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.asakusa}')),
      findsOneWidget,
    );
    expect(find.text('Google 지도 연동 예정 · 동선 0구간'), findsOneWidget);

    await tester.tap(find.byTooltip('지도 확대'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('지도 접기'), findsOneWidget);
    expect(find.text('아사쿠사 산책'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('itinerary-day-2026-11-27')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('itinerary-day-empty-2026-11-27')),
      findsOneWidget,
    );

    await tester.tap(find.text('준비'));
    await tester.pumpAndSettle();
    expect(find.text('여행 준비'), findsOneWidget);

    await tester.tap(find.text('비용'));
    await tester.pumpAndSettle();
    expect(find.text('여행 비용'), findsOneWidget);

    await tester.tap(find.text('영수증으로 등록'));
    await tester.pumpAndSettle();
    expect(find.text('영수증 검토'), findsOneWidget);
  });

  testWidgets('/map 호환 경로는 확대된 지도 상태를 연다', (tester) async {
    await _pumpRoute(
      tester,
      size: const Size(390, 844),
      initialRoute: '/trips/$tokyoTripId/map',
    );

    expect(find.byTooltip('지도 접기'), findsOneWidget);
  });

  testWidgets('800px에서 축약 rail로 전환한다', (tester) async {
    await _pumpRoute(
      tester,
      size: const Size(800, 1000),
      initialRoute: '/trips/$tokyoTripId/itinerary',
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(find.byKey(const Key('trip-shell-medium')), findsOneWidget);
    expect(find.byKey(const Key('trip-mobile-navigation')), findsNothing);
    expect(find.byKey(const Key('itinerary-compact-layout')), findsOneWidget);
  });

  testWidgets('1440px에서 같은 여행 셸을 확장 rail과 두 열로 재배치한다', (tester) async {
    await _pumpRoute(
      tester,
      size: const Size(1440, 1000),
      initialRoute: '/trips/$tokyoTripId/itinerary',
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.byKey(const Key('trip-mobile-navigation')), findsNothing);
    expect(find.byKey(const Key('trip-shell-expanded')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-expanded-layout')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('itinerary-day-2026-11-25')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('itinerary-row-${TokyoFixtureIds.arrival}')),
      findsOneWidget,
    );
  });

  testWidgets('390px 200% 글자 크기에서 세 주요 탭이 overflow하지 않는다', (tester) async {
    await _pumpRoute(
      tester,
      size: const Size(390, 844),
      initialRoute: '/trips/$tokyoTripId/itinerary',
      textScaleFactor: 2,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('준비'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('비용'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRoute(
  WidgetTester tester, {
  required Size size,
  required String initialRoute,
  double textScaleFactor = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  final repositories = InMemoryTripRepositories();
  final authService = MockAuthService();
  addTearDown(repositories.close);
  addTearDown(authService.dispose);
  await tester.pumpWidget(
    TripSplitApp(
      repositories: repositories,
      authService: authService,
      tripShareService: MockTripShareService(repositories),
      dataSourceLabel: 'mock',
      initialRoute: initialRoute,
    ),
  );
  await tester.pumpAndSettle();
}
