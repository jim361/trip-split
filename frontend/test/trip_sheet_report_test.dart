import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/sheets/trip_sheet_report.dart';

void main() {
  test('전체 조회 사본은 이후 repository 변경에 섞이지 않는다', () async {
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    final data = await repo.loadTripSnapshot(tokyoTripFixture.trip.id);
    final count = data.itinerary.length;
    await repo.createItineraryItem(
      data.trip.id,
      ItineraryItemDraft(date: data.trip.startDate, title: '나중에 추가', order: 99),
    );
    expect(data.itinerary, hasLength(count));
    expect(
      (await repo.loadTripSnapshot(data.trip.id)).itinerary,
      hasLength(count + 1),
    );
    expect(() => data.itinerary.clear(), throwsUnsupportedError);
  });

  test('일정 필터와 무관하게 전체 지출·통화별 정산·선결제를 유지한다', () async {
    final data = await _snapshot();
    final outside = _expense(
      id: 'prepaid',
      date: '2020-01-01',
      amount: 8000,
      currency: 'KRW',
    );
    final snapshot = _copy(data, expenses: [...data.expenses, outside]);
    final report = buildTripSheetReport(
      snapshot,
      SheetReportOptions(planId: 'B', dates: {data.trip.startDate}),
    );
    final ledger = report.sheets[1].rows;
    expect(
      ledger.where((row) => row.length == 8 && row[1].value == '선결제'),
      hasLength(1),
    );
    expect(
      ledger.any(
        (row) => row.first.value == '여행 합계 KRW' && row[1].value == 8000,
      ),
      isTrue,
    );
    expect(
      report.sheets.first.rows.expand((r) => r).map((c) => c.label).join(),
      contains('기간 외 지출 1건'),
    );
    expect(
      report.sheets.first.rows.expand((r) => r).map((c) => c.label).join(),
      contains('2020-01-01'),
    );
  });

  test('원본 74개 일정·87개 지출과 다음 날 귀국편을 누락하지 않는다', () async {
    final fixture = jsonDecode(
      File('../docs/fixtures/tokyo-2025-sheet1/report-fixture.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final original = await _snapshot();
    final itinerary = (fixture['itinerary'] as List).map((raw) {
      final i = raw as Map<String, dynamic>;
      return ItineraryItem(
        id: i['id'] as String,
        tripId: original.trip.id,
        date: i['date'] as String,
        title: i['title'] as String,
        order: i['order'] as int,
        updatedAt: 0,
        category: i['category'] as String,
        startTime: i['startTime'] as String?,
        endTime: i['endTime'] as String?,
      );
    }).toList();
    // 원본은 분담자가 없다. 원본 지출 합산 검증에만 합성 참여자 한 명을 사용한다.
    final expenses = (fixture['recordedExpenses'] as List).map((raw) {
      final e = raw as Map<String, dynamic>;
      return _expense(
        id: e['id'] as String,
        date: e['date'] as String,
        amount: e['amount'] as int,
        title: e['title'] as String? ?? e['name'] as String? ?? '원본 지출',
      );
    }).toList();
    final trip = fixture['trip'] as Map<String, dynamic>;
    final snapshot = _copy(
      original,
      trip: _trip(
        original.trip,
        trip['startDate'] as String,
        trip['endDate'] as String,
      ),
      itinerary: itinerary,
      expenses: expenses,
    );
    final report = buildTripSheetReport(snapshot, SheetReportOptions());
    expect(itinerary, hasLength(74));
    expect(expenses, hasLength(87));
    expect(expenses.fold<int>(0, (sum, e) => sum + e.totalAmount), 93631);
    final cells = report.sheets.first.rows
        .expand((r) => r)
        .where((c) => c.span == 3)
        .toList();
    for (final i in itinerary) {
      expect(
        cells.where((c) => c.label.split('\n').first.endsWith('. ${i.title}')),
        isNotEmpty,
      );
    }
    expect(cells.where((c) => c.label.contains('01:55–04:40')), hasLength(1));
    expect(itinerary.where((i) => i.startTime == null), hasLength(72));
    expect(cells.where((c) => c.label.contains('하네다 ~ 인천')), hasLength(1));
    expect(reportDates(snapshot).last, '2025-02-10');
  });

  for (final days in [3, 10]) {
    test('$days일·많은 지출·긴 메모가 동적으로 확장되고 숫자는 숫자로 출력된다', () async {
      final data = await _snapshot();
      final snapshot = _copy(
        data,
        trip: _trip(
          data.trip,
          '2026-11-01',
          '2026-11-${days.toString().padLeft(2, '0')}',
        ),
        itinerary: [
          ItineraryItem(
            id: 'untimed',
            tripId: data.trip.id,
            date: '2026-11-01',
            title: '=IMPORTXML("x")',
            order: 0,
            updatedAt: 0,
            memo: List.filled(50, '긴 메모를 모두 보존합니다').join('\n'),
          ),
        ],
        expenses: List.generate(
          40,
          (i) => _expense(id: 'e$i', date: '2026-11-01', amount: i + 1),
        ),
      );
      final report = buildTripSheetReport(snapshot, SheetReportOptions());
      final sheet = report.sheets.first;
      expect(sheet.widths, hasLength(1 + days * 3));
      expect(
        sheet.rows.where((r) => int.tryParse('${r.first.value}') != null),
        hasLength(40),
      );
      final row = sheet.rows.indexWhere(
        (r) => r.any((c) => c.label.contains('IMPORTXML')),
      );
      expect(sheet.rowHeight(row), greaterThan(800));
      final json = jsonEncode(report.writeRequests);
      expect(json, isNot(contains('formulaValue')));
      expect(json, contains('numberValue'));
      expect(json, contains('stringValue'));
      expect(json, contains('MERGE_ALL'));
      for (final sheet in report.sheets) {
        for (final row in sheet.rows) {
          expect(
            row.fold<int>(0, (sum, cell) => sum + cell.span),
            lessThanOrEqualTo(sheet.widths.length),
          );
        }
      }
    });
  }
  test('좌표·장소 없는 일정 보존과 지도 링크의 URL 검증', () {
    expect(reportPlaceLink(null), isNull);
    final place = Place(
      id: 'p',
      tripId: 't',
      name: '식당',
      provider: 'manual',
      source: 'manual',
      addedBy: 'u',
      createdAt: 0,
      updatedAt: 0,
      sourceUrl: 'javascript:alert(1)',
    );
    expect(reportPlaceLink(place)!.scheme, 'https');
    expect(reportPlaceLink(place)!.queryParameters['query'], '식당');
  });
}

Future<TripDataSnapshot> _snapshot() async {
  final repo = InMemoryTripRepositories();
  try {
    return await repo.loadTripSnapshot(tokyoTripFixture.trip.id);
  } finally {
    await repo.close();
  }
}

TripDataSnapshot _copy(
  TripDataSnapshot data, {
  Trip? trip,
  List<ItineraryItem>? itinerary,
  List<Expense>? expenses,
}) => TripDataSnapshot(
  trip: trip ?? data.trip,
  capturedAt: data.capturedAt,
  participants: data.participants,
  places: data.places,
  itinerary: itinerary ?? data.itinerary,
  expenses: expenses ?? data.expenses,
);
Trip _trip(Trip t, String start, String end) => Trip(
  id: t.id,
  title: t.title,
  countryCode: t.countryCode,
  timeZone: t.timeZone,
  mapProvider: t.mapProvider,
  defaultCurrency: t.defaultCurrency,
  startDate: start,
  endDate: end,
  ownerUid: t.ownerUid,
  shareCode: t.shareCode,
  createdAt: 0,
  updatedAt: 0,
);
Expense _expense({
  required String id,
  required String date,
  required int amount,
  String currency = 'JPY',
  String title = '선결제',
}) => Expense(
  id: id,
  tripId: tokyoTripFixture.trip.id,
  title: title,
  category: 'other',
  expenseDate: date,
  totalAmount: amount,
  currency: currency,
  payer: ExpensePayer(participantId: 'synthetic', amount: amount),
  consumers: ['synthetic'],
  allocationMethod: 'equal',
  allocatedAmounts: [
    MoneyAllocation(participantId: 'synthetic', amount: amount),
  ],
  receiptItems: [],
  source: 'manual',
  createdBy: 'test',
  updatedBy: 'test',
  createdAt: 0,
  updatedAt: 0,
);
