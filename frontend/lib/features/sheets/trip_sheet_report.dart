import 'dart:math' as math;

import '../../domain/models.dart';
import '../settlement/settlement_engine.dart';

final class SheetReportOptions {
  SheetReportOptions({this.planId = 'A', Set<String>? dates})
    : dates = dates == null ? null : Set.unmodifiable(dates);
  final String planId;
  final Set<String>? dates;
}

/// 미리보기와 Google Sheets가 같은 값·배치·서식을 사용합니다.
final class ReportCell {
  const ReportCell(
    this.value, {
    this.color = 0xFFFFFFFF,
    this.bold = false,
    this.link,
    this.span = 1,
    this.date = false,
  });
  final Object value;
  final int color;
  final bool bold;
  final Uri? link;
  final int span;
  final bool date;
  String get label => date
      ? DateTime.utc(
          1899,
          12,
          30,
        ).add(Duration(days: value as int)).toIso8601String().substring(0, 10)
      : '$value';
}

final class ReportSheet {
  ReportSheet(this.title, List<List<ReportCell>> rows, this.widths)
    : rows = List.unmodifiable(rows.map(List<ReportCell>.unmodifiable));
  final String title;
  final List<List<ReportCell>> rows;
  final List<double> widths;
  double rowHeight(int row) {
    var height = 36.0;
    var col = 0;
    for (final cell in rows[row]) {
      final width = widths.skip(col).take(cell.span).fold(0.0, (a, b) => a + b);
      final chars = math.max(1, ((width - 16) / 8).floor());
      final lines = cell.label
          .split('\n')
          .fold(
            0,
            (sum, line) => sum + math.max(1, (line.length / chars).ceil()),
          );
      height = math.max(height, lines * 20.0 + 16);
      col += cell.span;
    }
    return height;
  }
}

final class TripSheetReport {
  TripSheetReport({
    required this.title,
    required this.capturedAt,
    this.timeZone = 'UTC',
    required List<ReportSheet> sheets,
  }) : sheets = List.unmodifiable(sheets);
  final String title;
  final DateTime capturedAt;
  final String timeZone;
  final List<ReportSheet> sheets;

  /// Typed stringValue prevents user titles/memos beginning '=' becoming formulas.
  List<Map<String, Object?>> get writeRequests {
    final requests = <Map<String, Object?>>[];
    for (final entry in sheets.indexed) {
      final id = entry.$1, sheet = entry.$2;
      requests.add({
        'updateSheetProperties': {
          'properties': {
            'sheetId': id,
            'gridProperties': {
              'rowCount': math.max(5, sheet.rows.length),
              'columnCount': sheet.widths.length,
              'frozenRowCount': 4,
              'frozenColumnCount': 0,
            },
          },
          'fields': 'gridProperties',
        },
      });
      requests.add({
        'unmergeCells': {
          'range': {'sheetId': id},
        },
      });
      requests.add({
        'updateCells': {
          'start': {'sheetId': id, 'rowIndex': 0, 'columnIndex': 0},
          'rows': [
            for (final row in sheet.rows)
              {
                'values': [
                  for (final cell in row) ...[
                    {
                      'userEnteredValue': {
                        cell.value is num ? 'numberValue' : 'stringValue':
                            cell.value,
                      },
                      'userEnteredFormat': {
                        'backgroundColor': _rgb(cell.color),
                        'wrapStrategy': 'WRAP',
                        'verticalAlignment': 'TOP',
                        'textFormat': {
                          'fontSize': 10,
                          'bold': cell.bold,
                          if (cell.link != null)
                            'link': {'uri': cell.link.toString()},
                        },
                        if (cell.value is num)
                          'numberFormat': {
                            'type': cell.date ? 'DATE' : 'NUMBER',
                            'pattern': cell.date ? 'yyyy-mm-dd' : '#,##0',
                          },
                      },
                    },
                    for (var i = 1; i < cell.span; i++) <String, Object?>{},
                  ],
                ],
              },
          ],
          'fields': 'userEnteredValue,userEnteredFormat',
        },
      });
      for (final row in sheet.rows.indexed) {
        var col = 0;
        for (final cell in row.$2) {
          if (cell.span > 1) {
            requests.add({
              'mergeCells': {
                'range': {
                  'sheetId': id,
                  'startRowIndex': row.$1,
                  'endRowIndex': row.$1 + 1,
                  'startColumnIndex': col,
                  'endColumnIndex': col + cell.span,
                },
                'mergeType': 'MERGE_ALL',
              },
            });
          }
          col += cell.span;
        }
        requests.add({
          'updateDimensionProperties': {
            'range': {
              'sheetId': id,
              'dimension': 'ROWS',
              'startIndex': row.$1,
              'endIndex': row.$1 + 1,
            },
            'properties': {'pixelSize': sheet.rowHeight(row.$1).ceil()},
            'fields': 'pixelSize',
          },
        });
      }
      for (final col in sheet.widths.indexed) {
        requests.add({
          'updateDimensionProperties': {
            'range': {
              'sheetId': id,
              'dimension': 'COLUMNS',
              'startIndex': col.$1,
              'endIndex': col.$1 + 1,
            },
            'properties': {'pixelSize': col.$2.toInt()},
            'fields': 'pixelSize',
          },
        });
      }
    }
    return requests;
  }
}

Map<String, double> _rgb(int color) => {
  'red': ((color >> 16) & 255) / 255,
  'green': ((color >> 8) & 255) / 255,
  'blue': (color & 255) / 255,
};

const _header = 0xFFE0E9F8;
const _categoryColors = {
  'flight': 0xFFDCE7FA,
  'transport': 0xFFEDE8F7,
  'meal': 0xFFFFEAD1,
  'activity': 0xFFE2F0DF,
  'stay': 0xFFFFE2E5,
};

List<String> reportDates(TripDataSnapshot data) {
  final start = DateTime.parse('${data.trip.startDate}T00:00:00Z');
  final end = DateTime.parse('${data.trip.endDate}T00:00:00Z');
  final days = end.difference(start).inDays;
  if (days < 0 || days > 365) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '시트 보고서는 1~366일 여행을 지원합니다.',
      retryable: false,
    );
  }
  return {
    for (var i = 0; i <= days; i++)
      start.add(Duration(days: i)).toIso8601String().substring(0, 10),
    ...data.itinerary.map((i) => i.date),
  }.toList()..sort();
}

ReportCell _date(String date, {int span = 1}) => ReportCell(
  DateTime.parse('${date}T00:00:00Z')
      .difference(DateTime.utc(1899, 12, 30))
      .inDays,
  date: true,
  bold: true,
  color: _header,
  span: span,
);

Uri? reportPlaceLink(Place? place) {
  if (place == null) return null;
  final source = Uri.tryParse(place.sourceUrl ?? '');
  if (source != null && source.scheme == 'https' && source.host.isNotEmpty) {
    return source;
  }
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': place.lat != null && place.lng != null
        ? '${place.lat},${place.lng}'
        : place.name,
    if (place.provider == 'google' && place.providerPlaceId != null)
      'query_place_id': place.providerPlaceId!,
  });
}

TripSheetReport buildTripSheetReport(
  TripDataSnapshot data,
  SheetReportOptions options,
) {
  if (!itineraryPlanIds.contains(options.planId) ||
      options.dates?.isEmpty == true) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '날짜를 한 개 이상 선택하고 A/B안을 확인해 주세요.',
      retryable: false,
    );
  }
  final dates = reportDates(data);
  final places = {for (final p in data.places) p.id: p};
  final names = {for (final p in data.participants) p.id: p.name};
  final selected =
      data.itinerary
          .where(
            (i) =>
                i.planId == options.planId &&
                (options.dates == null || options.dates!.contains(i.date)),
          )
          .toList()
        ..sort((a, b) {
          final order = a.order.compareTo(b.order);
          return order == 0 ? a.id.compareTo(b.id) : order;
        });
  final numbers = <String, int>{};
  for (final date in dates) {
    var number = 0;
    for (final item in selected.where((i) => i.date == date)) {
      numbers[item.id] = ++number;
    }
  }
  final currencies = data.expenses.map((e) => e.currency).toSet().toList()
    ..sort();
  final columns = 1 + dates.length * 3;
  final rows = <List<ReportCell>>[
    [ReportCell(data.trip.title, span: columns, bold: true, color: _header)],
    [
      ReportCell(
        '${options.planId}안 · 선택 날짜의 일정 / 지출은 여행 전체 · ${data.trip.timeZone}',
        span: columns,
      ),
    ],
    [
      ReportCell(
        '조회 완료 ${data.capturedAt.toUtc().toIso8601String()} · 이후 변경은 포함하지 않음',
        span: columns,
      ),
    ],
    [
      const ReportCell('시간', bold: true, color: _header),
      for (final d in dates) _date(d, span: 3),
    ],
  ];
  final hours = selected
      .where((i) => i.startTime != null)
      .map((i) => int.parse(i.startTime!.split(':').first))
      .toList();
  final firstHour = hours.isEmpty ? 8 : hours.reduce(math.min);
  final lastHour = hours.isEmpty ? 8 : hours.reduce(math.max);
  for (final hour in [for (var h = firstHour; h <= lastHour; h++) h, -1]) {
    final byDate = {
      for (final d in dates)
        d: selected
            .where(
              (i) =>
                  i.date == d &&
                  (i.startTime == null
                          ? -1
                          : int.parse(i.startTime!.split(':').first)) ==
                      hour,
            )
            .toList(),
    };
    final count = byDate.values.fold(
      0,
      (n, items) => math.max(n, items.length),
    );
    if (hour == -1 && count == 0) continue;
    for (var index = 0; index < math.max(1, count); index++) {
      rows.add([
        ReportCell(
          index > 0
              ? ''
              : hour == -1
              ? '시간 미정'
              : '${hour.toString().padLeft(2, '0')}:00',
        ),
        for (final d in dates)
          if (index >= byDate[d]!.length)
            const ReportCell('', span: 3)
          else
            _itineraryCell(byDate[d]![index], numbers, places),
      ]);
    }
  }
  rows.add([
    ReportCell(
      '일별 지출 · 예약 가격과 영수증 품목은 중복 합산하지 않음',
      span: columns,
      color: _header,
      bold: true,
    ),
  ]);
  final expenses = [...data.expenses]
    ..sort((a, b) {
      final date = a.expenseDate.compareTo(b.expenseDate);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
  final daily = {
    for (final d in dates)
      d: expenses
          .where(
            (e) =>
                e.expenseDate == d &&
                d.compareTo(data.trip.startDate) >= 0 &&
                d.compareTo(data.trip.endDate) <= 0,
          )
          .toList(),
  };
  final count = daily.values.fold(0, (n, e) => math.max(n, e.length));
  for (var index = 0; index < count; index++) {
    rows.add([
      ReportCell('${index + 1}'),
      for (final d in dates)
        if (index >= daily[d]!.length) ...const [
          ReportCell(''),
          ReportCell(''),
          ReportCell(''),
        ] else ...[
          ReportCell(daily[d]![index].title),
          ReportCell(daily[d]![index].totalAmount),
          ReportCell(daily[d]![index].currency),
        ],
    ]);
  }
  for (final currency in currencies) {
    rows.add([
      ReportCell('합계 $currency', bold: true),
      for (final d in dates) ...[
        const ReportCell('일별 합계'),
        ReportCell(
          daily[d]!
              .where((e) => e.currency == currency)
              .fold<int>(0, (n, e) => n + e.totalAmount),
          bold: true,
        ),
        ReportCell(currency),
      ],
    ]);
  }
  final outside = expenses
      .where(
        (e) =>
            e.expenseDate.compareTo(data.trip.startDate) < 0 ||
            e.expenseDate.compareTo(data.trip.endDate) > 0,
      )
      .toList();
  rows.add([
    ReportCell(
      '여행 기간 외 지출 ${outside.length}건 · 지출·정산 탭에 전체 포함',
      span: columns,
      bold: true,
      color: _header,
    ),
  ]);
  for (final e in outside) {
    rows.add([
      ReportCell(
        '${e.expenseDate} · ${e.title} · ${e.currency} ${e.totalAmount}',
        span: columns,
      ),
    ]);
  }

  final ledger = <List<ReportCell>>[
    [const ReportCell('여행 전체 지출·정산', span: 8, bold: true, color: _header)],
    [const ReportCell('통화별 계산 · 송금 제안이며 완료 상태를 기록하지 않음', span: 8)],
    [ReportCell('조회 완료 ${data.capturedAt.toUtc().toIso8601String()}', span: 8)],
    [
      for (final t in ['날짜', '지출', '금액', '통화', '결제자', '유형', '배분', '메모'])
        ReportCell(t, bold: true, color: _header),
    ],
    for (final e in expenses)
      [
        _date(e.expenseDate),
        ReportCell(e.title),
        ReportCell(e.totalAmount),
        ReportCell(e.currency),
        ReportCell(names[e.payer.participantId] ?? e.payer.participantId),
        ReportCell(e.category),
        ReportCell(
          e.allocatedAmounts
              .map(
                (a) =>
                    '${names[a.participantId] ?? a.participantId}: ${a.amount}',
              )
              .join('\n'),
        ),
        ReportCell(e.memo ?? ''),
      ],
  ];
  for (final currency in currencies) {
    final balances = balancesForCurrency(expenses, currency);
    final transfers = proposeTransfers(balances);
    ledger.add([
      ReportCell('여행 합계 $currency', span: 2, bold: true),
      ReportCell(
        expenses
            .where((e) => e.currency == currency)
            .fold<int>(0, (sum, e) => sum + e.totalAmount),
        bold: true,
      ),
      ReportCell(currency, span: 5),
    ]);
    ledger.add([
      for (final t in ['참여자', '결제액', '부담액', '잔액', '통화'])
        ReportCell(t, bold: true, color: _header),
    ]);
    for (final e in balances.entries) {
      ledger.add([
        ReportCell(names[e.key] ?? e.key),
        ReportCell(e.value.paid),
        ReportCell(e.value.owed),
        ReportCell(e.value.net),
        ReportCell(currency),
      ]);
    }
    ledger.add([
      const ReportCell('송금 제안', span: 8, bold: true, color: _header),
    ]);
    for (final t in transfers) {
      ledger.add([
        ReportCell(names[t.from] ?? t.from),
        ReportCell(names[t.to] ?? t.to),
        ReportCell(t.amount),
        ReportCell(currency),
      ]);
    }
    if (transfers.isEmpty) {
      ledger.add([const ReportCell('송금할 금액이 없습니다.', span: 8)]);
    }
  }
  if (expenses.isEmpty) {
    ledger.add([const ReportCell('등록된 지출이 없습니다.', span: 8)]);
  }
  return TripSheetReport(
    title: '${data.trip.title} · ${options.planId}안 보고서',
    timeZone: data.trip.timeZone,
    capturedAt: data.capturedAt,
    sheets: [
      ReportSheet(
        '일정·지출',
        rows,
        List.unmodifiable([
          80.0,
          for (final _ in dates) ...[160.0, 80.0, 60.0],
        ]),
      ),
      ReportSheet('지출·정산', ledger, const [
        110,
        220,
        110,
        80,
        150,
        100,
        240,
        300,
      ]),
    ],
  );
}

ReportCell _itineraryCell(
  ItineraryItem item,
  Map<String, int> numbers,
  Map<String, Place> places,
) {
  final place = places[item.placeId];
  return ReportCell(
    [
      '${numbers[item.id]}. ${item.title}',
      if (item.startTime != null)
        '${item.startTime}${item.endTime == null ? '' : '–${item.endTime}'}',
      if (place != null) place.name,
      if (item.memo?.isNotEmpty == true) item.memo!,
    ].join('\n'),
    span: 3,
    color: _categoryColors[item.category] ?? 0xFFF2F2F2,
    link: reportPlaceLink(place),
  );
}
