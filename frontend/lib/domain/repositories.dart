import 'models.dart';
import 'preparation.dart';

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
  void validate() {
    if (name.trim().isEmpty ||
        name.trim().length > 80 ||
        (color != null && !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color!))) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '이름은 1~80자, 색상은 #RRGGBB 형식으로 입력해 주세요.',
        retryable: false,
      );
    }
  }
}

final class TripUpdate {
  TripUpdate({
    required String title,
    required this.startDate,
    required this.endDate,
  }) : title = title.trim() {
    if (this.title.isEmpty ||
        this.title.length > 80 ||
        !_isLocalDate(startDate) ||
        !_isLocalDate(endDate) ||
        startDate.compareTo(endDate) > 0) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '여행 이름과 실제 시작·종료 날짜를 확인해 주세요.',
        retryable: false,
      );
    }
  }
  final String title, startDate, endDate;
  Map<String, String> toJson() => {
    'title': title,
    'startDate': startDate,
    'endDate': endDate,
  };
}

final class PlaceDraft {
  factory PlaceDraft({
    required String name,
    required String provider,
    required String source,
    String? address,
    double? lat,
    double? lng,
    String? providerPlaceId,
    String? sourceUrl,
    String? memo,
  }) {
    final normalizedName = name.trim();
    final normalizedProvider = provider.trim();
    final normalizedSource = source.trim();
    final normalizedAddress = _optionalTrim(address);
    final normalizedProviderPlaceId = _optionalTrim(providerPlaceId);
    final normalizedSourceUrl = _optionalTrim(sourceUrl);
    final normalizedMemo = _optionalTrim(memo);

    if (normalizedName.isEmpty || normalizedName.length > 160) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '장소 이름은 1자 이상 160자 이하여야 합니다.',
        retryable: false,
        field: 'name',
      );
    }

    const allowedSources = <String, Set<String>>{
      'google': {'googleSearch', 'googleMapsUrl'},
      'naver': {'naverSearch', 'naverLink'},
      'manual': {'manual'},
    };
    if (!allowedSources.containsKey(normalizedProvider)) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '지원하지 않는 장소 provider입니다.',
        retryable: false,
        field: 'provider',
      );
    }
    if (!allowedSources[normalizedProvider]!.contains(normalizedSource)) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: 'provider와 장소 출처 조합을 확인해 주세요.',
        retryable: false,
        field: 'source',
      );
    }
    if ((lat == null) != (lng == null) ||
        (lat != null && (!lat.isFinite || lat < -90 || lat > 90)) ||
        (lng != null && (!lng.isFinite || lng < -180 || lng > 180))) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '장소 좌표를 확인해 주세요.',
        retryable: false,
        field: 'coordinates',
      );
    }

    return PlaceDraft._(
      name: normalizedName,
      provider: normalizedProvider,
      source: normalizedSource,
      address: normalizedAddress,
      lat: lat,
      lng: lng,
      providerPlaceId: normalizedProviderPlaceId,
      sourceUrl: normalizedSourceUrl,
      memo: normalizedMemo,
    );
  }

  const PlaceDraft._({
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

String? _optionalTrim(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

final class ItineraryItemDraft {
  factory ItineraryItemDraft({
    required LocalDate date,
    required String title,
    required int order,
    String planId = 'A',
    String category = 'other',
    String? startTime,
    String? endTime,
    EntityId? placeId,
    String? memo,
  }) {
    final normalizedDate = date.trim();
    final normalizedTitle = title.trim();
    final normalizedStartTime = _optionalItineraryTime(startTime, 'startTime');
    final normalizedEndTime = _optionalItineraryTime(endTime, 'endTime');

    if (!_isLocalDate(normalizedDate)) {
      throw _invalidItinerary('date', '일정 날짜는 YYYY-MM-DD 형식의 실제 날짜여야 합니다.');
    }
    if (normalizedTitle.isEmpty || normalizedTitle.length > 160) {
      throw _invalidItinerary('title', '일정 제목은 1자 이상 160자 이하여야 합니다.');
    }
    if (order < 0) {
      throw _invalidItinerary('order', '일정 순서는 0 이상이어야 합니다.');
    }
    if (!itineraryPlanIds.contains(planId)) {
      throw _invalidItinerary('planId', '일정 계획은 A안 또는 B안이어야 합니다.');
    }
    if (!itineraryCategories.contains(category)) {
      throw _invalidItinerary('category', '지원하지 않는 일정 유형입니다.');
    }

    return ItineraryItemDraft._(
      date: normalizedDate,
      title: normalizedTitle,
      order: order,
      planId: planId,
      category: category,
      startTime: normalizedStartTime,
      endTime: normalizedEndTime,
      placeId: _optionalTrim(placeId),
      memo: _optionalTrim(memo),
    );
  }

  const ItineraryItemDraft._({
    required this.date,
    required this.title,
    required this.order,
    required this.planId,
    required this.category,
    this.startTime,
    this.endTime,
    this.placeId,
    this.memo,
  });

  final LocalDate date;
  final String planId;
  final String category;
  final String? startTime;
  final String? endTime;
  final EntityId? placeId;
  final String title;
  final String? memo;
  final int order;
}

final _itineraryTimePattern = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
final _localDatePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

bool _isLocalDate(String value) {
  final match = _localDatePattern.firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  return year >= 2000 &&
      year <= 2100 &&
      parsed.year == year &&
      parsed.month == month &&
      parsed.day == day;
}

String? _optionalItineraryTime(String? value, String field) {
  final normalized = _optionalTrim(value);
  if (normalized != null && !_itineraryTimePattern.hasMatch(normalized)) {
    throw _invalidItinerary(field, '시간은 HH:mm 형식으로 입력해 주세요.');
  }
  return normalized;
}

AppError _invalidItinerary(String field, String message) => AppError(
  code: AppErrorCode.invalidArgument,
  message: message,
  retryable: false,
  field: field,
);

final class ItineraryOrderDraft {
  ItineraryOrderDraft({
    required this.date,
    required this.planId,
    required List<EntityId> itemIds,
  }) : itemIds = List.unmodifiable(itemIds) {
    if (!_isLocalDate(date) || !itineraryPlanIds.contains(planId)) {
      throw _invalidItinerary('order', '순서를 바꿀 날짜와 계획을 확인해 주세요.');
    }
    if (itemIds.isEmpty ||
        itemIds.any((id) => id.trim().isEmpty || id.contains('/')) ||
        itemIds.toSet().length != itemIds.length) {
      throw _invalidItinerary('order', '중복되지 않은 일정 목록이 필요합니다.');
    }
  }

  final LocalDate date;
  final String planId;
  final List<EntityId> itemIds;

  void checkItem(ItineraryItem item) {
    if (item.date != date || item.planId != planId) {
      throw const AppError(
        code: AppErrorCode.conflict,
        message: '일정의 날짜나 계획이 변경됐습니다. 목록을 확인하고 다시 시도해 주세요.',
        retryable: false,
        field: 'order',
      );
    }
  }
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

  /// 수동 폼은 항목별 원장을 총액만으로 덮어쓰지 않습니다.
  void validateManual({
    required EntityId tripId,
    required List<Participant> participants,
    required List<Place> places,
    required List<ItineraryItem> itinerary,
    Expense? previous,
  }) => validate(
    tripId: tripId,
    participants: participants,
    places: places,
    itinerary: itinerary,
    previous: previous,
    manualOnly: true,
  );

  void validate({
    required EntityId tripId,
    required List<Participant> participants,
    required List<Place> places,
    required List<ItineraryItem> itinerary,
    Expense? previous,
    bool manualOnly = false,
  }) {
    void invalid(String field, String message) => throw AppError(
      code: AppErrorCode.invalidArgument,
      message: message,
      retryable: false,
      field: field,
    );
    if (title.trim().isEmpty || title.length > 160) {
      invalid('title', '지출 제목은 1~160자로 입력해 주세요.');
    }
    if (!_isLocalDate(expenseDate)) {
      invalid('expenseDate', '지출 날짜는 YYYY-MM-DD 형식의 실제 날짜여야 합니다.');
    }
    if (category.trim().isEmpty || category.length > 80) {
      invalid('category', '지출 유형을 선택해 주세요.');
    }
    if ((memo?.length ?? 0) > 2000) invalid('memo', '메모는 2000자까지 입력할 수 있습니다.');
    if (!const ['KRW', 'JPY'].contains(currency)) {
      invalid('currency', 'KRW 또는 JPY를 선택해 주세요.');
    }
    const maxAmount = 9007199254740991;
    if (totalAmount <= 0 || totalAmount > maxAmount) {
      invalid('totalAmount', '총액은 1 이상의 안전한 정수로 입력해 주세요.');
    }
    if (manualOnly &&
        (source != 'manual' ||
            receiptItems.isNotEmpty ||
            !const ['equal', 'custom'].contains(allocationMethod))) {
      invalid('allocationMethod', '현재 수동 지출은 균등 분할과 직접 입력을 지원합니다.');
    }
    if (!['manual', 'ocr'].contains(source) ||
        !['equal', 'custom', 'itemized'].contains(allocationMethod)) {
      invalid('allocationMethod', '지원하지 않는 배분 방식입니다.');
    }
    if (source == 'ocr' && allocationMethod != 'itemized') {
      invalid('source', '총액으로 등록할 때는 수동 지출로 저장해 주세요.');
    }
    if (manualOnly &&
        previous != null &&
        (previous.source != 'manual' ||
            previous.receiptItems.isNotEmpty ||
            previous.allocationMethod == 'itemized')) {
      invalid('allocationMethod', '항목별·영수증 지출은 아직 이 화면에서 수정할 수 없습니다.');
    }
    if (payer.amount != totalAmount) {
      invalid('payer', '결제 금액과 총액이 일치해야 합니다.');
    }
    final consumerSet = consumers.toSet();
    if (consumers.isEmpty ||
        consumers.length > 100 ||
        consumerSet.length != consumers.length) {
      invalid('consumers', '부담할 사람을 중복 없이 한 명 이상 선택해 주세요.');
    }
    final allowedInactive = {
      if (previous != null) previous.payer.participantId,
      ...?previous?.consumers,
    };
    final participantsById = {
      for (final participant in participants.where((p) => p.tripId == tripId))
        participant.id: participant,
    };
    for (final id in {payer.participantId, ...consumers}) {
      final participant = participantsById[id];
      if (participant == null ||
          (!participant.isActive && !allowedInactive.contains(id))) {
        invalid(
          id == payer.participantId ? 'payer' : 'consumers',
          '결제자와 부담할 사람을 현재 여행의 참여자에서 다시 선택해 주세요.',
        );
      }
    }
    final allocationIds = allocatedAmounts.map((a) => a.participantId).toSet();
    if (allocatedAmounts.length != consumers.length ||
        allocationIds.length != consumers.length ||
        !allocationIds.containsAll(consumerSet)) {
      invalid('allocatedAmounts', '부담할 사람마다 금액이 하나씩 있어야 합니다.');
    }
    var sum = 0;
    for (final allocation in allocatedAmounts) {
      if (allocation.amount < 0 || allocation.amount > maxAmount - sum) {
        invalid('allocatedAmounts', '부담액은 0 이상의 안전한 정수여야 합니다.');
      }
      sum += allocation.amount;
      if (allocationMethod == 'equal') {
        final index = consumers.indexOf(allocation.participantId);
        final expected =
            totalAmount ~/ consumers.length +
            (index < totalAmount % consumers.length ? 1 : 0);
        if (allocation.amount != expected) {
          invalid('allocatedAmounts', '균등 분할 결과를 다시 확인해 주세요.');
        }
      }
    }
    if (sum != totalAmount) {
      invalid('allocatedAmounts', '부담액 합계와 총액을 맞춰 주세요.');
    }
    if (allocationMethod != 'itemized' && receiptItems.isNotEmpty) {
      invalid('receiptItems', '총액 분할에는 항목을 함께 저장할 수 없습니다.');
    }
    if (allocationMethod == 'itemized') {
      if (receiptItems.isEmpty ||
          receiptItems.length > 200 ||
          receiptItems.map((i) => i.id).toSet().length != receiptItems.length) {
        invalid('receiptItems', '영수증 항목을 1~200개 입력해 주세요.');
      }
      final aggregated = <String, int>{};
      var itemTotal = 0;
      for (final (index, item) in receiptItems.indexed) {
        if (item.id.trim().isEmpty ||
            item.id.length > 160 ||
            item.id.contains('/') ||
            item.name.trim().isEmpty ||
            item.name.length > 160 ||
            item.sortOrder != index) {
          invalid('receiptItems', '항목 이름과 순서를 확인해 주세요.');
        }
        if (!['manual', 'ocr'].contains(item.source) ||
            !['equal', 'custom'].contains(item.allocationMethod) ||
            item.amount.abs() > maxAmount) {
          invalid('receiptItems', '항목 배분 형식을 확인해 주세요.');
        }
        final validSign = switch (item.kind) {
          'item' || 'serviceFee' => item.amount > 0,
          'discount' => item.amount < 0,
          'adjustment' => item.amount != 0,
          _ => false,
        };
        if (!validSign) invalid('receiptItems', '일반 항목·봉사료는 양수, 할인은 음수여야 합니다.');
        final ids = item.consumers.toSet();
        if (ids.isEmpty ||
            ids.length != item.consumers.length ||
            !consumerSet.containsAll(ids) ||
            item.allocatedAmounts.length != ids.length ||
            item.allocatedAmounts.map((a) => a.participantId).toSet().length !=
                ids.length) {
          invalid('receiptItems', '항목별 소비자를 중복 없이 지정해 주세요.');
        }
        var itemSum = 0;
        for (final a in item.allocatedAmounts) {
          if (!ids.contains(a.participantId) ||
              a.amount.abs() > maxAmount ||
              (a.amount != 0 && a.amount.sign != item.amount.sign)) {
            invalid('receiptItems', '항목별 부담액을 확인해 주세요.');
          }
          if (item.allocationMethod == 'equal') {
            final base = item.amount ~/ ids.length;
            final remainder = item.amount - base * ids.length;
            final expected =
                base +
                (item.consumers.indexOf(a.participantId) < remainder.abs()
                    ? remainder.sign
                    : 0);
            if (a.amount != expected) {
              invalid('receiptItems', '항목 균등 배분을 확인해 주세요.');
            }
          }
          itemSum += a.amount;
          if (itemSum.abs() > maxAmount) {
            invalid('receiptItems', '항목 합계가 안전한 정수 범위를 넘었습니다.');
          }
          aggregated.update(
            a.participantId,
            (v) => v + a.amount,
            ifAbsent: () => a.amount,
          );
          if (aggregated[a.participantId]!.abs() > maxAmount) {
            invalid('receiptItems', '참여자 합계가 안전한 정수 범위를 넘었습니다.');
          }
        }
        if (itemSum != item.amount) {
          invalid('receiptItems', '항목 금액과 배분 합계를 맞춰 주세요.');
        }
        itemTotal += item.amount;
        if (itemTotal.abs() > maxAmount) {
          invalid('receiptItems', '항목 합계가 안전한 정수 범위를 넘었습니다.');
        }
      }
      if (itemTotal != totalAmount ||
          allocatedAmounts.any(
            (a) => a.amount != (aggregated[a.participantId] ?? 0),
          )) {
        invalid('receiptItems', '항목·조정 합계와 지출 총액·개인 부담액을 맞춰 주세요.');
      }
    }
    if (placeId != null &&
        !places.any((p) => p.tripId == tripId && p.id == placeId)) {
      invalid('placeId', '장소를 다시 선택하거나 연결을 해제해 주세요.');
    }
    if (itineraryItemId != null &&
        !itinerary.any((i) => i.tripId == tripId && i.id == itineraryItemId)) {
      invalid('itineraryItemId', '일정을 다시 선택하거나 연결을 해제해 주세요.');
    }
  }
}

abstract interface class TripsRepository {
  Stream<Trip?> watchTrip(EntityId tripId);
  Future<List<Trip>> listMyTrips();
  Future<void> updateTrip(EntityId tripId, TripUpdate draft);
}

abstract interface class UserProfilesRepository {
  Stream<UserProfile?> watchUser(String uid);
}

abstract interface class MembersRepository {
  Stream<List<TripMember>> watchMembers(EntityId tripId);
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

  Future<void> deactivateParticipant(EntityId tripId, EntityId participantId);
  Future<void> linkMyParticipant(EntityId tripId, EntityId? participantId);
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

  /// 선택 날짜·계획의 순서와 감사 필드만 원자적으로 갱신한다.
  Future<void> reorderItineraryItems(
    EntityId tripId,
    ItineraryOrderDraft draft,
  );
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
        UserProfilesRepository,
        MembersRepository,
        ParticipantsRepository,
        PlacesRepository,
        ItineraryRepository,
        PreparationRepository,
        ExpensesRepository {}
