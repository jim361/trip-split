import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/backup/trip_export.dart';

void main() {
  test('schema v1을 결정적으로 왕복하고 복원 가능한 필드를 보존한다', () {
    final fixture = _fixture();
    final payload = TripExportPayload.fromDomain(
      trip: fixture.trip,
      participants: fixture.participants.reversed.toList(),
      places: fixture.places,
      itineraryItems: fixture.itineraryItems,
      expenses: fixture.expenses,
    );

    final encoded = payload.encode();
    final decoded = TripExportPayload.decode(encoded);
    final restored = decoded.toJson();
    final trip = restored['trip']! as Map<String, dynamic>;
    final participants = restored['participants']! as List<dynamic>;
    final places = restored['places']! as List<dynamic>;
    final itinerary = restored['itineraryItems']! as List<dynamic>;
    final expenses = restored['expenses']! as List<dynamic>;
    final expense = expenses.single as Map<String, dynamic>;
    final payer = expense['payer']! as Map<String, dynamic>;
    final receiptItems = expense['receiptItems']! as List<dynamic>;

    expect(decoded.schemaVersion, 1);
    expect(trip['title'], '2026 도쿄');
    expect(participants.map((item) => item['id']), ['p1', 'p2']);
    expect(
      (places.single as Map<String, dynamic>)['providerPlaceId'],
      'google-place-1',
    );
    expect((itinerary.single as Map<String, dynamic>)['placeId'], 'place-1');
    expect(payer['participantId'], 'p1');
    expect((receiptItems.single as Map<String, dynamic>)['amount'], 3000);
    expect(decoded.encode(), encoded);
  });

  test('계정·공유 코드와 audit uid/timestamp를 export하지 않는다', () {
    final fixture = _fixture();
    final encoded = TripExportPayload.fromDomain(
      trip: fixture.trip,
      participants: fixture.participants,
      places: fixture.places,
      itineraryItems: fixture.itineraryItems,
      expenses: fixture.expenses,
    ).encode();
    final root = jsonDecode(encoded) as Map<String, dynamic>;

    expect(encoded, isNot(contains('owner-secret')));
    expect(encoded, isNot(contains('member-secret')));
    expect(encoded, isNot(contains('audit-secret')));
    expect(encoded, isNot(contains('SHARE-SECRET')));
    expect(root.keys, isNot(contains('members')));
    expect(root['trip'], isNot(containsPair('ownerUid', anything)));
    expect(root['trip'], isNot(containsPair('shareCode', anything)));
    expect(root['trip'], isNot(containsPair('createdAt', anything)));
  });

  test('다른 여행의 하위 데이터가 섞이면 export 전에 거부한다', () {
    final fixture = _fixture();
    final foreignParticipant = Participant(
      id: fixture.participants.first.id,
      tripId: 'another-trip',
      name: fixture.participants.first.name,
      isActive: true,
      createdAt: 0,
      updatedAt: 0,
    );

    expect(
      () => TripExportPayload.fromDomain(
        trip: fixture.trip,
        participants: [foreignParticipant],
        places: fixture.places,
        itineraryItems: fixture.itineraryItems,
        expenses: fixture.expenses,
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'participants[0].tripId'),
      ),
    );
  });

  test('malformed JSON을 AppError invalid-argument로 반환한다', () {
    expect(
      () => TripExportPayload.decode('{not-json'),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'file'),
      ),
    );
  });

  test('지원하지 않는 schemaVersion을 거부한다', () {
    expect(
      () => TripExportPayload.decode(
        jsonEncode({
          'schemaVersion': 2,
          'trip': <String, Object?>{},
          'participants': <Object?>[],
          'places': <Object?>[],
          'itineraryItems': <Object?>[],
          'expenses': <Object?>[],
        }),
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'schemaVersion'),
      ),
    );
  });

  test('필수 필드가 없으면 정확한 JSON 경로를 반환한다', () {
    expect(
      () => TripExportPayload.decode(
        jsonEncode({
          'schemaVersion': 1,
          'trip': {
            'countryCode': 'JP',
            'timeZone': 'Asia/Tokyo',
            'mapProvider': 'google',
            'defaultCurrency': 'JPY',
            'startDate': '2026-11-01',
            'endDate': '2026-11-05',
          },
          'participants': <Object?>[],
          'places': <Object?>[],
          'itineraryItems': <Object?>[],
          'expenses': <Object?>[],
        }),
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'trip.title'),
      ),
    );
  });
}

({
  Trip trip,
  List<Participant> participants,
  List<Place> places,
  List<ItineraryItem> itineraryItems,
  List<Expense> expenses,
})
_fixture() {
  const tripId = 'source-trip';
  const now = 123456789;
  final participants = [
    const Participant(
      id: 'p1',
      tripId: tripId,
      name: '나',
      color: '#123456',
      linkedUid: 'member-secret',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    const Participant(
      id: 'p2',
      tripId: tripId,
      name: '친구',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final places = [
    const Place(
      id: 'place-1',
      tripId: tripId,
      name: '도쿄역',
      address: 'Tokyo',
      lat: 35.6812,
      lng: 139.7671,
      provider: 'google',
      source: 'googleSearch',
      providerPlaceId: 'google-place-1',
      sourceUrl: 'https://example.test/place',
      addedBy: 'audit-secret',
      memo: '집합 장소',
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final itineraryItems = [
    const ItineraryItem(
      id: 'itinerary-1',
      tripId: tripId,
      date: '2026-11-01',
      startTime: '10:00',
      endTime: '11:00',
      placeId: 'place-1',
      title: '도쿄역 도착',
      memo: '짐 보관',
      order: 0,
      updatedBy: 'audit-secret',
      updatedAt: now,
    ),
  ];
  final expenses = [
    Expense(
      id: 'expense-1',
      tripId: tripId,
      title: '점심',
      category: 'food',
      expenseDate: '2026-11-01',
      totalAmount: 3000,
      currency: 'JPY',
      payer: const ExpensePayer(participantId: 'p1', amount: 3000),
      consumers: const ['p1', 'p2'],
      allocationMethod: 'itemized',
      allocatedAmounts: const [
        MoneyAllocation(participantId: 'p1', amount: 1500),
        MoneyAllocation(participantId: 'p2', amount: 1500),
      ],
      receiptItems: [
        ReceiptItem(
          id: 'receipt-item-1',
          kind: 'item',
          name: '라멘',
          amount: 3000,
          consumers: const ['p1', 'p2'],
          allocationMethod: 'equal',
          allocatedAmounts: const [
            MoneyAllocation(participantId: 'p1', amount: 1500),
            MoneyAllocation(participantId: 'p2', amount: 1500),
          ],
          source: 'manual',
          sortOrder: 0,
        ),
      ],
      source: 'manual',
      placeId: 'place-1',
      itineraryItemId: 'itinerary-1',
      memo: '현금 결제',
      createdBy: 'audit-secret',
      updatedBy: 'audit-secret',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  return (
    trip: const Trip(
      id: tripId,
      title: '2026 도쿄',
      countryCode: 'JP',
      timeZone: 'Asia/Tokyo',
      mapProvider: 'google',
      defaultCurrency: 'JPY',
      startDate: '2026-11-01',
      endDate: '2026-11-05',
      ownerUid: 'owner-secret',
      shareCode: 'SHARE-SECRET',
      createdAt: now,
      updatedAt: now,
    ),
    participants: participants,
    places: places,
    itineraryItems: itineraryItems,
    expenses: expenses,
  );
}
