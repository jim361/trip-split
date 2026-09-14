import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

import 'settlement_engine.dart';
import '../../shared/widgets/edit_frame.dart';

// [TASK-06 · 정산] 참가자와 통화별 지출을 보여 주는 화면 경계입니다.
class SettlementPage extends StatelessWidget {
  const SettlementPage({
    super.key,
    required this.trip,
    required this.currentUserUid,
    required this.participants,
    required this.expenses,
    required this.onOpenReceipts,
    required this.onAddExpense,
    required this.onOpenExpense,
    this.onManageParticipants,
    this.onPersonalSettlement,
  });

  final Trip trip;
  final String currentUserUid;
  final List<Participant> participants;
  final List<Expense> expenses;
  final VoidCallback onOpenReceipts;
  final VoidCallback onAddExpense;
  final ValueChanged<Expense> onOpenExpense;
  final VoidCallback? onManageParticipants;
  final VoidCallback? onPersonalSettlement;

  @override
  Widget build(BuildContext context) {
    final activeParticipants = participants
        .where((participant) => participant.isActive)
        .toList();
    final linkedParticipants = participants
        .where((participant) => participant.linkedUid == currentUserUid)
        .toList();
    final me = linkedParticipants.length == 1
        ? linkedParticipants.single
        : null;
    final totalsByCurrency = <CurrencyCode, CurrencyAmount>{};
    for (final expense in expenses) {
      totalsByCurrency.update(
        expense.currency,
        (total) => total + expense.totalAmount,
        ifAbsent: () => expense.totalAmount,
      );
    }
    if (totalsByCurrency.isEmpty) {
      totalsByCurrency[trip.defaultCurrency] = 0;
    }
    final currencyTotals = totalsByCurrency.entries.toList()
      ..sort((left, right) {
        if (left.key == trip.defaultCurrency) return -1;
        if (right.key == trip.defaultCurrency) return 1;
        return left.key.compareTo(right.key);
      });

    final defaultExpenses = expenses.where(
      (expense) => expense.currency == trip.defaultCurrency,
    );
    final paid = me == null
        ? 0
        : defaultExpenses
              .where((expense) => expense.payer.participantId == me.id)
              .fold<int>(0, (total, expense) => total + expense.payer.amount);
    final share = me == null
        ? 0
        : defaultExpenses.fold<int>(
            0,
            (total, expense) =>
                total +
                expense.allocatedAmounts
                    .where((allocation) => allocation.participantId == me.id)
                    .fold<int>(0, (sum, allocation) => sum + allocation.amount),
          );
    final balance = paid - share;
    final hasMixedCurrencies = currencyTotals.length > 1;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '03 / EXPENSES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _labelStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('여행 비용', style: textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIP TOTAL / ${trip.defaultCurrency}',
                          style: _labelStyle,
                        ),
                        const SizedBox(height: 6),
                        for (final total in currencyTotals)
                          Text(
                            _formatMoney(total.value, total.key),
                            key: ValueKey('currency-total-${total.key}'),
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: -1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '지출 ${expenses.length}건 · '
                      '${activeParticipants.length}명${hasMixedCurrencies ? ' · 환율 미적용' : ''}',
                      textAlign: TextAlign.right,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedInk,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              if (onManageParticipants != null)
                TextButton.icon(
                  onPressed: onManageParticipants,
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('정산 참여자 관리'),
                ),
              if (onPersonalSettlement != null)
                TextButton.icon(
                  onPressed: onPersonalSettlement,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('개인 소비·정산'),
                ),
            ],
          ),
        ),
        if (me == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('아직 내 정산 참여자가 연결되지 않았습니다. 여행 전체 지출은 확인할 수 있습니다.'),
          )
        else
          _FinancialSummary(
            currency: trip.defaultCurrency,
            paid: paid,
            share: share,
            balance: balance,
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.ink,
                width: AppTheme.sectionStroke,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('expense-add'),
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('지출 추가'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenReceipts,
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('영수증으로 등록'),
                ),
              ),
            ],
          ),
        ),
        _ExpenseLedger(
          expenses: expenses,
          showCurrency: hasMixedCurrencies,
          onOpenExpense: onOpenExpense,
        ),
        if (me != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 32, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.line)),
                  ),
                  child: const Text('최종 정산', style: _labelStyle),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        balance >= 0 ? '동행에게 받을 금액' : '동행에게 보낼 금액',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _formatMoney(balance.abs(), trip.defaultCurrency),
                      style: textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await Clipboard.setData(
                          ClipboardData(
                            text: settlementShareText(
                              trip.title,
                              expenses,
                              participants,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(actionError(error))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.content_copy_outlined, size: 18),
                    label: const Text('정산 문구 복사'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({
    required this.currency,
    required this.paid,
    required this.share,
    required this.balance,
  });

  final CurrencyCode currency;
  final CurrencyAmount paid;
  final CurrencyAmount share;
  final CurrencyAmount balance;

  @override
  Widget build(BuildContext context) {
    final values = [paid, share, balance.abs()];
    final labels = ['내가 결제', '내가 부담', balance >= 0 ? '받을 금액' : '보낼 금액'];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.ink,
            width: AppTheme.sectionStroke,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 96),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: index == 2
                      ? Theme.of(context).colorScheme.surfaceContainerLow
                      : Colors.transparent,
                  border: index < 2
                      ? const Border(right: BorderSide(color: AppTheme.line))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[index],
                      style: _labelStyle.copyWith(
                        color: index == 2
                            ? AppTheme.primary
                            : AppTheme.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatMoney(values[index], currency),
                          key: ValueKey('personal-summary-$index'),
                          style: TextStyle(
                            color: index == 2 ? AppTheme.primary : AppTheme.ink,
                            fontWeight: index == 2
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseLedger extends StatelessWidget {
  const _ExpenseLedger({
    required this.expenses,
    required this.showCurrency,
    required this.onOpenExpense,
  });

  final List<Expense> expenses;
  final bool showCurrency;
  final ValueChanged<Expense> onOpenExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.ink,
            width: AppTheme.sectionStroke,
          ),
        ),
      ),
      child: Column(
        children: [
          const _LedgerRow(
            date: 'DATE',
            item: 'ITEM',
            amount: 'AMOUNT',
            header: true,
          ),
          if (expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('아직 등록된 지출이 없습니다.'),
            )
          else
            for (final expense in expenses)
              Material(
                child: InkWell(
                  key: ValueKey('expense-row-${expense.id}'),
                  onTap: () => onOpenExpense(expense),
                  child: _LedgerRow(
                    date: _shortDate(expense.expenseDate),
                    item: expense.title,
                    amount: showCurrency
                        ? _formatMoney(expense.totalAmount, expense.currency)
                        : _formatAmount(expense.totalAmount),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.date,
    required this.item,
    required this.amount,
    this.header = false,
  });

  final String date;
  final String item;
  final String amount;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = header
        ? _labelStyle.copyWith(color: AppTheme.mutedInk)
        : Theme.of(context).textTheme.bodyMedium;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: header ? 8 : 12),
      decoration: BoxDecoration(
        color: header
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : null,
        border: const Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              date,
              style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(item, overflow: TextOverflow.ellipsis, style: style),
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortDate(LocalDate date) {
  if (date.length < 10) return date;
  return '${date.substring(5, 7)}.${date.substring(8, 10)}';
}

String _formatMoney(CurrencyAmount amount, CurrencyCode currency) {
  return '$currency ${_formatAmount(amount)}';
}

String _formatAmount(CurrencyAmount amount) {
  final digits = amount.abs().toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      formatted.write(',');
    }
    formatted.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$formatted';
}

const _labelStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  height: 1,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
  fontFeatures: [FontFeature.tabularFigures()],
);
