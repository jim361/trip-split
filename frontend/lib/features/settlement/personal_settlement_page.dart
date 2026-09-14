import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/trip_session.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../shared/widgets/edit_frame.dart';
import 'expense_detail_page.dart';
import 'expense_edit_page.dart';
import 'settlement_engine.dart';

class PersonalSettlementPage extends StatefulWidget {
  const PersonalSettlementPage({
    required this.trip,
    required this.repositories,
    required this.currentUid,
    super.key,
  });
  final Trip trip;
  final TripRepositories repositories;
  final String currentUid;
  @override
  State<PersonalSettlementPage> createState() => _PersonalSettlementPageState();
}

class _PersonalSettlementPageState extends State<PersonalSettlementPage> {
  late final TripSessionController _session;
  late String _currency;
  String _date = '', _category = '';
  @override
  void initState() {
    super.initState();
    _currency = widget.trip.defaultCurrency;
    _session = TripSessionController(
      tripId: widget.trip.id,
      repositories: widget.repositories,
    )..start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('개인 소비·정산')),
    body: AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        if (_session.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_session.error != null) {
          return Center(child: Text(_session.error!.message));
        }
        final linked = _session.participants
            .where((p) => p.linkedUid == widget.currentUid)
            .toList();
        if (linked.length != 1) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('정산 참여자 관리에서 내 계정을 연결해 주세요.'),
            ),
          );
        }
        final me = linked.single;
        final balances = balancesForCurrency(_session.expenses, _currency);
        final mine = balances[me.id] ?? (paid: 0, owed: 0, net: 0);
        final personal = _session.expenses
            .where(
              (e) =>
                  e.currency == _currency &&
                  e.allocatedAmounts.any((a) => a.participantId == me.id),
            )
            .toList();
        int own(Expense e) => e.allocatedAmounts
            .where((a) => a.participantId == me.id)
            .fold(0, (sum, a) => sum + a.amount);
        final categoryTotals = <String, int>{};
        for (final expense in personal) {
          categoryTotals.update(
            expense.category,
            (v) => v + own(expense),
            ifAbsent: () => own(expense),
          );
        }
        final dates = personal.map((e) => e.expenseDate).toSet().toList()
          ..sort();
        final date = dates.contains(_date) ? _date : '';
        final category = categoryTotals.containsKey(_category) ? _category : '';
        final filtered = personal.where(
          (e) =>
              (date.isEmpty || e.expenseDate == date) &&
              (category.isEmpty || e.category == category),
        );
        final names = {for (final p in _session.participants) p.id: p.name};
        List<Transfer> transfers;
        try {
          transfers = proposeTransfers(balances);
        } catch (error) {
          return Center(child: Text(actionError(error)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'JPY', label: Text('JPY · 엔')),
                ButtonSegment(value: 'KRW', label: Text('KRW · 원')),
              ],
              selected: {_currency},
              onSelectionChanged: (v) => setState(() {
                _currency = v.first;
                _date = '';
                _category = '';
              }),
            ),
            const SizedBox(height: 24),
            Text(
              '${me.name}님의 소비',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '결제 ${formatExpenseMoney(mine.paid, _currency)} · 부담 ${formatExpenseMoney(mine.owed, _currency)}',
            ),
            Text(
              '${mine.net >= 0 ? '받을' : '보낼'} 금액 ${formatExpenseMoney(mine.net.abs(), _currency)}',
            ),
            const SizedBox(height: 24),
            Text('카테고리별 부담액', style: Theme.of(context).textTheme.titleLarge),
            for (final e in categoryTotals.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expenseCategoryLabels[e.key] ?? e.key),
                trailing: Text(formatExpenseMoney(e.value, _currency)),
              ),
            const SizedBox(height: 16),
            FieldPair(
              DropdownButtonFormField<String>(
                key: ValueKey('personal-date-$_currency-$date'),
                initialValue: date,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '날짜'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('전체 날짜')),
                  for (final d in dates)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() => _date = v!),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('personal-category-$_currency-$category'),
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '유형'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('전체 유형')),
                  for (final c in categoryTotals.keys)
                    DropdownMenuItem(
                      value: c,
                      child: Text(expenseCategoryLabels[c] ?? c),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('선택한 조건의 개인 소비가 없습니다.'),
              ),
            for (final expense in filtered)
              Card(
                child: ListTile(
                  title: Text(expense.title),
                  subtitle: Text(
                    [
                      expense.expenseDate,
                      if (expense.placeId != null)
                        _session.places
                                .where((p) => p.id == expense.placeId)
                                .firstOrNull
                                ?.name ??
                            '삭제된 장소',
                      for (final item in expense.receiptItems)
                        if (item.consumers.contains(me.id))
                          '${item.name} · ${formatExpenseMoney(item.allocatedAmounts.where((a) => a.participantId == me.id).fold(0, (sum, a) => sum + a.amount), _currency)}',
                    ].join('\n'),
                  ),
                  trailing: Text(formatExpenseMoney(own(expense), _currency)),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ExpenseDetailPage(
                        trip: widget.trip,
                        repositories: widget.repositories,
                        expenseId: expense.id,
                        currentUserUid: widget.currentUid,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('송금 제안', style: Theme.of(context).textTheme.titleLarge),
            if (transfers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('송금할 금액이 없습니다.'),
              ),
            for (final transfer in transfers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${names[transfer.from] ?? transfer.from} → ${names[transfer.to] ?? transfer.to}',
                ),
                trailing: Text(formatExpenseMoney(transfer.amount, _currency)),
              ),
            const Text('현재 원장으로 계산한 제안이며 통화끼리 합산하지 않습니다.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(
                    ClipboardData(
                      text: settlementShareText(
                        widget.trip.title,
                        _session.expenses,
                        _session.participants,
                      ),
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('정산 문구를 복사했습니다.')),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(actionError(error))));
                  }
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('모든 통화 정산 문구 복사'),
            ),
          ],
        );
      },
    ),
  );
}
