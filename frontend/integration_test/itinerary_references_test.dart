import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trip_split/data/firebase/firebase_client.dart';
import 'package:trip_split/data/firebase/firestore_trip_repositories.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/preparation.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/platform/app_config.dart';
import 'package:trip_split/services/trip_share_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('참조 저장·해제·삭제 거부와 경합 최종 상태', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.useFirebaseEmulators, isTrue);
    final client = await FirebaseClient.initialize(config);
    await client.auth.signInAnonymously();
    final repositories = FirestoreTripRepositories(
      client.firestore,
      currentUid: () => client.auth.currentUser?.uid ?? '',
      functions: client.functions,
    );
    final trip = await FirebaseTripShareService(client.functions).createTrip(
      CreateTripCommand(
        title: '참조 검증 ${DateTime.now().microsecondsSinceEpoch}',
        countryCode: 'JP',
        timeZone: 'Asia/Tokyo',
        mapProvider: 'google',
        defaultCurrency: 'JPY',
        startDate: '2026-11-25',
        endDate: '2026-11-26',
        participantNames: const ['테스터'],
      ),
    );
    final place = await repositories.createPlace(
      trip.tripId,
      PlaceDraft(name: '연결할 장소', provider: 'manual', source: 'manual'),
    );
    final linked = await repositories.createItineraryItem(
      trip.tripId,
      _itinerary('연결 일정', placeId: place.id),
    );
    expect(await _referenceVersion(client.firestore, trip.tripId), 1);
    await expectLater(
      repositories.deletePlace(trip.tripId, place.id),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.conflict)
            .having((error) => error.field, 'field', 'placeId'),
      ),
    );
    await repositories.updateItineraryItem(
      trip.tripId,
      linked.id,
      _itinerary('연결 해제 일정'),
    );
    expect(await _referenceVersion(client.firestore, trip.tripId), 2);
    await repositories.deletePlace(trip.tripId, place.id);
    expect(await _referenceVersion(client.firestore, trip.tripId), 3);

    final reservable = await repositories.createItineraryItem(
      trip.tripId,
      _itinerary('예약 연결 일정'),
    );
    final reservationId = await repositories.saveReservation(
      trip.tripId,
      ReservationDraft(
        title: '예약',
        type: 'stay',
        status: 'planned',
        itineraryItemId: reservable.id,
      ),
    );
    expect(await _referenceVersion(client.firestore, trip.tripId), 4);
    await expectLater(
      repositories.deleteItineraryItem(trip.tripId, reservable.id),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.conflict)
            .having((error) => error.field, 'field', 'itineraryItemId'),
      ),
    );
    await repositories.deleteReservation(trip.tripId, reservationId);
    expect(await _referenceVersion(client.firestore, trip.tripId), 5);
    await repositories.deleteItineraryItem(trip.tripId, reservable.id);
    expect(await _referenceVersion(client.firestore, trip.tripId), 6);
    await expectLater(
      repositories.reorderItineraryItems(
        trip.tripId,
        ItineraryOrderDraft(
          date: '2026-11-25',
          planId: 'A',
          itemIds: [reservable.id],
        ),
      ),
      throwsA(isA<AppError>().having((error) => error.code, 'code', AppErrorCode.notFound)),
    );

    final racedPlace = await repositories.createPlace(
      trip.tripId,
      PlaceDraft(name: '경합 장소', provider: 'manual', source: 'manual'),
    );
    final outcomes = await Future.wait([
      _outcome(
        () => repositories.createItineraryItem(
          trip.tripId,
          _itinerary('경합 일정', placeId: racedPlace.id),
        ),
      ),
      _outcome(() => repositories.deletePlace(trip.tripId, racedPlace.id)),
    ]);
    expect(outcomes.where((outcome) => outcome == null), hasLength(1));
    final failure = outcomes.singleWhere((outcome) => outcome != null)!;
    expect(
      failure,
      isA<AppError>().having(
        (error) => error.code,
        'code',
        anyOf(
          AppErrorCode.conflict,
          AppErrorCode.notFound,
          AppErrorCode.permissionDenied,
        ),
      ),
    );
    final racedPlaceSnapshot = await client.firestore
        .doc('trips/${trip.tripId}/places/${racedPlace.id}')
        .get(const GetOptions(source: Source.server));
    final linkedRaces = await client.firestore
        .collection('trips/${trip.tripId}/itinerary')
        .where('placeId', isEqualTo: racedPlace.id)
        .get(const GetOptions(source: Source.server));
    if (racedPlaceSnapshot.exists) {
      expect(linkedRaces.docs, hasLength(1));
    } else {
      expect(linkedRaces.docs, isEmpty);
    }
    expect(await _referenceVersion(client.firestore, trip.tripId), 7);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

ItineraryItemDraft _itinerary(String title, {String? placeId}) =>
    ItineraryItemDraft(
      date: '2026-11-25',
      title: title,
      order: 0,
      placeId: placeId,
    );

Future<int> _referenceVersion(FirebaseFirestore firestore, String tripId) async {
  final trip = await firestore
      .doc('trips/$tripId')
      .get(const GetOptions(source: Source.server));
  return trip.data()!['referenceVersion'] as int? ?? 0;
}

Future<Object?> _outcome<T>(Future<T> Function() action) async {
  try {
    await action();
    return null;
  } catch (error) {
    return error;
  }
}
