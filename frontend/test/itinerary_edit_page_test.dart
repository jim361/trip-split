import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/app.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/itinerary/itinerary_edit_page.dart';
import 'package:trip_split/services/mock_auth_service.dart';
import 'package:trip_split/services/trip_share_service.dart';

void main() {
  testWidgets('장소 없는 일정 추가·연결·해제·삭제 후 선택 날짜와 B안·지도 확대를 유지한다', (tester) async {
    final repo = await _pump(
      tester,
      query: '?map=expanded&day=2026-11-26&plan=B',
    );
    await _tap(tester, find.byKey(const Key('itinerary-add')));
    await _enter(tester, 'title', '자유 시간');
    await _save(tester);
    var item = (await repo.inner.watchItinerary(tokyoTripId).first).singleWhere(
      (item) => item.title == '자유 시간',
    );
    expect(
      (item.date, item.planId, item.order, item.placeId),
      ('2026-11-26', 'B', 0, null),
    );

    await _tap(tester, find.byKey(ValueKey('itinerary-row-${item.id}')));
    await _selectPlace(tester, '', '우에노역');
    await _save(tester);
    item = (await repo.inner.watchItinerary(tokyoTripId).first).singleWhere(
      (other) => other.id == item.id,
    );
    expect(item.placeId, TokyoFixtureIds.ueno);
    await _top(tester);
    expect(find.byTooltip('지도 접기'), findsOneWidget);
    expect(find.text('02 / ITINERARY MAP'), findsOneWidget);
    expect(find.byKey(ValueKey('map-pin-${item.id}')), findsOneWidget);
    // 지도 route를 교체해도 B안이 유지된다.
    await _tap(tester, find.byTooltip('지도 접기'));
    expect(find.byKey(ValueKey('map-pin-${item.id}')), findsOneWidget);
    await _tap(tester, find.byTooltip('지도 확대'));

    await _tap(tester, find.byKey(ValueKey('itinerary-row-${item.id}')));
    await _selectPlace(tester, TokyoFixtureIds.ueno, '장소 없음');
    await _save(tester);
    item = (await repo.inner.watchItinerary(tokyoTripId).first).singleWhere(
      (other) => other.id == item.id,
    );
    expect(item.placeId, isNull);
    await _tap(tester, find.byKey(ValueKey('itinerary-row-${item.id}')));
    await _tap(tester, find.byKey(const Key('itinerary-delete')));
    await _tap(tester, find.text('삭제'));
    expect(
      (await repo.inner.watchItinerary(tokyoTripId).first).any(
        (other) => other.id == item.id,
      ),
      isFalse,
    );
    expect(find.byType(ItineraryEditPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜와 계획을 바꾼 일정은 목적 그룹 끝에 저장하고 다른 일정은 유지한다', (tester) async {
    final repo = await _pump(tester);
    await repo.inner.createItineraryItem(
      tokyoTripId,
      ItineraryItemDraft(
        date: '2026-11-26',
        title: 'B안 기존 일정',
        planId: 'B',
        order: 4,
      ),
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('itinerary-row-${TokyoFixtureIds.arrival}')),
    );
    await _enter(tester, 'date', '2026-11-26');
    await _tap(tester, find.byKey(const ValueKey('edit-plan-A')));
    await _tap(tester, find.text('B안').last);
    await _save(tester);
    final items = await repo.inner.watchItinerary(tokyoTripId).first;
    final moved = items.singleWhere(
      (item) => item.id == TokyoFixtureIds.arrival,
    );
    expect((moved.date, moved.planId, moved.order), ('2026-11-26', 'B', 5));
    expect(
      items.singleWhere((item) => item.id == TokyoFixtureIds.transfer).order,
      1,
    );
    expect(items.singleWhere((item) => item.title == 'B안 기존 일정').order, 4);
  });

  testWidgets('빈 제목·실제 날짜·시간 오류는 저장 전에 필드별로 안내한다', (tester) async {
    final repo = await _pump(tester);
    await _tap(tester, find.byKey(const Key('itinerary-add')));
    await _save(tester);
    expect(_error(tester), contains('제목'));
    await _enter(tester, 'title', '체크인');
    await _enter(tester, 'date', '2026-02-30');
    await _save(tester);
    expect(_error(tester), contains('실제 날짜'));
    await _enter(tester, 'date', '2026-11-25');
    await _enter(tester, 'startTime', '25:00');
    await _save(tester);
    expect(_error(tester), contains('HH:mm'));
    expect(repo.createCalls, 0);
    await _enter(tester, 'startTime', '15:00');
    await _enter(tester, 'endTime', '16:00');
    await _enter(tester, 'memo', '늦게 도착할 수 있음');
    await _save(tester);
    final item = (await repo.inner.watchItinerary(tokyoTripId).first)
        .singleWhere((item) => item.title == '체크인');
    expect(
      (item.startTime, item.endTime, item.memo),
      ('15:00', '16:00', '늦게 도착할 수 있음'),
    );
  });

  testWidgets('저장 중 중복 제출·뒤로 가기를 막고 실패 후 입력을 보존해 재시도한다', (tester) async {
    final repo = await _pump(tester);
    repo.createGate = Completer<void>();
    await _tap(tester, find.byKey(const Key('itinerary-add')));
    await _enter(tester, 'title', '실패해도 남는 입력');
    final save = find.byKey(const Key('itinerary-save'));
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(repo.createCalls, 1);
    expect(find.byType(ItineraryEditPage), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    repo.createGate!.completeError(
      const AppError(
        code: AppErrorCode.unavailable,
        message: '연결을 확인해 주세요.',
        retryable: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(_error(tester), '연결을 확인해 주세요.');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('edit-title')))
          .controller!
          .text,
      '실패해도 남는 입력',
    );
    repo.createGate = null;
    await _save(tester);
    expect(repo.createCalls, 2);
    expect(
      (await repo.inner.watchItinerary(tokyoTripId).first).where(
        (item) => item.title == '실패해도 남는 입력',
      ),
      hasLength(1),
    );
  });

  testWidgets('키보드와 큰 글자에서도 저장에 접근하고 미저장 상태의 뒤로 가기를 확인한다', (tester) async {
    final repo = await _pump(tester, scale: 2);
    await _tap(tester, find.byKey(const Key('itinerary-add')));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('edit-plan-A'))).dy,
      greaterThan(
        tester.getBottomRight(find.byKey(const ValueKey('edit-date'))).dy,
      ),
    );
    await _enter(tester, 'title', '저장하지 않은 일정');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.byKey(const Key('itinerary-save'))).dy,
      lessThanOrEqualTo(844 - 300),
    );
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    tester.testTextInput.hide();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('편집을 그만둘까요?'), findsOneWidget);
    await _tap(tester, find.text('취소'));
    expect(find.byType(ItineraryEditPage), findsOneWidget);
    await _tap(tester, find.byTooltip('편집 닫기'));
    await _tap(tester, find.text('나가기'));
    expect(find.byType(ItineraryEditPage), findsNothing);
    expect(repo.createCalls, 0);
  });

  testWidgets('길게 끌어 순서를 저장하고 지도와 동기화하며 저장 실패 시 되돌린다', (tester) async {
    final repo = await _pump(tester);
    await _dragItem(tester, TokyoFixtureIds.transfer, const Offset(0, 90));
    var items = await repo.inner.watchItinerary(tokyoTripId).first;
    expect(items.take(3).map((item) => item.id), [
      TokyoFixtureIds.arrival,
      TokyoFixtureIds.checkIn,
      TokyoFixtureIds.transfer,
    ]);
    await _top(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.checkIn}')),
        matching: find.text('02'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.transfer}')),
        matching: find.text('03'),
      ),
      findsOneWidget,
    );
    repo.failReorder = true;
    repo.reorderGate = Completer<void>();
    await _dragItem(
      tester,
      TokyoFixtureIds.transfer,
      const Offset(0, -90),
      settle: false,
    );
    expect(repo.reorderCalls, 2);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.transfer}')),
        matching: find.text('02'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const ValueKey('itinerary-row-${TokyoFixtureIds.transfer}'),
            ),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('itinerary-row-${TokyoFixtureIds.checkIn}'),
              ),
            )
            .dy,
      ),
    );
    expect(
      tester
          .widgetList<ReorderableDelayedDragStartListener>(
            find.byType(ReorderableDelayedDragStartListener),
          )
          .every((listener) => !listener.enabled),
      isTrue,
    );
    repo.reorderGate!.complete();
    await tester.pumpAndSettle();
    items = await repo.inner.watchItinerary(tokyoTripId).first;
    expect(items.take(3).map((item) => item.id), [
      TokyoFixtureIds.arrival,
      TokyoFixtureIds.checkIn,
      TokyoFixtureIds.transfer,
    ]);
    expect(find.byKey(const Key('itinerary-order-error')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-pin-${TokyoFixtureIds.transfer}')),
        matching: find.text('03'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const ValueKey('itinerary-row-${TokyoFixtureIds.checkIn}'),
            ),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('itinerary-row-${TokyoFixtureIds.transfer}'),
              ),
            )
            .dy,
      ),
    );
  });

  testWidgets('두 칸 폼에서 날짜·계획·시간·장소를 잘림 없이 입력한다', (tester) async {
    await _pump(tester);
    await _tap(tester, find.byKey(const Key('itinerary-add')));
    for (final (left, right) in [
      ('edit-date', 'edit-plan-A'),
      ('edit-startTime', 'edit-endTime'),
      ('edit-category', 'edit-place-'),
    ]) {
      final leftRect = tester.getRect(find.byKey(ValueKey(left)));
      final rightRect = tester.getRect(find.byKey(ValueKey(right)));
      expect(leftRect.top, rightRect.top);
      expect(leftRect.right, lessThan(rightRect.left));
    }
    await _enter(tester, 'title', '짧은 입력 폼');
    await _tap(tester, find.byTooltip('날짜 선택'));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('시작 시간 선택'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _selectPlace(tester, '', '우에노역');
    expect(tester.takeException(), isNull);
  });

  testWidgets('긴 목록을 끝까지 끌면 자동 스크롤하고 같은 날짜·A안만 재정렬한다', (tester) async {
    final repo = await _pump(tester);
    for (var index = 0; index < 10; index++) {
      await repo.inner.createItineraryItem(
        tokyoTripId,
        ItineraryItemDraft(
          date: '2026-11-25',
          title: '추가 일정 $index',
          planId: 'A',
          order: index + 3,
        ),
      );
    }
    final alternate = await repo.inner.createItineraryItem(
      tokyoTripId,
      ItineraryItemDraft(
        date: '2026-11-25',
        title: '유지할 B안',
        planId: 'B',
        order: 4,
      ),
    );
    final before = await repo.inner.watchItinerary(tokyoTripId).first;
    await tester.pumpAndSettle();
    final row = find.byKey(
      const ValueKey('itinerary-row-${TokyoFixtureIds.arrival}'),
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final originalScroll = scroll.pixels;
    final gesture = await tester.startGesture(tester.getCenter(row));
    await tester.pump(const Duration(milliseconds: 600));
    final distance =
        tester
            .getBottomRight(find.byKey(const Key('itinerary-compact-layout')))
            .dy -
        12 -
        tester.getCenter(row).dy;
    for (var step = 0; step < 20; step++) {
      await gesture.moveBy(Offset(0, distance / 20));
      await tester.pump(const Duration(milliseconds: 30));
    }
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(scroll.pixels, greaterThan(originalScroll));
    await gesture.up();
    await tester.pumpAndSettle();
    final after = await repo.inner.watchItinerary(tokyoTripId).first;
    final group = after.where(
      (item) => item.date == '2026-11-25' && item.planId == 'A',
    );
    expect(group.last.id, TokyoFixtureIds.arrival);
    expect(
      group.map((item) => item.order),
      List.generate(13, (index) => index),
    );
    expect(after.singleWhere((item) => item.id == alternate.id).order, 4);
    for (final item in before.where((item) => item.date != '2026-11-25')) {
      expect(
        after.singleWhere((other) => other.id == item.id).order,
        item.order,
      );
    }
    expect(repo.reorderCalls, 1);
    await _dragItem(tester, TokyoFixtureIds.arrival, Offset.zero);
    expect(repo.reorderCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('편집 중 삭제된 장소와 일정을 재생성하지 않고 오류와 입력을 유지한다', (tester) async {
    final repo = await _pump(tester);
    await _tap(
      tester,
      find.byKey(const ValueKey('itinerary-row-${TokyoFixtureIds.arrival}')),
    );
    await repo.inner.deletePlace(tokyoTripId, TokyoFixtureIds.narita);
    await tester.pumpAndSettle();
    await _save(tester);
    expect(_error(tester), contains('장소'));
    await _selectPlace(tester, TokyoFixtureIds.narita, '장소 없음');
    await repo.inner.deleteItineraryItem(tokyoTripId, TokyoFixtureIds.arrival);
    await _save(tester);
    expect(_error(tester), contains('이미 삭제'));
    expect(repo.createCalls, 0);
    expect(find.byType(ItineraryEditPage), findsOneWidget);
  });
}

Future<_ControlledRepositories> _pump(
  WidgetTester tester, {
  String query = '',
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
  final repo = _ControlledRepositories();
  final auth = MockAuthService();
  addTearDown(repo.inner.close);
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    TripSplitApp(
      repositories: repo,
      authService: auth,
      tripShareService: MockTripShareService(repo.inner),
      dataSourceLabel: 'mock',
      initialRoute: '/trips/$tokyoTripId/itinerary$query',
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String field, String value) async {
  final finder = find.byKey(ValueKey('edit-$field'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) =>
    _tap(tester, find.byKey(const Key('itinerary-save')));
String? _error(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('itinerary-edit-error'))).data;
Future<void> _selectPlace(
  WidgetTester tester,
  String current,
  String label,
) async {
  await _tap(tester, find.byKey(ValueKey('edit-place-$current')));
  await _tap(tester, find.text(label).last);
}

Future<void> _top(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('itinerary-compact-layout')),
    const Offset(0, 1600),
  );
  await tester.pumpAndSettle();
}

Future<void> _dragItem(
  WidgetTester tester,
  String id,
  Offset offset, {
  bool settle = true,
}) async {
  final row = find.byKey(ValueKey('itinerary-row-$id'));
  if (row.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      row,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(row));
  await tester.pump(const Duration(milliseconds: 600));
  for (var step = 0; step < 10; step++) {
    await gesture.moveBy(offset / 10);
    await tester.pump(const Duration(milliseconds: 30));
  }
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  if (settle) await tester.pumpAndSettle();
}

class _ControlledRepositories implements TripRepositories {
  final inner = InMemoryTripRepositories();
  Completer<void>? createGate;
  int createCalls = 0;
  bool failReorder = false;
  Completer<void>? reorderGate;
  int reorderCalls = 0;
  @override
  Stream<Trip?> watchTrip(EntityId id) => inner.watchTrip(id);
  @override
  Stream<List<TripMember>> watchMembers(EntityId id) => inner.watchMembers(id);
  @override
  Stream<List<Participant>> watchParticipants(EntityId id) =>
      inner.watchParticipants(id);
  @override
  Stream<List<Place>> watchPlaces(EntityId id) => inner.watchPlaces(id);
  @override
  Stream<List<ItineraryItem>> watchItinerary(EntityId id) =>
      inner.watchItinerary(id);
  @override
  Stream<List<Expense>> watchExpenses(EntityId id) => inner.watchExpenses(id);
  @override
  Future<ItineraryItem> createItineraryItem(
    EntityId id,
    ItineraryItemDraft draft,
  ) async {
    createCalls++;
    await createGate?.future;
    return inner.createItineraryItem(id, draft);
  }

  @override
  Future<void> updateItineraryItem(
    EntityId trip,
    EntityId id,
    ItineraryItemDraft draft,
  ) => inner.updateItineraryItem(trip, id, draft);
  @override
  Future<void> deleteItineraryItem(EntityId trip, EntityId id) =>
      inner.deleteItineraryItem(trip, id);
  @override
  Future<void> reorderItineraryItems(
    EntityId trip,
    ItineraryOrderDraft draft,
  ) async {
    reorderCalls++;
    await reorderGate?.future;
    if (failReorder) {
      throw const AppError(
        code: AppErrorCode.unavailable,
        message: '순서 저장 실패',
        retryable: true,
      );
    }
    return inner.reorderItineraryItems(trip, draft);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
