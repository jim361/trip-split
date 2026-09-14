import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/preparation.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/places/mock_place_provider.dart';
import 'package:trip_split/features/places/places_page.dart';
import 'package:trip_split/features/preparation/preparation_page.dart';
import 'package:trip_split/features/receipts/mock_receipt_parser.dart';
import 'package:trip_split/features/receipts/receipt_parser.dart';
import 'package:trip_split/features/receipts/receipt_review_page.dart';
import 'package:trip_split/features/receipts/receipts_page.dart';
import 'package:trip_split/features/settlement/participants_page.dart';
import 'package:trip_split/features/settlement/settlement_engine.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

const me = TokyoFixtureIds.participantMe;
const friend = TokyoFixtureIds.participantFriend1;

void main() {
  testWidgets('장소 검색의 빈 결과에서 직접 입력하고 수정·연결 참조 안내를 확인한다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    await pumpPage(
      tester,
      PlacesPage(
        trip: trip,
        repositories: repo,
        provider: MockPlaceProvider(),
        linkResolver: MockPlaceProvider(),
      ),
    );
    await tester.enterText(find.byKey(const Key('place-query')), '없는검색어');
    await tap(tester, find.byTooltip('검색 실행'));
    expect(find.textContaining('검색 결과가 없습니다'), findsOneWidget);
    await tap(tester, find.byKey(const Key('place-manual-add')));
    await tester.enterText(
      find.byKey(const Key('place-field-name')),
      '호텔 앞 집합',
    );
    await tap(tester, find.byKey(const Key('form-save')));
    final saved = (await repo.watchPlaces(tokyoTripId).first).singleWhere(
      (p) => p.name == '호텔 앞 집합',
    );
    expect(saved.lat, isNull);
    expect(saved.provider, 'manual');
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('place-${saved.id}')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, find.byKey(ValueKey('place-${saved.id}')));
    await tester.enterText(find.byKey(const Key('place-field-name')), '호텔 로비');
    await tap(tester, find.byKey(const Key('form-save')));
    expect(
      (await repo.watchPlaces(tokyoTripId).first)
          .singleWhere((p) => p.id == saved.id)
          .name,
      '호텔 로비',
    );
    await repo.createItineraryItem(
      tokyoTripId,
      ItineraryItemDraft(
        date: trip.startDate,
        title: '아침 집합',
        planId: 'A',
        order: 20,
        placeId: saved.id,
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('호텔 로비 삭제'));
    expect(find.text('연결된 장소입니다'), findsOneWidget);
    expect(find.textContaining('아침 집합'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('예약과 체크리스트를 만들고 완료 상태·편집 내용을 저장한다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    await pumpPage(
      tester,
      Scaffold(
        body: PreparationPage(
          trip: trip,
          repositories: repo,
          participants: await repo.watchParticipants(tokyoTripId).first,
          itinerary: await repo.watchItinerary(tokyoTripId).first,
        ),
      ),
    );
    await tap(tester, find.byKey(const Key('reservation-add')));
    await tester.enterText(
      find.byKey(const Key('preparation-title')),
      '우에노 숙소',
    );
    await tester.enterText(
      find.byKey(const Key('reservation-url')),
      'javascript:bad',
    );
    await tap(tester, find.byKey(const Key('form-save')));
    expect(find.textContaining('http/https'), findsOneWidget);
    expect(await repo.watchReservations(tokyoTripId).first, isEmpty);
    await tester.enterText(
      find.byKey(const Key('reservation-url')),
      'https://example.com/booking',
    );
    await tap(tester, find.byKey(const Key('form-save')));
    expect(
      (await repo.watchReservations(tokyoTripId).first).single.draft.title,
      '우에노 숙소',
    );
    await tap(tester, find.byKey(const Key('checklist-add')));
    await tester.enterText(
      find.byKey(const Key('preparation-title')),
      '여권 챙기기',
    );
    await tap(tester, find.byKey(const Key('form-save')));
    final item = (await repo.watchChecklist(tokyoTripId).first).single;
    final row = find.byKey(ValueKey('checklist-${item.id}'));
    await tap(
      tester,
      find.descendant(of: row, matching: find.byType(Checkbox)),
    );
    expect(
      (await repo.watchChecklist(tokyoTripId).first).single.draft.isDone,
      isTrue,
    );
    await tap(tester, find.text('여권 챙기기'));
    await tester.enterText(
      find.byKey(const Key('preparation-title')),
      '여권과 카드 챙기기',
    );
    await tap(tester, find.byKey(const Key('form-save')));
    expect(
      (await repo.watchChecklist(tokyoTripId).first).single.draft.isDone,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  test('준비물 참조·수정 보존과 여행 목록·설정·계정 재연결을 검증한다', () async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    final participant = (await repo.watchParticipants(tokyoTripId).first)
        .singleWhere((p) => p.id == me);
    await repo.linkMyParticipant(tokyoTripId, friend);
    final people = await repo.watchParticipants(tokyoTripId).first;
    expect(people.singleWhere((p) => p.id == me).linkedUid, isNull);
    expect(
      people.singleWhere((p) => p.id == friend).linkedUid,
      participant.linkedUid,
    );
    await repo.updateTrip(
      tokyoTripId,
      TripUpdate(
        title: '변경된 여행',
        startDate: trip.startDate,
        endDate: trip.endDate,
      ),
    );
    expect(
      (await repo.listMyTrips()).singleWhere((t) => t.id == tokyoTripId).title,
      '변경된 여행',
    );
    await expectLater(
      repo.saveChecklist(
        tokyoTripId,
        ChecklistDraft(title: '잘못된 담당', assigneeParticipantId: 'missing'),
      ),
      throwsA(isA<AppError>()),
    );
    await expectLater(
      repo.saveReservation(
        tokyoTripId,
        ReservationDraft(
          title: '잘못된 일정',
          type: 'stay',
          status: 'planned',
          itineraryItemId: 'missing',
        ),
      ),
      throwsA(isA<AppError>()),
    );
    final id = await repo.saveReservation(
      tokyoTripId,
      ReservationDraft(
        title: '예약',
        type: 'stay',
        status: 'planned',
        memo: '삭제될 메모',
      ),
    );
    final before = (await repo.watchReservations(tokyoTripId).first).single;
    await repo.saveReservation(
      tokyoTripId,
      ReservationDraft(title: '예약 수정', type: 'stay', status: 'booked'),
      id: id,
    );
    final after = (await repo.watchReservations(tokyoTripId).first).single;
    expect(after.createdAt, before.createdAt);
    expect(after.draft.memo, isNull);
  });

  testWidgets('참여자 이름 변경과 비활성화가 기존 계정 연결·지출 이력을 유지한다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    final original = (await repo.watchParticipants(tokyoTripId).first)
        .singleWhere((p) => p.id == me);
    final expenseCount = (await repo.watchExpenses(tokyoTripId).first).length;
    await pumpPage(
      tester,
      ParticipantsPage(
        tripId: trip.id,
        repositories: repo,
        currentUid: original.linkedUid!,
      ),
    );
    await tap(tester, find.byKey(const ValueKey('participant-$me')));
    await tester.enterText(find.byKey(const Key('participant-name')), '지민');
    await tap(tester, find.byType(SwitchListTile));
    await tap(tester, find.byKey(const Key('form-save')));
    await tap(tester, find.text('확인'));
    final after = (await repo.watchParticipants(tokyoTripId).first).singleWhere(
      (p) => p.id == me,
    );
    expect(after.name, '지민');
    expect(after.isActive, isFalse);
    expect(after.linkedUid, original.linkedUid);
    expect((await repo.watchExpenses(tokyoTripId).first).length, expenseCount);
  });

  testWidgets('OCR 후보는 자동 저장되지 않고 항목 금액과 총액을 확인해야 저장된다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    final uid = (await repo.watchParticipants(tokyoTripId).first)
        .singleWhere((p) => p.id == me)
        .linkedUid!;
    final before = (await repo.watchExpenses(tokyoTripId).first).length;
    await pumpPushed(
      tester,
      ReceiptReviewPage(
        trip: trip,
        repositories: repo,
        currentUid: uid,
        parsed: japaneseReceiptFixture,
      ),
    );
    expect((await repo.watchExpenses(tokyoTripId).first).length, before);
    await tester.enterText(find.byKey(const Key('receipt-total')), '1700');
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('form-save'))).onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const Key('receipt-total')), '1750');
    await tap(tester, find.byKey(const Key('receipt-row-receipt-item-1')));
    await tester.enterText(
      find.byKey(const Key('receipt-item-name')),
      '새우 튀김 정식',
    );
    await tap(tester, find.byKey(const Key('form-save')));
    await tap(tester, find.byKey(const Key('form-save')));
    final saved = (await repo.watchExpenses(tokyoTripId).first).singleWhere(
      (e) => e.title == '아사쿠사 식당',
    );
    expect(saved.source, 'ocr');
    expect(saved.allocationMethod, 'itemized');
    expect(saved.receiptItems.first.name, '새우 튀김 정식');
    expect(saved.allocatedAmounts.map((a) => a.amount), [584, 583, 583]);
    expect((await repo.watchExpenses(tokyoTripId).first).length, before + 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('지원하지 않는 OCR 통화는 직접 확인 전 저장을 막는다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    final uid = (await repo.watchParticipants(tokyoTripId).first)
        .singleWhere((p) => p.id == me)
        .linkedUid!;
    final fixture = japaneseReceiptFixture;
    await pumpPushed(
      tester,
      ReceiptReviewPage(
        trip: trip,
        repositories: repo,
        currentUid: uid,
        parsed: ParseReceiptResponse(
          rawText: fixture.rawText,
          sourceLanguage: 'ja',
          merchantNameOriginal: '미확인 통화',
          expenseDate: fixture.expenseDate,
          currencyCandidate: 'USD',
          totalAmountCandidate: 1750,
          items: fixture.items,
          warnings: const [],
        ),
      ),
    );
    expect(find.textContaining('인식된 통화를 지원하지'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('form-save'))).onPressed,
      isNull,
    );
    await tap(tester, find.byKey(const Key('receipt-currency-JPY')));
    await tap(tester, find.text('KRW · 원').last);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('form-save'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('인식 오류에서 이미지 교체·재시도·수동 등록을 사용할 수 있다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    var manual = 0;
    await pumpPage(
      tester,
      Scaffold(
        body: ReceiptsPage(
          trip: trip,
          repositories: repo,
          currentUid: 'mock-user',
          parser: const MockReceiptParser(
            failure: MockReceiptFailure.unavailable,
          ),
          onBackToSettlement: () {},
          onManualExpense: () => manual++,
          onExpenseSaved: (_) {},
        ),
      ),
    );
    await tap(tester, find.byKey(const Key('receipt-sample')));
    await tap(tester, find.byKey(const Key('receipt-recognize')));
    expect(find.textContaining('잠시 사용할 수 없습니다'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('receipt-recognize')))
          .onPressed,
      isNotNull,
    );
    await tap(tester, find.byKey(const Key('receipt-manual-fallback')));
    expect(manual, 1);
    expect(tester.takeException(), isNull);
  });

  test('통화별 송금 제안은 모든 잔액을 해소하고 소비자 순서에 맞는 음수 나머지를 보존한다', () {
    final balances = <String, ParticipantBalance>{
      'a': (paid: 100, owed: 10, net: 90),
      'b': (paid: 0, owed: 60, net: -60),
      'c': (paid: 0, owed: 30, net: -30),
    };
    final transfers = proposeTransfers(balances);
    final remaining = balances.map((id, value) => MapEntry(id, value.net));
    for (final t in transfers) {
      remaining[t.from] = remaining[t.from]! + t.amount;
      remaining[t.to] = remaining[t.to]! - t.amount;
    }
    expect(remaining.values.every((n) => n == 0), isTrue);
    expect(proposeTransfers(balances), transfers);
    expect(
      allocateEqually(
        totalAmount: -2,
        consumers: ['c', 'a', 'b'],
      ).map((a) => a.amount),
      [-1, -1, 0],
    );
    expect(
      () => proposeTransfers({'a': (paid: 1, owed: 0, net: 1)}),
      throwsA(isA<AppError>()),
    );
  });

  testWidgets('200% 글씨와 키보드에서도 장소 폼 저장·뒤로 가기 확인에 접근한다', (tester) async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final trip = (await repo.watchTrip(tokyoTripId).first)!;
    await pumpPushed(
      tester,
      PlaceEditPage(trip: trip, repositories: repo),
      scale: 2,
    );
    await tester.enterText(
      find.byKey(const Key('place-field-name')),
      '큰 글씨 장소',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const Key('form-save'))).bottom,
      lessThanOrEqualTo(844 - 280),
    );
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tap(tester, find.text('취소'));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('place-field-name')))
          .controller!
          .text,
      '큰 글씨 장소',
    );
    tester.view.resetViewInsets();
  });
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  double scale = 1,
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
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
  await tester.pumpAndSettle();
}

Future<void> pumpPushed(
  WidgetTester tester,
  Widget page, {
  double scale = 1,
}) async {
  await pumpPage(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => page),
          ),
          child: const Text('열기'),
        ),
      ),
    ),
    scale: scale,
  );
  await tap(tester, find.text('열기'));
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
