import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/receipts/mock_receipt_parser.dart';
import 'package:trip_split/features/receipts/receipt_parser.dart';

Uint8List _jpegBytes() => Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

void main() {
  test('bytes를 검증한 뒤 canonical parseReceipt 요청으로 변환한다', () {
    final request = ParseReceiptRequest.fromBytes(
      tripId: ' tokyo-2026-11 ',
      imageBytes: _jpegBytes(),
      mimeType: 'IMAGE/JPEG',
    );

    expect(request.tripId, 'tokyo-2026-11');
    expect(request.mimeType, 'image/jpeg');
    expect(base64Decode(request.imageBase64), _jpegBytes());
    expect(request.toJson().keys, ['tripId', 'imageBase64', 'mimeType']);
  });

  test('지원하지 않는 MIME은 외부 호출 전에 invalid-image로 거부한다', () {
    expect(
      () => ParseReceiptRequest.fromBytes(
        tripId: 'tokyo-2026-11',
        imageBytes: _jpegBytes(),
        mimeType: 'image/heic',
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidImage)
            .having((error) => error.field, 'field', 'mimeType'),
      ),
    );
  });

  test('잘못된 base64와 MIME 불일치는 invalid-image로 거부한다', () {
    expect(
      () => ParseReceiptRequest(
        tripId: 'tokyo-2026-11',
        imageBase64: 'not-base64',
        mimeType: 'image/jpeg',
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidImage)
            .having((error) => error.field, 'field', 'imageBase64'),
      ),
    );
    expect(
      () => ParseReceiptRequest.fromBytes(
        tripId: 'tokyo-2026-11',
        imageBytes: _jpegBytes(),
        mimeType: 'image/png',
      ),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.invalidImage,
        ),
      ),
    );
  });

  test('최대 크기를 넘는 이미지는 payload-too-large로 거부한다', () {
    expect(receiptImageMaxBytes, 5 * 1024 * 1024);
    expect(
      () => ParseReceiptRequest.fromBytes(
        tripId: 'tokyo-2026-11',
        imageBytes: _jpegBytes(),
        mimeType: 'image/jpeg',
        maxImageBytes: 3,
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.payloadTooLarge)
            .having((error) => error.details['maxBytes'], 'maxBytes', 3),
      ),
    );
  });

  test('일본어 fixture를 원문·번역·JPY 항목 후보로 반환한다', () async {
    final request = ParseReceiptRequest.fromBytes(
      tripId: 'tokyo-2026-11',
      imageBytes: _jpegBytes(),
      mimeType: 'image/jpeg',
    );

    final result = await const MockReceiptParser().parseReceipt(request);

    expect(result.sourceLanguage, 'ja');
    expect(result.merchantNameOriginal, '浅草食堂');
    expect(result.merchantNameTranslated, '아사쿠사 식당');
    expect(result.expenseDate, '2026-11-26');
    expect(result.currencyCandidate, 'JPY');
    expect(result.totalAmountCandidate, 1750);
    expect(result.items.map((item) => item.nameOriginal), ['天ぷら定食', '抹茶ラテ']);
    expect(result.items.map((item) => item.nameTranslated), ['튀김 정식', '말차 라테']);
    expect(result.items.map((item) => item.sourceOrder), [0, 1]);
    expect(result.warnings, isNotEmpty);
  });

  test('mock provider 장애와 빈 결과를 canonical OCR 오류로 매핑한다', () async {
    final request = ParseReceiptRequest.fromBytes(
      tripId: 'tokyo-2026-11',
      imageBytes: _jpegBytes(),
      mimeType: 'image/jpeg',
    );

    await expectLater(
      const MockReceiptParser(failure: MockReceiptFailure.unavailable)
          .parseReceipt(request),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.ocrUnavailable)
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
    await expectLater(
      const MockReceiptParser(failure: MockReceiptFailure.noResult)
          .parseReceipt(request),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.ocrNoResult)
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });
}
