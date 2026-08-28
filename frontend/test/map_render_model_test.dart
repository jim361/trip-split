import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/map/map_render_model.dart';

void main() {
  test('도쿄 fixture를 날짜별 번호 pin과 직선 segment로 파생한다', () {
    final model = deriveMapRenderModel(
      places: tokyoTripFixture.places,
      itinerary: tokyoTripFixture.itinerary,
    );

    expect(model.pins.map((pin) => (pin.itineraryItemId, pin.number)), [
      (TokyoFixtureIds.arrival, 1),
      (TokyoFixtureIds.transfer, 2),
      (TokyoFixtureIds.checkIn, 3),
      (TokyoFixtureIds.asakusa, 1),
    ]);
    expect(
      model.segments.map(
        (segment) => (segment.fromItineraryItemId, segment.toItineraryItemId),
      ),
      [
        (TokyoFixtureIds.arrival, TokyoFixtureIds.transfer),
        (TokyoFixtureIds.transfer, TokyoFixtureIds.checkIn),
      ],
    );
    expect(model.pins[0].colorHex, model.pins[2].colorHex);
    expect(model.pins[0].colorHex, isNot(model.pins[3].colorHex));
    expect(model.missingLocations, isEmpty);
    expect(model.emptyState, MapEmptyState.none);
  });

  test('order를 안정적으로 정렬하되 입력 목록은 변경하지 않는다', () {
    final original = [
      _item(id: 'last', placeId: 'last-place', order: 2),
      _item(id: 'first-a', placeId: 'first-a-place', order: 0),
      _item(id: 'first-b', placeId: 'first-b-place', order: 0),
    ];
    final originalIds = original.map((item) => item.id).toList();

    final model = deriveMapRenderModel(
      places: [
        _place(id: 'last-place', lat: 3, lng: 3),
        _place(id: 'first-a-place', lat: 1, lng: 1),
        _place(id: 'first-b-place', lat: 2, lng: 2),
      ],
      itinerary: original,
    );
    final reversedModel = deriveMapRenderModel(
      places: [
        _place(id: 'last-place', lat: 3, lng: 3),
        _place(id: 'first-a-place', lat: 1, lng: 1),
        _place(id: 'first-b-place', lat: 2, lng: 2),
      ],
      itinerary: original.reversed.toList(),
    );

    expect(original.map((item) => item.id), originalIds);
    expect(model.pins.map((pin) => (pin.itineraryItemId, pin.number)), [
      ('first-a', 1),
      ('first-b', 2),
      ('last', 3),
    ]);
    expect(model.segments, hasLength(2));
    expect(
      reversedModel.pins.map((pin) => pin.itineraryItemId),
      model.pins.map((pin) => pin.itineraryItemId),
    );
  });

  test('좌표 누락 사유와 빈 상태를 파생한다', () {
    final model = deriveMapRenderModel(
      places: [_place(id: 'coordinates-missing')],
      itinerary: [
        _item(id: 'unlinked', order: 0),
        _item(id: 'not-found', placeId: 'unknown', order: 1),
        _item(
          id: 'coordinates-missing-item',
          placeId: 'coordinates-missing',
          order: 2,
        ),
      ],
    );

    expect(model.pins, isEmpty);
    expect(model.segments, isEmpty);
    expect(model.missingLocations.map((missing) => missing.reason), [
      MissingMapLocationReason.placeNotLinked,
      MissingMapLocationReason.placeNotFound,
      MissingMapLocationReason.coordinatesMissing,
    ]);
    expect(model.missingLocations.map((missing) => missing.number), [1, 2, 3]);
    expect(model.emptyState, MapEmptyState.noMappableItems);
    expect(
      deriveMapRenderModel(places: const [], itinerary: const []).emptyState,
      MapEmptyState.noItinerary,
    );
  });

  test('좌표 없는 일정의 번호를 유지하고 지도에 찍을 수 있는 지점을 연결한다', () {
    final model = deriveMapRenderModel(
      places: [
        _place(id: 'first-place', lat: 35, lng: 139),
        _place(id: 'missing-place'),
        _place(id: 'third-place', lat: 36, lng: 140),
      ],
      itinerary: [
        _item(id: 'first', placeId: 'first-place', order: 0),
        _item(id: 'missing', placeId: 'missing-place', order: 1),
        _item(id: 'third', placeId: 'third-place', order: 2),
      ],
    );

    expect(model.pins.map((pin) => pin.number), [1, 3]);
    expect(model.missingLocations.single.number, 2);
    expect(model.segments, hasLength(1));
    expect(model.segments.single.fromItineraryItemId, 'first');
    expect(model.segments.single.toItineraryItemId, 'third');
  });
}

ItineraryItem _item({
  required String id,
  String? placeId,
  required int order,
}) => ItineraryItem(
  id: id,
  tripId: 'trip',
  date: '2026-11-25',
  title: id,
  order: order,
  placeId: placeId,
  updatedAt: 0,
);

Place _place({required String id, double? lat, double? lng}) => Place(
  id: id,
  tripId: 'trip',
  name: id,
  provider: 'manual',
  source: 'manual',
  lat: lat,
  lng: lng,
  addedBy: 'test-user',
  createdAt: 0,
  updatedAt: 0,
);
