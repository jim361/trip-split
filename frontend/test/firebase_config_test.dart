import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/platform/app_config.dart';

void main() {
  test('Firebase Emulator의 Android host와 demo project를 구성한다', () {
    const config = AppConfig(
      dataSource: AppDataSource.firebase,
      useFirebaseEmulators: true,
    );

    expect(config.emulatorHost, '10.0.2.2');
    expect(config.firebaseProjectId, 'demo-trip-split');
    expect(config.firebaseApiKey, matches(RegExp(r'^A[\w-]{38}$')));
    expect(config.usesDemoFirebaseProject, isTrue);
  });

  test('DATA_SOURCE 오타를 조용히 mock으로 바꾸지 않는다', () {
    expect(() => AppDataSource.parse('firebae'), throwsA(isA<ArgumentError>()));
  });
}
