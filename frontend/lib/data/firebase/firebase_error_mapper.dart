import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models.dart';

AppError mapFirebaseError(Object error) {
  if (error case AppError()) return error;

  if (error case GoogleSignInException(:final code)) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => const AppError(
        code: AppErrorCode.conflict,
        message: '계정 연결이 취소됐습니다.',
        retryable: false,
      ),
      GoogleSignInExceptionCode.interrupted ||
      GoogleSignInExceptionCode.uiUnavailable => const AppError(
        code: AppErrorCode.unavailable,
        message: 'Google 계정 연결을 진행할 수 없습니다.',
        retryable: true,
      ),
      _ => const AppError(
        code: AppErrorCode.unknown,
        message: 'Google 계정 연결에 실패했습니다.',
        retryable: false,
      ),
    };
  }

  if (error case FirebaseException(:final code, :final message)) {
    final normalized = code.replaceFirst('functions/', '');
    final firebaseAppCode = switch (normalized) {
      'unauthenticated' => AppErrorCode.unauthenticated,
      'permission-denied' => AppErrorCode.permissionDenied,
      'invalid-argument' => AppErrorCode.invalidArgument,
      'not-found' => AppErrorCode.notFound,
      'already-exists' ||
      'aborted' ||
      'failed-precondition' ||
      'account-exists-with-different-credential' ||
      'credential-already-in-use' => AppErrorCode.conflict,
      'resource-exhausted' => AppErrorCode.resourceExhausted,
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppErrorCode.unavailable,
      _ => AppErrorCode.unknown,
    };
    final callableDetails = error is FirebaseFunctionsException
        ? error.details
        : null;
    final details = callableDetails is Map
        ? Map<String, Object?>.from(callableDetails)
        : const <String, Object?>{};
    final appCode =
        _appErrorCodeFromWire(details['appCode']) ?? firebaseAppCode;
    final retryable = details['retryable'] is bool
        ? details['retryable']! as bool
        : _defaultRetryable(appCode);
    return AppError(
      code: appCode,
      message: (message == null || message.trim().isEmpty)
          ? _fallbackMessage(appCode)
          : message,
      retryable: retryable,
      field: details['field'] is String ? details['field'] as String : null,
      details: details,
    );
  }

  return const AppError(
    code: AppErrorCode.unknown,
    message: '예상하지 못한 오류가 발생했습니다.',
    retryable: false,
  );
}

String _fallbackMessage(AppErrorCode code) => switch (code) {
  AppErrorCode.unauthenticated => '로그인 세션이 필요합니다.',
  AppErrorCode.permissionDenied => '이 작업을 수행할 권한이 없습니다.',
  AppErrorCode.invalidArgument => '입력값을 확인해 주세요.',
  AppErrorCode.notFound => '요청한 데이터를 찾을 수 없습니다.',
  AppErrorCode.conflict => '현재 상태에서 요청을 처리할 수 없습니다.',
  AppErrorCode.resourceExhausted => '잠시 후 다시 시도해 주세요.',
  AppErrorCode.unavailable => '서비스에 연결할 수 없습니다.',
  AppErrorCode.invalidImage => '지원하는 영수증 이미지를 선택해 주세요.',
  AppErrorCode.payloadTooLarge => '이미지 크기를 줄여 다시 시도해 주세요.',
  AppErrorCode.ocrUnavailable => '영수증 인식을 잠시 사용할 수 없습니다.',
  AppErrorCode.ocrNoResult => '영수증에서 항목을 찾지 못했습니다.',
  _ => '예상하지 못한 오류가 발생했습니다.',
};

AppErrorCode? _appErrorCodeFromWire(Object? value) {
  if (value is! String) return null;
  for (final code in AppErrorCode.values) {
    if (code.wireValue == value) return code;
  }
  return null;
}

bool _defaultRetryable(AppErrorCode code) => switch (code) {
  AppErrorCode.unavailable ||
  AppErrorCode.resourceExhausted ||
  AppErrorCode.ocrUnavailable => true,
  _ => false,
};
