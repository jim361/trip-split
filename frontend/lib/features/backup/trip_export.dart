import 'dart:convert';

import '../../domain/models.dart';

/// `.trip.json` schema version 1의 새 여행 복원 payload다.
///
/// 복원은 항상 새 여행 ID, owner, share code, member와 audit 값을 만든다. 따라서
/// 원본 Trip의 id/ownerUid/shareCode, member·user profile, Participant.linkedUid,
/// 그리고 created/updated uid·timestamp는 내보내지 않는다. 하위 엔티티 ID는
/// place/itinerary/expense 사이의 참조를 유지하기 위해 보존한다.
final class TripExportPayload {
  TripExportPayload._(this._json);

  static const currentSchemaVersion = 1;

  factory TripExportPayload.fromDomain({
    required Trip trip,
    required List<Participant> participants,
    required List<Place> places,
    required List<ItineraryItem> itineraryItems,
    required List<Expense> expenses,
  }) {
    _validateTripScope(
      trip.id,
      participants: participants,
      places: places,
      itineraryItems: itineraryItems,
      expenses: expenses,
    );
    return TripExportPayload._(
      _normalizePayload({
        'schemaVersion': currentSchemaVersion,
        'trip': {
          'title': trip.title,
          'countryCode': trip.countryCode,
          'timeZone': trip.timeZone,
          'mapProvider': trip.mapProvider,
          'defaultCurrency': trip.defaultCurrency,
          'startDate': trip.startDate,
          'endDate': trip.endDate,
        },
        'participants': participants
            .map(
              (participant) => {
                'id': participant.id,
                'name': participant.name,
                'color': participant.color,
                'isActive': participant.isActive,
              },
            )
            .toList(growable: false),
        'places': places.map(_placeJson).toList(growable: false),
        'itineraryItems': itineraryItems
            .map(_itineraryJson)
            .toList(growable: false),
        'expenses': expenses.map(_expenseJson).toList(growable: false),
      }),
    );
  }

  factory TripExportPayload.decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw _invalid('file', '올바른 JSON 파일이 아닙니다.');
    }
    return TripExportPayload._(_normalizePayload(decoded));
  }

  final Map<String, Object?> _json;

  int get schemaVersion => _json['schemaVersion']! as int;

  /// 호출자가 내부 payload를 변경하지 못하도록 JSON-safe 깊은 복사본을 반환한다.
  Map<String, Object?> toJson() {
    return (jsonDecode(encode()) as Map).cast<String, Object?>();
  }

  String encode() => jsonEncode(_json);
}

void _validateTripScope(
  EntityId tripId, {
  required List<Participant> participants,
  required List<Place> places,
  required List<ItineraryItem> itineraryItems,
  required List<Expense> expenses,
}) {
  for (var index = 0; index < participants.length; index++) {
    _requireTripId(participants[index].tripId, tripId, 'participants[$index]');
  }
  for (var index = 0; index < places.length; index++) {
    _requireTripId(places[index].tripId, tripId, 'places[$index]');
  }
  for (var index = 0; index < itineraryItems.length; index++) {
    _requireTripId(
      itineraryItems[index].tripId,
      tripId,
      'itineraryItems[$index]',
    );
  }
  for (var index = 0; index < expenses.length; index++) {
    _requireTripId(expenses[index].tripId, tripId, 'expenses[$index]');
  }
}

void _requireTripId(EntityId actual, EntityId expected, String path) {
  if (actual != expected) {
    throw _invalid('$path.tripId', '다른 여행의 데이터는 함께 내보낼 수 없습니다.');
  }
}

Map<String, Object?> _placeJson(Place place) => {
  'id': place.id,
  'name': place.name,
  'address': place.address,
  'lat': place.lat,
  'lng': place.lng,
  'provider': place.provider,
  'source': place.source,
  'providerPlaceId': place.providerPlaceId,
  'sourceUrl': place.sourceUrl,
  'memo': place.memo,
};

Map<String, Object?> _itineraryJson(ItineraryItem item) => {
  'id': item.id,
  'date': item.date,
  'planId': item.planId,
  'category': item.category,
  'startTime': item.startTime,
  'endTime': item.endTime,
  'placeId': item.placeId,
  'title': item.title,
  'memo': item.memo,
  'order': item.order,
};

Map<String, Object?> _expenseJson(Expense expense) => {
  'id': expense.id,
  'title': expense.title,
  'category': expense.category,
  'expenseDate': expense.expenseDate,
  'totalAmount': expense.totalAmount,
  'currency': expense.currency,
  'payer': {
    'participantId': expense.payer.participantId,
    'amount': expense.payer.amount,
  },
  'consumers': expense.consumers,
  'allocationMethod': expense.allocationMethod,
  'allocatedAmounts': expense.allocatedAmounts
      .map(_allocationJson)
      .toList(growable: false),
  'receiptItems': expense.receiptItems
      .map(
        (item) => {
          'id': item.id,
          'kind': item.kind,
          'name': item.name,
          'amount': item.amount,
          'consumers': item.consumers,
          'allocationMethod': item.allocationMethod,
          'allocatedAmounts': item.allocatedAmounts
              .map(_allocationJson)
              .toList(growable: false),
          'source': item.source,
          'sortOrder': item.sortOrder,
        },
      )
      .toList(growable: false),
  'source': expense.source,
  'placeId': expense.placeId,
  'itineraryItemId': expense.itineraryItemId,
  'memo': expense.memo,
};

Map<String, Object?> _allocationJson(MoneyAllocation allocation) => {
  'participantId': allocation.participantId,
  'amount': allocation.amount,
};

enum _FieldKind {
  string,
  nullableString,
  integer,
  boolean,
  nullableNumber,
  stringList,
  payer,
  allocationList,
  receiptItemList,
}

const _tripSchema = {
  'title': _FieldKind.string,
  'countryCode': _FieldKind.string,
  'timeZone': _FieldKind.string,
  'mapProvider': _FieldKind.string,
  'defaultCurrency': _FieldKind.string,
  'startDate': _FieldKind.string,
  'endDate': _FieldKind.string,
};
const _participantSchema = {
  'id': _FieldKind.string,
  'name': _FieldKind.string,
  'color': _FieldKind.nullableString,
  'isActive': _FieldKind.boolean,
};
const _placeSchema = {
  'id': _FieldKind.string,
  'name': _FieldKind.string,
  'address': _FieldKind.nullableString,
  'lat': _FieldKind.nullableNumber,
  'lng': _FieldKind.nullableNumber,
  'provider': _FieldKind.string,
  'source': _FieldKind.string,
  'providerPlaceId': _FieldKind.nullableString,
  'sourceUrl': _FieldKind.nullableString,
  'memo': _FieldKind.nullableString,
};
const _itinerarySchema = {
  'id': _FieldKind.string,
  'date': _FieldKind.string,
  'planId': _FieldKind.string,
  'category': _FieldKind.string,
  'startTime': _FieldKind.nullableString,
  'endTime': _FieldKind.nullableString,
  'placeId': _FieldKind.nullableString,
  'title': _FieldKind.string,
  'memo': _FieldKind.nullableString,
  'order': _FieldKind.integer,
};
const _expenseSchema = {
  'id': _FieldKind.string,
  'title': _FieldKind.string,
  'category': _FieldKind.string,
  'expenseDate': _FieldKind.string,
  'totalAmount': _FieldKind.integer,
  'currency': _FieldKind.string,
  'payer': _FieldKind.payer,
  'consumers': _FieldKind.stringList,
  'allocationMethod': _FieldKind.string,
  'allocatedAmounts': _FieldKind.allocationList,
  'receiptItems': _FieldKind.receiptItemList,
  'source': _FieldKind.string,
  'placeId': _FieldKind.nullableString,
  'itineraryItemId': _FieldKind.nullableString,
  'memo': _FieldKind.nullableString,
};
const _payerSchema = {
  'participantId': _FieldKind.string,
  'amount': _FieldKind.integer,
};
const _allocationSchema = {
  'participantId': _FieldKind.string,
  'amount': _FieldKind.integer,
};
const _receiptItemSchema = {
  'id': _FieldKind.string,
  'kind': _FieldKind.string,
  'name': _FieldKind.string,
  'amount': _FieldKind.integer,
  'consumers': _FieldKind.stringList,
  'allocationMethod': _FieldKind.string,
  'allocatedAmounts': _FieldKind.allocationList,
  'source': _FieldKind.string,
  'sortOrder': _FieldKind.integer,
};

Map<String, Object?> _normalizePayload(Object? value) {
  final root = _object(value, r'$');
  _rejectKeys(root, const ['members', 'userProfiles', 'shareCodes'], r'$');

  final version = _integer(root['schemaVersion'], 'schemaVersion');
  if (version != TripExportPayload.currentSchemaVersion) {
    throw AppError(
      code: AppErrorCode.invalidArgument,
      message: '지원하지 않는 백업 파일 버전입니다.',
      retryable: false,
      field: 'schemaVersion',
      details: {
        'expected': TripExportPayload.currentSchemaVersion,
        'actual': version,
      },
    );
  }

  final participants = _collection(
    root['participants'],
    _participantSchema,
    'participants',
    forbidden: const ['tripId', 'linkedUid', 'createdAt', 'updatedAt'],
  )..sort(_byId);
  final places = _collection(
    root['places'],
    _placeSchema,
    'places',
    forbidden: const ['tripId', 'addedBy', 'createdAt', 'updatedAt'],
  )..sort(_byId);
  final itineraryItems = _collection(
    _list(root['itineraryItems'], 'itineraryItems').indexed.map((entry) {
      final raw = _object(entry.$2, 'itineraryItems[${entry.$1}]');
      return {
        ...raw,
        if (!raw.containsKey('planId')) 'planId': 'A',
        if (!raw.containsKey('category')) 'category': 'other',
      };
    }).toList(),
    _itinerarySchema,
    'itineraryItems',
    forbidden: const ['tripId', 'updatedBy', 'updatedAt'],
  );
  for (final entry in itineraryItems.indexed) {
    final item = entry.$2;
    if (!itineraryPlanIds.contains(item['planId'])) {
      throw _invalid('itineraryItems[${entry.$1}].planId', '일정 계획을 확인해 주세요.');
    }
    if (!itineraryCategories.contains(item['category'])) {
      throw _invalid('itineraryItems[${entry.$1}].category', '일정 유형을 확인해 주세요.');
    }
  }
  itineraryItems.sort(_byItineraryOrder);
  final expenses = _collection(
    root['expenses'],
    _expenseSchema,
    'expenses',
    forbidden: const [
      'tripId',
      'createdBy',
      'updatedBy',
      'createdAt',
      'updatedAt',
    ],
  )..sort(_byExpenseDate);

  _validateEntityIds(participants, 'participants');
  _validateEntityIds(places, 'places');
  _validateEntityIds(itineraryItems, 'itineraryItems');
  _validateEntityIds(expenses, 'expenses');
  _validateRestoreGraph(
    participants: participants,
    places: places,
    itineraryItems: itineraryItems,
    expenses: expenses,
  );

  return {
    'schemaVersion': version,
    'trip': _normalizeObject(
      root['trip'],
      _tripSchema,
      'trip',
      forbidden: const [
        'id',
        'ownerUid',
        'shareCode',
        'createdAt',
        'updatedAt',
      ],
    ),
    'participants': participants,
    'places': places,
    'itineraryItems': itineraryItems,
    'expenses': expenses,
  };
}

void _validateEntityIds(List<Map<String, Object?>> values, String path) {
  final seen = <String>{};
  for (var index = 0; index < values.length; index++) {
    final id = values[index]['id']! as String;
    if (id.trim() != id ||
        id == '.' ||
        id == '..' ||
        id.contains('/') ||
        utf8.encode(id).length > 1500 ||
        RegExp(r'^__.*__$').hasMatch(id)) {
      throw _invalid('$path[$index].id', '저장할 수 없는 entity ID입니다.');
    }
    if (!seen.add(id)) {
      throw _invalid('$path[$index].id', '같은 entity ID를 두 번 사용할 수 없습니다.');
    }
  }
}

void _validateRestoreGraph({
  required List<Map<String, Object?>> participants,
  required List<Map<String, Object?>> places,
  required List<Map<String, Object?>> itineraryItems,
  required List<Map<String, Object?>> expenses,
}) {
  final participantIds = _ids(participants);
  final placeIds = _ids(places);
  final itineraryIds = _ids(itineraryItems);

  for (var index = 0; index < itineraryItems.length; index++) {
    final placeId = itineraryItems[index]['placeId'] as String?;
    _requireReference(placeId, placeIds, 'itineraryItems[$index].placeId');
  }

  for (var index = 0; index < expenses.length; index++) {
    final expense = expenses[index];
    final path = 'expenses[$index]';
    _requireReference(expense['placeId'] as String?, placeIds, '$path.placeId');
    _requireReference(
      expense['itineraryItemId'] as String?,
      itineraryIds,
      '$path.itineraryItemId',
    );
    final payer = (expense['payer']! as Map).cast<String, Object?>();
    _requireReference(
      payer['participantId']! as String,
      participantIds,
      '$path.payer.participantId',
    );
    _validateParticipantList(
      expense['consumers']! as List,
      participantIds,
      '$path.consumers',
    );
    _validateAllocations(
      expense['allocatedAmounts']! as List,
      participantIds,
      '$path.allocatedAmounts',
    );

    final receiptItems = (expense['receiptItems']! as List)
        .map((item) => (item as Map).cast<String, Object?>())
        .toList(growable: false);
    _validateEntityIds(receiptItems, '$path.receiptItems');
    for (var itemIndex = 0; itemIndex < receiptItems.length; itemIndex++) {
      final item = receiptItems[itemIndex];
      final itemPath = '$path.receiptItems[$itemIndex]';
      _validateParticipantList(
        item['consumers']! as List,
        participantIds,
        '$itemPath.consumers',
      );
      _validateAllocations(
        item['allocatedAmounts']! as List,
        participantIds,
        '$itemPath.allocatedAmounts',
      );
    }
  }
}

Set<String> _ids(List<Map<String, Object?>> values) => {
  for (final value in values) value['id']! as String,
};

void _validateParticipantList(
  List<Object?> values,
  Set<String> participantIds,
  String path,
) {
  for (var index = 0; index < values.length; index++) {
    _requireReference(
      values[index]! as String,
      participantIds,
      '$path[$index]',
    );
  }
}

void _validateAllocations(
  List<Object?> values,
  Set<String> participantIds,
  String path,
) {
  for (var index = 0; index < values.length; index++) {
    final allocation = (values[index]! as Map).cast<String, Object?>();
    _requireReference(
      allocation['participantId']! as String,
      participantIds,
      '$path[$index].participantId',
    );
  }
}

void _requireReference(String? value, Set<String> ids, String path) {
  if (value != null && !ids.contains(value)) {
    throw _invalid(path, '백업 파일 안에서 참조 대상을 찾을 수 없습니다.');
  }
}

List<Map<String, Object?>> _collection(
  Object? value,
  Map<String, _FieldKind> schema,
  String path, {
  List<String> forbidden = const [],
}) {
  final list = _list(value, path);
  return list.indexed
      .map((entry) {
        return _normalizeObject(
          entry.$2,
          schema,
          '$path[${entry.$1}]',
          forbidden: forbidden,
        );
      })
      .toList(growable: false);
}

Map<String, Object?> _normalizeObject(
  Object? value,
  Map<String, _FieldKind> schema,
  String path, {
  List<String> forbidden = const [],
}) {
  final map = _object(value, path);
  _rejectKeys(map, forbidden, path);
  return {
    for (final field in schema.entries)
      field.key: _normalizeField(
        map[field.key],
        field.value,
        '$path.${field.key}',
      ),
  };
}

Object? _normalizeField(Object? value, _FieldKind kind, String path) {
  return switch (kind) {
    _FieldKind.string => _string(value, path),
    _FieldKind.nullableString => _nullableString(value, path),
    _FieldKind.integer => _integer(value, path),
    _FieldKind.boolean => _boolean(value, path),
    _FieldKind.nullableNumber => _nullableNumber(value, path),
    _FieldKind.stringList =>
      _list(value, path).indexed
          .map((entry) => _string(entry.$2, '$path[${entry.$1}]'))
          .toList(growable: false),
    _FieldKind.payer => _normalizeObject(value, _payerSchema, path),
    _FieldKind.allocationList => _collection(value, _allocationSchema, path),
    _FieldKind.receiptItemList => _collection(
      value,
      _receiptItemSchema,
      path,
    )..sort(_byReceiptOrder),
  };
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw _invalid(path, 'JSON 객체가 필요합니다.');
  }
  return value.cast<String, Object?>();
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) {
    throw _invalid(path, 'JSON 배열이 필요합니다.');
  }
  return value.cast<Object?>();
}

String _string(Object? value, String path) {
  if (value is! String || value.isEmpty) {
    throw _invalid(path, '비어 있지 않은 문자열이 필요합니다.');
  }
  return value;
}

String? _nullableString(Object? value, String path) {
  if (value == null) return null;
  if (value is! String) {
    throw _invalid(path, '문자열 또는 null이 필요합니다.');
  }
  return value;
}

int _integer(Object? value, String path) {
  if (value is! int) throw _invalid(path, '정수가 필요합니다.');
  return value;
}

bool _boolean(Object? value, String path) {
  if (value is! bool) throw _invalid(path, 'boolean 값이 필요합니다.');
  return value;
}

double? _nullableNumber(Object? value, String path) {
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw _invalid(path, '유한한 숫자 또는 null이 필요합니다.');
  }
  return value.toDouble();
}

void _rejectKeys(
  Map<String, Object?> map,
  List<String> forbidden,
  String path,
) {
  for (final key in forbidden) {
    if (map.containsKey(key)) {
      throw _invalid(
        path == r'$' ? key : '$path.$key',
        '새 여행 복원 파일에 포함할 수 없는 필드입니다.',
      );
    }
  }
}

int _byId(Map<String, Object?> left, Map<String, Object?> right) {
  return (left['id']! as String).compareTo(right['id']! as String);
}

int _byItineraryOrder(Map<String, Object?> left, Map<String, Object?> right) {
  final plan = (left['planId']! as String).compareTo(
    right['planId']! as String,
  );
  if (plan != 0) return plan;
  final date = (left['date']! as String).compareTo(right['date']! as String);
  if (date != 0) return date;
  final order = (left['order']! as int).compareTo(right['order']! as int);
  return order != 0 ? order : _byId(left, right);
}

int _byExpenseDate(Map<String, Object?> left, Map<String, Object?> right) {
  final date = (left['expenseDate']! as String).compareTo(
    right['expenseDate']! as String,
  );
  return date != 0 ? date : _byId(left, right);
}

int _byReceiptOrder(Map<String, Object?> left, Map<String, Object?> right) {
  final order = (left['sortOrder']! as int).compareTo(
    right['sortOrder']! as int,
  );
  return order != 0 ? order : _byId(left, right);
}

AppError _invalid(String field, String message) => AppError(
  code: AppErrorCode.invalidArgument,
  message: message,
  retryable: false,
  field: field,
);
