import 'package:flutter/services.dart';

import '../features/receipts/receipt_parser.dart';

/// Android 시스템 UI와의 경계. Widget은 Intent/파일 SDK를 직접 호출하지 않습니다.
class AndroidActions {
  static const _channel = MethodChannel('trip_split/android_actions');
  static Future<void> shareText(String text) =>
      _channel.invokeMethod<void>('shareText', {'text': text});
  static Future<void> openUrl(Uri url) =>
      _channel.invokeMethod<void>('openUrl', {'url': url.toString()});
  static Future<ReceiptImageInput?> pickReceipt() => _receipt('pickReceipt');
  static Future<ReceiptImageInput?> captureReceipt() =>
      _receipt('captureReceipt');
  static Future<ReceiptImageInput?> _receipt(String method) async {
    final result = await _channel.invokeMapMethod<String, Object?>(method);
    if (result == null) return null;
    return ReceiptImageInput(
      bytes: result['bytes'] as Uint8List,
      mimeType: result['mimeType'] as String,
    );
  }
}
