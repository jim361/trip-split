import 'package:flutter/material.dart';

import '../../domain/models.dart';

String actionError(Object error) =>
    error is AppError ? error.message : '처리하지 못했습니다. 입력 내용을 확인하고 다시 시도해 주세요.';

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String action = '확인',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class FieldPair extends StatelessWidget {
  const FieldPair(this.first, this.second, {super.key});
  final Widget first;
  final Widget second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      if (size.maxWidth < 328 * MediaQuery.textScalerOf(context).scale(1)) {
        return Column(children: [first, const SizedBox(height: 16), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

/// 여러 입력 화면의 저장 중/수정 후 이탈 동작을 동일하게 유지합니다.
class EditFrame extends StatefulWidget {
  const EditFrame({
    required this.title,
    required this.busy,
    required this.dirty,
    required this.onSave,
    required this.children,
    this.error,
    this.saveLabel = '저장',
    super.key,
  });
  final String title;
  final bool busy;
  final bool dirty;
  final VoidCallback? onSave;
  final List<Widget> children;
  final String? error;
  final String saveLabel;
  @override
  State<EditFrame> createState() => _EditFrameState();
}

class _EditFrameState extends State<EditFrame> {
  bool _confirming = false;
  Future<void> _close() async {
    if (widget.busy || _confirming) return;
    _confirming = true;
    final leave =
        !widget.dirty ||
        await confirmAction(
          context,
          '편집을 그만둘까요?',
          '저장하지 않은 변경 내용이 사라집니다.',
          action: '나가기',
        );
    _confirming = false;
    if (leave && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !widget.busy && !widget.dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: '편집 닫기',
          onPressed: widget.busy ? null : _close,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      for (final child in widget.children) ...[
                        child,
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              widget.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      FilledButton(
                        key: const Key('form-save'),
                        onPressed: widget.busy ? null : widget.onSave,
                        child: Text(widget.busy ? '저장 중…' : widget.saveLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
