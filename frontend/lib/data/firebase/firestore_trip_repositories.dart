import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'firebase_error_mapper.dart';

/// [TASK-02 · Firestore repository] Widget에서 SDK를 격리하는 공통 계약 구현체입니다.
final class FirestoreTripRepositories implements TripRepositories {
  FirestoreTripRepositories(
    this._firestore, {
    required String Function() currentUid,
    // ignore: prefer_initializing_formals
  }) : _currentUid = currentUid;

  final FirebaseFirestore _firestore;
  final String Function() _currentUid;

  @override
  Stream<Trip?> watchTrip(EntityId tripId) => _mapErrors(
    _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists
              ? _trip(snapshot.id, snapshot.data() ?? const {})
              : null,
        ),
  );

  @override
  Stream<UserProfile?> watchUser(String uid) => _mapErrors(
    _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists
              ? _userProfile(snapshot.id, snapshot.data() ?? const {})
              : null,
        ),
  );

  @override
  Stream<List<TripMember>> watchMembers(EntityId tripId) => _watchCollection(
    _tripCollection(tripId, 'members'),
    (snapshot) => _tripMember(tripId, snapshot.id, snapshot.data()),
  );

  @override
  Stream<List<Participant>> watchParticipants(EntityId tripId) =>
      _watchCollection(
        _tripCollection(tripId, 'participants'),
        (snapshot) => _participant(tripId, snapshot.id, snapshot.data()),
      );

  @override
  Future<Participant> createParticipant(
    EntityId tripId,
    ParticipantDraft draft,
  ) => _guard(() async {
    final reference = _tripCollection(tripId, 'participants').doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    await reference.set({
      ..._participantDraft(draft),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Participant(
      id: reference.id,
      tripId: tripId,
      name: draft.name,
      color: draft.color,
      linkedUid: draft.linkedUid,
      isActive: draft.isActive,
      createdAt: now,
      updatedAt: now,
    );
  });

  @override
  Future<void> updateParticipant(
    EntityId tripId,
    EntityId participantId,
    ParticipantDraft draft,
  ) => _guard(
    () => _tripCollection(tripId, 'participants').doc(participantId).update({
      ..._participantDraft(draft, deleteNulls: true),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deactivateParticipant(EntityId tripId, EntityId participantId) =>
      _guard(
        () => _tripCollection(tripId, 'participants').doc(participantId).update(
          {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()},
        ),
      );

  @override
  Stream<List<Place>> watchPlaces(EntityId tripId) => _watchCollection(
    _tripCollection(tripId, 'places'),
    (snapshot) => _place(tripId, snapshot.id, snapshot.data()),
  );

  @override
  Future<Place> createPlace(EntityId tripId, PlaceDraft draft) =>
      _guard(() async {
        final reference = _tripCollection(tripId, 'places').doc();
        final now = DateTime.now().millisecondsSinceEpoch;
        final uid = _requireUid();
        await reference.set({
          ..._placeDraft(draft),
          'addedBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return Place(
          id: reference.id,
          tripId: tripId,
          name: draft.name,
          address: draft.address,
          lat: draft.lat,
          lng: draft.lng,
          provider: draft.provider,
          source: draft.source,
          providerPlaceId: draft.providerPlaceId,
          sourceUrl: draft.sourceUrl,
          addedBy: uid,
          memo: draft.memo,
          createdAt: now,
          updatedAt: now,
        );
      });

  @override
  Future<void> updatePlace(
    EntityId tripId,
    EntityId placeId,
    PlaceDraft draft,
  ) => _guard(
    () => _tripCollection(tripId, 'places').doc(placeId).update({
      ..._placeDraft(draft, deleteNulls: true),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deletePlace(EntityId tripId, EntityId placeId) =>
      _guard(() => _tripCollection(tripId, 'places').doc(placeId).delete());

  @override
  Stream<List<ItineraryItem>> watchItinerary(EntityId tripId) =>
      _watchCollection(
        _tripCollection(tripId, 'itinerary'),
        (snapshot) => _itineraryItem(tripId, snapshot.id, snapshot.data()),
      ).map((items) {
        items.sort((left, right) {
          final date = left.date.compareTo(right.date);
          if (date != 0) return date;
          final order = left.order.compareTo(right.order);
          return order != 0 ? order : left.id.compareTo(right.id);
        });
        return items;
      });

  @override
  Future<ItineraryItem> createItineraryItem(
    EntityId tripId,
    ItineraryItemDraft draft,
  ) => _guard(() async {
    final reference = _tripCollection(tripId, 'itinerary').doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _requireUid();
    await reference.set({
      ..._itineraryDraft(draft),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ItineraryItem(
      id: reference.id,
      tripId: tripId,
      date: draft.date,
      startTime: draft.startTime,
      endTime: draft.endTime,
      placeId: draft.placeId,
      title: draft.title,
      memo: draft.memo,
      order: draft.order,
      updatedBy: uid,
      updatedAt: now,
    );
  });

  @override
  Future<void> updateItineraryItem(
    EntityId tripId,
    EntityId itineraryItemId,
    ItineraryItemDraft draft,
  ) => _guard(
    () => _tripCollection(tripId, 'itinerary').doc(itineraryItemId).update({
      ..._itineraryDraft(draft, deleteNulls: true),
      'updatedBy': _requireUid(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteItineraryItem(EntityId tripId, EntityId itineraryItemId) =>
      _guard(
        () =>
            _tripCollection(tripId, 'itinerary').doc(itineraryItemId).delete(),
      );

  @override
  Stream<List<Expense>> watchExpenses(EntityId tripId) => _watchCollection(
    _tripCollection(tripId, 'expenses'),
    (snapshot) => _expense(tripId, snapshot.id, snapshot.data()),
  );

  @override
  Future<Expense> createExpense(EntityId tripId, ExpenseDraft draft) =>
      _guard(() async {
        final reference = _tripCollection(tripId, 'expenses').doc();
        final now = DateTime.now().millisecondsSinceEpoch;
        final uid = _requireUid();
        await reference.set({
          ..._expenseDraft(draft),
          'createdBy': uid,
          'updatedBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return Expense(
          id: reference.id,
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
          createdBy: uid,
          updatedBy: uid,
          createdAt: now,
          updatedAt: now,
        );
      });

  @override
  Future<void> updateExpense(
    EntityId tripId,
    EntityId expenseId,
    ExpenseDraft draft,
  ) => _guard(
    () => _tripCollection(tripId, 'expenses').doc(expenseId).update({
      ..._expenseDraft(draft, deleteNulls: true),
      'updatedBy': _requireUid(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteExpense(EntityId tripId, EntityId expenseId) =>
      _guard(() => _tripCollection(tripId, 'expenses').doc(expenseId).delete());

  CollectionReference<Map<String, dynamic>> _tripCollection(
    String tripId,
    String name,
  ) => _firestore.collection('trips').doc(tripId).collection(name);

  Stream<List<T>> _watchCollection<T>(
    CollectionReference<Map<String, dynamic>> collection,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>>) convert,
  ) => _mapErrors(
    collection.snapshots().map(
      (snapshot) => snapshot.docs.map(convert).toList(),
    ),
  );

  String _requireUid() {
    final uid = _currentUid().trim();
    if (uid.isEmpty) {
      throw const AppError(
        code: AppErrorCode.unauthenticated,
        message: '로그인 세션이 필요합니다.',
        retryable: false,
      );
    }
    return uid;
  }
}

Stream<T> _mapErrors<T>(Stream<T> source) => source.transform(
  StreamTransformer<T, T>.fromHandlers(
    handleError: (error, stackTrace, sink) {
      sink.addError(mapFirebaseError(error), stackTrace);
    },
  ),
);

Future<T> _guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error) {
    throw mapFirebaseError(error);
  }
}

Map<String, Object?> _participantDraft(
  ParticipantDraft draft, {
  bool deleteNulls = false,
}) => {
  'name': draft.name.trim(),
  if (draft.color != null)
    'color': draft.color
  else if (deleteNulls)
    'color': FieldValue.delete(),
  if (draft.linkedUid != null)
    'linkedUid': draft.linkedUid
  else if (deleteNulls)
    'linkedUid': FieldValue.delete(),
  'isActive': draft.isActive,
};

Map<String, Object?> _placeDraft(
  PlaceDraft draft, {
  bool deleteNulls = false,
}) => {
  'name': draft.name.trim(),
  if (draft.address != null)
    'address': draft.address
  else if (deleteNulls)
    'address': FieldValue.delete(),
  if (draft.lat != null)
    'lat': draft.lat
  else if (deleteNulls)
    'lat': FieldValue.delete(),
  if (draft.lng != null)
    'lng': draft.lng
  else if (deleteNulls)
    'lng': FieldValue.delete(),
  'provider': draft.provider,
  'source': draft.source,
  if (draft.providerPlaceId != null)
    'providerPlaceId': draft.providerPlaceId
  else if (deleteNulls)
    'providerPlaceId': FieldValue.delete(),
  if (draft.sourceUrl != null)
    'sourceUrl': draft.sourceUrl
  else if (deleteNulls)
    'sourceUrl': FieldValue.delete(),
  if (draft.memo != null)
    'memo': draft.memo
  else if (deleteNulls)
    'memo': FieldValue.delete(),
};

Map<String, Object?> _itineraryDraft(
  ItineraryItemDraft draft, {
  bool deleteNulls = false,
}) => {
  'date': draft.date,
  if (draft.startTime != null)
    'startTime': draft.startTime
  else if (deleteNulls)
    'startTime': FieldValue.delete(),
  if (draft.endTime != null)
    'endTime': draft.endTime
  else if (deleteNulls)
    'endTime': FieldValue.delete(),
  if (draft.placeId != null)
    'placeId': draft.placeId
  else if (deleteNulls)
    'placeId': FieldValue.delete(),
  'title': draft.title.trim(),
  if (draft.memo != null)
    'memo': draft.memo
  else if (deleteNulls)
    'memo': FieldValue.delete(),
  'order': draft.order,
};

Map<String, Object?> _expenseDraft(
  ExpenseDraft draft, {
  bool deleteNulls = false,
}) => {
  'title': draft.title.trim(),
  'category': draft.category,
  'expenseDate': draft.expenseDate,
  'totalAmount': draft.totalAmount,
  'currency': draft.currency,
  'payer': _payerJson(draft.payer),
  'consumers': draft.consumers,
  'allocationMethod': draft.allocationMethod,
  'allocatedAmounts': draft.allocatedAmounts.map(_allocationJson).toList(),
  'receiptItems': draft.receiptItems.map(_receiptItemJson).toList(),
  'source': draft.source,
  if (draft.placeId != null)
    'placeId': draft.placeId
  else if (deleteNulls)
    'placeId': FieldValue.delete(),
  if (draft.itineraryItemId != null)
    'itineraryItemId': draft.itineraryItemId
  else if (deleteNulls)
    'itineraryItemId': FieldValue.delete(),
  if (draft.memo != null)
    'memo': draft.memo
  else if (deleteNulls)
    'memo': FieldValue.delete(),
};

Map<String, Object> _payerJson(ExpensePayer payer) => {
  'participantId': payer.participantId,
  'amount': payer.amount,
};

Map<String, Object> _allocationJson(MoneyAllocation allocation) => {
  'participantId': allocation.participantId,
  'amount': allocation.amount,
};

Map<String, Object> _receiptItemJson(ReceiptItem item) => {
  'id': item.id,
  'kind': item.kind,
  'name': item.name,
  'amount': item.amount,
  'consumers': item.consumers,
  'allocationMethod': item.allocationMethod,
  'allocatedAmounts': item.allocatedAmounts.map(_allocationJson).toList(),
  'source': item.source,
  'sortOrder': item.sortOrder,
};

Trip _trip(String id, Map<String, dynamic> data) => Trip(
  id: id,
  title: _text(data, 'title'),
  countryCode: _text(data, 'countryCode'),
  timeZone: _text(data, 'timeZone'),
  mapProvider: _text(data, 'mapProvider'),
  defaultCurrency: _text(data, 'defaultCurrency'),
  startDate: _text(data, 'startDate'),
  endDate: _text(data, 'endDate'),
  ownerUid: _text(data, 'ownerUid'),
  shareCode: _text(data, 'shareCode'),
  createdAt: _epoch(data['createdAt']),
  updatedAt: _epoch(data['updatedAt']),
);

UserProfile _userProfile(String uid, Map<String, dynamic> data) => UserProfile(
  uid: uid,
  displayName: _text(data, 'displayName'),
  email: _optionalText(data['email']),
  photoUrl: _optionalText(data['photoURL']),
  authProvider: _text(data, 'authProvider'),
  createdAt: _epoch(data['createdAt']),
  updatedAt: _epoch(data['updatedAt']),
);

TripMember _tripMember(String tripId, String uid, Map<String, dynamic> data) =>
    TripMember(
      uid: uid,
      tripId: tripId,
      displayName: _text(data, 'displayName'),
      photoUrl: _optionalText(data['photoURL']),
      role: _text(data, 'role'),
      joinedAt: _epoch(data['joinedAt']),
      lastActiveAt: _epoch(data['lastActiveAt']),
    );

Participant _participant(String tripId, String id, Map<String, dynamic> data) =>
    Participant(
      id: id,
      tripId: tripId,
      name: _text(data, 'name'),
      color: _optionalText(data['color']),
      linkedUid: _optionalText(data['linkedUid']),
      isActive: data['isActive'] == true,
      createdAt: _epoch(data['createdAt']),
      updatedAt: _epoch(data['updatedAt']),
    );

Place _place(String tripId, String id, Map<String, dynamic> data) => Place(
  id: id,
  tripId: tripId,
  name: _text(data, 'name'),
  address: _optionalText(data['address']),
  lat: _number(data['lat']),
  lng: _number(data['lng']),
  provider: _text(data, 'provider'),
  source: _text(data, 'source'),
  providerPlaceId: _optionalText(data['providerPlaceId']),
  sourceUrl: _optionalText(data['sourceUrl']),
  addedBy: _text(data, 'addedBy'),
  memo: _optionalText(data['memo']),
  createdAt: _epoch(data['createdAt']),
  updatedAt: _epoch(data['updatedAt']),
);

ItineraryItem _itineraryItem(
  String tripId,
  String id,
  Map<String, dynamic> data,
) => ItineraryItem(
  id: id,
  tripId: tripId,
  date: _text(data, 'date'),
  startTime: _optionalText(data['startTime']),
  endTime: _optionalText(data['endTime']),
  placeId: _optionalText(data['placeId']),
  title: _text(data, 'title'),
  memo: _optionalText(data['memo']),
  order: _integer(data['order']),
  updatedBy: _optionalText(data['updatedBy']),
  updatedAt: _epoch(data['updatedAt']),
);

Expense _expense(String tripId, String id, Map<String, dynamic> data) =>
    Expense(
      id: id,
      tripId: tripId,
      title: _text(data, 'title'),
      category: _text(data, 'category'),
      expenseDate: _text(data, 'expenseDate'),
      totalAmount: _integer(data['totalAmount']),
      currency: _text(data, 'currency'),
      payer: _payer(_record(data['payer'])),
      consumers: _stringList(data['consumers']),
      allocationMethod: _text(data, 'allocationMethod'),
      allocatedAmounts: _recordList(data['allocatedAmounts'])
          .map(_allocation)
          .toList(),
      receiptItems: _recordList(data['receiptItems'])
          .map(_receiptItem)
          .toList(),
      source: _text(data, 'source'),
      placeId: _optionalText(data['placeId']),
      itineraryItemId: _optionalText(data['itineraryItemId']),
      memo: _optionalText(data['memo']),
      createdBy: _text(data, 'createdBy'),
      updatedBy: _text(data, 'updatedBy'),
      createdAt: _epoch(data['createdAt']),
      updatedAt: _epoch(data['updatedAt']),
    );

ExpensePayer _payer(Map<String, dynamic> data) => ExpensePayer(
  participantId: _text(data, 'participantId'),
  amount: _integer(data['amount']),
);

MoneyAllocation _allocation(Map<String, dynamic> data) => MoneyAllocation(
  participantId: _text(data, 'participantId'),
  amount: _integer(data['amount']),
);

ReceiptItem _receiptItem(Map<String, dynamic> data) => ReceiptItem(
  id: _text(data, 'id'),
  kind: _text(data, 'kind'),
  name: _text(data, 'name'),
  amount: _integer(data['amount']),
  consumers: _stringList(data['consumers']),
  allocationMethod: _text(data, 'allocationMethod'),
  allocatedAmounts: _recordList(data['allocatedAmounts'])
      .map(_allocation)
      .toList(),
  source: _text(data, 'source'),
  sortOrder: _integer(data['sortOrder']),
);

String _text(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  throw AppError(
    code: AppErrorCode.unknown,
    message: 'Firestore $key 필드 형식이 올바르지 않습니다.',
    retryable: false,
    field: key,
  );
}

String? _optionalText(Object? value) => value is String ? value : null;

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

double? _number(Object? value) => value is num ? value.toDouble() : null;

int _epoch(Object? value) => switch (value) {
  Timestamp() => value.millisecondsSinceEpoch,
  DateTime() => value.millisecondsSinceEpoch,
  int() => value,
  _ => 0,
};

Map<String, dynamic> _record(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

List<Map<String, dynamic>> _recordList(Object? value) =>
    value is List ? value.map(_record).toList() : const [];

List<String> _stringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];
