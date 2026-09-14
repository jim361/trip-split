import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/app/trip_session.dart';
import 'package:trip_split/services/auth_service.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/settlement/expense_edit_page.dart';
import 'package:trip_split/features/settlement/expense_detail_page.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';

const me = TokyoFixtureIds.participantMe;
const friend1 = TokyoFixtureIds.participantFriend1;
const friend2 = TokyoFixtureIds.participantFriend2;

void main() {
  test('세션은 지출 첫 응답까지 기다린 뒤 입력 화면을 준비한다', () async {
    final repo = ExpenseTestRepositories();
    addTearDown(repo.inner.close);
    repo.expensesGate = Completer<List<Expense>>();
    final session = TripSessionController(
      tripId: tokyoTripId,
      repositories: repo,
    )..start();
    addTearDown(session.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(session.trip, isNotNull);
    expect(session.isLoading, isTrue);
    repo.expensesGate!.complete(
      await repo.inner.watchExpenses(tokyoTripId).first,
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.isLoading, isFalse);
  });

  testWidgets('계정 미연결 시 결제자를 직접 선택하고 KRW 지출을 JPY와 섞지 않는다', (tester) async {
    final repo = await pumpExpenses(tester, uid: 'unlinked-user');
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'title', '출국 교통비');
    await enterExpense(tester, 'totalAmount', '12000');
    await tapExpense(tester, find.byKey(const Key('expense-currency-JPY')));
    await tapExpense(tester, find.text('KRW · 원').last);
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    expect(find.textContaining('결제자와 부담할 사람'), findsWidgets);
    await tapExpense(tester, find.byKey(const Key('expense-payer-')));
    await tapExpense(tester, find.text('나').last);
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    await tapExpense(tester, find.byKey(const Key('expense-to-list')));
    expect(
      tester.widget<Text>(find.byKey(const Key('currency-total-JPY'))).data,
      'JPY 4,500',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('currency-total-KRW'))).data,
      'KRW 12,000',
    );
    expect(find.byKey(const Key('personal-summary-0')), findsNothing);
    expect(
      (await repo.inner.watchExpenses(tokyoTripId).first)
          .singleWhere((e) => e.title == '출국 교통비')
          .currency,
      'KRW',
    );
  });

  testWidgets('응답만 유실된 저장은 원장에 표시하고 재등록 없이 닫을 수 있다', (tester) async {
    final repo = await pumpExpenses(tester);
    repo.failAfterCreate = true;
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'title', '이미 저장된 점심');
    await enterExpense(tester, 'totalAmount', '3000');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    await tapExpense(tester, find.text('비용 목록 확인 후 다시 시도'));
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('이미 저장된 점심'),
      ),
      findsOneWidget,
    );
    await tapExpense(tester, find.text('닫기'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapExpense(tester, find.text('나가기'));
    expect(find.byType(ExpenseEditPage), findsNothing);
    expect(repo.createCalls, 1);
    expect(
      (await repo.inner.watchExpenses(tokyoTripId).first).where(
        (e) => e.title == '이미 저장된 점심',
      ),
      hasLength(1),
    );
  });
  testWidgets('지출 추가→균등 배분→상세→요약 갱신과 직접 배분 수정·삭제', (tester) async {
    final repo = await pumpExpenses(tester);
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'title', '우에노 점심');
    await enterExpense(tester, 'totalAmount', '10,000');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    expect(find.text('JPY 3,334'), findsOneWidget);
    expect(find.text('JPY 3,333'), findsNWidgets(2));
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    expect(find.byType(ExpenseDetailPage), findsOneWidget);
    expect(find.text('우에노 점심'), findsOneWidget);
    var created = (await repo.inner.watchExpenses(tokyoTripId).first)
        .singleWhere((e) => e.title == '우에노 점심');
    final original = created;
    expect(created.payer.participantId, me);
    expect(created.payer.participantId, isNot(tokyoOwnerUid));
    expect(created.consumers, [me, friend1, friend2]);
    expect(created.allocatedAmounts.map((a) => a.amount), [3334, 3333, 3333]);
    await tapExpense(tester, find.byKey(const Key('expense-to-list')));
    expect(
      tester.widget<Text>(find.byKey(const Key('currency-total-JPY'))).data,
      'JPY 14,500',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('personal-summary-1'))).data,
      'JPY 4,834',
    );
    await tapExpense(tester, find.byKey(ValueKey('expense-row-${created.id}')));
    await tapExpense(tester, find.byKey(const Key('expense-edit')));
    await enterExpense(tester, 'memo', '직접 배분한 점심');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    await tapExpense(tester, find.text('직접 입력'));
    await enterExpense(tester, 'amount-$me', '5000');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('expense-save')))
          .onPressed,
      isNull,
    );
    await enterExpense(tester, 'amount-$friend1', '3000');
    await enterExpense(tester, 'amount-$friend2', '2000');
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    created = (await repo.inner.watchExpenses(tokyoTripId).first).singleWhere(
      (e) => e.id == created.id,
    );
    expect(created.allocationMethod, 'custom');
    expect(created.allocatedAmounts.map((a) => a.amount), [5000, 3000, 2000]);
    expect(created.memo, '직접 배분한 점심');
    expect(
      (created.createdAt, created.createdBy),
      (original.createdAt, original.createdBy),
    );
    await tapExpense(tester, find.byKey(const Key('expense-to-list')));
    expect(
      tester.widget<Text>(find.byKey(const Key('personal-summary-1'))).data,
      'JPY 6,500',
    );
    await tapExpense(tester, find.byKey(ValueKey('expense-row-${created.id}')));
    repo.failDelete = true;
    await tapExpense(tester, find.byKey(const Key('expense-delete')));
    await tapExpense(tester, find.text('삭제'));
    expect(find.text('삭제 실패'), findsOneWidget);
    expect((await repo.inner.watchExpenses(tokyoTripId).first).length, 2);
    repo.failDelete = false;
    await tapExpense(tester, find.byKey(const Key('expense-delete')));
    await tapExpense(tester, find.text('삭제'));
    expect(
      tester.widget<Text>(find.byKey(const Key('currency-total-JPY'))).data,
      'JPY 4,500',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('personal-summary-1'))).data,
      'JPY 1,500',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 제목·소수·잘못된 날짜를 차단하고 소비자 선택 순서와 0원 배분을 보존한다', (tester) async {
    final repo = await pumpExpenses(tester);
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'totalAmount', '1.5');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    expect(find.textContaining('소수점 없는'), findsWidgets);
    await enterExpense(tester, 'totalAmount', '1');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    expect(find.textContaining('지출 제목은'), findsWidgets);
    await enterExpense(tester, 'title', '1엔 배분');
    await enterExpense(tester, 'expenseDate', '2026-02-30');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    expect(find.textContaining('실제 날짜'), findsWidgets);
    await enterExpense(tester, 'expenseDate', '2026-11-25');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    await tapExpense(
      tester,
      find.byKey(const ValueKey('expense-consumer-$me')),
    );
    await tapExpense(
      tester,
      find.byKey(const ValueKey('expense-consumer-$me')),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('expense-allocation-$friend1')),
          )
          .data,
      'JPY 1',
    );
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    final item = (await repo.inner.watchExpenses(tokyoTripId).first)
        .singleWhere((e) => e.title == '1엔 배분');
    expect(item.consumers, [friend1, friend2, me]);
    expect(item.allocatedAmounts.map((a) => a.amount), [1, 0, 0]);
  });

  testWidgets('저장 중 중복 제출과 뒤로 가기를 차단하고 원장 확인 후에만 재시도한다', (tester) async {
    final repo = await pumpExpenses(tester);
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'title', '입력이 남는 지출');
    await enterExpense(tester, 'totalAmount', '3000');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    repo.createGate = Completer<void>();
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.binding.handlePopRoute();
    expect(repo.createCalls, 1);
    repo.createGate!.completeError(
      const AppError(
        code: AppErrorCode.unavailable,
        message: '연결 실패',
        retryable: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('연결 실패'), findsOneWidget);
    expect(find.text('입력이 남는 지출'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('expense-save')))
          .onPressed,
      isNull,
    );
    await tapExpense(tester, find.text('비용 목록 확인 후 다시 시도'));
    expect(find.textContaining('우에노 저녁'), findsOneWidget);
    await tapExpense(tester, find.text('중복 없음 · 재시도 허용'));
    repo.createGate = null;
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    expect(repo.createCalls, 2);
    expect(
      (await repo.inner.watchExpenses(tokyoTripId).first).where(
        (e) => e.title == '입력이 남는 지출',
      ),
      hasLength(1),
    );
  });

  testWidgets('큰 글씨·키보드에서도 배분과 저장 버튼에 접근하고 뒤로 가면 입력이 유지된다', (tester) async {
    final repo = await pumpExpenses(tester, scale: 2);
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'title', '키보드 확인');
    await enterExpense(tester, 'totalAmount', '900');
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    await tapExpense(tester, find.text('직접 입력'));
    await enterExpense(tester, 'amount-$me', '300');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.byKey(const Key('expense-save'))).dy,
      lessThanOrEqualTo(544),
    );
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    tester.testTextInput.hide();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense-title')))
          .controller!
          .text,
      '키보드 확인',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('편집을 그만둘까요?'), findsOneWidget);
    await tapExpense(tester, find.text('취소'));
    expect(find.byType(ExpenseEditPage), findsOneWidget);
    expect(repo.createCalls, 0);
  });

  testWidgets('편집 중 비활성화된 새 참여자와 삭제된 연결을 저장 전에 확인한다', (tester) async {
    final repo = await pumpExpenses(tester);
    await tapExpense(tester, find.byKey(const Key('expense-add')));
    await enterExpense(tester, 'title', '장소와 연결');
    await enterExpense(tester, 'totalAmount', '3000');
    await tapExpense(tester, find.text('장소·일정 연결 (선택)'));
    await tapExpense(tester, find.byKey(const Key('expense-placeId-')));
    await tapExpense(tester, find.text('우에노역').last);
    await repo.inner.deletePlace(tokyoTripId, TokyoFixtureIds.ueno);
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    expect(find.textContaining('장소를 다시'), findsWidgets);
    await tapExpense(
      tester,
      find.byKey(const Key('expense-placeId-${TokyoFixtureIds.ueno}')),
    );
    await tapExpense(tester, find.text('장소 없음').last);
    await tapExpense(tester, find.byKey(const Key('expense-next')));
    await repo.inner.deactivateParticipant(tokyoTripId, friend1);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('expense-save')))
          .onPressed,
      isNull,
    );
    await tapExpense(
      tester,
      find.byKey(const Key('expense-consumer-$friend1')),
    );
    await tapExpense(tester, find.byKey(const Key('expense-save')));
    final item = (await repo.inner.watchExpenses(tokyoTripId).first)
        .singleWhere((e) => e.title == '장소와 연결');
    expect(item.placeId, isNull);
    expect(item.consumers, [me, friend2]);
  });
}

Future<ExpenseTestRepositories> pumpExpenses(
  WidgetTester tester, {
  double scale = 1,
  String uid = tokyoOwnerUid,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetViewInsets();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final repo = ExpenseTestRepositories();
  final auth = MockAuthService(
    initialUser: AuthUser(uid: uid, displayName: '테스트', isAnonymous: true),
  );
  addTearDown(repo.inner.close);
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    TripSplitApp(
      repositories: repo,
      authService: auth,
      tripShareService: MockTripShareService(repo.inner),
      dataSourceLabel: 'mock',
      initialRoute: '/trips/$tokyoTripId/settlement',
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> tapExpense(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterExpense(
  WidgetTester tester,
  String field,
  String value,
) async {
  final finder = find.byKey(ValueKey('expense-$field'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

class ExpenseTestRepositories implements TripRepositories {
  final inner = InMemoryTripRepositories();
  Completer<void>? createGate;
  int createCalls = 0;
  bool failDelete = false;
  bool failAfterCreate = false;
  Completer<List<Expense>>? expensesGate;
  @override
  Stream<Trip?> watchTrip(String id) => inner.watchTrip(id);
  @override
  Stream<List<TripMember>> watchMembers(String id) => inner.watchMembers(id);
  @override
  Stream<List<Participant>> watchParticipants(String id) =>
      inner.watchParticipants(id);
  @override
  Stream<List<Place>> watchPlaces(String id) => inner.watchPlaces(id);
  @override
  Stream<List<ItineraryItem>> watchItinerary(String id) =>
      inner.watchItinerary(id);
  @override
  Stream<List<Expense>> watchExpenses(String id) => expensesGate == null
      ? inner.watchExpenses(id)
      : Stream.fromFuture(expensesGate!.future);
  @override
  Future<Expense> createExpense(String id, ExpenseDraft draft) async {
    createCalls++;
    await createGate?.future;
    final expense = await inner.createExpense(id, draft);
    if (failAfterCreate) {
      throw const AppError(
        code: AppErrorCode.unavailable,
        message: '저장 응답 유실',
        retryable: true,
      );
    }
    return expense;
  }

  @override
  Future<void> updateExpense(String trip, String id, ExpenseDraft draft) =>
      inner.updateExpense(trip, id, draft);
  @override
  Future<void> deleteExpense(String trip, String id) async {
    if (failDelete) {
      throw const AppError(
        code: AppErrorCode.unavailable,
        message: '삭제 실패',
        retryable: true,
      );
    }
    await inner.deleteExpense(trip, id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
