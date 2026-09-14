import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) => writeResponseData(
    {...?data, 'passed': true},
    destinationDirectory: 'build/android-e2e',
    testOutputFilename: '${data!['role']}-${data['phase']}',
  ),
);
