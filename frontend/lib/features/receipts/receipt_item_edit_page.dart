import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../shared/widgets/edit_frame.dart';
import '../settlement/expense_edit_page.dart';
import '../settlement/settlement_engine.dart';

const receiptKindLabels = {
  'item': '일반 항목',
  'discount': '할인',
  'serviceFee': '봉사료',
  'adjustment': '기타 조정',
};
int parseSignedReceiptAmount(String text) {
  final trimmed = text.trim();
  return trimmed.startsWith('-')
      ? -parseExpenseAmount(trimmed.substring(1))
      : parseExpenseAmount(trimmed);
}

class ReceiptItemEditPage extends StatefulWidget {
  const ReceiptItemEditPage({
    required this.item,
    required this.participants,
    super.key,
  });
  final ReceiptItem item;
  final List<Participant> participants;
  @override
  State<ReceiptItemEditPage> createState() => _ReceiptItemEditPageState();
}

class _ReceiptItemEditPageState extends State<ReceiptItemEditPage> {
  late final TextEditingController _name, _amount;
  late final List<String> _consumers;
  final _custom = <String, TextEditingController>{};
  late String _kind, _method;
  bool _dirty = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item.name);
    _amount = TextEditingController(
      text: item.amount == 0 ? '' : item.amount.toString(),
    );
    _consumers = [...item.consumers];
    _kind = item.kind;
    _method = item.allocationMethod;
    for (final a in item.allocatedAmounts) {
      _custom[a.participantId] = TextEditingController(
        text: a.amount.toString(),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    for (final c in _custom.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {
    _dirty = true;
    _error = null;
  });
  TextEditingController _controller(String id) =>
      _custom.putIfAbsent(id, () => TextEditingController(text: '0'));
  List<MoneyAllocation> _allocations(int amount) => _method == 'equal'
      ? allocateEqually(totalAmount: amount, consumers: _consumers)
      : [
          for (final id in _consumers)
            MoneyAllocation(
              participantId: id,
              amount: parseSignedReceiptAmount(_controller(id).text),
            ),
        ];
  void _save() {
    try {
      final amount = parseSignedReceiptAmount(_amount.text);
      final allocations = _allocations(amount);
      final validSign = switch (_kind) {
        'item' || 'serviceFee' => amount > 0,
        'discount' => amount < 0,
        'adjustment' => amount != 0,
        _ => false,
      };
      if (_name.text.trim().isEmpty ||
          _name.text.trim().length > 160 ||
          !validSign ||
          _consumers.isEmpty ||
          allocations.fold(0, (s, a) => s + a.amount) != amount ||
          allocations.any(
            (a) => a.amount != 0 && a.amount.sign != amount.sign,
          )) {
        throw const AppError(
          code: AppErrorCode.invalidArgument,
          message: '이름·금액·소비자와 배분 합계를 확인해 주세요. 할인은 음수로 입력합니다.',
          retryable: false,
        );
      }
      Navigator.pop(
        context,
        ReceiptItem(
          id: widget.item.id,
          kind: _kind,
          name: _name.text.trim(),
          amount: amount,
          consumers: _consumers,
          allocationMethod: _method,
          allocatedAmounts: allocations,
          source: widget.item.source,
          sortOrder: widget.item.sortOrder,
        ),
      );
    } catch (error) {
      setState(() => _error = actionError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MoneyAllocation> preview = [];
    try {
      preview = _allocations(parseSignedReceiptAmount(_amount.text));
    } catch (_) {
      /* 입력 중에는 저장 검증에서 안내합니다. */
    }
    return EditFrame(
      title: '항목·조정 편집',
      busy: false,
      dirty: _dirty,
      error: _error,
      onSave: _save,
      saveLabel: '항목 적용',
      children: [
        TextField(
          key: const Key('receipt-item-name'),
          controller: _name,
          onChanged: (_) => _changed(),
          decoration: const InputDecoration(labelText: '항목 이름'),
        ),
        FieldPair(
          DropdownButtonFormField<String>(
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '항목 종류'),
            items: receiptKindLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) {
              _kind = v!;
              _changed();
            },
          ),
          TextField(
            key: const Key('receipt-item-amount'),
            controller: _amount,
            onChanged: (_) => _changed(),
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(labelText: '금액 · 할인은 음수'),
          ),
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'equal', label: Text('항목 균등')),
            ButtonSegment(value: 'custom', label: Text('직접 배분')),
          ],
          selected: {_method},
          onSelectionChanged: (v) {
            if (v.first == 'custom') {
              for (final a in preview) {
                _controller(a.participantId).text = a.amount.toString();
              }
            }
            _method = v.first;
            _changed();
          },
        ),
        for (final person in widget.participants)
          Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(person.name),
                value: _consumers.contains(person.id),
                onChanged: (v) {
                  if (v!) {
                    _consumers.add(person.id);
                  } else {
                    _consumers.remove(person.id);
                  }
                  _changed();
                },
              ),
              if (_consumers.contains(person.id))
                _method == 'custom'
                    ? TextField(
                        key: ValueKey('receipt-item-custom-${person.id}'),
                        controller: _controller(person.id),
                        onChanged: (_) => _changed(),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '${person.name} 부담액',
                        ),
                      )
                    : Text(
                        '${preview.where((a) => a.participantId == person.id).firstOrNull?.amount ?? 0}',
                      ),
            ],
          ),
        Text('배분 합계 ${preview.fold(0, (s, a) => s + a.amount)}'),
      ],
    );
  }
}
