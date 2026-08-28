import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';

void main() {
  test('도쿄 fixture가 Android 첫 검증 계약을 고정한다', () {
    final trip = tokyoTripFixture.trip;

    expect(trip.id, 'tokyo-2026-11');
    expect(trip.countryCode, 'JP');
    expect(trip.timeZone, 'Asia/Tokyo');
    expect(trip.mapProvider, 'google');
    expect(trip.defaultCurrency, 'JPY');
    expect(tokyoTripFixture.participants, hasLength(3));
    expect(tokyoTripFixture.expenses.single.totalAmount, 4500);
  });

  test('mock 장소 저장소가 현재값과 변경값을 같은 stream으로 보낸다', () async {
    final repositories = InMemoryTripRepositories(now: () => 1234);
    addTearDown(repositories.close);
    final places = StreamIterator(repositories.watchPlaces(tokyoTripId));
    addTearDown(places.cancel);

    expect(await places.moveNext(), isTrue);
    expect(places.current, hasLength(4));

    final nextUpdate = places.moveNext();
    await Future<void>.delayed(Duration.zero);
    final created = await repositories.createPlace(
      tokyoTripId,
      const PlaceDraft(
        name: '도쿄역',
        provider: 'google',
        source: 'googleSearch',
        lat: 35.6812,
        lng: 139.7671,
      ),
    );

    expect(created.id, 'mock-place-1');
    expect(created.addedBy, tokyoOwnerUid);
    expect(created.createdAt, 1234);
    expect(await nextUpdate, isTrue);
    expect(places.current.map((place) => place.id), contains(created.id));
  });

  test('다른 여행 ID의 entity 수정은 AppError로 거부한다', () async {
    final repositories = InMemoryTripRepositories();
    addTearDown(repositories.close);

    await expectLater(
      repositories.deletePlace('another-trip', TokyoFixtureIds.narita),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.notFound,
        ),
      ),
    );
  });
}
