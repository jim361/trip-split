enum AppDataSource {
  mock,
  firebase;

  static AppDataSource parse(String value) =>
      switch (value.trim().toLowerCase()) {
        'mock' => mock,
        'firebase' => firebase,
        _ => throw ArgumentError.value(
          value,
          'DATA_SOURCE',
          'mock 또는 firebase여야 합니다.',
        ),
      };
}

const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// [TASK-02 · 실행 설정] secret 없이 dart-define만 앱 경계로 노출합니다.
final class AppConfig {
  const AppConfig({
    this.dataSource = AppDataSource.mock,
    this.useFirebaseEmulators = false,
    this.emulatorHost = '10.0.2.2',
    this.authEmulatorPort = 9099,
    this.firestoreEmulatorPort = 8080,
    this.functionsEmulatorPort = 5001,
    this.functionsRegion = 'asia-northeast3',
    this.firebaseApiKey = 'AIza00000000000000000000000000000000000',
    this.firebaseAppId = '1:000000000000:android:demo',
    this.firebaseMessagingSenderId = '000000000000',
    this.firebaseProjectId = 'demo-trip-split',
    this.googleServerClientId,
  });

  factory AppConfig.fromEnvironment() => AppConfig(
    dataSource: AppDataSource.parse(
      const String.fromEnvironment('DATA_SOURCE', defaultValue: 'mock'),
    ),
    useFirebaseEmulators: const bool.fromEnvironment('USE_FIREBASE_EMULATORS'),
    emulatorHost: const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    ),
    authEmulatorPort: const int.fromEnvironment(
      'FIREBASE_AUTH_EMULATOR_PORT',
      defaultValue: 9099,
    ),
    firestoreEmulatorPort: const int.fromEnvironment(
      'FIRESTORE_EMULATOR_PORT',
      defaultValue: 8080,
    ),
    functionsEmulatorPort: const int.fromEnvironment(
      'FUNCTIONS_EMULATOR_PORT',
      defaultValue: 5001,
    ),
    functionsRegion: const String.fromEnvironment(
      'FIREBASE_FUNCTIONS_REGION',
      defaultValue: 'asia-northeast3',
    ),
    firebaseApiKey: const String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: 'AIza00000000000000000000000000000000000',
    ),
    firebaseAppId: const String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '1:000000000000:android:demo',
    ),
    firebaseMessagingSenderId: const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '000000000000',
    ),
    firebaseProjectId: const String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'demo-trip-split',
    ),
    googleServerClientId: _emptyToNull(_googleServerClientId),
  );

  final AppDataSource dataSource;
  final bool useFirebaseEmulators;
  final String emulatorHost;
  final int authEmulatorPort;
  final int firestoreEmulatorPort;
  final int functionsEmulatorPort;
  final String functionsRegion;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String? googleServerClientId;

  bool get usesDemoFirebaseProject => firebaseProjectId == 'demo-trip-split';
}

String? _emptyToNull(String value) {
  return value.trim().isEmpty ? null : value.trim();
}
