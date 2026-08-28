import 'models.dart';

final class ParticipantDraft {
  const ParticipantDraft({
    required this.name,
    this.color,
    this.linkedUid,
    this.isActive = true,
  });

  final String name;
  final String? color;
  final String? linkedUid;
  final bool isActive;
}

final class PlaceDraft {
  const PlaceDraft({
    required this.name,
    required this.provider,
    required this.source,
    this.address,
    this.lat,
    this.lng,
    this.providerPlaceId,
    this.sourceUrl,
    this.memo,
  });

  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String provider;
  final String source;
  final String? providerPlaceId;
  final String? sourceUrl;
  final String? memo;
}

final class ItineraryItemDraft {
  const ItineraryItemDraft({
    required this.date,
    required this.title,
    required this.order,
    this.startTime,
    this.endTime,
    this.placeId,
    this.memo,
  });

  final LocalDate date;
  final String? startTime;
  final String? endTime;
  final EntityId? placeId;
  final String title;
  final String? memo;
  final int order;
}

final class ExpenseDraft {
  ExpenseDraft({
    required this.title,
    required this.category,
    required this.expenseDate,
    required this.totalAmount,
    required this.currency,
    required this.payer,
    required List<ParticipantId> consumers,
    required this.allocationMethod,
    required List<MoneyAllocation> allocatedAmounts,
    required List<ReceiptItem> receiptItems,
    required this.source,
    this.placeId,
    this.itineraryItemId,
    this.memo,
  }) : consumers = List.unmodifiable(consumers),
       allocatedAmounts = List.unmodifiable(allocatedAmounts),
       receiptItems = List.unmodifiable(receiptItems);

  final String title;
  final String category;
  final LocalDate expenseDate;
  final CurrencyAmount totalAmount;
  final CurrencyCode currency;
  final ExpensePayer payer;
  final List<ParticipantId> consumers;
  final String allocationMethod;
  final List<MoneyAllocation> allocatedAmounts;
  final List<ReceiptItem> receiptItems;
  final String source;
  final EntityId? placeId;
  final EntityId? itineraryItemId;
  final String? memo;
}

abstract interface class TripsRepository {
  Stream<Trip?> watchTrip(EntityId tripId);
}

abstract interface class ParticipantsRepository {
  Stream<List<Participant>> watchParticipants(EntityId tripId);

  Future<Participant> createParticipant(
    EntityId tripId,
    ParticipantDraft draft,
  );

  Future<void> updateParticipant(
    EntityId tripId,
    EntityId participantId,
    ParticipantDraft draft,
  );

  Future<void> deleteParticipant(EntityId tripId, EntityId participantId);
}

abstract interface class PlacesRepository {
  Stream<List<Place>> watchPlaces(EntityId tripId);

  Future<Place> createPlace(EntityId tripId, PlaceDraft draft);

  Future<void> updatePlace(EntityId tripId, EntityId placeId, PlaceDraft draft);

  Future<void> deletePlace(EntityId tripId, EntityId placeId);
}

abstract interface class ItineraryRepository {
  Stream<List<ItineraryItem>> watchItinerary(EntityId tripId);

  Future<ItineraryItem> createItineraryItem(
    EntityId tripId,
    ItineraryItemDraft draft,
  );

  Future<void> updateItineraryItem(
    EntityId tripId,
    EntityId itineraryItemId,
    ItineraryItemDraft draft,
  );

  Future<void> deleteItineraryItem(EntityId tripId, EntityId itineraryItemId);
}

abstract interface class ExpensesRepository {
  Stream<List<Expense>> watchExpenses(EntityId tripId);

  Future<Expense> createExpense(EntityId tripId, ExpenseDraft draft);

  Future<void> updateExpense(
    EntityId tripId,
    EntityId expenseId,
    ExpenseDraft draft,
  );

  Future<void> deleteExpense(EntityId tripId, EntityId expenseId);
}

abstract interface class TripRepositories
    implements
        TripsRepository,
        ParticipantsRepository,
        PlacesRepository,
        ItineraryRepository,
        ExpensesRepository {}
