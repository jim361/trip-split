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
            currentUserUid: tokyoOwnerUid,
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

  testWidgets('다른 멤버와 비활성 참여자도 로그인 UID의 개인 금액을 표시한다', (tester) async {
    final friend = tokyoTripFixture.participants[1];
    for (final isActive in [true, false]) {
      final participants = [
        tokyoTripFixture.participants.first,
        Participant(
          id: friend.id,
          tripId: friend.tripId,
          name: friend.name,
          linkedUid: 'guest-user',
          isActive: isActive,
          createdAt: friend.createdAt,
          updatedAt: friend.updatedAt,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementPage(
              trip: tokyoTripFixture.trip,
              currentUserUid: 'guest-user',
              participants: participants,
              expenses: tokyoTripFixture.expenses,
              onOpenReceipts: () {},
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('personal-summary-0')))
            .data,
        'JPY 0',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('personal-summary-1')))
            .data,
        'JPY 1,500',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('personal-summary-2')))
            .data,
        'JPY 1,500',
      );
      expect(find.text('보낼 금액'), findsOneWidget);
    }
  });

  testWidgets('미연결 계정은 다른 참여자를 나로 대신 표시하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettlementPage(
            trip: tokyoTripFixture.trip,
            currentUserUid: 'unlinked-user',
            participants: tokyoTripFixture.participants,
            expenses: tokyoTripFixture.expenses,
            onOpenReceipts: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('아직 내 정산 참여자가 연결되지 않았습니다'), findsOneWidget);
    expect(find.byKey(const ValueKey('currency-total-JPY')), findsOneWidget);
    expect(find.byKey(const ValueKey('personal-summary-0')), findsNothing);
    expect(find.text('최종 정산'), findsNothing);
  });
}
