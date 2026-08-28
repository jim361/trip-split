typedef EntityId = String;
typedef ParticipantId = EntityId;
typedef EpochMillis = int;
typedef LocalDate = String;
typedef CurrencyAmount = int;
typedef CurrencyCode = String;

enum AppErrorCode {
  unauthenticated('unauthenticated'),
  permissionDenied('permission-denied'),
  invalidArgument('invalid-argument'),
  notFound('not-found'),
  conflict('conflict'),
  resourceExhausted('resource-exhausted'),
  unavailable('unavailable'),
  invalidImage('invalid-image'),
  payloadTooLarge('payload-too-large'),
  ocrUnavailable('ocr-unavailable'),
  ocrNoResult('ocr-no-result'),
  unknown('unknown');

  const AppErrorCode(this.wireValue);

  final String wireValue;
}

final class AppError implements Exception {
  const AppError({
    required this.code,
    required this.message,
    required this.retryable,
    this.field,
    this.details = const {},
  });

  final AppErrorCode code;
  final String message;
  final bool retryable;
  final String? field;
  final Map<String, Object?> details;

  @override
  String toString() => 'AppError(${code.wireValue}): $message';
}

final class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.authProvider,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String authProvider;
  final EpochMillis createdAt;
  final EpochMillis updatedAt;
}

final class TripMember {
  const TripMember({
    required this.uid,
    required this.tripId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.lastActiveAt,
    this.photoUrl,
  });

  final String uid;
  final EntityId tripId;
  final String displayName;
  final String? photoUrl;
  final String role;
  final EpochMillis joinedAt;
  final EpochMillis lastActiveAt;
}

final class ShareCode {
  const ShareCode({
    required this.code,
    required this.tripId,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    required this.useCount,
    this.expiresAt,
    this.maxUses,
  });

  final String code;
  final EntityId tripId;
  final String createdBy;
  final EpochMillis createdAt;
  final bool isActive;
  final int useCount;
  final EpochMillis? expiresAt;
  final int? maxUses;
}

final class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.countryCode,
    required this.timeZone,
    required this.mapProvider,
    required this.defaultCurrency,
    required this.startDate,
    required this.endDate,
    required this.ownerUid,
    required this.shareCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final String title;
  final String countryCode;
  final String timeZone;
  final String mapProvider;
  final CurrencyCode defaultCurrency;
  final LocalDate startDate;
  final LocalDate endDate;
  final String ownerUid;
  final String shareCode;
  final EpochMillis createdAt;
  final EpochMillis updatedAt;
}

final class Participant {
  const Participant({
    required this.id,
    required this.tripId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.linkedUid,
  });

  final ParticipantId id;
  final EntityId tripId;
  final String name;
  final String? color;
  final String? linkedUid;
  final bool isActive;
  final EpochMillis createdAt;
  final EpochMillis updatedAt;
}

final class Place {
  const Place({
    required this.id,
    required this.tripId,
    required this.name,
    required this.provider,
    required this.source,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.lat,
    this.lng,
    this.providerPlaceId,
    this.sourceUrl,
    this.memo,
  });

  final EntityId id;
  final EntityId tripId;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String provider;
  final String source;
  final String? providerPlaceId;
  final String? sourceUrl;
  final String addedBy;
  final String? memo;
  final EpochMillis createdAt;
  final EpochMillis updatedAt;
}

final class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.tripId,
    required this.date,
    required this.title,
    required this.order,
    required this.updatedAt,
    this.startTime,
    this.endTime,
    this.placeId,
    this.memo,
    this.updatedBy,
  });

  final EntityId id;
  final EntityId tripId;
  final LocalDate date;
  final String? startTime;
  final String? endTime;
  final EntityId? placeId;
  final String title;
  final String? memo;
  final int order;
  final String? updatedBy;
  final EpochMillis updatedAt;
}

final class MoneyAllocation {
  const MoneyAllocation({required this.participantId, required this.amount});

  final ParticipantId participantId;
  final CurrencyAmount amount;
}

final class ExpensePayer {
  const ExpensePayer({required this.participantId, required this.amount});

  final ParticipantId participantId;
  final CurrencyAmount amount;
}

final class ReceiptItem {
  ReceiptItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.amount,
    required List<ParticipantId> consumers,
    required this.allocationMethod,
    required List<MoneyAllocation> allocatedAmounts,
    required this.source,
    required this.sortOrder,
  }) : consumers = List.unmodifiable(consumers),
       allocatedAmounts = List.unmodifiable(allocatedAmounts);

  final EntityId id;
  final String kind;
  final String name;
  final CurrencyAmount amount;
  final List<ParticipantId> consumers;
  final String allocationMethod;
  final List<MoneyAllocation> allocatedAmounts;
  final String source;
  final int sortOrder;
}

final class Expense {
  Expense({
    required this.id,
    required this.tripId,
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
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.placeId,
    this.itineraryItemId,
    this.memo,
  }) : consumers = List.unmodifiable(consumers),
       allocatedAmounts = List.unmodifiable(allocatedAmounts),
       receiptItems = List.unmodifiable(receiptItems);

  final EntityId id;
  final EntityId tripId;
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
  final String createdBy;
  final String updatedBy;
  final EpochMillis createdAt;
  final EpochMillis updatedAt;
}
