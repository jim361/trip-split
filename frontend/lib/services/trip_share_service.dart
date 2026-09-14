import 'package:cloud_functions/cloud_functions.dart';

import '../data/firebase/firebase_error_mapper.dart';
import '../data/mock/in_memory_trip_repositories.dart';
import '../domain/models.dart';

final class CreateTripCommand {
  CreateTripCommand({
    required this.title,
    required this.countryCode,
    required this.timeZone,
    required this.mapProvider,
    required this.defaultCurrency,
    required this.startDate,
    required this.endDate,
    required List<String> participantNames,
    this.displayName,
  }) : participantNames = List.unmodifiable(participantNames);

  final String title;
  final String countryCode;
  final String timeZone;
  final String mapProvider;
  final String defaultCurrency;
  final String startDate;
  final String endDate;
  final List<String> participantNames;
  final String? displayName;

  Map<String, Object?> toJson() => {
    'title': title,
    'countryCode': countryCode,
    'timeZone': timeZone,
    'mapProvider': mapProvider,
    'defaultCurrency': defaultCurrency,
    'startDate': startDate,
    'endDate': endDate,
    'participantNames': participantNames,
    'displayName': ?displayName,
  };
}

final class CreateTripResult {
  const CreateTripResult({required this.tripId, required this.shareCode});

  final String tripId;
  final String shareCode;
}

final class JoinTripResult {
  const JoinTripResult({
    required this.tripId,
    required this.title,
    required this.shareCode,
  });

  final String tripId;
  final String title;
  final String shareCode;
}

abstract interface class TripShareService {
  Future<CreateTripResult> createTrip(CreateTripCommand command);

  Future<CreateTripResult> createShareCode(String tripId);

  Future<JoinTripResult> joinTrip(String shareCode, {String? displayName});
}

final class FirebaseTripShareService implements TripShareService {
  const FirebaseTripShareService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<CreateTripResult> createTrip(CreateTripCommand command) async {
    final data = await _call('createTrip', command.toJson());
    return CreateTripResult(
      tripId: _requiredResultString(data, 'tripId'),
      shareCode: _requiredResultString(data, 'shareCode'),
    );
  }

  @override
  Future<CreateTripResult> createShareCode(String tripId) async {
    final data = await _call('createShareCode', {'tripId': tripId});
    return CreateTripResult(
      tripId: _requiredResultString(data, 'tripId'),
      shareCode: _requiredResultString(data, 'shareCode'),
    );
  }

  @override
  Future<JoinTripResult> joinTrip(
    String shareCode, {
    String? displayName,
  }) async {
    final data = await _call('joinTrip', {
      'shareCode': shareCode,
      'displayName': ?displayName,
    });
    return JoinTripResult(
      tripId: _requiredResultString(data, 'tripId'),
      title: _requiredResultString(data, 'title'),
      shareCode: _requiredResultString(data, 'shareCode'),
    );
  }

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, Object?> input,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(input);
      final data = result.data;
      if (data is! Map) {
        throw const AppError(
          code: AppErrorCode.unknown,
          message: '서버 응답 형식을 확인할 수 없습니다.',
          retryable: false,
        );
      }
      return data.cast<Object?, Object?>();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

final class MockTripShareService implements TripShareService {
  const MockTripShareService(this._store);

  final InMemoryTripRepositories _store;

  @override
  Future<CreateTripResult> createTrip(CreateTripCommand command) async {
    _validateCreateTrip(command);
    final trip = await _store.createTripSession(
      title: command.title,
      countryCode: command.countryCode.trim().toUpperCase(),
      timeZone: command.timeZone.trim(),
      mapProvider: command.mapProvider,
      defaultCurrency: command.defaultCurrency.trim().toUpperCase(),
      startDate: command.startDate,
      endDate: command.endDate,
      participantNames: command.participantNames,
      displayName: command.displayName,
    );
    return CreateTripResult(tripId: trip.id, shareCode: trip.shareCode);
  }

  @override
  Future<CreateTripResult> createShareCode(String tripId) async {
    if (tripId.trim().isEmpty) {
      throw _invalidArgument('여행 ID를 확인해 주세요.', 'tripId');
    }
    final trip = await _store.regenerateShareCode(tripId.trim());
    return CreateTripResult(tripId: trip.id, shareCode: trip.shareCode);
  }

  @override
  Future<JoinTripResult> joinTrip(
    String shareCode, {
    String? displayName,
  }) async {
    final trip = await _store.joinTripSession(
      shareCode,
      displayName: displayName,
    );
    return JoinTripResult(
      tripId: trip.id,
      title: trip.title,
      shareCode: trip.shareCode,
    );
  }
}

void _validateCreateTrip(CreateTripCommand command) {
  final title = command.title.trim();
  if (title.isEmpty || title.length > 80) {
    throw _invalidArgument('여행 이름은 1자부터 80자까지 입력해 주세요.', 'title');
  }
  final start = _parseLocalDate(command.startDate, 'startDate');
  final end = _parseLocalDate(command.endDate, 'endDate');
  if (start.isAfter(end)) {
    throw _invalidArgument('종료일은 시작일보다 빠를 수 없습니다.', 'endDate');
  }
  if (!RegExp(r'^[A-Z]{2}$')
      .hasMatch(command.countryCode.trim().toUpperCase())) {
    throw _invalidArgument('국가 코드를 확인해 주세요.', 'countryCode');
  }
  if (!const {
    'KRW',
    'JPY',
  }.contains(command.defaultCurrency.trim().toUpperCase())) {
    throw _invalidArgument('통화 코드를 확인해 주세요.', 'defaultCurrency');
  }
  if (command.timeZone.trim().isEmpty) {
    throw _invalidArgument('time zone을 확인해 주세요.', 'timeZone');
  }
  if (command.mapProvider != 'google' && command.mapProvider != 'naver') {
    throw _invalidArgument('지도 provider를 확인해 주세요.', 'mapProvider');
  }
  if (command.participantNames.isEmpty ||
      command.participantNames.length > 20) {
    throw _invalidArgument('정산 인원은 1명부터 20명까지 설정할 수 있습니다.', 'participantNames');
  }
  if (command.participantNames.any(
    (name) => name.trim().isEmpty || name.trim().length > 80,
  )) {
    throw _invalidArgument('참여자 이름은 1자부터 80자까지 입력해 주세요.', 'participantNames');
  }
}

DateTime _parseLocalDate(String value, String field) {
  final parsed = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      parsed == null ||
      parsed.toIso8601String().substring(0, 10) != value) {
    throw _invalidArgument('여행 날짜 형식을 확인해 주세요.', field);
  }
  return parsed;
}

String _requiredResultString(Map<Object?, Object?> data, String field) {
  final value = data[field];
  if (value is String && value.isNotEmpty) return value;
  throw AppError(
    code: AppErrorCode.unknown,
    message: '서버 응답에 $field가 없습니다.',
    retryable: false,
  );
}

AppError _invalidArgument(String message, String field) => AppError(
  code: AppErrorCode.invalidArgument,
  message: message,
  retryable: false,
  field: field,
);
