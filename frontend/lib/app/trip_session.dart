import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';

/// [TASK-01 · 여행 세션] repository stream을 화면용 상태로만 조립합니다.
final class TripSessionController extends ChangeNotifier {
  TripSessionController({required this.tripId, required this.repositories});

  final EntityId tripId;
  final TripRepositories repositories;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Trip? trip;
  List<Participant> participants = const [];
  List<Place> places = const [];
  List<ItineraryItem> itinerary = const [];
  List<Expense> expenses = const [];
  AppError? error;
  bool _disposed = false;

  bool get isLoading => trip == null && error == null;

  void start() {
    _subscriptions
      ..add(
        repositories.watchTrip(tripId).listen((value) {
          if (value == null) {
            _setError(
              const AppError(
                code: AppErrorCode.notFound,
                message: '여행을 찾을 수 없습니다.',
                retryable: false,
              ),
            );
            return;
          }
          trip = value;
          _notify();
        }, onError: _setError),
      )
      ..add(
        repositories.watchParticipants(tripId).listen((value) {
          participants = value;
          _notify();
        }, onError: _setError),
      )
      ..add(
        repositories.watchPlaces(tripId).listen((value) {
          places = value;
          _notify();
        }, onError: _setError),
      )
      ..add(
        repositories.watchItinerary(tripId).listen((value) {
          itinerary = value;
          _notify();
        }, onError: _setError),
      )
      ..add(
        repositories.watchExpenses(tripId).listen((value) {
          expenses = value;
          _notify();
        }, onError: _setError),
      );
  }

  void _setError(Object value) {
    error = value is AppError
        ? value
        : AppError(
            code: AppErrorCode.unknown,
            message: '여행 데이터를 불러오지 못했습니다.',
            retryable: true,
            details: {'cause': value.toString()},
          );
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
