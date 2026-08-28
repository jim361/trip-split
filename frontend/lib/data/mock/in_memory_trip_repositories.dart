import 'dart:async';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'tokyo_trip_fixture.dart';

typedef EpochClock = EpochMillis Function();

final class InMemoryTripRepositories implements TripRepositories {
  InMemoryTripRepositories({
    TokyoTripFixture? seed,
    this.actorUid = tokyoOwnerUid,
    EpochClock? now,
  }) : _fixture = seed ?? tokyoTripFixture,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _participants.addEntries(
      _fixture.participants.map((value) => MapEntry(value.id, value)),
    );
    _places.addEntries(
      _fixture.places.map((value) => MapEntry(value.id, value)),
    );
    _itinerary.addEntries(
      _fixture.itinerary.map((value) => MapEntry(value.id, value)),
    );
    _expenses.addEntries(
      _fixture.expenses.map((value) => MapEntry(value.id, value)),
    );
  }

  final String actorUid;
  final TokyoTripFixture _fixture;
  final EpochClock _now;
  final _changes = StreamController<void>.broadcast(sync: true);
  final Map<EntityId, Participant> _participants = {};
  final Map<EntityId, Place> _places = {};
  final Map<EntityId, ItineraryItem> _itinerary = {};
  final Map<EntityId, Expense> _expenses = {};
  var _nextId = 1;

  @override
  Stream<Trip?> watchTrip(EntityId tripId) async* {
    yield _trip(tripId);
    yield* _changes.stream.map((_) => _trip(tripId));
  }

  @override
  Stream<List<Participant>> watchParticipants(EntityId tripId) async* {
    yield _participantsFor(tripId);
    yield* _changes.stream.map((_) => _participantsFor(tripId));
  }

  @override
  Stream<List<Place>> watchPlaces(EntityId tripId) async* {
    yield _placesFor(tripId);
    yield* _changes.stream.map((_) => _placesFor(tripId));
  }

  @override
  Stream<List<ItineraryItem>> watchItinerary(EntityId tripId) async* {
    yield _itineraryFor(tripId);
    yield* _changes.stream.map((_) => _itineraryFor(tripId));
  }

  @override
  Stream<List<Expense>> watchExpenses(EntityId tripId) async* {
    yield _expensesFor(tripId);
    yield* _changes.stream.map((_) => _expensesFor(tripId));
  }

  @override
  Future<Participant> createParticipant(
    EntityId tripId,
    ParticipantDraft draft,
  ) async {
    _requireTrip(tripId);
    final timestamp = _now();
    final participant = Participant(
      id: _id('participant'),
      tripId: tripId,
      name: draft.name,
      color: draft.color,
      linkedUid: draft.linkedUid,
      isActive: draft.isActive,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    _participants[participant.id] = participant;
    _changes.add(null);
    return participant;
  }

  @override
  Future<void> updateParticipant(
    EntityId tripId,
    EntityId participantId,
    ParticipantDraft draft,
  ) async {
    final current = _find(_participants, tripId, participantId, '참여자');
    _participants[participantId] = Participant(
      id: current.id,
      tripId: current.tripId,
      name: draft.name,
      color: draft.color,
      linkedUid: draft.linkedUid,
      isActive: draft.isActive,
      createdAt: current.createdAt,
      updatedAt: _now(),
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteParticipant(
    EntityId tripId,
    EntityId participantId,
  ) async {
    _find(_participants, tripId, participantId, '참여자');
    _participants.remove(participantId);
    _changes.add(null);
  }

  @override
  Future<Place> createPlace(EntityId tripId, PlaceDraft draft) async {
    _requireTrip(tripId);
    final timestamp = _now();
    final place = Place(
      id: _id('place'),
      tripId: tripId,
      name: draft.name,
      address: draft.address,
      lat: draft.lat,
      lng: draft.lng,
      provider: draft.provider,
      source: draft.source,
      providerPlaceId: draft.providerPlaceId,
      sourceUrl: draft.sourceUrl,
      addedBy: actorUid,
      memo: draft.memo,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    _places[place.id] = place;
    _changes.add(null);
    return place;
  }

  @override
  Future<void> updatePlace(
    EntityId tripId,
    EntityId placeId,
    PlaceDraft draft,
  ) async {
    final current = _find(_places, tripId, placeId, '장소');
    _places[placeId] = Place(
      id: current.id,
      tripId: current.tripId,
      name: draft.name,
      address: draft.address,
      lat: draft.lat,
      lng: draft.lng,
      provider: draft.provider,
      source: draft.source,
      providerPlaceId: draft.providerPlaceId,
      sourceUrl: draft.sourceUrl,
      addedBy: current.addedBy,
      memo: draft.memo,
      createdAt: current.createdAt,
      updatedAt: _now(),
    );
    _changes.add(null);
  }

  @override
  Future<void> deletePlace(EntityId tripId, EntityId placeId) async {
    _find(_places, tripId, placeId, '장소');
    _places.remove(placeId);
    _changes.add(null);
  }

  @override
  Future<ItineraryItem> createItineraryItem(
    EntityId tripId,
    ItineraryItemDraft draft,
  ) async {
    _requireTrip(tripId);
    final item = ItineraryItem(
      id: _id('itinerary'),
      tripId: tripId,
      date: draft.date,
      startTime: draft.startTime,
      endTime: draft.endTime,
      placeId: draft.placeId,
      title: draft.title,
      memo: draft.memo,
      order: draft.order,
      updatedBy: actorUid,
      updatedAt: _now(),
    );
    _itinerary[item.id] = item;
    _changes.add(null);
    return item;
  }

  @override
  Future<void> updateItineraryItem(
    EntityId tripId,
    EntityId itineraryItemId,
    ItineraryItemDraft draft,
  ) async {
    final current = _find(_itinerary, tripId, itineraryItemId, '일정');
    _itinerary[itineraryItemId] = ItineraryItem(
      id: current.id,
      tripId: current.tripId,
      date: draft.date,
      startTime: draft.startTime,
      endTime: draft.endTime,
      placeId: draft.placeId,
      title: draft.title,
      memo: draft.memo,
      order: draft.order,
      updatedBy: actorUid,
      updatedAt: _now(),
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteItineraryItem(
    EntityId tripId,
    EntityId itineraryItemId,
  ) async {
    _find(_itinerary, tripId, itineraryItemId, '일정');
    _itinerary.remove(itineraryItemId);
    _changes.add(null);
  }

  @override
  Future<Expense> createExpense(EntityId tripId, ExpenseDraft draft) async {
    _requireTrip(tripId);
    final timestamp = _now();
    final expense = _expenseFromDraft(
      id: _id('expense'),
      tripId: tripId,
      draft: draft,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    _expenses[expense.id] = expense;
    _changes.add(null);
    return expense;
  }

  @override
  Future<void> updateExpense(
    EntityId tripId,
    EntityId expenseId,
    ExpenseDraft draft,
  ) async {
    final current = _find(_expenses, tripId, expenseId, '지출');
    _expenses[expenseId] = _expenseFromDraft(
      id: current.id,
      tripId: current.tripId,
      draft: draft,
      createdAt: current.createdAt,
      updatedAt: _now(),
      createdBy: current.createdBy,
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteExpense(EntityId tripId, EntityId expenseId) async {
    _find(_expenses, tripId, expenseId, '지출');
    _expenses.remove(expenseId);
    _changes.add(null);
  }

  Future<void> close() => _changes.close();

  Trip? _trip(EntityId tripId) =>
      _fixture.trip.id == tripId ? _fixture.trip : null;

  void _requireTrip(EntityId tripId) {
    if (_trip(tripId) == null) {
      throw AppError(
        code: AppErrorCode.notFound,
        message: '여행을 찾을 수 없습니다.',
        retryable: false,
        details: {'id': tripId},
      );
    }
  }

  T _find<T>(
    Map<EntityId, T> values,
    EntityId tripId,
    EntityId id,
    String label,
  ) {
    final value = values[id];
    final valueTripId = switch (value) {
      Participant value => value.tripId,
      Place value => value.tripId,
      ItineraryItem value => value.tripId,
      Expense value => value.tripId,
      _ => null,
    };
    if (value == null || valueTripId != tripId) {
      throw AppError(
        code: AppErrorCode.notFound,
        message: '$label을(를) 찾을 수 없습니다.',
        retryable: false,
        details: {'id': id},
      );
    }
    return value;
  }

  List<Participant> _participantsFor(EntityId tripId) =>
      _participants.values.where((value) => value.tripId == tripId).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  List<Place> _placesFor(EntityId tripId) =>
      _places.values.where((value) => value.tripId == tripId).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  List<ItineraryItem> _itineraryFor(EntityId tripId) =>
      _itinerary.values.where((value) => value.tripId == tripId).toList()
        ..sort((a, b) {
          final date = a.date.compareTo(b.date);
          if (date != 0) return date;
          final order = a.order.compareTo(b.order);
          return order != 0 ? order : a.id.compareTo(b.id);
        });

  List<Expense> _expensesFor(EntityId tripId) =>
      _expenses.values.where((value) => value.tripId == tripId).toList()
        ..sort((a, b) {
          final date = a.expenseDate.compareTo(b.expenseDate);
          return date != 0 ? date : a.id.compareTo(b.id);
        });

  Expense _expenseFromDraft({
    required EntityId id,
    required EntityId tripId,
    required ExpenseDraft draft,
    required EpochMillis createdAt,
    required EpochMillis updatedAt,
    String? createdBy,
  }) => Expense(
    id: id,
    tripId: tripId,
    title: draft.title,
    category: draft.category,
    expenseDate: draft.expenseDate,
    totalAmount: draft.totalAmount,
    currency: draft.currency,
    payer: draft.payer,
    consumers: draft.consumers,
    allocationMethod: draft.allocationMethod,
    allocatedAmounts: draft.allocatedAmounts,
    receiptItems: draft.receiptItems,
    source: draft.source,
    placeId: draft.placeId,
    itineraryItemId: draft.itineraryItemId,
    memo: draft.memo,
    createdBy: createdBy ?? actorUid,
    updatedBy: actorUid,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  EntityId _id(String kind) => 'mock-$kind-${_nextId++}';
}
