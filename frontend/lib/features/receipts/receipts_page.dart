import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../platform/android_actions.dart';
import '../../shared/widgets/edit_frame.dart';
import 'mock_receipt_parser.dart';
import 'receipt_parser.dart';
import 'receipt_review_page.dart';

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({
    required this.trip,
    required this.repositories,
    required this.currentUid,
    required this.parser,
    required this.onBackToSettlement,
    required this.onManualExpense,
    required this.onExpenseSaved,
    this.imagePicker,
    super.key,
  });
  final Trip trip;
  final TripRepositories repositories;
  final String currentUid;
  final ReceiptParser parser;
  final VoidCallback onBackToSettlement, onManualExpense;
  final ValueChanged<String> onExpenseSaved;
  final Future<ReceiptImageInput?> Function()? imagePicker;
  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  ReceiptImageInput? _image;
  bool _busy = false, _sample = false;
  String? _error;
  @override
  void dispose() {
    _image = null;
    super.dispose();
  }

  Future<void> _pick({bool camera = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image =
          await (widget.imagePicker ??
              (camera
                  ? AndroidActions.captureReceipt
                  : AndroidActions.pickReceipt))();
      if (image != null && mounted) {
        setState(() {
          _image = image;
          _sample = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is PlatformException
              ? error.message
              : actionError(error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _useSample() {
    setState(() {
      _sample = true;
      _error = null;
      _image = ReceiptImageInput(
        mimeType: 'image/png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a1ioAAAAASUVORK5CYII=',
        ),
      );
    });
  }

  Future<void> _recognize() async {
    if (_busy || _image == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.parser.parseReceipt(
        tripId: widget.trip.id,
        image: _image!,
      );
      if (!mounted) return;
      final id = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => ReceiptReviewPage(
            trip: widget.trip,
            repositories: widget.repositories,
            currentUid: widget.currentUid,
            parsed: result,
            image: _sample ? null : _image,
          ),
        ),
      );
      if (id != null && mounted) {
        setState(() {
          _image = null;
          _sample = false;
        });
        widget.onExpenseSaved(id);
      }
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_busy,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
      children: [
        Text('영수증 검토', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text('이미지 선택 → 인식·번역 → 항목 검토·배분 → 지출 저장'),
        const SizedBox(height: 24),
        if (_sample)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '샘플 영수증',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(japaneseReceiptFixture.rawText),
                ],
              ),
            ),
          )
        else if (_image != null)
          Image.memory(
            _image!.bytes,
            height: 220,
            errorBuilder: (_, _, _) =>
                const Text('이미지 미리보기를 열 수 없습니다. 다른 파일을 선택해 주세요.'),
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Icon(Icons.receipt_long_outlined, size: 64),
            ),
          ),
        OutlinedButton.icon(
          key: const Key('receipt-camera'),
          onPressed: _busy ? null : () => _pick(camera: true),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('카메라로 촬영'),
        ),
        OutlinedButton.icon(
          key: const Key('receipt-image-pick'),
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(_image == null ? '영수증 이미지 선택' : '이미지 교체'),
        ),
        if (widget.parser is MockReceiptParser)
          OutlinedButton(
            key: const Key('receipt-sample'),
            onPressed: _busy ? null : _useSample,
            child: const Text('샘플 영수증으로 흐름 확인'),
          ),
        if (_image != null)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _image = null;
                    _sample = false;
                    _error = null;
                  }),
            child: const Text('이미지 제거'),
          ),
        const SizedBox(height: 12),
        Text(
          widget.parser is MockReceiptParser
              ? '현재는 샘플 인식 결과로 흐름을 확인합니다. 이미지를 외부로 전송하지 않습니다.'
              : '이미지는 저장하지 않으며 인식과 번역을 위해 처리 서비스로 전송됩니다. Emulator에서는 고정 샘플을 반환합니다. 실제 외부 서비스는 아직 연결하지 않았습니다.',
        ),
        const Text('JPEG·PNG·WebP, 최대 5 MiB. 인식 결과를 검토한 후 저장을 눌러야 지출에 반영됩니다.'),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('receipt-recognize'),
          onPressed: _busy || _image == null ? null : _recognize,
          child: Text(_busy ? '인식·검토 중…' : '인식하고 검토하기'),
        ),
        OutlinedButton(
          key: const Key('receipt-manual-fallback'),
          onPressed: _busy ? null : widget.onManualExpense,
          child: const Text('전체 금액으로 직접 등록'),
        ),
        TextButton(
          onPressed: _busy ? null : widget.onBackToSettlement,
          child: const Text('정산으로 돌아가기'),
        ),
      ],
    ),
  );
}
