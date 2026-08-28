import 'dart:convert';
import 'dart:typed_data';

import '../../domain/models.dart';

const receiptImageMaxBytes = 5 * 1024 * 1024;
const supportedReceiptImageMimeTypes = <String>{
  'image/jpeg',
  'image/png',
  'image/webp',
};

/// [TASK-07 · OCR 호출] 이미지 본문을 저장하지 않는 parseReceipt wire 요청입니다.
final class ParseReceiptRequest {
  factory ParseReceiptRequest({
    required String tripId,
    required String imageBase64,
    required String mimeType,
    int maxImageBytes = receiptImageMaxBytes,
  }) {
    final normalizedTripId = _validateTripId(tripId);
    final normalizedMimeType = _normalizeMimeType(mimeType);
    _validateMaxImageBytes(maxImageBytes);
    final bytes = _decodeImageBase64(imageBase64, maxImageBytes);
    _validateImageBytes(bytes, normalizedMimeType, maxImageBytes);
    return ParseReceiptRequest._(
      tripId: normalizedTripId,
      imageBase64: imageBase64,
      mimeType: normalizedMimeType,
    );
  }

  factory ParseReceiptRequest.fromBytes({
    required String tripId,
    required Uint8List imageBytes,
    required String mimeType,
    int maxImageBytes = receiptImageMaxBytes,
  }) {
    final normalizedTripId = _validateTripId(tripId);
    final normalizedMimeType = _normalizeMimeType(mimeType);
    _validateMaxImageBytes(maxImageBytes);
    _validateImageBytes(imageBytes, normalizedMimeType, maxImageBytes);
    return ParseReceiptRequest._(
      tripId: normalizedTripId,
      imageBase64: base64Encode(imageBytes),
      mimeType: normalizedMimeType,
    );
  }

  const ParseReceiptRequest._({
    required this.tripId,
    required this.imageBase64,
    required this.mimeType,
  });

  final EntityId tripId;
  final String imageBase64;
  final String mimeType;

  Map<String, Object> toJson() => {
    'tripId': tripId,
    'imageBase64': imageBase64,
    'mimeType': mimeType,
  };
}

final class OcrItemCandidate {
  const OcrItemCandidate({
    required this.nameOriginal,
    required this.sourceOrder,
    this.nameTranslated,
    this.amount,
    this.confidence,
  });

  final String nameOriginal;
  final String? nameTranslated;
  final CurrencyAmount? amount;
  final double? confidence;
  final int sourceOrder;
}

final class ParseReceiptResponse {
  ParseReceiptResponse({
    required this.rawText,
    required List<OcrItemCandidate> items,
    required List<String> warnings,
    this.sourceLanguage,
    this.merchantNameOriginal,
    this.merchantNameTranslated,
    this.expenseDate,
    this.currencyCandidate,
    this.totalAmountCandidate,
  }) : items = List.unmodifiable(items),
       warnings = List.unmodifiable(warnings);

  final String rawText;
  final String? sourceLanguage;
  final String? merchantNameOriginal;
  final String? merchantNameTranslated;
  final LocalDate? expenseDate;
  final CurrencyCode? currencyCandidate;
  final CurrencyAmount? totalAmountCandidate;
  final List<OcrItemCandidate> items;
  final List<String> warnings;
}

typedef ParsedReceipt = ParseReceiptResponse;

/// 호출 구현은 응답만 반환하며 이미지나 OCR 초안을 저장하지 않습니다.
abstract interface class ReceiptParser {
  Future<ParseReceiptResponse> parseReceipt(ParseReceiptRequest request);
}

String _validateTripId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 160) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '여행 ID를 확인해 주세요.',
      retryable: false,
      field: 'tripId',
    );
  }
  return normalized;
}

String _normalizeMimeType(String value) {
  final normalized = value.trim().toLowerCase();
  if (!supportedReceiptImageMimeTypes.contains(normalized)) {
    throw const AppError(
      code: AppErrorCode.invalidImage,
      message: 'JPEG, PNG 또는 WebP 영수증 이미지를 선택해 주세요.',
      retryable: false,
      field: 'mimeType',
    );
  }
  return normalized;
}

Uint8List _decodeImageBase64(String value, int maxImageBytes) {
  final maxEncodedLength = ((maxImageBytes + 2) ~/ 3) * 4;
  if (value.length > maxEncodedLength) {
    throw _payloadTooLarge(maxImageBytes);
  }
  if (value.isEmpty ||
      value.length % 4 != 0 ||
      !RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(value)) {
    throw _invalidBase64();
  }
  try {
    return base64Decode(value);
  } on FormatException {
    throw _invalidBase64();
  }
}

void _validateImageBytes(Uint8List bytes, String mimeType, int maxImageBytes) {
  if (bytes.length > maxImageBytes) {
    throw _payloadTooLarge(maxImageBytes, actualBytes: bytes.length);
  }
  if (bytes.isEmpty || !_matchesImageSignature(bytes, mimeType)) {
    throw const AppError(
      code: AppErrorCode.invalidImage,
      message: '이미지 형식과 파일 내용을 확인해 주세요.',
      retryable: false,
      field: 'imageBase64',
    );
  }
}

void _validateMaxImageBytes(int value) {
  if (value < 1) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '이미지 크기 제한을 확인해 주세요.',
      retryable: false,
      field: 'maxImageBytes',
    );
  }
}

bool _matchesImageSignature(Uint8List bytes, String mimeType) =>
    switch (mimeType) {
      'image/jpeg' =>
        bytes.length >= 3 &&
            bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff,
      'image/png' =>
        bytes.length >= 8 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47 &&
            bytes[4] == 0x0d &&
            bytes[5] == 0x0a &&
            bytes[6] == 0x1a &&
            bytes[7] == 0x0a,
      'image/webp' =>
        bytes.length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50,
      _ => false,
    };

AppError _invalidBase64() => const AppError(
  code: AppErrorCode.invalidImage,
  message: '이미지 데이터를 읽을 수 없습니다.',
  retryable: false,
  field: 'imageBase64',
);

AppError _payloadTooLarge(int maxBytes, {int? actualBytes}) => AppError(
  code: AppErrorCode.payloadTooLarge,
  message: '영수증 이미지 크기 제한을 초과했습니다.',
  retryable: false,
  field: 'imageBase64',
  details: {'maxBytes': maxBytes, 'actualBytes': ?actualBytes},
);
