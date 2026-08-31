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
      PlaceDraft(
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

  test('일정 생성·수정과 구독에 B안과 유형을 보존한다', () async {
    final repositories = InMemoryTripRepositories();
    addTearDown(repositories.close);
    final created = await repositories.createItineraryItem(
      tokyoTripId,
      ItineraryItemDraft(
        date: '2026-11-25',
        title: '비 오는 날 점심',
        order: 0,
        planId: 'B',
        category: 'meal',
      ),
    );
    expect(created.planId, 'B');
    expect(created.category, 'meal');
    await repositories.updateItineraryItem(
      tokyoTripId,
      created.id,
      ItineraryItemDraft(
        date: created.date,
        title: '실내 전시 관람',
        order: 0,
        planId: created.planId,
        category: 'activity',
      ),
    );
    final saved = (await repositories.watchItinerary(tokyoTripId).first)
        .singleWhere((item) => item.id == created.id);
    expect(saved.planId, 'B');
    expect(saved.category, 'activity');
    expect(saved.id, created.id);
  });

  test('정산 참여자 제외는 문서를 삭제하지 않고 비활성화한다', () async {
    final repositories = InMemoryTripRepositories(now: () => 5678);
    addTearDown(repositories.close);

    await repositories.deactivateParticipant(
      tokyoTripId,
      TokyoFixtureIds.participantFriend1,
    );
    final participants = await repositories
        .watchParticipants(tokyoTripId)
        .first;
    final participant = participants.singleWhere(
      (value) => value.id == TokyoFixtureIds.participantFriend1,
    );

    expect(participants, hasLength(3));
    expect(participant.isActive, isFalse);
    expect(participant.updatedAt, 5678);
  });
}
