import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trip_split/app/auth_session_gate.dart';
import 'package:trip_split/app/trip_shell.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/itinerary/itinerary_page.dart';
import 'package:trip_split/features/settlement/settlement_page.dart';
import 'package:trip_split/main.dart' as app;
import 'package:trip_split/platform/app_config.dart';

const _tripTitle = 'Android 두 기기 검증';
const _ownerItem = '소유자 일정';
const _guestItem = '참여자 일정';
const _offlineItem = '오프라인 중 추가 일정';
const _checklist = '여권 준비';
const _expense = '공동 점심';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('두 Android 앱의 공유·갱신·오프라인·재시작', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.useFirebaseEmulators, isTrue);
    expect(config.firebaseProjectId, 'demo-trip-split');
    expect(config.enableGoogleMaps || config.enableGoogleSheets, isFalse);
    final ui = _Ui(tester);
    await app.main();
    await ui.wait(find.byKey(const Key('account-continue-guest')));
    final auth = AuthSessionScope.of(
      tester.element(find.byKey(const Key('account-continue-guest'))),
    ).user;
    expect(auth.isAnonymous, isTrue);
    final registration = await _request('register', {'uid': auth.uid});
    final role = registration['role'] as String;
    binding.reportData = {
      'role': role,
      'phase': registration['setupComplete'] == true ? 'restart' : 'flow',
      'uid': auth.uid,
    };
    debugPrint('E2E $role authenticated: ${auth.uid}');
    if (registration['setupComplete'] == true) {
      await ui.tapKey('account-continue-guest');
      await ui.wait(find.byKey(Key('trip-tile-${registration['tripId']}')));
      await ui.tapKey('trip-tile-${registration['tripId']}');
      await ui.tapKey('featured-trip-open');
      await ui.synced();
      expect(ui.shell.userId, registration['${role}Uid']);
      expect(ui.shell.location.tripId, registration['tripId']);
      await ui.itineraryContains(_ownerItem, _guestItem, _offlineItem);
      await ui.tapText('비용');
      await ui.wait(find.byType(SettlementPage));
      expect(ui.settlement.expenses.single.title, _expense);
      expect(ui.settlement.expenses.single.totalAmount, 3000);
      expect(
        ui.settlement.participants.where((p) => p.linkedUid != null),
        hasLength(2),
      );
      await _event({'${role}RestartVerified': true});
    } else if (role == 'owner') {
      await _owner(ui);
    } else {
      expect(registration['ownerUid'], isNot(auth.uid));
      await _guest(ui);
    }
    final view = tester.view;
    final contentBottom =
        (view.physicalSize.height - view.padding.bottom) /
        view.devicePixelRatio;
    expect(
      tester.getBottomRight(find.text('비용')).dy,
      lessThanOrEqualTo(contentBottom),
      reason: 'navigation labels must clear the Android system gesture area',
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 12)));
}

Future<void> _owner(_Ui ui) async {
  await ui.tapKey('account-continue-guest');
  await ui.enter('trip-title', _tripTitle);
  await ui.enter('participant-0', '소유자');
  await ui.enter('participant-1', '참여자');
  await ui.tapKey('create-trip');
  await ui.synced();
  await ui.addItinerary(_ownerItem);
  await _event({
    'shareCode': ui.shell.shareCode,
    'tripId': ui.shell.location.tripId,
    'ownerReady': true,
  });
  await ui.barrier('guestJoined');
  await ui.itineraryContains(_ownerItem, _guestItem);
  await ui.tapText('비용');
  await ui.wait(find.byType(SettlementPage));
  expect(
    ui.settlement.participants.singleWhere((p) => p.name == '소유자').linkedUid,
    ui.shell.userId,
    reason: 'createTrip links the first participant to its owner',
  );
  await ui.barrier('guestExpenseCreated');
  await ui.waitUntil(
    () => ui.settlement.expenses.any((e) => e.title == _expense),
    'guest expense stream',
  );
  expect(ui.settlement.expenses.single.totalAmount, 3000);
  await ui.tapText(_expense);
  await ui.tapKey('expense-edit');
  await ui.enter('expense-totalAmount', '3600');
  await ui.tapKey('expense-next');
  await ui.tapKey('expense-save');
  await ui.wait(find.byKey(const Key('expense-detail-total')));
  await ui.back('비용 목록으로');
  await _event({'ownerExpenseUpdated': true});
  await ui.barrier('guestExpenseUpdateSeen');
  await ui.tapText('준비');
  await ui.tapKey('checklist-add');
  await ui.enter('preparation-title', _checklist);
  await ui.tapKey('form-save');
  await ui.wait(find.text(_checklist));
  await _event({'checklistReady': true});
  await ui.barrier('guestOfflinePending');
  final row = find.ancestor(
    of: find.text(_checklist),
    matching: find.byType(ListTile),
  );
  expect(
    ui.tester
        .widget<Checkbox>(
          find.descendant(of: row, matching: find.byType(Checkbox)),
        )
        .value,
    isFalse,
  );
  await ui.tapText('일정·지도');
  await ui.addItinerary(_offlineItem);
  await _event({'offlineOwnerWriteDone': true});
  await ui.barrier('guestReconnected');
  await ui.tapText('준비');
  await ui.wait(find.text(_checklist));
  await ui.waitUntil(
    () =>
        ui.tester
            .widget<Checkbox>(
              find.descendant(of: row, matching: find.byType(Checkbox)),
            )
            .value ==
        true,
    'offline checklist synced to owner',
  );
  await ui.tapText('비용');
  await ui.waitUntil(
    () => ui.settlement.expenses.single.totalAmount == 3000,
    'guest edit synced back',
  );
  await ui.synced();
  await _event({'ownerFlowVerified': true, 'setupComplete': true});
}

Future<void> _guest(_Ui ui) async {
  final ready = await ui.barrier('ownerReady');
  await ui.tapKey('account-continue-share');
  await ui.enter('share-code', ready['shareCode'] as String);
  await ui.tapKey('join-trip');
  await ui.synced();
  expect(ui.shell.location.tripId, ready['tripId']);
  await ui.itineraryContains(_ownerItem);
  await ui.addItinerary(_guestItem);
  await _event({'guestJoined': true});
  await ui.tapText('비용');
  await ui.linkParticipant('참여자');
  await ui.tapKey('expense-add');
  await ui.enter('expense-title', _expense);
  await ui.enter('expense-totalAmount', '3000');
  await ui.tapKey('expense-next');
  await ui.tapKey('expense-save');
  await ui.wait(find.byKey(const Key('expense-detail-total')));
  await ui.back('비용 목록으로');
  await _event({'guestExpenseCreated': true});
  await ui.barrier('ownerExpenseUpdated');
  await ui.waitUntil(
    () => ui.settlement.expenses.single.totalAmount == 3600,
    'owner expense edit streamed to guest',
  );
  await _event({'guestExpenseUpdateSeen': true});
  await ui.barrier('checklistReady');
  await ui.tapText('준비');
  await ui.wait(find.text(_checklist));
  try {
    await _request('guest-network', {'enabled': false});
    await ui.waitUntil(
      () => ui.shell.syncState == TripSyncState.cached,
      'offline cache indicator',
    );
    final row = find.ancestor(
      of: find.text(_checklist),
      matching: find.byType(ListTile),
    );
    await ui.tap(find.descendant(of: row, matching: find.byType(Checkbox)));
    await ui.waitUntil(
      () => ui.shell.syncState == TripSyncState.pending,
      'offline pending write indicator',
    );
    await _event({'guestOfflinePending': true});
    await ui.barrier('offlineOwnerWriteDone');
    await ui.tapText('일정·지도');
    await ui.wait(find.byType(ItineraryPage));
    expect(
      ui.itinerary.itinerary.where((i) => i.title == _offlineItem),
      isEmpty,
    );
    await ui.itineraryContains(_ownerItem, _guestItem);
  } finally {
    await _request('guest-network', {'enabled': true});
  }
  await ui.synced();
  await ui.itineraryContains(_ownerItem, _guestItem, _offlineItem);
  await ui.tapText('비용');
  await ui.waitUntil(
    () => ui.settlement.expenses.length == 1,
    'ledger after reconnect',
  );
  await ui.tapText(_expense);
  await ui.tapKey('expense-edit');
  await ui.enter('expense-totalAmount', '3000');
  await ui.tapKey('expense-next');
  await ui.tapKey('expense-save');
  await ui.wait(find.byKey(const Key('expense-detail-total')));
  await ui.back('비용 목록으로');
  await ui.synced();
  expect(ui.settlement.expenses, hasLength(1));
  await _event({'guestReconnected': true, 'guestFlowVerified': true});
  await ui.barrier('ownerFlowVerified');
}

Future<Map<String, dynamic>> _request(
  String path, [
  Map<String, dynamic>? body,
]) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.openUrl(
      body == null ? 'GET' : 'POST',
      Uri.parse('http://127.0.0.1:5877/$path'),
    );
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 20));
    final text = await response.transform(utf8.decoder).join();
    expect(response.statusCode, 200, reason: text);
    return jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Future<void> _event(Map<String, dynamic> event) async {
  await _request('event', event);
}

class _Ui {
  _Ui(this.tester);
  final WidgetTester tester;
  TripShell get shell => tester.widget<TripShell>(find.byType(TripShell));
  ItineraryPage get itinerary =>
      tester.widget<ItineraryPage>(find.byType(ItineraryPage));
  SettlementPage get settlement =>
      tester.widget<SettlementPage>(find.byType(SettlementPage));

  Future<void> waitUntil(bool Function() condition, String label) async {
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail('Timeout: $label');
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> wait(Finder finder) =>
      waitUntil(() => finder.evaluate().isNotEmpty, finder.toString());
  Future<void> visible(Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 35,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tap(Finder finder) async {
    await visible(finder);
    await waitUntil(
      () => finder.hitTestable().evaluate().isNotEmpty,
      'touch target ready: $finder',
    );
    await tester.tap(finder);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
  }

  Future<void> tapKey(String key) => tap(find.byKey(Key(key)));
  Future<void> tapText(String text) => tap(find.text(text));
  Future<void> enter(String key, String text) async {
    final finder = find.byKey(Key(key));
    await visible(finder);
    await tester.enterText(finder, text);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> back(String tooltip) => tap(find.byTooltip(tooltip));
  Future<void> synced() async {
    await wait(find.byType(TripShell));
    await waitUntil(
      () => shell.syncState == TripSyncState.synced,
      'server synced',
    );
  }

  Future<void> itineraryContains(String a, [String? b, String? c]) async {
    await wait(find.byType(ItineraryPage));
    await waitUntil(
      () => [a, b, c].whereType<String>().every(
        (title) => itinerary.itinerary.any((i) => i.title == title),
      ),
      'itinerary stream contents',
    );
  }

  Future<void> addItinerary(String title) async {
    await tapKey('itinerary-add');
    await enter('edit-title', title);
    await enter('edit-startTime', '10:00');
    await tapKey('itinerary-save');
    await itineraryContains(title);
    await synced();
  }

  Future<void> linkParticipant(String name) async {
    await tapText('정산 참여자 관리');
    await wait(find.text(name));
    final card = find.ancestor(
      of: find.text(name),
      matching: find.byType(Card),
    );
    await tap(find.descendant(of: card, matching: find.text('내 계정 연결')));
    await tapText('확인');
    await wait(find.text('내 계정 연결됨'));
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));
    await wait(find.byType(SettlementPage));
    await waitUntil(
      () => settlement.participants.any(
        (p) => p.name == name && p.linkedUid == shell.userId,
      ),
      'participant link',
    );
  }

  Future<Map<String, dynamic>> barrier(String key) async {
    final deadline = DateTime.now().add(const Duration(minutes: 6));
    while (DateTime.now().isBefore(deadline)) {
      final state = await _request('state');
      if (state[key] == true) return state;
      await tester.pump(const Duration(milliseconds: 500));
    }
    fail('Other device did not reach $key');
  }
}
