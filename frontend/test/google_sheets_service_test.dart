import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/sheets/google_sheets_service.dart';
import 'package:trip_split/features/sheets/trip_sheet_report.dart';

void main() {
  final report = TripSheetReport(
    title: '보고서',
    capturedAt: DateTime.utc(2026),
    sheets: [
      ReportSheet(
        '일정',
        [
          [const ReportCell('제목')],
        ],
        const [200],
      ),
    ],
  );
  test('OAuth 취소는 문서를 만들지 않고 중복 제출은 차단한다', () async {
    final fake = _Fake();
    final gate = Completer<String>();
    final service = fake.service(authorize: () => gate.future);
    final first = service.create(report);
    await expectLater(service.create(report), throwsA(isA<AppError>()));
    gate.completeError(
      const AppError(
        code: AppErrorCode.permissionDenied,
        message: '취소',
        retryable: false,
      ),
    );
    await expectLater(first, throwsA(isA<AppError>()));
    expect(fake.paths, isEmpty);
    expect(fake.saved, isNull);
  });
  test('생성 응답 유실은 재시작 뒤에도 자동 재생성하지 않는다', () async {
    final fake = _Fake()..failCreate = true;
    final first = fake.service();
    await expectLater(first.create(report), throwsA(isA<AppError>()));
    expect(first.creationUncertain, isTrue);
    final restarted = fake.service();
    await restarted.restore();
    expect(restarted.creationUncertain, isTrue);
    await expectLater(restarted.create(report), throwsA(isA<AppError>()));
    expect(fake.paths, ['/v4/spreadsheets']);
  });
  test('내용 쓰기 실패는 ID와 사본을 보존하고 같은 문서만 복구한다', () async {
    final fake = _Fake()..writeStatus = 503;
    final first = fake.service();
    await expectLater(first.create(report), throwsA(isA<AppError>()));
    expect(first.spreadsheetId, 'sheet-123');
    expect(fake.saved, contains('제목'));
    final restarted = fake.service();
    await restarted.restore();
    fake.writeStatus = 200;
    await restarted.retryWrite();
    expect(restarted.complete, isTrue);
    expect(
      restarted.spreadsheetUrl.toString(),
      'https://docs.google.com/spreadsheets/d/sheet-123/edit',
    );
    expect(fake.paths.where((p) => p == '/v4/spreadsheets'), hasLength(1));
    expect(fake.bodies[1], fake.bodies[2]);
    expect(fake.saved, isNull);
    expect(fake.savedValues.join(), isNot(contains('access-token')));
  });
  test('명시적 생성 거부는 불확실 상태를 남기지 않는다', () async {
    final fake = _Fake()..createStatus = 403;
    final service = fake.service();
    await expectLater(service.create(report), throwsA(isA<AppError>()));
    expect(service.hasPending, isFalse);
    expect(fake.saved, isNull);
  });
  test('서버의 생성 시간 초과도 자동 재생성하지 않는다', () async {
    final fake = _Fake()..createStatus = 408;
    final service = fake.service();
    await expectLater(service.create(report), throwsA(isA<AppError>()));
    expect(service.creationUncertain, isTrue);
    expect(fake.saved, isNotNull);
  });
}

class _Fake {
  String? saved;
  final savedValues = <String>[];
  final paths = <String>[];
  final bodies = <Map<String, Object?>>[];
  bool failCreate = false;
  int createStatus = 200, writeStatus = 200;
  GoogleSheetsService service({Future<String> Function()? authorize}) =>
      GoogleSheetsService(
        authorize: authorize ?? () async => 'access-token',
        loadRecovery: () async => saved,
        saveRecovery: (value) async {
          saved = value;
          savedValues.add(value ?? '');
        },
        request: (path, body, token) async {
          paths.add(path);
          bodies.add(body);
          if (path == '/v4/spreadsheets' && failCreate) {
            throw const SocketException('lost response');
          }
          return (
            status: path == '/v4/spreadsheets' ? createStatus : writeStatus,
            body: path == '/v4/spreadsheets'
                ? {'spreadsheetId': 'sheet-123'}
                : <String, dynamic>{},
          );
        },
      );
}
