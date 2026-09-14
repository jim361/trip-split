import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../platform/android_actions.dart';
import '../../shared/widgets/edit_frame.dart';
import 'google_sheets_service.dart';
import 'trip_sheet_report.dart';

class TripSheetsPage extends StatefulWidget {
  const TripSheetsPage({
    required this.tripId,
    required this.repositories,
    this.service,
    super.key,
  });
  final String tripId;
  final TripRepositories repositories;
  final GoogleSheetsService? service;
  @override
  State<TripSheetsPage> createState() => _TripSheetsPageState();
}

class _TripSheetsPageState extends State<TripSheetsPage> {
  TripDataSnapshot? _data;
  TripSheetReport? _report;
  Set<String> _dates = {};
  String _plan = 'A';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _run(() async {
    await widget.service?.restore();
    final data = await widget.repositories.loadTripSnapshot(widget.tripId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _dates = reportDates(data).toSet();
      _report = null;
    });
  });

  @override
  Widget build(BuildContext context) {
    final data = _data, report = _report, service = widget.service;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(report == null ? '시트 내보내기' : '시트 미리보기')),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (service?.hasPending == true)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service!.complete
                            ? 'Google Sheets에 저장했습니다.'
                            : service.creationUncertain
                            ? '생성 응답을 확인하지 못했습니다. Google Drive에서 제목을 먼저 확인해 주세요.'
                            : '문서는 생성됐지만 내용 저장이 끝나지 않았습니다. 저장 당시의 사본으로 복구합니다.',
                      ),
                      Text(service.pendingTitle ?? ''),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (service.spreadsheetUrl != null)
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () => AndroidActions.openUrl(
                                        service.spreadsheetUrl!,
                                      ),
                                    ),
                              child: const Text('시트 열기'),
                            ),
                          if (!service.complete && !service.creationUncertain)
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(service.retryWrite),
                              child: const Text('같은 문서에 다시 쓰기'),
                            ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    if (!service.complete &&
                                        !await confirmAction(
                                          context,
                                          '새 보고서를 시작할까요?',
                                          'Google Drive에서 기존 보고서를 확인한 뒤 진행해 주세요. 복구 정보가 지워지며 기존 문서는 삭제되지 않습니다.',
                                        )) {
                                      return;
                                    }
                                    await _run(service.startNew);
                                  },
                            child: Text(
                              service.complete
                                  ? '다른 보고서 만들기'
                                  : 'Drive 확인 후 새로 시작',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (data == null)
                Expanded(
                  child: Center(
                    child: _busy
                        ? const Text('전체 여행 데이터를 불러오는 중입니다.')
                        : FilledButton(
                            onPressed: _load,
                            child: const Text('다시 불러오기'),
                          ),
                  ),
                )
              else if (report == null)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        data.trip.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '선택한 날짜·A/B안의 일정과 여행 전체 지출을 보고서로 만듭니다. 기간 밖 선결제와 통화별 정산도 포함합니다.',
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'A', label: Text('A안')),
                          ButtonSegment(value: 'B', label: Text('B안')),
                        ],
                        selected: {_plan},
                        onSelectionChanged: _busy
                            ? null
                            : (value) => setState(() => _plan = value.single),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final d in reportDates(data))
                            FilterChip(
                              label: Text(d),
                              selected: _dates.contains(d),
                              onSelected: _busy
                                  ? null
                                  : (selected) => setState(() {
                                      if (selected) {
                                        _dates.add(d);
                                      } else {
                                        _dates.remove(d);
                                      }
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('sheet-preview'),
                        onPressed: _busy || _dates.isEmpty
                            ? null
                            : () => _run(() async {
                                final report = buildTripSheetReport(
                                  data,
                                  SheetReportOptions(
                                    planId: _plan,
                                    dates: _dates,
                                  ),
                                );
                                setState(() => _report = report);
                              }),
                        icon: const Icon(Icons.preview_outlined),
                        label: const Text('미리보기'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _load,
                        child: const Text('최신 데이터 다시 불러오기'),
                      ),
                    ],
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _report = null),
                        child: const Text('옵션 변경'),
                      ),
                      FilledButton.icon(
                        key: const Key('sheet-create'),
                        onPressed:
                            _busy || service == null || service.hasPending
                            ? null
                            : () => _run(() => service.create(report)),
                        icon: const Icon(Icons.add_chart),
                        label: const Text('Google Sheets 생성'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    service == null
                        ? '미리보기 준비 완료 · Google Sheets 연결 설정이 필요합니다.'
                        : '생성 버튼을 누르면 Google 계정의 파일 생성 권한을 요청합니다.',
                  ),
                ),
                Expanded(
                  child: DefaultTabController(
                    length: report.sheets.length,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            for (final s in report.sheets) Tab(text: s.title),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              for (final s in report.sheets)
                                SheetReportPreview(sheet: s),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SheetReportPreview extends StatelessWidget {
  const SheetReportPreview({required this.sheet, super.key});
  final ReportSheet sheet;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: sheet.widths.fold<double>(0.0, (a, b) => a + b),
      child: ListView.builder(
        itemCount: sheet.rows.length,
        itemBuilder: (context, index) {
          final positions = <int>[];
          var col = 0;
          for (final cell in sheet.rows[index]) {
            positions.add(col);
            col += cell.span;
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in sheet.rows[index].indexed)
                  Builder(
                    builder: (context) {
                      final cell = entry.$2;
                      final width = sheet.widths
                          .skip(positions[entry.$1])
                          .take(cell.span)
                          .fold(0.0, (a, b) => a + b);
                      return Container(
                        width: width,
                        constraints: BoxConstraints(
                          minHeight: sheet.rowHeight(index),
                        ),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(cell.color),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: .5,
                          ),
                        ),
                        child: Text(
                          cell.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: cell.bold
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: cell.link == null
                                ? const Color(0xFF202020)
                                : const Color(0xFF1D4ED8),
                            decoration: cell.link == null
                                ? null
                                : TextDecoration.underline,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
