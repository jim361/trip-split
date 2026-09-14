import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/trip_session.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';

void main() {
  test('구독 오류는 해당 데이터가 복구돼야 해제하고 재시도 구독은 중복하지 않는다', () async {
    final repo = _Repositories();
    final session = TripSessionController(
      tripId: tokyoTripId,
      repositories: repo,
    )..start();
    addTearDown(() async {
      session.dispose();
      await repo.inner.close();
      await repo.places.close();
    });
    await Future<void>.delayed(Duration.zero);
    repo.places.addError(
      const AppError(
        code: AppErrorCode.unavailable,
        message: '장소 오류',
        retryable: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.error?.message, '장소 오류');
    await repo.inner.updateTrip(
      tokyoTripId,
      TripUpdate(title: '새 이름', startDate: '2026-11-25', endDate: '2026-11-27'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.error?.message, '장소 오류');
    repo.places.add(tokyoTripFixture.places);
    await Future<void>.delayed(Duration.zero);
    expect(session.error, isNull);
    expect(session.isLoading, isFalse);
    session.start();
    expect(repo.listens, 1);
    await session.retry();
    expect(repo.listens, 2);
    expect(session.isLoading, isTrue);
    repo.places.add(tokyoTripFixture.places);
    await Future<void>.delayed(Duration.zero);
    expect(session.isLoading, isFalse);
  });
}

class _Repositories implements TripRepositories {
  final inner = InMemoryTripRepositories();
  final places = StreamController<List<Place>>.broadcast();
  int listens = 0;
  @override
  Stream<List<Place>> watchPlaces(String id) {
    listens++;
    return places.stream;
  }

  @override
  Stream<Trip?> watchTrip(String id) => inner.watchTrip(id);
  @override
  Stream<List<TripMember>> watchMembers(String id) => inner.watchMembers(id);
  @override
  Stream<List<Participant>> watchParticipants(String id) =>
      inner.watchParticipants(id);
  @override
  Stream<List<ItineraryItem>> watchItinerary(String id) =>
      inner.watchItinerary(id);
  @override
  Stream<List<Expense>> watchExpenses(String id) => inner.watchExpenses(id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
