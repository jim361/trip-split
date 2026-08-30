import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

void main() {
  testWidgets('계정 없이 시작해 도쿄 여행과 시간표를 선택한다', (tester) async {
    _usePhoneSize(tester);
    final repositories = InMemoryTripRepositories();
    final authService = MockAuthService();
    addTearDown(repositories.close);
    addTearDown(authService.dispose);

    await _pumpApp(tester, repositories, authService);

    expect(find.text('Google로 계속'), findsOneWidget);
    expect(find.text('계정 없이 시작'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('account-continue-google'))).height,
      greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
    );

    await tester.tap(find.byKey(const Key('account-continue-guest')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('trip-account-action'))).shortestSide,
      greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
    );
    expect(find.byTooltip('Google 계정 연결'), findsOneWidget);
    expect(find.bySemanticsLabel('메뉴'), findsOneWidget);
    expect(find.byKey(ValueKey('trip-tile-$tokyoTripId')), findsOneWidget);
    expect(
      find.byKey(ValueKey('timetable-item-${TokyoFixtureIds.arrival}')),
      findsOneWidget,
    );
    expect(find.text('나리타 공항 도착'), findsOneWidget);

    await tester.tap(find.byKey(const Key('featured-trip-open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trip-mobile-navigation')), findsOneWidget);
    expect(find.byTooltip('공유 코드 TKY26JP 복사'), findsOneWidget);
  });

  testWidgets('Google 시작 뒤 도쿄 기본값으로 여행을 만든다', (tester) async {
    _usePhoneSize(tester);
    final repositories = InMemoryTripRepositories();
    final authService = MockAuthService();
    addTearDown(repositories.close);
    addTearDown(authService.dispose);

    await _pumpApp(tester, repositories, authService);
    await tester.tap(find.byKey(const Key('account-continue-google')));
    await tester.pumpAndSettle();

    final linkedUser = await authService.ensureAnonymousSession();
    expect(linkedUser.isAnonymous, isFalse);
    expect(linkedUser.displayName, '나 (Google 연결)');

    await tester.dragUntilVisible(
      find.byKey(const Key('create-trip')),
      find.byKey(const Key('trip-home-compact')),
      const Offset(0, -600),
    );
    await tester.ensureVisible(find.byKey(const Key('create-trip')));
    await tester.pumpAndSettle();
    expect(find.text('일본 · Asia/Tokyo · JPY · Google Maps'), findsOneWidget);
    expect(find.byKey(const Key('participant-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-trip')));
    await tester.pumpAndSettle();

    expect(find.text('01 / ITINERARY MAP'), findsOneWidget);
    expect(find.byKey(const Key('trip-mobile-navigation')), findsOneWidget);
    expect(find.byTooltip('공유 코드 TEST2222 복사'), findsOneWidget);
  });

  testWidgets('공유 코드로 목업 여행에 참여한다', (tester) async {
    _usePhoneSize(tester);
    final repositories = InMemoryTripRepositories();
    final authService = MockAuthService();
    addTearDown(repositories.close);
    addTearDown(authService.dispose);

    await _pumpApp(tester, repositories, authService);
    await tester.tap(find.byKey(const Key('account-continue-share')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('share-code')), 'tky26jp');
    await tester.ensureVisible(find.byKey(const Key('join-trip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('join-trip')));
    await tester.pumpAndSettle();

    expect(find.text('01 / ITINERARY MAP'), findsOneWidget);
    expect(find.byKey(const Key('trip-mobile-navigation')), findsOneWidget);
    expect(find.byTooltip('공유 코드 TKY26JP 복사'), findsOneWidget);
    expect(find.text('나리타 공항 도착'), findsOneWidget);
  });

  testWidgets('390px 200% 글자 크기에서 계정 시작과 여행 선택이 overflow하지 않는다', (
    tester,
  ) async {
    _usePhoneSize(tester, textScaleFactor: 2);
    final repositories = InMemoryTripRepositories();
    final authService = MockAuthService();
    addTearDown(repositories.close);
    addTearDown(authService.dispose);

    await _pumpApp(tester, repositories, authService);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('account-continue-guest')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('trip-home-compact')), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  InMemoryTripRepositories repositories,
  MockAuthService authService,
) async {
  await tester.pumpWidget(
    TripSplitApp(
      repositories: repositories,
      authService: authService,
      tripShareService: MockTripShareService(repositories),
      dataSourceLabel: 'mock',
    ),
  );
  await tester.pumpAndSettle();
}

void _usePhoneSize(WidgetTester tester, {double textScaleFactor = 1}) {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
