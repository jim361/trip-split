import 'package:flutter/material.dart';

import '../../app/trip_session.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../shared/widgets/edit_frame.dart';
import '../settlement/expense_edit_page.dart';
import '../settlement/settlement_engine.dart';
import 'receipt_item_edit_page.dart';
import 'receipt_parser.dart';

class ReceiptReviewPage extends StatefulWidget {
  const ReceiptReviewPage({
    required this.trip,
    required this.repositories,
    required this.currentUid,
    this.parsed,
    this.expense,
    this.image,
    super.key,
  });
  final Trip trip;
  final TripRepositories repositories;
  final String currentUid;
  final ParseReceiptResponse? parsed;
  final Expense? expense;
  final ReceiptImageInput? image;
  @override
  State<ReceiptReviewPage> createState() => _ReceiptReviewPageState();
}

class _ReceiptReviewPageState extends State<ReceiptReviewPage> {
  late final TripSessionController _session;
  late final TextEditingController _title, _total, _date, _memo;
  final _items = <ReceiptItem>[];
  final _consumers = <String>[];
  final _custom = <String, TextEditingController>{};
  String _currency = 'JPY', _category = 'food', _method = 'itemized';
  String? _payer, _place, _itinerary;
  bool _initialized = false, _busy = false, _dirty = false, _uncertain = false;
  String? _error;
  bool _currencyNeedsConfirmation = false;
  var _nextItem = 1;
  @override
  void initState() {
    super.initState();
    final expense = widget.expense, parsed = widget.parsed;
    _title = TextEditingController(
      text:
          expense?.title ??
          parsed?.merchantNameTranslated ??
          parsed?.merchantNameOriginal ??
          '',
    );
    _total = TextEditingController(
      text:
          (expense?.totalAmount ?? parsed?.totalAmountCandidate)?.toString() ??
          '',
    );
    _date = TextEditingController(
      text:
          expense?.expenseDate ?? parsed?.expenseDate ?? widget.trip.startDate,
    );
    _memo = TextEditingController(text: expense?.memo ?? '');
    _currency =
        expense?.currency ??
        (['KRW', 'JPY'].contains(parsed?.currencyCandidate)
            ? parsed!.currencyCandidate!
            : widget.trip.defaultCurrency);
    _currencyNeedsConfirmation =
        expense == null &&
        parsed?.currencyCandidate != null &&
        !['KRW', 'JPY'].contains(parsed!.currencyCandidate);
    _category = expense?.category ?? 'food';
    _method = expense?.allocationMethod ?? 'itemized';
    _place = expense?.placeId;
    _itinerary = expense?.itineraryItemId;
    _payer = expense?.payer.participantId;
    _dirty = parsed != null;
    _session =
        TripSessionController(
            tripId: widget.trip.id,
            repositories: widget.repositories,
          )
          ..addListener(_refresh)
          ..start();
  }

  void _refresh() {
    if (!_initialized && !_session.isLoading && _session.error == null) {
      final active = _session.participants.where((p) => p.isActive).toList();
      _consumers.addAll(widget.expense?.consumers ?? active.map((p) => p.id));
      final linked = active
          .where((p) => p.linkedUid == widget.currentUid)
          .toList();
      _payer ??= linked.length == 1 ? linked.single.id : null;
      if (widget.expense != null) {
        _items.addAll(widget.expense!.receiptItems);
      } else {
        final candidates = [...?widget.parsed?.items]
          ..sort((a, b) => a.sourceOrder.compareTo(b.sourceOrder));
        for (final candidate in candidates) {
          final amount = candidate.amount ?? 0;
          _items.add(
            ReceiptItem(
              id: _newId(),
              kind: amount < 0 ? 'discount' : 'item',
              name: candidate.nameTranslated ?? candidate.nameOriginal,
              amount: amount,
              consumers: _consumers,
              allocationMethod: 'equal',
              allocatedAmounts: _consumers.isEmpty
                  ? []
                  : allocateEqually(totalAmount: amount, consumers: _consumers),
              source: 'ocr',
              sortOrder: _items.length,
            ),
          );
        }
      }
      for (final a in widget.expense?.allocatedAmounts ?? <MoneyAllocation>[]) {
        _custom[a.participantId] = TextEditingController(
          text: a.amount.toString(),
        );
      }
      _initialized = true;
    }
    if (mounted) setState(() {});
  }

  String _newId() {
    while (_items.any((i) => i.id == 'receipt-item-$_nextItem')) {
      _nextItem++;
    }
    return 'receipt-item-${_nextItem++}';
  }

  @override
  void dispose() {
    _session.removeListener(_refresh);
    _session.dispose();
    _title.dispose();
    _total.dispose();
    _date.dispose();
    _memo.dispose();
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

  ExpenseDraft _draft() {
    final total = parseExpenseAmount(_total.text);
    final amounts = <String, int>{};
    for (final item in _items) {
      for (final a in item.allocatedAmounts) {
        amounts.update(
          a.participantId,
          (v) => v + a.amount,
          ifAbsent: () => a.amount,
        );
      }
    }
    final allocations = _method == 'equal'
        ? allocateEqually(totalAmount: total, consumers: _consumers)
        : [
            for (final id in _consumers)
              MoneyAllocation(
                participantId: id,
                amount: _method == 'custom'
                    ? parseExpenseAmount(_controller(id).text)
                    : amounts[id] ?? 0,
              ),
          ];
    return ExpenseDraft(
      title: _title.text.trim(),
      category: _category,
      expenseDate: _date.text.trim(),
      totalAmount: total,
      currency: _currency,
      payer: ExpensePayer(participantId: _payer ?? '', amount: total),
      consumers: _consumers,
      allocationMethod: _method,
      allocatedAmounts: allocations,
      receiptItems: _method != 'itemized'
          ? []
          : [
              for (final (index, item) in _items.indexed)
                ReceiptItem(
                  id: item.id,
                  kind: item.kind,
                  name: item.name,
                  amount: item.amount,
                  consumers: item.consumers,
                  allocationMethod: item.allocationMethod,
                  allocatedAmounts: item.allocatedAmounts,
                  source: item.source,
                  sortOrder: index,
                ),
            ],
      source: _method == 'itemized'
          ? widget.expense?.source ?? 'ocr'
          : 'manual',
      placeId: _place,
      itineraryItemId: _itinerary,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
    );
  }

  void _validate(ExpenseDraft draft) {
    if (_currencyNeedsConfirmation) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '인식된 통화를 지원하지 않습니다. 금액을 확인하고 JPY 또는 KRW를 선택해 주세요.',
        retryable: false,
      );
    }
    draft.validate(
      tripId: widget.trip.id,
      participants: _session.participants,
      places: _session.places,
      itinerary: _session.itinerary,
      previous: widget.expense,
    );
  }

  Future<void> _save() async {
    if (_busy || _uncertain) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = _draft();
      _validate(draft);
      var id = widget.expense?.id;
      if (id == null) {
        id = (await widget.repositories.createExpense(
          widget.trip.id,
          draft,
        )).id;
      } else {
        await widget.repositories.updateExpense(widget.trip.id, id, draft);
      }
      if (mounted) Navigator.pop(context, id);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = actionError(error);
          _uncertain =
              widget.expense == null &&
              (error is! AppError ||
                  [
                    AppErrorCode.unknown,
                    AppErrorCode.unavailable,
                  ].contains(error.code));
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkLedger() async {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: _session,
        builder: (context, _) => AlertDialog(
          title: const Text('이미 저장되었는지 확인해 주세요'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '응답만 유실되었을 수 있습니다. 같은 지출이 있으면 편집을 나가고 비용 목록에서 확인해 주세요.',
                  ),
                  if (_session.error != null) Text(_session.error!.message),
                  for (final expense in _session.expenses)
                    ListTile(
                      title: Text(expense.title),
                      subtitle: Text(
                        '${expense.expenseDate} · ${formatExpenseMoney(expense.totalAmount, expense.currency)}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: _session.isLoading || _session.error != null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('중복 없음 · 재시도 허용'),
            ),
          ],
        ),
      ),
    );
    if (allow == true && mounted) {
      setState(() {
        _uncertain = false;
        _error = null;
      });
    }
  }

  Future<void> _editItem([int? index]) async {
    final participants = _session.participants
        .where(
          (p) =>
              _consumers.contains(p.id) ||
              (index != null && _items[index].consumers.contains(p.id)),
        )
        .toList();
    final item = index == null
        ? ReceiptItem(
            id: _newId(),
            kind: 'item',
            name: '',
            amount: 0,
            consumers: _consumers,
            allocationMethod: 'equal',
            allocatedAmounts: [],
            source: 'manual',
            sortOrder: _items.length,
          )
        : _items[index];
    final result = await Navigator.of(context).push<ReceiptItem>(
      MaterialPageRoute(
        builder: (_) =>
            ReceiptItemEditPage(item: item, participants: participants),
      ),
    );
    if (result != null && mounted) {
      if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
      _changed();
    }
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => TextField(
    key: ValueKey(key),
    controller: controller,
    enabled: !_busy,
    maxLines: lines,
    onChanged: (_) => _changed(),
    decoration: InputDecoration(labelText: label),
  );
  Widget _select(
    String key,
    String label,
    String selected,
    Map<String, String> options,
    ValueChanged<String> change,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$key-$selected'),
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: _busy
        ? null
        : (v) {
            change(v!);
            _changed();
          },
  );
  @override
  Widget build(BuildContext context) {
    ExpenseDraft? draft;
    String? validation;
    try {
      draft = _draft();
      _validate(draft);
    } catch (error) {
      validation = actionError(error);
    }
    final eligible = _session.participants
        .where(
          (p) =>
              p.isActive ||
              widget.expense?.payer.participantId == p.id ||
              (widget.expense?.consumers.contains(p.id) ?? false),
        )
        .toList();
    final itemTotal = _items.fold(0, (sum, item) => sum + item.amount);
    final allocated =
        draft?.allocatedAmounts.fold(0, (sum, a) => sum + a.amount) ?? 0;
    return EditFrame(
      title: '영수증 검토·배분',
      busy: _busy,
      dirty: _dirty,
      error: _error ?? validation,
      saveLabel: '확인하고 지출 저장',
      onSave:
          validation != null ||
              !_initialized ||
              _uncertain ||
              _session.error != null
          ? null
          : _save,
      children: [
        if (!_initialized) const LinearProgressIndicator(),
        if (_session.error != null) Text(_session.error!.message),
        if (_uncertain)
          OutlinedButton(
            onPressed: _checkLedger,
            child: const Text('비용 목록 확인 후 다시 시도'),
          ),
        if (widget.parsed != null)
          ExpansionTile(
            title: const Text('원문·번역 확인'),
            children: [
              if (widget.image != null)
                Image.memory(
                  widget.image!.bytes,
                  height: 160,
                  errorBuilder: (_, _, _) => const Text('이미지 미리보기를 열 수 없습니다.'),
                ),
              SelectableText(widget.parsed!.rawText),
              for (final item in widget.parsed!.items)
                ListTile(
                  title: Text(
                    '${item.nameOriginal} → ${item.nameTranslated ?? '번역 없음'}',
                  ),
                  subtitle: Text(
                    '인식 금액 ${item.amount ?? '확인 필요'} · 신뢰도 ${item.confidence == null ? '정보 없음' : '${(item.confidence! * 100).round()}%'}',
                  ),
                ),
              for (final warning in widget.parsed!.warnings) Text(warning),
            ],
          ),
        _field('receipt-title', _title, '지출 제목'),
        FieldPair(
          _field('receipt-total', _total, '영수증 총액'),
          _select(
            'receipt-currency',
            '통화',
            _currency,
            const {'JPY': 'JPY · 엔', 'KRW': 'KRW · 원'},
            (v) {
              _currency = v;
              _currencyNeedsConfirmation = false;
            },
          ),
        ),
        FieldPair(
          _field('receipt-date', _date, '날짜 · YYYY-MM-DD'),
          _select('receipt-category', '유형', _category, {
            ...expenseCategoryLabels,
            if (!expenseCategoryLabels.containsKey(_category))
              _category: _category,
          }, (v) => _category = v),
        ),
        _select('receipt-payer', '결제자', _payer ?? '', {
          '': '결제자 선택',
          for (final p in eligible) p.id: p.name,
          if (_payer != null && !eligible.any((p) => p.id == _payer))
            _payer!: '참여자 다시 선택 필요',
        }, (v) => _payer = v.isEmpty ? null : v),
        Wrap(
          spacing: 8,
          children: [
            for (final p in eligible)
              FilterChip(
                label: Text(p.name),
                selected: _consumers.contains(p.id),
                onSelected: _busy
                    ? null
                    : (v) {
                        if (v) {
                          _consumers.add(p.id);
                        } else {
                          _consumers.remove(p.id);
                        }
                        _changed();
                      },
              ),
          ],
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'itemized', label: Text('항목별')),
            ButtonSegment(value: 'equal', label: Text('전체 균등')),
            ButtonSegment(value: 'custom', label: Text('직접 입력')),
          ],
          selected: {_method},
          onSelectionChanged: _busy
              ? null
              : (v) {
                  if (v.first == 'custom' && _method != 'custom') {
                    for (final a
                        in draft?.allocatedAmounts ?? <MoneyAllocation>[]) {
                      _controller(a.participantId).text = a.amount.toString();
                    }
                  }
                  _method = v.first;
                  _changed();
                },
        ),
        if (_method == 'itemized') ...[
          const Text('항목을 눌러 이름·금액·소비자를 수정합니다. 길게 누르면 순서를 바꿀 수 있어요.'),
          SizedBox(
            height: _items.isEmpty ? 48 : 280,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _items.length,
              onReorderItem: (from, to) {
                if (!_busy) {
                  final item = _items.removeAt(from);
                  _items.insert(to, item);
                  _changed();
                }
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(item.id),
                  index: index,
                  enabled: !_busy,
                  child: Card(
                    child: ListTile(
                      key: ValueKey('receipt-row-${item.id}'),
                      onTap: _busy ? null : () => _editItem(index),
                      title: Text(item.name),
                      subtitle: Text(
                        '${receiptKindLabels[item.kind]} · ${formatExpenseMoney(item.amount, _currency)} · ${item.consumers.length}명',
                      ),
                      leading: const Icon(Icons.drag_handle),
                      trailing: IconButton(
                        tooltip: '${item.name} 제외',
                        onPressed: _busy
                            ? null
                            : () {
                                _items.removeAt(index);
                                _changed();
                              },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          OutlinedButton.icon(
            key: const Key('receipt-item-add'),
            onPressed: _busy || _items.length >= 200 ? null : () => _editItem(),
            icon: const Icon(Icons.add),
            label: const Text('누락 항목·할인·봉사료 추가'),
          ),
          Text('항목·조정 합계 ${formatExpenseMoney(itemTotal, _currency)}'),
        ],
        for (final id in _consumers)
          _method == 'custom'
              ? _field(
                  'receipt-custom-$id',
                  _controller(id),
                  '${_session.participants.where((p) => p.id == id).firstOrNull?.name ?? id} 부담액',
                )
              : Text(
                  '${_session.participants.where((p) => p.id == id).firstOrNull?.name ?? id} · ${formatExpenseMoney(draft?.allocatedAmounts.where((a) => a.participantId == id).firstOrNull?.amount ?? 0, _currency)}',
                ),
        Text(
          '배분 합계 ${formatExpenseMoney(allocated, _currency)} · 차액 ${formatExpenseMoney((draft?.totalAmount ?? 0) - allocated, _currency)}',
        ),
        if (_method != 'itemized')
          const Text('총액 분할로 저장하면 검토 항목은 원장에 저장하지 않습니다.'),
        ExpansionTile(
          title: const Text('장소·일정 연결과 메모'),
          children: [
            _select('receipt-place', '장소', _place ?? '', {
              '': '연결 없음',
              for (final p in _session.places) p.id: p.name,
              if (_place != null && !_session.places.any((p) => p.id == _place))
                _place!: '삭제된 장소 · 해제 필요',
            }, (v) => _place = v.isEmpty ? null : v),
            _select('receipt-itinerary', '일정', _itinerary ?? '', {
              '': '연결 없음',
              for (final i in _session.itinerary) i.id: i.title,
              if (_itinerary != null &&
                  !_session.itinerary.any((i) => i.id == _itinerary))
                _itinerary!: '삭제된 일정 · 해제 필요',
            }, (v) => _itinerary = v.isEmpty ? null : v),
            _field('receipt-memo', _memo, '메모', lines: 3),
          ],
        ),
      ],
    );
  }
}
