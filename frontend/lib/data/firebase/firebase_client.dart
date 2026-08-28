import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/models.dart';
import '../../platform/app_config.dart';

final class FirebaseClient {
  const FirebaseClient({
    required this.app,
    required this.auth,
    required this.firestore,
    required this.functions,
  });

  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  static bool _emulatorsConnected = false;

  static Future<FirebaseClient> initialize(AppConfig config) async {
    if (config.dataSource != AppDataSource.firebase) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: 'Firebase data source일 때만 초기화할 수 있습니다.',
        retryable: false,
        field: 'DATA_SOURCE',
      );
    }
    if (!config.useFirebaseEmulators && config.usesDemoFirebaseProject) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '실제 Firebase 프로젝트 설정이 필요합니다.',
        retryable: false,
        field: 'FIREBASE_PROJECT_ID',
      );
    }

    final options = FirebaseOptions(
      apiKey: config.firebaseApiKey,
      appId: config.firebaseAppId,
      messagingSenderId: config.firebaseMessagingSenderId,
      projectId: config.firebaseProjectId,
    );
    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp(options: options)
        : Firebase.app();
    final auth = FirebaseAuth.instanceFor(app: app);
    final firestore = FirebaseFirestore.instanceFor(app: app);
    final functions = FirebaseFunctions.instanceFor(
      app: app,
      region: config.functionsRegion,
    );

    if (config.useFirebaseEmulators && !_emulatorsConnected) {
      await auth.useAuthEmulator(config.emulatorHost, config.authEmulatorPort);
      firestore.useFirestoreEmulator(
        config.emulatorHost,
        config.firestoreEmulatorPort,
      );
      functions.useFunctionsEmulator(
        config.emulatorHost,
        config.functionsEmulatorPort,
      );
      _emulatorsConnected = true;
    }

    return FirebaseClient(
      app: app,
      auth: auth,
      firestore: firestore,
      functions: functions,
    );
  }
}
