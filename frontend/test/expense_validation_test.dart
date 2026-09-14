import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/settlement/expense_edit_page.dart';

const me = TokyoFixtureIds.participantMe;
const friend1 = TokyoFixtureIds.participantFriend1;
const friend2 = TokyoFixtureIds.participantFriend2;

void main() {
  test('금액 입력은 올바른 정수·천 단위 쉼표만 허용하고 안전 범위를 지킨다', () {
    expect(parseExpenseAmount('10,000'), 10000);
    expect(parseExpenseAmount('0'), 0);
    expect(parseExpenseAmount('9007199254740991'), 9007199254740991);
    for (final value in [
      '',
      '1.2',
      '1e3',
      '-1',
      '1,2',
      '9007199254740992',
      '99999999999999999999999999',
    ]) {
      expect(
        () => parseExpenseAmount(value),
        throwsA(isA<AppError>()),
        reason: value,
      );
    }
  });

  test('저장 경계에서 합계·집합·균등 배분·통화·참여자·장소를 검증하고 실패 시 원장을 보존한다', () async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final invalid = [
      draft(title: ''),
      draft(date: '2026-02-30'),
      draft(amount: 0),
      draft(amount: 9007199254740992),
      draft(currency: 'USD'),
      draft(payerAmount: 100),
      draft(payerId: tokyoOwnerUid),
      draft(consumers: []),
      draft(consumers: [me, me, friend2]),
      draft(method: 'itemized'),
      draft(source: 'ocr'),
      draft(
        allocations: const [MoneyAllocation(participantId: me, amount: 4500)],
      ),
      draft(
        allocations: const [
          MoneyAllocation(participantId: me, amount: 1500),
          MoneyAllocation(participantId: me, amount: 1500),
          MoneyAllocation(participantId: friend2, amount: 1500),
        ],
      ),
      draft(
        method: 'custom',
        allocations: const [
          MoneyAllocation(participantId: me, amount: -100),
          MoneyAllocation(participantId: friend1, amount: 2300),
          MoneyAllocation(participantId: friend2, amount: 2300),
        ],
      ),
      draft(
        allocations: const [
          MoneyAllocation(participantId: me, amount: 1000),
          MoneyAllocation(participantId: friend1, amount: 2000),
          MoneyAllocation(participantId: friend2, amount: 1500),
        ],
      ),
      draft(
        method: 'custom',
        allocations: const [
          MoneyAllocation(participantId: me, amount: 1000),
          MoneyAllocation(participantId: friend1, amount: 1000),
          MoneyAllocation(participantId: friend2, amount: 1000),
        ],
      ),
      draft(placeId: 'unknown'),
      draft(itineraryId: 'unknown'),
    ];
    for (final value in invalid) {
      await expectLater(
        repo.createExpense(tokyoTripId, value),
        throwsA(isA<AppError>()),
      );
    }
    expect(await repo.watchExpenses(tokyoTripId).first, hasLength(1));
    final current = (await repo.watchExpenses(tokyoTripId).first).single;
    await expectLater(
      repo.updateExpense(tokyoTripId, current.id, draft(payerAmount: 1)),
      throwsA(isA<AppError>()),
    );
    expect(
      (await repo.watchExpenses(tokyoTripId).first).single.totalAmount,
      4500,
    );
  });

  test('비활성 참여자는 새 지출에서 거부하고 기존 지출 수정에서는 유지하며 삭제는 멱등이다', () async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    await repo.deactivateParticipant(tokyoTripId, friend1);
    await expectLater(
      repo.createExpense(tokyoTripId, draft()),
      throwsA(isA<AppError>()),
    );
    await repo.updateExpense(
      tokyoTripId,
      TokyoFixtureIds.dinnerExpense,
      draft(title: '유지된 과거 지출'),
    );
    final updated = (await repo.watchExpenses(tokyoTripId).first).single;
    expect(updated.consumers, [me, friend1, friend2]);
    await repo.deleteExpense(tokyoTripId, updated.id);
    await repo.deleteExpense(tokyoTripId, updated.id);
    expect(await repo.watchExpenses(tokyoTripId).first, isEmpty);
  });

  test('다른 여행의 참여자와 참조는 같은 ID 형태여도 저장할 수 없다', () {
    expect(
      () => draft().validateManual(
        tripId: 'other-trip',
        participants: tokyoTripFixture.participants,
        places: tokyoTripFixture.places,
        itinerary: tokyoTripFixture.itinerary,
      ),
      throwsA(isA<AppError>()),
    );
  });
}

ExpenseDraft draft({
  String title = '점심',
  String date = '2026-11-25',
  int amount = 4500,
  String currency = 'JPY',
  String payerId = me,
  int? payerAmount,
  List<String> consumers = const [me, friend1, friend2],
  List<MoneyAllocation>? allocations,
  String method = 'equal',
  String source = 'manual',
  String? placeId,
  String? itineraryId,
}) => ExpenseDraft(
  title: title,
  category: 'food',
  expenseDate: date,
  totalAmount: amount,
  currency: currency,
  payer: ExpensePayer(participantId: payerId, amount: payerAmount ?? amount),
  consumers: consumers,
  allocationMethod: method,
  allocatedAmounts:
      allocations ??
      const [
        MoneyAllocation(participantId: me, amount: 1500),
        MoneyAllocation(participantId: friend1, amount: 1500),
        MoneyAllocation(participantId: friend2, amount: 1500),
      ],
  receiptItems: const [],
  source: source,
  placeId: placeId,
  itineraryItemId: itineraryId,
);
