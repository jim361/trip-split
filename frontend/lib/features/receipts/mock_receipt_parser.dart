import '../../domain/models.dart';
import 'receipt_parser.dart';

enum MockReceiptFailure { unavailable, noResult }

final japaneseReceiptFixture = ParseReceiptResponse(
  rawText: '''浅草食堂
2026年11月26日
天ぷら定食 1,200円
抹茶ラテ 550円
合計 1,750円''',
  sourceLanguage: 'ja',
  merchantNameOriginal: '浅草食堂',
  merchantNameTranslated: '아사쿠사 식당',
  expenseDate: '2026-11-26',
  currencyCandidate: 'JPY',
  totalAmountCandidate: 1750,
  items: const [
    OcrItemCandidate(
      nameOriginal: '天ぷら定食',
      nameTranslated: '튀김 정식',
      amount: 1200,
      confidence: 0.98,
      sourceOrder: 0,
    ),
    OcrItemCandidate(
      nameOriginal: '抹茶ラテ',
      nameTranslated: '말차 라테',
      amount: 550,
      confidence: 0.96,
      sourceOrder: 1,
    ),
  ],
  warnings: const ['번역과 금액을 원문 이미지에서 확인해 주세요.'],
);

/// 실제 provider나 저장소를 사용하지 않는 일본어 OCR 호출 fixture입니다.
final class MockReceiptParser implements ReceiptParser {
  const MockReceiptParser({this.failure});

  final MockReceiptFailure? failure;

  @override
  Future<ParseReceiptResponse> parseReceipt(ParseReceiptRequest request) async {
    switch (failure) {
      case MockReceiptFailure.unavailable:
        throw const AppError(
          code: AppErrorCode.ocrUnavailable,
          message: '영수증 인식 서비스를 잠시 사용할 수 없습니다.',
          retryable: true,
        );
      case MockReceiptFailure.noResult:
        throw const AppError(
          code: AppErrorCode.ocrNoResult,
          message: '인식된 영수증 항목이 없습니다.',
          retryable: false,
        );
      case null:
        return japaneseReceiptFixture;
    }
  }
}
