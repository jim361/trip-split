import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/itinerary/itinerary_editor.dart';

void main() {
  test('도쿄 fixture의 날짜와 시간을 검증하고 날짜별 order를 유지한다', () {
    for (final item in tokyoTripFixture.itinerary) {
      final draft = validateItineraryItemDraft(
        ItineraryItemDraft(
          date: item.date,
          title: item.title,
          order: item.order,
          startTime: item.startTime,
          endTime: item.endTime,
          placeId: item.placeId,
          memo: item.memo,
        ),
      );
      expect(draft.date, item.date);
      expect(draft.startTime, item.startTime);
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
    final draft = validateItineraryItemDraft(
      const ItineraryItemDraft(
        date: ' 2026-11-25 ',
        title: ' 나리타 도착 ',
        order: 0,
        startTime: ' 09:05 ',
        endTime: '',
        placeId: ' ',
      ),
    );

    expect(draft.date, '2026-11-25');
    expect(draft.title, '나리타 도착');
    expect(draft.startTime, '09:05');
    expect(draft.endTime, isNull);
    expect(draft.placeId, isNull);
  });

  test('잘못된 날짜, 제목, order와 시간 형식을 거부한다', () {
    for (final date in ['2026/11/25', '2026-02-29', '2026-13-01']) {
      _expectInvalid(_draft(date: date), 'date');
    }
    _expectInvalid(_draft(title: '   '), 'title');
    _expectInvalid(_draft(order: -1), 'order');
    for (final time in ['9:30', '24:00', '12:60']) {
      _expectInvalid(_draft(startTime: time), 'startTime');
    }
    _expectInvalid(_draft(endTime: '18시'), 'endTime');
  });
}

void _expectInvalid(ItineraryItemDraft draft, String field) {
  expect(
    () => validateItineraryItemDraft(draft),
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
  String? startTime,
  String? endTime,
}) => ItineraryItemDraft(
  date: date,
  title: title,
  order: order,
  startTime: startTime,
  endTime: endTime,
);

ItineraryItem _item({
  required String id,
  required LocalDate date,
  required int order,
}) => ItineraryItem(
  id: id,
  tripId: 'trip',
  date: date,
  title: id,
  order: order,
  updatedAt: 0,
);
