import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models.dart';
import 'trip_sheet_report.dart';

typedef SheetsResponse = ({int status, Map<String, dynamic> body});
typedef SheetsRequest = Future<SheetsResponse> Function(
  String path,
  Map<String, Object?> body,
  String token,
);

/// [TASK-08] 새 문서 생성과 내용 쓰기를 분리하고 응답 유실 시 ID를 보존합니다.
final class GoogleSheetsService {
  GoogleSheetsService({
    required this.authorize,
    required this.loadRecovery,
    required this.saveRecovery,
    SheetsRequest? request,
  }) : _request = request ?? _post;
  final Future<String> Function() authorize;
  final Future<String?> Function() loadRecovery;
  final Future<void> Function(String?) saveRecovery;
  final SheetsRequest _request;
  Map<String, Object?>? _recovery;
  bool _busy = false;
  bool get busy => _busy;
  bool get hasPending => _recovery != null;
  bool get creationUncertain => hasPending && spreadsheetId == null;
  String? get spreadsheetId => _recovery?['id'] as String?;
  String? get pendingTitle => _recovery?['title'] as String?;
  Uri? get spreadsheetUrl => spreadsheetId == null
      ? null
      : Uri.https('docs.google.com', '/spreadsheets/d/$spreadsheetId/edit');

  Future<void> restore() async {
    if (_recovery != null) return;
    final saved = await loadRecovery();
    if (saved != null) {
      _recovery = Map<String, Object?>.from(jsonDecode(saved) as Map);
    }
  }

  Future<void> create(TripSheetReport report) async {
    if (_busy || hasPending) throw _error('진행 중인 보고서를 먼저 확인해 주세요.');
    _busy = true;
    try {
      final token = await authorize();
      _recovery = {'title': report.title, 'requests': report.writeRequests};
      // Persist before the POST: an interrupted process must not blindly create again.
      await _persist();
      final response = await _request('/v4/spreadsheets', {
        'properties': {
          'title': report.title,
          'locale': 'ko_KR',
          'timeZone': report.timeZone,
        },
        'sheets': [
          for (final s in report.sheets.indexed)
            {
              'properties': {'sheetId': s.$1, 'title': s.$2.title},
            },
        ],
      }, token);
      if (response.status >= 400 &&
          response.status < 500 &&
          response.status != 408) {
        _recovery = null;
        await _persist();
      }
      _check(response);
      final id = response.body['spreadsheetId'];
      if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
        throw _error('생성 결과를 확인하지 못했습니다. Google Drive에서 보고서 제목을 확인해 주세요.');
      }
      _recovery!['id'] = id;
      await _persist();
      await _write(token);
    } on GoogleSignInException catch (error) {
      throw _error(
        error.code == GoogleSignInExceptionCode.canceled
            ? 'Google 권한 요청을 취소했습니다.'
            : 'Google 계정과 시트 생성 권한을 확인해 주세요.',
      );
    } on IOException {
      throw _error('연결이 끊겼습니다. 생성 상태를 확인하고 다시 시도해 주세요.');
    } on TimeoutException {
      throw _error('응답 시간이 초과됐습니다. 생성 상태를 확인해 주세요.');
    } finally {
      _busy = false;
    }
  }

  Future<void> retryWrite() async {
    if (_busy || spreadsheetId == null || complete) {
      throw _error('복구할 문서 ID가 없습니다.');
    }
    _busy = true;
    try {
      await _write(await authorize());
    } finally {
      _busy = false;
    }
  }

  Future<void> _write(String token) async {
    final response = await _request(
      '/v4/spreadsheets/$spreadsheetId:batchUpdate',
      {'requests': _recovery!['requests']},
      token,
    );
    _check(response);
    // Keep the successful ID for opening; remove the locally stored report content.
    await saveRecovery(null);
    _recovery = {'id': spreadsheetId, 'title': pendingTitle, 'complete': true};
  }

  bool get complete => _recovery?['complete'] == true;

  /// Explicit user action after checking Drive; never deletes an external document.
  Future<void> startNew() async {
    if (_busy) return;
    await saveRecovery(null);
    _recovery = null;
  }

  Future<void> _persist() =>
      saveRecovery(_recovery == null ? null : jsonEncode(_recovery));
}

AppError _error(String message) => AppError(
  code: AppErrorCode.unavailable,
  message: message,
  retryable: false,
);
void _check(SheetsResponse response) {
  if (response.status >= 200 && response.status < 300) return;
  throw _error(switch (response.status) {
    401 || 403 => 'Google 권한이 만료되었거나 Sheets API 접근이 거부됐습니다. 권한을 다시 확인해 주세요.',
    429 => '요청 한도를 초과했습니다. 잠시 후 다시 시도해 주세요.',
    _ => 'Google Sheets 저장에 실패했습니다. 생성 상태와 연결을 확인해 주세요.',
  });
}

Future<SheetsResponse> _post(
  String path,
  Map<String, Object?> body,
  String token,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    return await (() async {
      final request = await client.postUrl(
        Uri.https('sheets.googleapis.com', path),
      );
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      final raw = await utf8.decoder.bind(response).join();
      return (
        status: response.statusCode,
        body: raw.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(raw) as Map<String, dynamic>,
      );
    })().timeout(const Duration(seconds: 45));
  } finally {
    client.close(force: true);
  }
}
