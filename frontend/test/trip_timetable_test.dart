import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/itinerary/trip_timetable.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

void main() {
  testWidgets('compact 폭에서 전체 날짜를 유지하면서 미리보기 높이를 제한한다', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await _pumpTimetable(tester, tokyoTripFixture.itinerary);

    final gridSize = tester.getSize(
      find.byKey(const Key('trip-timetable-grid')),
    );
    expect(gridSize.width, greaterThan(390));
    expect(gridSize.height, lessThanOrEqualTo(260));
    expect(
      find.byKey(const ValueKey('timetable-day-2026-11-25')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timetable-day-2026-12-01')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(ValueKey('timetable-item-${TokyoFixtureIds.asakusa}')),
          )
          .height,
      greaterThan(
        tester
            .getSize(
              find.byKey(ValueKey('timetable-item-${TokyoFixtureIds.arrival}')),
            )
            .height,
      ),
    );
  });

  testWidgets('종료 시간이 없으면 60분으로 표시하고 시간 없는 일정은 분리한다', (tester) async {
    final withoutEnd = ItineraryItem(
      id: 'without-end',
      tripId: tokyoTripId,
      date: '2026-11-25',
      startTime: '12:00',
      title: '종료 시간 없는 일정',
      order: 0,
      updatedAt: 0,
    );
    final withoutTime = ItineraryItem(
      id: 'without-time',
      tripId: tokyoTripId,
      date: '2026-11-25',
      title: '시간 미정 일정',
      order: 1,
      updatedAt: 0,
    );

    await _pumpTimetable(tester, [withoutEnd, withoutTime]);

    expect(
      find.byKey(const ValueKey('timetable-item-without-end')),
      findsOneWidget,
    );
    expect(find.text('시간 미정'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timetable-unscheduled-without-time')),
      findsOneWidget,
    );
  });

  testWidgets('일정 블록을 날짜, 수동 순서, ID 순으로 그린다', (tester) async {
    final itinerary = [
      _item(id: 'z', date: '2026-11-26', order: 0, startTime: '07:00'),
      _item(id: 'c', date: '2026-11-25', order: 1, startTime: '08:00'),
      _item(id: 'b', date: '2026-11-25', order: 0, startTime: '09:00'),
      _item(id: 'a', date: '2026-11-25', order: 0, startTime: '18:00'),
    ];

    await _pumpTimetable(tester, itinerary);

    final titles = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .where((text) => text?.startsWith('일정 ') ?? false)
        .toList();
    expect(titles, ['일정 a', '일정 b', '일정 c', '일정 z']);
  });

  testWidgets('작은 요약에서 A/B안을 전환하고 선택한 계획만 표시한다', (tester) async {
    final alternate = ItineraryItem(
      id: 'alternate',
      tripId: tokyoTripId,
      date: '2026-11-25',
      startTime: '10:00',
      endTime: '11:00',
      title: '실내 전시 관람',
      planId: 'B',
      category: 'activity',
      order: 0,
      updatedAt: 0,
    );
    await _pumpTimetable(tester, [...tokyoTripFixture.itinerary, alternate]);
    expect(find.text(alternate.title), findsNothing);
    await tester.tap(find.byKey(const ValueKey('itinerary-plan-B')));
    await tester.pumpAndSettle();
    expect(find.text(alternate.title), findsOneWidget);
    expect(find.text('나리타 공항 도착'), findsNothing);
    expect(find.text('관광·활동 · 10:00'), findsOneWidget);
    final block = tester.widget<Container>(
      find.byKey(const ValueKey('timetable-item-alternate')),
    );
    expect((block.decoration! as BoxDecoration).color, const Color(0xFFBFD2B0));
  });
}

ItineraryItem _item({
  required String id,
  required String date,
  required int order,
  required String startTime,
}) => ItineraryItem(
  id: id,
  tripId: tokyoTripId,
  date: date,
  startTime: startTime,
  title: '일정 $id',
  order: order,
  updatedAt: 0,
);

Future<void> _pumpTimetable(
  WidgetTester tester,
  List<ItineraryItem> itinerary,
) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: TripTimetable(trip: tokyoTripFixture.trip, itinerary: itinerary),
      ),
    ),
  ),
);
