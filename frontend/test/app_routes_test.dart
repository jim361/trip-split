import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/app/router.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';

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
    expect(TripLocation.tryParse('/unknown'), isNull);
  });

  testWidgets('390px에서 세 탭과 영수증 하위 화면을 이동한다', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
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
        initialRoute: '/trips/$tokyoTripId/itinerary',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 11월 도쿄 여행'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('일정·지도'), findsOneWidget);
    expect(find.text('준비'), findsOneWidget);
    expect(find.text('비용'), findsOneWidget);
    expect(find.text('나리타 공항 도착'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.arrival}')),
      findsOneWidget,
    );
    expect(find.text('Google 지도 연동 예정 · 동선 2구간'), findsOneWidget);

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
        initialRoute: '/trips/$tokyoTripId/map',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지도 접기'), findsOneWidget);
  });
}
