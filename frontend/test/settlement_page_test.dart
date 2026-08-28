import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/settlement/settlement_page.dart';

void main() {
  testWidgets('KRW와 JPY 지출을 환율 없이 통화별로 표시한다', (tester) async {
    final krwExpense = Expense(
      id: 'expense-krw',
      tripId: tokyoTripId,
      title: '출국 전 교통비',
      category: 'transport',
      expenseDate: '2026-11-24',
      totalAmount: 12000,
      currency: 'KRW',
      payer: const ExpensePayer(
        participantId: TokyoFixtureIds.participantMe,
        amount: 12000,
      ),
      consumers: const [TokyoFixtureIds.participantMe],
      allocationMethod: 'equal',
      allocatedAmounts: const [
        MoneyAllocation(
          participantId: TokyoFixtureIds.participantMe,
          amount: 12000,
        ),
      ],
      receiptItems: const [],
      source: 'manual',
      createdBy: tokyoOwnerUid,
      updatedBy: tokyoOwnerUid,
      createdAt: 0,
      updatedAt: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettlementPage(
            trip: tokyoTripFixture.trip,
            participants: tokyoTripFixture.participants,
            expenses: [tokyoTripFixture.expenses.single, krwExpense],
            onOpenReceipts: () {},
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('currency-total-JPY')))
          .data,
      'JPY 4,500',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('currency-total-KRW')))
          .data,
      'KRW 12,000',
    );
    expect(find.textContaining('환율 미적용'), findsOneWidget);
    expect(find.text('JPY 16,500'), findsNothing);
  });
}
