import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/itinerary/itinerary_editor.dart';

void main() {
  test('도쿄 fixture의 날짜와 시간을 검증하고 날짜별 order를 유지한다', () {
    for (final item in tokyoTripFixture.itinerary) {
      final draft = ItineraryItemDraft(
        date: item.date,
        title: item.title,
        order: item.order,
        planId: item.planId,
        category: item.category,
        startTime: item.startTime,
        endTime: item.endTime,
        placeId: item.placeId,
        memo: item.memo,
      );
      expect(draft.date, item.date);
      expect(draft.startTime, item.startTime);
      expect(draft.category, item.category);
    }

    final normalized = normalizeItineraryOrders(
      tokyoTripFixture.itinerary.reversed.toList(),
    );
    expect(normalized.map((item) => item.id), [
      TokyoFixtureIds.arrival,
      TokyoFixtureIds.transfer,
      TokyoFixtureIds.checkIn,
      TokyoFixtureIds.asakusa,
    ]);
    expect(normalized.map((item) => item.order), [0, 1, 2, 0]);
  });

  test('입력을 바꾸지 않고 동률 order를 ID로 결정해 날짜별 0부터 정규화한다', () {
    final input = [
      _item(id: 'day-two', date: '2026-11-26', order: 8),
      _item(id: 'b', date: '2026-11-25', order: 9),
      _item(id: 'a', date: '2026-11-25', order: 9),
      _item(id: 'c', date: '2026-11-25', order: 20),
    ];
    final originalIds = input.map((item) => item.id).toList();
    final originalOrders = input.map((item) => item.order).toList();

    final normalized = normalizeItineraryOrders(input);
    final reversed = normalizeItineraryOrders(input.reversed.toList());

    expect(input.map((item) => item.id), originalIds);
    expect(input.map((item) => item.order), originalOrders);
    expect(normalized.map((item) => item.id), ['a', 'b', 'c', 'day-two']);
    expect(normalized.map((item) => item.order), [0, 1, 2, 0]);
    expect(reversed.map((item) => item.id), normalized.map((item) => item.id));
  });

  test('선택 입력을 정리하고 placeId가 없는 일정을 허용한다', () {
    final draft = ItineraryItemDraft(
      date: ' 2026-11-25 ',
      title: ' 나리타 도착 ',
      order: 0,
      startTime: ' 09:05 ',
      endTime: '',
      placeId: ' ',
    );

    expect(draft.date, '2026-11-25');
    expect(draft.title, '나리타 도착');
    expect(draft.startTime, '09:05');
    expect(draft.endTime, isNull);
    expect(draft.placeId, isNull);
    expect(draft.planId, 'A');
    expect(draft.category, 'other');
  });

  test('A/B안 날짜별 순서를 독립적으로 정규화하고 유형을 보존한다', () {
    final normalized = normalizeItineraryOrders([
      _item(id: 'b2', date: '2026-11-25', order: 8, planId: 'B'),
      _item(id: 'a1', date: '2026-11-25', order: 4, category: 'flight'),
      _item(
        id: 'b1',
        date: '2026-11-25',
        order: 2,
        planId: 'B',
        category: 'meal',
      ),
    ]);
    expect(normalized.map((item) => item.id), ['a1', 'b1', 'b2']);
    expect(normalized.map((item) => item.order), [0, 0, 1]);
    expect(normalized.map((item) => item.planId), ['A', 'B', 'B']);
    expect(normalized.map((item) => item.category), [
      'flight',
      'meal',
      'other',
    ]);
  });

  test('허용되지 않은 계획과 유형을 거부한다', () {
    _expectInvalid(() => _draft(planId: 'C'), 'planId');
    _expectInvalid(() => _draft(category: 'food'), 'category');
  });

  test('잘못된 날짜, 제목, order와 시간 형식을 거부한다', () {
    for (final date in ['2026/11/25', '2026-02-29', '2026-13-01']) {
      _expectInvalid(() => _draft(date: date), 'date');
    }
    _expectInvalid(() => _draft(title: '   '), 'title');
    _expectInvalid(() => _draft(title: List.filled(161, '가').join()), 'title');
    _expectInvalid(() => _draft(order: -1), 'order');
    for (final time in ['9:30', '24:00', '12:60']) {
      _expectInvalid(() => _draft(startTime: time), 'startTime');
    }
    _expectInvalid(() => _draft(endTime: '18시'), 'endTime');
  });
}

void _expectInvalid(void Function() callback, String field) {
  expect(
    callback,
    throwsA(
      isA<AppError>()
          .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
          .having((error) => error.field, 'field', field),
    ),
  );
}

ItineraryItemDraft _draft({
  String date = '2026-11-25',
  String title = '일정',
  int order = 0,
  String planId = 'A',
  String category = 'other',
  String? startTime,
  String? endTime,
}) => ItineraryItemDraft(
  date: date,
  title: title,
  order: order,
  planId: planId,
  category: category,
  startTime: startTime,
  endTime: endTime,
);

ItineraryItem _item({
  required String id,
  required LocalDate date,
  required int order,
  String planId = 'A',
  String category = 'other',
}) => ItineraryItem(
  id: id,
  tripId: 'trip',
  date: date,
  title: id,
  order: order,
  planId: planId,
  category: category,
  updatedAt: 0,
);
