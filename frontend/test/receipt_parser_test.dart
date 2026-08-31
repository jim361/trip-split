import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/receipts/mock_receipt_parser.dart';
import 'package:trip_split/features/receipts/receipt_parser.dart';

Uint8List _jpegBytes() => Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

void main() {
  test('bytes를 검증한 뒤 canonical parseReceipt 요청으로 변환한다', () {
    final sourceBytes = _jpegBytes();
    final image = ReceiptImageInput(
      bytes: sourceBytes,
      mimeType: 'IMAGE/JPEG',
      fileName: ' receipt.jpg ',
    );
    sourceBytes[0] = 0;
    final request = ParseReceiptRequest(
      tripId: ' tokyo-2026-11 ',
      image: image,
    );
    final json = request.toJson();

    expect(image.mimeType, 'image/jpeg');
    expect(image.fileName, 'receipt.jpg');
    expect(json['tripId'], 'tokyo-2026-11');
    expect(base64Decode(json['imageBase64']! as String), _jpegBytes());
    expect(json['mimeType'], 'image/jpeg');
    expect(json.keys, ['tripId', 'imageBase64', 'mimeType']);
  });

  test('지원하지 않는 MIME은 외부 호출 전에 invalid-image로 거부한다', () {
    expect(
      () => ReceiptImageInput(bytes: _jpegBytes(), mimeType: 'image/heic'),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidImage)
            .having((error) => error.field, 'field', 'mimeType'),
      ),
    );
  });

  test('MIME과 이미지 시그니처가 다르면 invalid-image로 거부한다', () {
    expect(
      () => ReceiptImageInput(bytes: _jpegBytes(), mimeType: 'image/png'),
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
    final bytes = Uint8List(receiptImageMaxBytes + 1)
      ..setAll(0, [0xff, 0xd8, 0xff]);
    expect(
      () => ReceiptImageInput(bytes: bytes, mimeType: 'image/jpeg'),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.payloadTooLarge)
            .having(
              (error) => error.details['maxBytes'],
              'maxBytes',
              receiptImageMaxBytes,
            ),
      ),
    );
  });

  test('일본어 fixture를 원문·번역·JPY 항목 후보로 반환한다', () async {
    final image = ReceiptImageInput(
      bytes: _jpegBytes(),
      mimeType: 'image/jpeg',
    );

    final result = await const MockReceiptParser().parseReceipt(
      tripId: 'tokyo-2026-11',
      image: image,
    );

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
    final image = ReceiptImageInput(
      bytes: _jpegBytes(),
      mimeType: 'image/jpeg',
    );

    await expectLater(
      const MockReceiptParser(failure: MockReceiptFailure.unavailable)
          .parseReceipt(tripId: 'tokyo-2026-11', image: image),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.ocrUnavailable)
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
    await expectLater(
      const MockReceiptParser(failure: MockReceiptFailure.noResult)
          .parseReceipt(tripId: 'tokyo-2026-11', image: image),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.ocrNoResult)
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });
}
