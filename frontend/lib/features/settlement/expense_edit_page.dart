import 'package:flutter/material.dart';

import '../../app/trip_session.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'settlement_engine.dart';

const expenseCategoryLabels = {
  'food': '식비',
  'transport': '교통',
  'stay': '숙박',
  'activity': '관광·활동',
  'shopping': '쇼핑',
  'other': '기타',
};

String formatExpenseMoney(int amount, String currency) =>
    '$currency ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

int parseExpenseAmount(String input, {String field = 'totalAmount'}) {
  final text = input.trim();
  final amount = int.tryParse(text.replaceAll(',', ''));
  if (!RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)$').hasMatch(text) ||
      amount == null ||
      amount < 0 ||
      amount > 9007199254740991) {
    throw AppError(
      code: AppErrorCode.invalidArgument,
      message: '금액은 소수점 없는 0 이상의 정수로 입력해 주세요.',
      retryable: false,
      field: field,
    );
  }
  return amount;
}

class ExpenseEditPage extends StatefulWidget {
  const ExpenseEditPage({
    super.key,
    required this.trip,
    required this.repositories,
    required this.currentUserUid,
    required this.participants,
    this.expense,
  });

  final Trip trip;
  final TripRepositories repositories;
  final String currentUserUid;
  final List<Participant> participants;
  final Expense? expense;

  @override
  State<ExpenseEditPage> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  late final TripSessionController _session;
  late final Map<String, TextEditingController> _fields;
  final _amounts = <String, TextEditingController>{};
  final _scroll = ScrollController();
  late final List<String> _consumers;
  late String _currency, _category, _method;
  String? _payer, _placeId, _itineraryId;
  int _step = 0;
  bool _busy = false, _dirty = false, _confirming = false, _uncertain = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _fields = {
      'title': TextEditingController(text: expense?.title ?? ''),
      'expenseDate': TextEditingController(
        text: expense?.expenseDate ?? widget.trip.startDate,
      ),
      'totalAmount': TextEditingController(
        text: expense?.totalAmount.toString() ?? '',
      ),
      'memo': TextEditingController(text: expense?.memo ?? ''),
    };
    _currency = expense?.currency ?? widget.trip.defaultCurrency;
    _category = expense?.category ?? 'food';
    _method = expense?.allocationMethod ?? 'equal';
    final active = widget.participants.where((p) => p.isActive).toList();
    final linked = active
        .where((p) => p.linkedUid == widget.currentUserUid)
        .toList();
    _payer =
        expense?.payer.participantId ??
        (linked.length == 1 ? linked.single.id : null);
    _consumers =
        expense?.consumers.toList() ?? active.map((p) => p.id).toList();
    _placeId = expense?.placeId;
    _itineraryId = expense?.itineraryItemId;
    for (final allocation
        in _method == 'custom'
            ? expense!.allocatedAmounts
            : <MoneyAllocation>[]) {
      _amounts[allocation.participantId] = TextEditingController(
        text: '${allocation.amount}',
      );
    }
    _session =
        TripSessionController(
            tripId: widget.trip.id,
            repositories: widget.repositories,
          )
          ..addListener(_refresh)
          ..start();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _changed() => setState(() {
    _dirty = true;
    _error = null;
  });

  @override
  void dispose() {
    _session.removeListener(_refresh);
    _session.dispose();
    for (final field in [..._fields.values, ..._amounts.values]) {
      field.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  List<Participant> get _participants =>
      _session.isLoading ? widget.participants : _session.participants;
  Set<String> get _existingPeople => {
    if (widget.expense != null) widget.expense!.payer.participantId,
    ...?widget.expense?.consumers,
  };
  List<Participant> get _eligible => _participants
      .where((p) => p.isActive || _existingPeople.contains(p.id))
      .toList();
  String _name(String id) {
    final matches = _participants.where((p) => p.id == id);
    if (matches.isEmpty) return '삭제된 참여자';
    final person = matches.single;
    return '${person.name}${person.isActive ? '' : ' (비활성)'}';
  }

  ExpenseDraft _draft({bool equalPreview = false}) {
    final amount = parseExpenseAmount(_fields['totalAmount']!.text);
    final method = equalPreview ? 'equal' : _method;
    return ExpenseDraft(
      title: _fields['title']!.text.trim(),
      category: _category,
      expenseDate: _fields['expenseDate']!.text.trim(),
      totalAmount: amount,
      currency: _currency,
      payer: ExpensePayer(participantId: _payer ?? '', amount: amount),
      consumers: _consumers,
      allocationMethod: method,
      allocatedAmounts: method == 'equal'
          ? allocateEqually(totalAmount: amount, consumers: _consumers)
          : [
              for (final id in _consumers)
                MoneyAllocation(
                  participantId: id,
                  amount: parseExpenseAmount(
                    _amounts[id]?.text ?? '',
                    field: 'amount-$id',
                  ),
                ),
            ],
      receiptItems: const [],
      source: 'manual',
      placeId: _placeId,
      itineraryItemId: _itineraryId,
      memo: _fields['memo']!.text.trim().isEmpty
          ? null
          : _fields['memo']!.text.trim(),
    );
  }

  void _validate(ExpenseDraft draft) => draft.validateManual(
    tripId: widget.trip.id,
    participants: _participants,
    places: _session.places,
    itinerary: _session.itinerary,
    previous: widget.expense,
  );

  @override
  Widget build(BuildContext context) {
    ExpenseDraft? preview;
    AppError? validation;
    if (_step == 1) {
      try {
        preview = _draft();
        _validate(preview);
      } on AppError catch (error) {
        validation = error;
      }
    }
    final error = _error ?? _session.error ?? validation;
    final ready = !_busy && !_session.isLoading && _session.error == null;
    return PopScope<String>(
      canPop: !_busy && !_dirty && _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expense == null ? '지출 추가' : '지출 편집'),
          leading: IconButton(
            tooltip: '지출 편집 뒤로',
            onPressed: _busy ? null : _back,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      _step == 0 ? '1 / 2  기본 정보' : '2 / 2  배분 확인',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  LinearProgressIndicator(value: _step == 0 ? .5 : 1),
                  Expanded(
                    child: ListView(
                      controller: _scroll,
                      key: const Key('expense-edit-fields'),
                      padding: const EdgeInsets.all(16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: _step == 0
                          ? _basicFields(error)
                          : _splitFields(preview, error),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                error.message,
                                key: const Key('expense-edit-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        if (_uncertain)
                          TextButton(
                            onPressed: _busy ? null : _checkLedger,
                            child: const Text('비용 목록 확인 후 다시 시도'),
                          ),
                        FilledButton(
                          key: Key(
                            _step == 0 ? 'expense-next' : 'expense-save',
                          ),
                          onPressed:
                              !ready ||
                                  _uncertain ||
                                  (_step == 1 && validation != null)
                              ? null
                              : _step == 0
                              ? _next
                              : _save,
                          child: Text(
                            _busy
                                ? '저장 중…'
                                : _step == 0
                                ? '다음 · 배분 확인'
                                : '지출 저장',
                          ),
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

  List<Widget> _basicFields(AppError? error) => [
    _text('title', '지출 제목', error: error, maxLength: 160),
    const SizedBox(height: 16),
    _pair(
      _text('totalAmount', '총액', error: error, keyboard: TextInputType.number),
      _select(
        'currency',
        '통화',
        _currency,
        const {'JPY': 'JPY · 엔', 'KRW': 'KRW · 원'},
        (value) {
          _currency = value;
          _changed();
        },
      ),
    ),
    _pair(
      _text(
        'expenseDate',
        '날짜',
        error: error,
        keyboard: TextInputType.datetime,
        suffix: IconButton(
          tooltip: '지출 날짜 선택',
          onPressed: _busy ? null : _pickDate,
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
      _select(
        'category',
        '유형',
        _category,
        {
          ...expenseCategoryLabels,
          if (!expenseCategoryLabels.containsKey(_category))
            _category: _category,
        },
        (value) {
          _category = value;
          _changed();
        },
      ),
    ),
    _select(
      'payer',
      '결제한 사람',
      _payer ?? '',
      {
        '': '결제자를 선택해 주세요',
        if (_payer != null && !_eligible.any((p) => p.id == _payer))
          _payer!: '선택할 수 없는 참여자',
        for (final p in _eligible) p.id: _name(p.id),
      },
      (value) {
        _payer = value.isEmpty ? null : value;
        _changed();
      },
      error: error,
    ),
    const SizedBox(height: 16),
    _text('memo', '메모 (선택)', error: error, maxLines: 2),
    ExpansionTile(
      title: const Text('장소·일정 연결 (선택)'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      initiallyExpanded: _placeId != null || _itineraryId != null,
      children: [
        _select(
          'placeId',
          '장소',
          _placeId ?? '',
          {
            '': '장소 없음',
            ?_placeId: '삭제된 장소 · 연결 해제 필요',
            for (final p in _session.places) p.id: p.name,
          },
          (value) {
            _placeId = value.isEmpty ? null : value;
            _changed();
          },
          error: error,
        ),
        const SizedBox(height: 16),
        _select(
          'itineraryItemId',
          '일정',
          _itineraryId ?? '',
          {
            '': '일정 없음',
            ?_itineraryId: '삭제된 일정 · 연결 해제 필요',
            for (final i in _session.itinerary)
              i.id: '${i.date.substring(5)} ${i.planId}안 · ${i.title}',
          },
          (value) {
            _itineraryId = value.isEmpty ? null : value;
            _changed();
          },
          error: error,
        ),
      ],
    ),
  ];

  List<Widget> _splitFields(ExpenseDraft? preview, AppError? error) {
    final total = parseExpenseAmount(_fields['totalAmount']!.text);
    final allocations = {
      for (final a in preview?.allocatedAmounts ?? <MoneyAllocation>[])
        a.participantId: a.amount,
    };
    final sum = allocations.values.fold<int>(0, (a, b) => a + b);
    final ids = [
      ..._consumers,
      ..._eligible.map((p) => p.id).where((id) => !_consumers.contains(id)),
    ];
    return [
      Text(
        _fields['title']!.text,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(
        formatExpenseMoney(total, _currency),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text('${_fields['expenseDate']!.text} · ${_name(_payer!)} 결제'),
      const SizedBox(height: 24),
      const Text('함께 부담할 사람'),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        key: const Key('expense-split-method'),
        segments: const [
          ButtonSegment(value: 'equal', label: Text('균등 분할')),
          ButtonSegment(value: 'custom', label: Text('직접 입력')),
        ],
        selected: {_method},
        onSelectionChanged: _busy
            ? null
            : (selected) {
                if (selected.single == 'custom' && _consumers.isNotEmpty) {
                  for (final a in allocateEqually(
                    totalAmount: total,
                    consumers: _consumers,
                  )) {
                    _amounts.putIfAbsent(
                      a.participantId,
                      () => TextEditingController(text: '${a.amount}'),
                    );
                  }
                }
                _method = selected.single;
                _changed();
              },
      ),
      const SizedBox(height: 12),
      for (final id in ids)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                key: ValueKey('expense-consumer-$id'),
                value: _consumers.contains(id),
                onChanged: _busy
                    ? null
                    : (checked) {
                        if (checked!) {
                          _consumers.add(id);
                        } else {
                          _consumers.remove(id);
                        }
                        _amounts.putIfAbsent(
                          id,
                          () => TextEditingController(text: '0'),
                        );
                        _changed();
                      },
              ),
              Expanded(child: Text(_name(id))),
              if (_consumers.contains(id))
                SizedBox(
                  width: 128,
                  child: _method == 'custom'
                      ? TextField(
                          key: ValueKey('expense-amount-$id'),
                          controller: _amounts.putIfAbsent(
                            id,
                            () => TextEditingController(text: '0'),
                          ),
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _changed(),
                          decoration: InputDecoration(
                            labelText: _currency,
                            contentPadding: const EdgeInsets.all(12),
                            errorText: error?.field == 'amount-$id'
                                ? '정수 입력'
                                : null,
                          ),
                        )
                      : Text(
                          formatExpenseMoney(allocations[id] ?? 0, _currency),
                          key: ValueKey('expense-allocation-$id'),
                          textAlign: TextAlign.right,
                        ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      Text(
        _method == 'equal'
            ? '나머지 1원·1엔은 위에 표시된 선택 순서대로 나눕니다.'
            : '선택한 사람의 부담액 합계를 총액과 맞춰 주세요.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '배분 합계  ${formatExpenseMoney(sum, _currency)}',
              key: const Key('expense-allocation-total'),
            ),
            const SizedBox(height: 8),
            Text(
              sum == total && preview != null
                  ? '총액과 일치합니다.'
                  : sum < total
                  ? '${formatExpenseMoney(total - sum, _currency)} 부족합니다.'
                  : '${formatExpenseMoney(sum - total, _currency)} 초과했습니다.',
              key: const Key('expense-allocation-status'),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _text(
    String field,
    String label, {
    AppError? error,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboard,
    Widget? suffix,
  }) => TextField(
    key: ValueKey('expense-$field'),
    controller: _fields[field],
    enabled: !_busy,
    onChanged: (_) => _changed(),
    maxLength: maxLength,
    maxLines: maxLines,
    keyboardType: keyboard,
    textInputAction: maxLines > 1
        ? TextInputAction.newline
        : TextInputAction.next,
    style: Theme.of(context).textTheme.bodyMedium,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      errorText: error?.field == field ? error?.message : null,
    ),
  );

  Widget _select(
    String field,
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged, {
    AppError? error,
  }) => DropdownButtonFormField<String>(
    key: ValueKey('expense-$field-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      errorText: error?.field == field ? error?.message : null,
    ),
    items: [
      for (final entry in options.entries)
        DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: _busy ? null : (value) => onChanged(value!),
  );

  Widget _pair(Widget first, Widget second) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            328 * MediaQuery.textScalerOf(context).scale(14) / 14) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 16), second],
          );
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
    ),
  );

  void _next() {
    FocusScope.of(context).unfocus();
    try {
      _validate(_draft(equalPreview: true));
      _scroll.jumpTo(0);
      setState(() {
        _step = 1;
        _error = null;
      });
    } on AppError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _save() async {
    if (_busy || _uncertain) return;
    FocusScope.of(context).unfocus();
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
          _error = error is AppError
              ? error
              : const AppError(
                  code: AppErrorCode.unknown,
                  message: '저장하지 못했습니다. 입력 내용은 유지됩니다.',
                  retryable: false,
                );
          _uncertain =
              widget.expense == null &&
              const [
                AppErrorCode.unavailable,
                AppErrorCode.unknown,
              ].contains(_error!.code);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkLedger() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: _session,
        builder: (context, _) => AlertDialog(
          title: const Text('중복 등록 여부를 확인해 주세요'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('통신 오류 전에 저장됐을 수 있습니다. 같은 지출이 있으면 편집을 닫아 주세요.'),
                  const SizedBox(height: 16),
                  if (_session.error != null) Text(_session.error!.message),
                  for (final expense in _session.expenses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${expense.expenseDate} · ${expense.title}\n${formatExpenseMoney(expense.totalAmount, expense.currency)}',
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
            TextButton(
              onPressed: _session.isLoading || _session.error != null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('중복 없음 · 재시도 허용'),
            ),
          ],
        ),
      ),
    );
    if (mounted && confirmed == true) {
      setState(() {
        _uncertain = false;
        _error = null;
      });
    }
  }

  Future<void> _back() async {
    if (_busy || _confirming) return;
    FocusScope.of(context).unfocus();
    if (_step == 1) {
      _scroll.jumpTo(0);
      setState(() {
        _step = 0;
        _error = null;
      });
      return;
    }
    if (_dirty) {
      _confirming = true;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('편집을 그만둘까요?'),
          content: const Text('저장하지 않은 입력이 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('나가기'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (leave != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final first = DateTime(2000), last = DateTime(2100, 12, 31);
    var initial =
        DateTime.tryParse(_fields['expenseDate']!.text) ??
        DateTime.parse(widget.trip.startDate);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (date != null && mounted) {
      _fields['expenseDate']!.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _changed();
    }
  }
}
