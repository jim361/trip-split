import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/itinerary/itinerary_page.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

void main() {
  testWidgets('계획 전환은 날짜를 유지하며 목록과 지도에서 다른 안을 제외한다', (tester) async {
    const alternate = ItineraryItem(
      id: 'alternate',
      tripId: tokyoTripId,
      date: '2026-11-25',
      startTime: '10:00',
      title: 'B안 우에노 점심',
      placeId: TokyoFixtureIds.ueno,
      planId: 'B',
      category: 'meal',
      order: 0,
      updatedAt: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ItineraryPage(
            trip: tokyoTripFixture.trip,
            places: tokyoTripFixture.places,
            itinerary: [...tokyoTripFixture.itinerary, alternate],
            selectedDate: '2026-11-25',
            mapExpanded: false,
            onToggleMap: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('map-pin-alternate')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('itinerary-plan-B')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-pin-alternate')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('itinerary-row-alternate')),
      findsOneWidget,
    );
    expect(find.text('식사'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.arrival}')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('itinerary-row-${TokyoFixtureIds.arrival}')),
      findsNothing,
    );
    expect(find.text('01 / ITINERARY MAP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
