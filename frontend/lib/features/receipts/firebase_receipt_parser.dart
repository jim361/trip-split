import 'package:cloud_functions/cloud_functions.dart';

import '../../data/firebase/firebase_error_mapper.dart';
import 'receipt_parser.dart';

class FirebaseReceiptParser implements ReceiptParser {
  const FirebaseReceiptParser(this.functions);
  final FirebaseFunctions functions;
  @override
  Future<ParseReceiptResponse> parseReceipt({
    required String tripId,
    required ReceiptImageInput image,
  }) async {
    try {
      final response = await functions
          .httpsCallable('parseReceipt')
          .call<Object?>(
            ParseReceiptRequest(tripId: tripId, image: image).toJson(),
          );
      final data = Map<String, dynamic>.from(response.data as Map);
      return ParseReceiptResponse(
        rawText: data['rawText'] as String,
        sourceLanguage: data['sourceLanguage'] as String?,
        merchantNameOriginal: data['merchantNameOriginal'] as String?,
        merchantNameTranslated: data['merchantNameTranslated'] as String?,
        expenseDate: data['expenseDate'] as String?,
        currencyCandidate: data['currencyCandidate'] as String?,
        totalAmountCandidate: data['totalAmountCandidate'] as int?,
        warnings: (data['warnings'] as List).cast<String>(),
        items: (data['items'] as List).map((value) {
          final item = Map<String, dynamic>.from(value as Map);
          return OcrItemCandidate(
            nameOriginal: item['nameOriginal'] as String,
            nameTranslated: item['nameTranslated'] as String?,
            amount: item['amount'] as int?,
            confidence: (item['confidence'] as num?)?.toDouble(),
            sourceOrder: item['sourceOrder'] as int,
          );
        }).toList(),
      );
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}
