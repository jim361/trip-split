import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';

// [TASK-06 · 정산] 참가자와 JPY 지출을 보여 주는 화면 경계입니다.
class SettlementPage extends StatelessWidget {
  const SettlementPage({
    super.key,
    required this.trip,
    required this.participants,
    required this.expenses,
    required this.onOpenReceipts,
  });

  final Trip trip;
  final List<Participant> participants;
  final List<Expense> expenses;
  final VoidCallback onOpenReceipts;

  @override
  Widget build(BuildContext context) {
    final activeParticipants = participants
        .where((participant) => participant.isActive)
        .toList();
    final participantById = {
      for (final participant in participants) participant.id: participant,
    };
    final total = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.totalAmount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('여행 비용', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${trip.title} · ${activeParticipants.length}명'),
        const SizedBox(height: 16),
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('현재 지출 합계'),
                const SizedBox(height: 6),
                Text(
                  '${trip.defaultCurrency} ¥$total',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text('지출 ${expenses.length}건 · 항목별 배분 계산은 후속 구현'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('참가자', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final participant in activeParticipants)
              Chip(
                avatar: const Icon(Icons.person_outline, size: 18),
                label: Text(participant.name),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                '지출 내역',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: onOpenReceipts,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('영수증으로 등록'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (expenses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('아직 등록된 지출이 없습니다.'),
            ),
          )
        else
          for (final expense in expenses)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.payments_outlined),
                ),
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.expenseDate} · '
                  '${participantById[expense.payer.participantId]?.name ?? '알 수 없음'} 결제',
                ),
                trailing: Text('¥${expense.totalAmount}'),
              ),
            ),
      ],
    );
  }
}
