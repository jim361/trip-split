import 'package:flutter/material.dart';

import '../../app/trip_session.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'expense_edit_page.dart';
import '../receipts/receipt_review_page.dart';
import '../receipts/receipt_item_edit_page.dart';

class ExpenseDetailPage extends StatefulWidget {
  const ExpenseDetailPage({
    super.key,
    required this.trip,
    required this.repositories,
    required this.expenseId,
    required this.currentUserUid,
  });

  final Trip trip;
  final TripRepositories repositories;
  final String expenseId, currentUserUid;

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late final TripSessionController _session;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _session.removeListener(_refresh);
    _session.dispose();
    super.dispose();
  }

  String _name(String id) {
    final people = _session.participants.where((p) => p.id == id);
    return people.isEmpty ? '알 수 없는 참여자' : people.single.name;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _session.expenses.where(
      (expense) => expense.id == widget.expenseId,
    );
    final expense = matches.isEmpty ? null : matches.single;
    return PopScope<void>(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지출 상세'),
          leading: IconButton(
            tooltip: '비용 목록으로',
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _session.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _session.error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_session.error!.message),
                    )
                  : expense == null
                  ? const Center(child: Text('이 지출은 삭제됐습니다. 비용 목록에서 확인해 주세요.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          expense.title,
                          key: const Key('expense-detail-title'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          formatExpenseMoney(
                            expense.totalAmount,
                            expense.currency,
                          ),
                          key: const Key('expense-detail-total'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${expense.expenseDate} · ${expenseCategoryLabels[expense.category] ?? expense.category}',
                        ),
                        const SizedBox(height: 8),
                        Text('${_name(expense.payer.participantId)} 결제'),
                        const SizedBox(height: 24),
                        const Divider(),
                        for (final item in expense.receiptItems)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: Text(
                              '${receiptKindLabels[item.kind]} · ${item.consumers.map(_name).join(', ')}',
                            ),
                            trailing: Text(
                              formatExpenseMoney(item.amount, expense.currency),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          expense.allocationMethod == 'equal'
                              ? '균등 분할'
                              : expense.allocationMethod == 'custom'
                              ? '직접 입력'
                              : '항목별 분할',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final id in expense.consumers)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(child: Text(_name(id))),
                                Text(
                                  formatExpenseMoney(
                                    expense.allocatedAmounts
                                        .where((a) => a.participantId == id)
                                        .fold<int>(
                                          0,
                                          (sum, a) => sum + a.amount,
                                        ),
                                    expense.currency,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        if (expense.placeId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              '장소 · ${_session.places.where((p) => p.id == expense.placeId).firstOrNull?.name ?? '삭제된 장소'}',
                            ),
                          ),
                        if (expense.itineraryItemId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              '일정 · ${_session.itinerary.where((i) => i.id == expense.itineraryItemId).firstOrNull?.title ?? '삭제된 일정'}',
                            ),
                          ),
                        if (expense.memo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(expense.memo!),
                          ),
                        const SizedBox(height: 32),
                        if (_error != null)
                          Text(
                            _error!,
                            key: const Key('expense-detail-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (expense.source == 'manual' &&
                            expense.receiptItems.isEmpty &&
                            const [
                              'equal',
                              'custom',
                            ].contains(expense.allocationMethod))
                          FilledButton(
                            key: const Key('expense-edit'),
                            onPressed: _busy ? null : () => _edit(expense),
                            child: const Text('지출 수정'),
                          )
                        else
                          FilledButton(
                            key: const Key('expense-edit'),
                            onPressed: _busy
                                ? null
                                : () async {
                                    setState(() => _busy = true);
                                    await Navigator.of(context).push<String>(
                                      MaterialPageRoute(
                                        builder: (_) => ReceiptReviewPage(
                                          trip: widget.trip,
                                          repositories: widget.repositories,
                                          currentUid: widget.currentUserUid,
                                          expense: expense,
                                        ),
                                      ),
                                    );
                                    if (mounted) setState(() => _busy = false);
                                  },
                            child: const Text('항목별 지출 수정'),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('expense-delete'),
                          onPressed: _busy ? null : () => _delete(expense),
                          child: const Text('지출 삭제'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('expense-to-list'),
                          onPressed: _busy
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('비용 목록으로'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(Expense expense) async {
    if (_busy) return;
    setState(() => _busy = true);
    ScaffoldMessenger.of(context).clearSnackBars();
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ExpenseEditPage(
          trip: widget.trip,
          repositories: widget.repositories,
          expense: expense,
          currentUserUid: widget.currentUserUid,
          participants: _session.participants,
        ),
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete(Expense expense) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지출을 삭제할까요?'),
        content: const Text('삭제하면 비용 요약과 부담액도 다시 계산됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    try {
      if (confirmed == true) {
        await widget.repositories.deleteExpense(widget.trip.id, expense.id);
        if (mounted) Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AppError
              ? error.message
              : '지출을 삭제하지 못했습니다. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
