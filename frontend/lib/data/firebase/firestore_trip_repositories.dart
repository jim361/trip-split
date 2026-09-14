import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../domain/preparation.dart';
import 'firebase_error_mapper.dart';

/// [TASK-02 · Firestore repository] Widget에서 SDK를 격리하는 공통 계약 구현체입니다.
final class FirestoreTripRepositories
    implements TripRepositories, TripSyncRepository {
  FirestoreTripRepositories(
    this._firestore, {
    required String Function() currentUid,
    FirebaseFunctions? functions,
    // ignore: prefer_initializing_formals
  }) : _currentUid = currentUid,
       // ignore: prefer_initializing_formals
       _functions = functions;

  final FirebaseFirestore _firestore;
  final String Function() _currentUid;
  final FirebaseFunctions? _functions;

  @override
  Future<TripDataSnapshot> loadTripSnapshot(String tripId) => _guard(() async {
    const options = GetOptions(source: Source.server);
    final values = await Future.wait<Object>([
      _firestore.doc('trips/$tripId').get(options),
      for (final name in ['participants', 'places', 'itinerary', 'expenses'])
        _tripCollection(tripId, name).get(options),
    ]).timeout(const Duration(seconds: 30));
    final trip = values[0] as DocumentSnapshot<Map<String, dynamic>>;
    final metadata = [
      trip.metadata,
      for (final value in values.skip(1))
        (value as QuerySnapshot<Map<String, dynamic>>).metadata,
    ];
    if (metadata.any((m) => m.isFromCache || m.hasPendingWrites)) {
      throw const AppError(
        code: AppErrorCode.unavailable,
        message: '저장 중인 변경이 있습니다. 서버 반영 후 보고서를 다시 불러와 주세요.',
        retryable: true,
      );
    }
    if (!trip.exists) {
      throw const AppError(
        code: AppErrorCode.notFound,
        message: '여행을 찾을 수 없습니다.',
        retryable: false,
      );
    }
    List<T> rows<T>(
      int index,
      T Function(String, String, Map<String, dynamic>) convert,
    ) => (values[index] as QuerySnapshot<Map<String, dynamic>>).docs
        .map((doc) => convert(tripId, doc.id, doc.data()))
        .toList();
    return TripDataSnapshot(
      trip: _trip(trip.id, trip.data()!),
      capturedAt: DateTime.now().toUtc(),
      participants: rows(1, _participant),
      places: rows(2, _place),
      itinerary: rows(3, itineraryItemFromFirestore),
      expenses: rows(4, _expense),
    );
  });

  @override
  Stream<TripSyncState> watchSyncState(String tripId) {
    final states = <int, SnapshotMetadata>{};
    final subscriptions = <StreamSubscription<Object?>>[];
    late StreamController<TripSyncState> controller;
    void update(int index, SnapshotMetadata metadata) {
      states[index] = metadata;
      controller.add(
        states.values.any((m) => m.hasPendingWrites)
            ? TripSyncState.pending
            : states.length < 8
            ? TripSyncState.loading
            : states.values.any((m) => m.isFromCache)
            ? TripSyncState.cached
            : TripSyncState.synced,
      );
    }

    controller = StreamController<TripSyncState>(
      onListen: () {
        subscriptions.add(
          _firestore
              .doc('trips/$tripId')
              .snapshots(includeMetadataChanges: true)
              .listen(
                (s) => update(0, s.metadata),
                onError: controller.addError,
              ),
        );
        const names = [
          'members',
          'participants',
          'places',
          'itinerary',
          'expenses',
          'reservations',
          'checklistItems',
        ];
        for (final entry in names.indexed) {
          subscriptions.add(
            _tripCollection(tripId, entry.$2)
                .snapshots(includeMetadataChanges: true)
                .listen(
                  (s) => update(entry.$1 + 1, s.metadata),
                  onError: controller.addError,
                ),
          );
        }
      },
      onCancel: () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
      },
    );
    return _mapErrors(controller.stream.distinct());
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, Object?> input) =>
      _guard(() async {
        final functions = _functions;
        if (functions == null) {
          throw const AppError(
            code: AppErrorCode.unavailable,
            message: '서버 연결 설정을 확인해 주세요.',
            retryable: false,
          );
        }
        final result = await functions.httpsCallable(name).call<Object?>(input);
        if (result.data is! Map) throw const FormatException('Callable 응답 형식');
        return Map<String, dynamic>.from(result.data as Map);
      });
  @override
  Future<List<Trip>> listMyTrips() async {
    final response = await _call('listMyTrips', {});
    return (response['trips'] as List).map((value) {
      final data = Map<String, dynamic>.from(value as Map);
      return _trip(data['id'] as String, data);
    }).toList();
  }

  @override
  Future<void> updateTrip(String tripId, TripUpdate draft) => _guard(
    () => _firestore.doc('trips/$tripId').update({
      ...draft.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );
  @override
  Future<void> linkMyParticipant(String tripId, String? participantId) async {
    await _call('linkMyParticipant', {
      'tripId': tripId,
      'participantId': participantId,
    });
  }

  @override
  Stream<List<Reservation>> watchReservations(String tripId) =>
      _watchCollection(_tripCollection(tripId, 'reservations'), (snapshot) {
        final data = snapshot.data();
        return Reservation(
          id: snapshot.id,
          tripId: tripId,
          draft: ReservationDraft.fromJson(data),
          createdAt: _epoch(data['createdAt']),
          updatedAt: _epoch(data['updatedAt']),
          createdBy: data['createdBy'] as String,
          updatedBy: data['updatedBy'] as String,
        );
      });
  @override
  Stream<List<ChecklistItem>> watchChecklist(String tripId) =>
      _watchCollection(_tripCollection(tripId, 'checklistItems'), (snapshot) {
        final data = snapshot.data();
        return ChecklistItem(
          id: snapshot.id,
          tripId: tripId,
          draft: ChecklistDraft.fromJson(data),
          createdAt: _epoch(data['createdAt']),
          updatedAt: _epoch(data['updatedAt']),
          createdBy: data['createdBy'] as String,
          updatedBy: data['updatedBy'] as String,
        );
      });
  @override
  Future<String> saveReservation(
    String tripId,
    ReservationDraft draft, {
    String? id,
  }) => _savePreparation(tripId, 'reservations', draft.toJson(), id: id);
  @override
  Future<String> saveChecklist(
    String tripId,
    ChecklistDraft draft, {
    String? id,
  }) => _savePreparation(tripId, 'checklistItems', draft.toJson(), id: id);

  Future<String> _savePreparation(
    String tripId,
    String collection,
    Map<String, Object> data, {
    String? id,
  }) => _guard(() async {
    final ref = _tripCollection(tripId, collection).doc(id);
    final uid = _requireUid();
    final itineraryItemId = collection == 'reservations'
        ? _optionalText(data['itineraryItemId'])
        : null;
    if (id == null && itineraryItemId == null) {
      await ref.set({
        ...data,
        'createdBy': uid,
        'updatedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.runTransaction((transaction) async {
        final trip = collection == 'reservations'
            ? await transaction.get(_firestore.doc('trips/$tripId'))
            : null;
        DocumentSnapshot<Map<String, dynamic>>? old;
        String? previousItineraryItemId;
        if (id != null) {
          old = await transaction.get(ref);
          if (!old.exists) {
            throw const AppError(
              code: AppErrorCode.notFound,
              message: '이미 삭제된 준비 항목입니다.',
              retryable: false,
            );
          }
          previousItineraryItemId = _optionalText(old.data()!['itineraryItemId']);
        }
        if (previousItineraryItemId != itineraryItemId) {
          if (itineraryItemId != null) {
            await _requireReferenceTarget(
              transaction,
              _tripCollection(tripId, 'itinerary').doc(itineraryItemId),
              'itineraryItemId',
            );
          }
          transaction.update(trip!.reference, _referenceVersionUpdate(trip));
        }
        transaction.set(ref, {
          ...data,
          if (old != null) 'createdBy': old.data()!['createdBy'] else 'createdBy': uid,
          if (old != null)
            'createdAt': old.data()!['createdAt']
          else
            'createdAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
    return ref.id;
  });
  @override
  Future<void> setChecklistCompleted(
    String tripId,
    String id,
    bool completed,
  ) => _guard(
    () => _tripCollection(tripId, 'checklistItems').doc(id).update({
      'isDone': completed,
      'updatedBy': _requireUid(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );
  @override
  Future<void> deleteReservation(String tripId, String id) => _guard(() async {
    final ref = _tripCollection(tripId, 'reservations').doc(id);
    await _firestore.runTransaction((transaction) async {
      final trip = await transaction.get(_firestore.doc('trips/$tripId'));
      final old = await transaction.get(ref);
      if (!old.exists) return;
      if (_optionalText(old.data()!['itineraryItemId']) != null) {
        transaction.update(trip.reference, _referenceVersionUpdate(trip));
      }
      transaction.delete(ref);
    });
  });
  @override
  Future<void> deleteChecklist(String tripId, String id) =>
      _guard(() => _tripCollection(tripId, 'checklistItems').doc(id).delete());

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
    _rejectDirectParticipantLink(draft);
    draft.validate();
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
      linkedUid: null,
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
  ) => _guard(() {
    _rejectDirectParticipantLink(draft);
    draft.validate();
    return _tripCollection(tripId, 'participants').doc(participantId).update({
      ..._participantDraft(draft, deleteNulls: true),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

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
  Future<void> deletePlace(EntityId tripId, EntityId placeId) async {
    await _call('deletePlace', {'tripId': tripId, 'placeId': placeId});
  }

  @override
  Stream<List<ItineraryItem>> watchItinerary(EntityId tripId) =>
      _watchCollection(
        _tripCollection(tripId, 'itinerary'),
        (snapshot) =>
            itineraryItemFromFirestore(tripId, snapshot.id, snapshot.data()),
      ).map((items) {
        items.sort((left, right) {
          final plan = left.planId.compareTo(right.planId);
          if (plan != 0) return plan;
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
    final data = {
      ..._itineraryDraft(draft),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (draft.placeId == null) {
      await reference.set(data);
    } else {
      await _firestore.runTransaction((transaction) async {
        final trip = await transaction.get(_firestore.doc('trips/$tripId'));
        await _requireReferenceTarget(
          transaction,
          _tripCollection(tripId, 'places').doc(draft.placeId),
          'placeId',
        );
        transaction.update(trip.reference, _referenceVersionUpdate(trip));
        transaction.set(reference, data);
      });
    }
    return ItineraryItem(
      id: reference.id,
      tripId: tripId,
      date: draft.date,
      planId: draft.planId,
      category: draft.category,
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
  ) => _guard(() async {
    final reference = _tripCollection(tripId, 'itinerary').doc(itineraryItemId);
    final uid = _requireUid();
    await _firestore.runTransaction((transaction) async {
      final trip = await transaction.get(_firestore.doc('trips/$tripId'));
      final old = await transaction.get(reference);
      if (!old.exists) {
        throw const AppError(
          code: AppErrorCode.notFound,
          message: '이미 삭제된 일정입니다.',
          retryable: false,
        );
      }
      if (_optionalText(old.data()!['placeId']) != draft.placeId) {
        if (draft.placeId != null) {
          await _requireReferenceTarget(
            transaction,
            _tripCollection(tripId, 'places').doc(draft.placeId),
            'placeId',
          );
        }
        transaction.update(trip.reference, _referenceVersionUpdate(trip));
      }
      transaction.update(reference, {
        ..._itineraryDraft(draft, deleteNulls: true),
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  });

  @override
  Future<void> deleteItineraryItem(
    EntityId tripId,
    EntityId itineraryItemId,
  ) async {
    await _call('deleteItineraryItem', {
      'tripId': tripId,
      'itineraryItemId': itineraryItemId,
    });
  }

  @override
  Future<void> reorderItineraryItems(
    EntityId tripId,
    ItineraryOrderDraft draft,
  ) => _guard(() async {
    final uid = _requireUid();
    final references = [
      for (final id in draft.itemIds)
        _tripCollection(tripId, 'itinerary').doc(id),
    ];
    // 이동·삭제와 경합하면 재조회한 뒤 거부한다. 일부 순서만 저장하지 않는다.
    try {
      await _firestore.runTransaction((transaction) async {
        for (final reference in references) {
          final snapshot = await transaction.get(reference);
          final data = snapshot.data();
          if (data == null) {
            throw const AppError(
              code: AppErrorCode.notFound,
              message: '삭제된 일정이 있습니다. 목록을 확인하고 다시 시도해 주세요.',
              retryable: false,
            );
          }
          draft.checkItem(itineraryItemFromFirestore(tripId, snapshot.id, data));
        }
        for (final (order, reference) in references.indexed) {
          transaction.update(reference, {
            'order': order,
            'updatedBy': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (error) {
      if (mapFirebaseError(error).code != AppErrorCode.permissionDenied) {
        rethrow;
      }
      await _classifyReorderPermissionDenied(tripId, draft, references, error);
    }
  });

  @override
  Stream<List<Expense>> watchExpenses(EntityId tripId) =>
      _watchCollection(
        _tripCollection(tripId, 'expenses'),
        (snapshot) => _expense(tripId, snapshot.id, snapshot.data()),
      ).map(
        (expenses) => [...expenses]
          ..sort((left, right) {
            final byDate = left.expenseDate.compareTo(right.expenseDate);
            return byDate != 0 ? byDate : left.id.compareTo(right.id);
          }),
      );

  @override
  Future<Expense> createExpense(EntityId tripId, ExpenseDraft draft) async {
    final result = await _call('createExpense', {
      'tripId': tripId,
      'draft': _expenseDraft(draft),
    });
    final expense = Map<String, dynamic>.from(result['expense'] as Map);
    return _expense(tripId, expense['id'] as String, expense);
  }

  @override
  Future<void> updateExpense(
    EntityId tripId,
    EntityId expenseId,
    ExpenseDraft draft,
  ) async {
    await _call('updateExpense', {
      'tripId': tripId,
      'expenseId': expenseId,
      'draft': _expenseDraft(draft),
    });
  }

  @override
  Future<void> deleteExpense(EntityId tripId, EntityId expenseId) async {
    await _call('deleteExpense', {'tripId': tripId, 'expenseId': expenseId});
  }

  CollectionReference<Map<String, dynamic>> _tripCollection(
    String tripId,
    String name,
  ) => _firestore.collection('trips').doc(tripId).collection(name);

  Future<void> _requireReferenceTarget(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> target,
    String field,
  ) async {
    if ((await transaction.get(target)).exists) return;
    throw AppError(
      code: AppErrorCode.notFound,
      message: '연결할 항목을 찾을 수 없습니다. 다시 선택해 주세요.',
      retryable: false,
      field: field,
    );
  }

  Map<String, Object?> _referenceVersionUpdate(
    DocumentSnapshot<Map<String, dynamic>> trip,
  ) {
    if (!trip.exists) {
      throw const AppError(
        code: AppErrorCode.notFound,
        message: '여행을 찾을 수 없습니다.',
        retryable: false,
      );
    }
    final data = trip.data()!;
    final version = data.containsKey('referenceVersion')
        ? data['referenceVersion']
        : 0;
    if (version is! int || version < 0 || version >= 9007199254740991) {
      throw const AppError(
        code: AppErrorCode.conflict,
        message: '여행의 참조 버전을 확인해 주세요.',
        retryable: false,
        field: 'referenceVersion',
      );
    }
    // ponytail: 여행 하나의 참조 쓰기를 직렬화한다. 실제 경합이 커지면 대상별 버전으로 분리한다.
    return {
      'referenceVersion': version + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _classifyReorderPermissionDenied(
    String tripId,
    ItineraryOrderDraft draft,
    List<DocumentReference<Map<String, dynamic>>> references,
    Object originalError,
  ) => classifyReorderPermissionDenied(
    draft: draft,
    originalError: originalError,
    reload: () async {
      final snapshots = await Future.wait(
        references.map(
          (reference) => reference.get(const GetOptions(source: Source.server)),
        ),
      );
      return [
        for (final snapshot in snapshots)
          switch (snapshot.data()) {
            final data? => itineraryItemFromFirestore(tripId, snapshot.id, data),
            null => null,
          },
      ];
    },
  );

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

/// 재조회 실패는 원래 permission-denied를 유지하고, 확인된 상태만 분류합니다.
Future<void> classifyReorderPermissionDenied({
  required ItineraryOrderDraft draft,
  required Object originalError,
  required Future<List<ItineraryItem?>> Function() reload,
}) async {
  late final List<ItineraryItem?> items;
  try {
    items = await reload();
  } catch (_) {
    throw originalError;
  }
  for (final item in items) {
    if (item == null) {
      throw const AppError(
        code: AppErrorCode.notFound,
        message: '삭제된 일정이 있습니다. 목록을 확인하고 다시 시도해 주세요.',
        retryable: false,
      );
    }
    draft.checkItem(item);
  }
  throw originalError;
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
  'isActive': draft.isActive,
};

void _rejectDirectParticipantLink(ParticipantDraft draft) {
  if (draft.linkedUid == null) return;
  throw const AppError(
    code: AppErrorCode.invalidArgument,
    message: '계정과 정산 인원 연결은 전용 서버 작업으로 처리해야 합니다.',
    retryable: false,
    field: 'linkedUid',
  );
}

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
  'planId': draft.planId,
  'category': draft.category,
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

ItineraryItem itineraryItemFromFirestore(
  String tripId,
  String id,
  Map<String, dynamic> data,
) => ItineraryItem(
  id: id,
  tripId: tripId,
  date: _text(data, 'date'),
  planId: _optionalEnum(data, 'planId', itineraryPlanIds, 'A'),
  category: _optionalEnum(data, 'category', itineraryCategories, 'other'),
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

String _optionalEnum(
  Map<String, dynamic> data,
  String key,
  List<String> allowed,
  String fallback,
) {
  if (!data.containsKey(key)) return fallback;
  final value = _text(data, key);
  if (allowed.contains(value)) return value;
  throw AppError(
    code: AppErrorCode.unknown,
    message: 'Firestore $key 필드 값이 올바르지 않습니다.',
    retryable: false,
    field: key,
  );
}

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
