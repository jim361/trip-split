import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trip_split/data/firebase/firebase_error_mapper.dart';
import 'package:trip_split/domain/models.dart';

void main() {
  test('Firebase unavailable 오류를 재시도 가능 AppError로 변환한다', () {
    final mapped = mapFirebaseError(
      FirebaseException(plugin: 'functions', code: 'unavailable'),
    );

    expect(mapped.code, AppErrorCode.unavailable);
    expect(mapped.retryable, isTrue);
  });

  test('Google 계정 선택 취소를 재시도 오류로 오인하지 않는다', () {
    final mapped = mapFirebaseError(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    expect(mapped.code, AppErrorCode.conflict);
    expect(mapped.retryable, isFalse);
  });

  test('Callable details의 field를 AppError에 보존한다', () {
    final mapped = mapFirebaseError(
      _TestFunctionsException(details: const {'field': 'participantNames'}),
    );

    expect(mapped.code, AppErrorCode.invalidArgument);
    expect(mapped.field, 'participantNames');
    expect(mapped.details, {'field': 'participantNames'});
  });
}

final class _TestFunctionsException extends FirebaseFunctionsException {
  _TestFunctionsException({required super.details})
    : super(code: 'invalid-argument', message: '입력값 오류');
}
