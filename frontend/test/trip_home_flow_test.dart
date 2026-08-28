import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';

void main() {
  testWidgets('익명 uid를 표시하고 도쿄 기본값으로 여행을 만든다', (tester) async {
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('uid '), findsOneWidget);
    expect(find.text('일본 · Asia/Tokyo · JPY · Google Maps'), findsOneWidget);
    expect(find.byKey(const Key('participant-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('link-google')));
    await tester.pumpAndSettle();
    expect(find.text('Google 연결됨'), findsOneWidget);
    expect(find.text('uid tokyo-owner'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-trip')));
    await tester.pumpAndSettle();

    expect(find.text('2026년 11월 도쿄 여행'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('TEST2222'), findsOneWidget);
  });

  testWidgets('공유 코드로 목업 여행에 참여한다', (tester) async {
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('share-code')), 'tky26jp');
    await tester.tap(find.byKey(const Key('join-trip')));
    await tester.pumpAndSettle();

    expect(find.text('2026년 11월 도쿄 여행'), findsWidgets);
    expect(find.text('나리타 공항 도착'), findsOneWidget);
  });
}
