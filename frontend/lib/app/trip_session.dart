import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';

/// [TASK-01] repository stream과 오류 복구를 화면 상태로 조립합니다.
final class TripSessionController extends ChangeNotifier {
  TripSessionController({required this.tripId, required this.repositories});
  final EntityId tripId;
  final TripRepositories repositories;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final _errors = <String, AppError>{};
  final _loaded = <String>{};
  bool _disposed = false;
  bool _restarting = false;

  Trip? trip;
  List<TripMember> members = const [];
  List<Participant> participants = const [];
  List<Place> places = const [];
  List<ItineraryItem> itinerary = const [];
  List<Expense> expenses = const [];
  TripSyncState? syncState;
  AppError? get error => _errors.values.firstOrNull;
  bool get isLoading => error == null && _loaded.length < 6;

  void start() {
    if (_disposed || _subscriptions.isNotEmpty) return;
    _listen('trip', repositories.watchTrip(tripId), (value) {
      if (value == null) {
        throw const AppError(
          code: AppErrorCode.notFound,
          message: '여행을 찾을 수 없습니다.',
          retryable: false,
        );
      }
      trip = value;
    });
    _listen(
      'members',
      repositories.watchMembers(tripId),
      (value) => members = value,
    );
    _listen(
      'participants',
      repositories.watchParticipants(tripId),
      (value) => participants = value,
    );
    _listen(
      'places',
      repositories.watchPlaces(tripId),
      (value) => places = value,
    );
    _listen(
      'itinerary',
      repositories.watchItinerary(tripId),
      (value) => itinerary = value,
    );
    _listen(
      'expenses',
      repositories.watchExpenses(tripId),
      (value) => expenses = value,
    );
    if (repositories case final TripSyncRepository sync) {
      _listen(
        'sync',
        sync.watchSyncState(tripId),
        (value) => syncState = value,
        countLoaded: false,
      );
    }
  }

  void _listen<T>(
    String key,
    Stream<T> stream,
    void Function(T) update, {
    bool countLoaded = true,
  }) {
    void onError(Object value) {
      _errors[key] = value is AppError
          ? value
          : const AppError(
              code: AppErrorCode.unknown,
              message: '여행 데이터를 불러오지 못했습니다.',
              retryable: true,
            );
      _notify();
    }

    _subscriptions.add(
      stream.listen((value) {
        if (_disposed) return;
        try {
          update(value);
          _errors.remove(key);
          if (countLoaded) _loaded.add(key);
          _notify();
        } catch (error) {
          onError(error);
        }
      }, onError: onError),
    );
  }

  Future<void> retry() async {
    if (_disposed || _restarting) return;
    _restarting = true;
    await Future.wait(_subscriptions.map((s) => s.cancel()));
    _subscriptions.clear();
    _errors.clear();
    _loaded.clear();
    syncState = null;
    _restarting = false;
    start();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
