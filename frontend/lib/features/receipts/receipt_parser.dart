import 'dart:convert';
import 'dart:typed_data';

import '../../domain/models.dart';

const receiptImageMaxBytes = 5 * 1024 * 1024;
const supportedReceiptImageMimeTypes = <String>{
  'image/jpeg',
  'image/png',
  'image/webp',
};

/// [TASK-07 · OCR 호출] 앱 내부에서만 유지하는 검증된 영수증 이미지입니다.
final class ReceiptImageInput {
  factory ReceiptImageInput({
    required Uint8List bytes,
    required String mimeType,
    String? fileName,
  }) {
    final normalizedMimeType = _normalizeMimeType(mimeType);
    _validateImageBytes(bytes, normalizedMimeType);
    return ReceiptImageInput._(
      bytes: Uint8List.fromList(bytes),
      mimeType: normalizedMimeType,
      fileName: _normalizeFileName(fileName),
    );
  }

  ReceiptImageInput._({
    required this._bytes,
    required this.mimeType,
    required this.fileName,
  });

  final Uint8List _bytes;
  final String mimeType;
  final String? fileName;

  Uint8List get bytes => Uint8List.fromList(_bytes);
}

/// 검증된 앱 입력을 Firebase Callable wire 형식으로만 변환합니다.
final class ParseReceiptRequest {
  factory ParseReceiptRequest({
    required EntityId tripId,
    required ReceiptImageInput image,
  }) {
    final normalizedTripId = _validateTripId(tripId);
    return ParseReceiptRequest._(
      tripId: normalizedTripId,
      imageBase64: base64Encode(image._bytes),
      mimeType: image.mimeType,
    );
  }

  const ParseReceiptRequest._({
    required this._tripId,
    required this._imageBase64,
    required this._mimeType,
  });

  final EntityId _tripId;
  final String _imageBase64;
  final String _mimeType;

  Map<String, Object> toJson() => {
    'tripId': _tripId,
    'imageBase64': _imageBase64,
    'mimeType': _mimeType,
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
  Future<ParseReceiptResponse> parseReceipt({
    required EntityId tripId,
    required ReceiptImageInput image,
  });
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

void _validateImageBytes(Uint8List bytes, String mimeType) {
  if (bytes.length > receiptImageMaxBytes) {
    throw _payloadTooLarge(actualBytes: bytes.length);
  }
  if (bytes.isEmpty || !_matchesImageSignature(bytes, mimeType)) {
    throw const AppError(
      code: AppErrorCode.invalidImage,
      message: '이미지 형식과 파일 내용을 확인해 주세요.',
      retryable: false,
      field: 'bytes',
    );
  }
}

String? _normalizeFileName(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.length > 255) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '파일 이름은 255자 이하여야 합니다.',
      retryable: false,
      field: 'fileName',
    );
  }
  return normalized;
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

AppError _payloadTooLarge({required int actualBytes}) => AppError(
  code: AppErrorCode.payloadTooLarge,
  message: '영수증 이미지 크기 제한을 초과했습니다.',
  retryable: false,
  field: 'bytes',
  details: {'maxBytes': receiptImageMaxBytes, 'actualBytes': actualBytes},
);
