import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['SCREENSHOT_DIR'] ??
        'build/screen-catalog/screenshots',
  );
  await directory.create(recursive: true);
  final names = <String>[];
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^\d{2}-[a-z-]+$').hasMatch(name) || bytes.isEmpty) {
        return false;
      }
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      names.add(name);
      return true;
    },
    responseDataCallback: (_) async {
      final revision = await Process.run('git', ['rev-parse', 'HEAD']);
      final status = await Process.run('git', ['status', '--porcelain']);
      if (revision.exitCode != 0 || status.exitCode != 0) {
        throw StateError('캡처 기준 Git 상태를 읽을 수 없습니다.');
      }
      await writeResponseData(
        {
          'passed': true,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
          'dataSource': 'mock',
          'baseCommit': (revision.stdout as String).trim(),
          'workingTreeModified': (status.stdout as String).trim().isNotEmpty,
          'screenshots': names,
        },
        destinationDirectory: directory.path,
        testOutputFilename: 'capture-result',
      );
    },
  );
}
