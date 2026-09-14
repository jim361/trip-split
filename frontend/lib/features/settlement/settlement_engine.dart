import '../../domain/models.dart';

typedef ParticipantBalance = ({int paid, int owed, int net});
typedef Transfer = ({String from, String to, int amount});

Map<String, ParticipantBalance> balancesForCurrency(
  List<Expense> expenses,
  String currency,
) {
  final paid = <String, int>{}, owed = <String, int>{};
  for (final expense in expenses.where((e) => e.currency == currency)) {
    paid.update(
      expense.payer.participantId,
      (v) => v + expense.payer.amount,
      ifAbsent: () => expense.payer.amount,
    );
    for (final allocation in expense.allocatedAmounts) {
      owed.update(
        allocation.participantId,
        (v) => v + allocation.amount,
        ifAbsent: () => allocation.amount,
      );
    }
  }
  return {
    for (final id in {...paid.keys, ...owed.keys})
      id: (
        paid: paid[id] ?? 0,
        owed: owed[id] ?? 0,
        net: (paid[id] ?? 0) - (owed[id] ?? 0),
      ),
  };
}

List<Transfer> proposeTransfers(Map<String, ParticipantBalance> balances) {
  final remaining = {for (final e in balances.entries) e.key: e.value.net};
  final creditors = remaining.keys.where((id) => remaining[id]! > 0).toList()
    ..sort((a, b) {
      final amount = remaining[b]!.compareTo(remaining[a]!);
      return amount != 0 ? amount : a.compareTo(b);
    });
  final debtors = remaining.keys.where((id) => remaining[id]! < 0).toList()
    ..sort((a, b) {
      final amount = remaining[a]!.compareTo(remaining[b]!);
      return amount != 0 ? amount : a.compareTo(b);
    });
  final result = <Transfer>[];
  var c = 0, d = 0;
  while (c < creditors.length && d < debtors.length) {
    final to = creditors[c], from = debtors[d];
    final credit = remaining[to]!, debt = -remaining[from]!;
    final amount = credit < debt ? credit : debt;
    result.add((from: from, to: to, amount: amount));
    remaining[to] = credit - amount;
    remaining[from] = amount - debt;
    if (remaining[to] == 0) c++;
    if (remaining[from] == 0) d++;
  }
  if (remaining.values.any((v) => v != 0)) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '원장 배분 합계가 맞지 않아 송금 제안을 만들 수 없습니다.',
      retryable: false,
    );
  }
  return result;
}

String settlementShareText(
  String title,
  List<Expense> expenses,
  List<Participant> participants,
) {
  final names = {for (final p in participants) p.id: p.name};
  final currencies = expenses.map((e) => e.currency).toSet().toList()..sort();
  final lines = <String>['$title · 정산 안내'];
  for (final currency in currencies) {
    lines.add('[$currency]');
    final transfers = proposeTransfers(balancesForCurrency(expenses, currency));
    if (transfers.isEmpty) lines.add('송금할 금액이 없습니다.');
    for (final t in transfers) {
      lines.add(
        '${names[t.from] ?? t.from} → ${names[t.to] ?? t.to}: $currency ${t.amount}',
      );
    }
  }
  if (currencies.isEmpty) lines.add('등록된 지출이 없습니다.');
  lines.add('통화별로 계산한 제안입니다. 송금 완료 상태는 기록하지 않습니다.');
  return lines.join('\n');
}

/// 소비자 순서를 보존해 최소 통화 단위 정수를 균등 배분한다.
List<MoneyAllocation> allocateEqually({
  required CurrencyAmount totalAmount,
  required List<ParticipantId> consumers,
}) {
  if (consumers.isEmpty) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '소비자를 한 명 이상 선택해 주세요.',
      retryable: false,
      field: 'consumers',
    );
  }

  if (consumers.toSet().length != consumers.length) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '같은 참여자를 소비자에 두 번 넣을 수 없습니다.',
      retryable: false,
      field: 'consumers',
    );
  }

  final baseAmount = totalAmount ~/ consumers.length;
  final remainder = totalAmount - (baseAmount * consumers.length);
  final remainderCount = remainder.abs();
  final remainderUnit = remainder.sign;

  return List<MoneyAllocation>.unmodifiable(
    List<MoneyAllocation>.generate(consumers.length, (index) {
      return MoneyAllocation(
        participantId: consumers[index],
        amount: baseAmount + (index < remainderCount ? remainderUnit : 0),
      );
    }),
  );
}
