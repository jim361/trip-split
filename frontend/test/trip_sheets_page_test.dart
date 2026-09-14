import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';
import 'package:trip_split/features/sheets/google_sheets_service.dart';
import 'package:trip_split/features/sheets/trip_sheets_page.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

void main() {
  testWidgets('전체 조회 전에는 출력하지 않고 옵션→미리보기→생성은 한 번만 처리한다', (tester) async {
    final inner = InMemoryTripRepositories();
    addTearDown(inner.close);
    final gate = Completer<TripDataSnapshot>();
    final repo = _Repositories(gate.future);
    final write = Completer<SheetsResponse>();
    final paths = <String>[];
    final service = GoogleSheetsService(
      authorize: () async => 'test-token',
      loadRecovery: () async => null,
      saveRecovery: (_) async {},
      request: (path, body, token) async {
        paths.add(path);
        return path == '/v4/spreadsheets'
            ? (status: 200, body: {'spreadsheetId': 'created'})
            : write.future;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TripSheetsPage(
          tripId: tokyoTripId,
          repositories: repo,
          service: service,
        ),
      ),
    );
    expect(find.byKey(const Key('sheet-preview')), findsNothing);
    gate.complete(await inner.loadTripSnapshot(tokyoTripId));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sheet-preview')));
    await tester.pumpAndSettle();
    expect(find.text('시트 미리보기'), findsOneWidget);
    expect(find.text('지출·정산'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sheet-create')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('sheet-create')))
          .onPressed,
      isNull,
    );
    write.complete((status: 200, body: <String, dynamic>{}));
    await tester.pumpAndSettle();
    expect(paths.where((p) => p == '/v4/spreadsheets'), hasLength(1));
    expect(find.text('Google Sheets에 저장했습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px 미리보기와 큰 글씨에서 화면을 열고 가로·세로 스크롤한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = InMemoryTripRepositories();
    addTearDown(repo.close);
    const boundaryKey = Key('sheet-capture');
    if (Platform.environment['CAPTURE_SHEET_PREVIEW'] == '1') {
      final bytes = File('C:/Windows/Fonts/malgun.ttf').readAsBytesSync();
      await tester.runAsync(() async {
        for (final family in [
          'SheetPreviewFont',
          'sans-serif',
          'monospace',
          'Roboto',
        ]) {
          await (FontLoader(
            family,
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
        final icons = File(
          'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
        ).readAsBytesSync();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(icons)))).load();
      });
    }
    Widget app(double scale) => MaterialApp(
      theme: AppTheme.light.copyWith(
        textTheme: AppTheme.light.textTheme.apply(
          fontFamily: Platform.environment['CAPTURE_SHEET_PREVIEW'] == '1'
              ? 'SheetPreviewFont'
              : null,
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: boundaryKey,
        child: TripSheetsPage(tripId: tokyoTripId, repositories: repo),
      ),
    );
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sheet-preview')));
    await tester.tap(find.byKey(const Key('sheet-preview')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.environment['CAPTURE_SHEET_PREVIEW'] == '1') {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '../docs/screenshots/2026-09-14/14-sheet-preview.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.drag(
      find.byType(SheetReportPreview).first,
      const Offset(-500, -200),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _Repositories implements TripRepositories {
  _Repositories(this.data);
  final Future<TripDataSnapshot> data;
  @override
  Future<TripDataSnapshot> loadTripSnapshot(String tripId) => data;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
