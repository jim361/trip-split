import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/firebase/firebase_client.dart';
import 'data/firebase/firestore_trip_repositories.dart';
import 'data/mock/in_memory_trip_repositories.dart';
import 'domain/models.dart';
import 'domain/repositories.dart';
import 'platform/app_config.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/mock_auth_service.dart';
import 'services/trip_share_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final config = AppConfig.fromEnvironment();
    final dependencies = await _AppDependencies.create(config);
    runApp(
      TripSplitApp(
        repositories: dependencies.repositories,
        authService: dependencies.authService,
        tripShareService: dependencies.tripShareService,
        dataSourceLabel: config.dataSource.name,
      ),
    );
  } catch (error) {
    runApp(_StartupErrorApp(error: error));
  }
}

final class _AppDependencies {
  const _AppDependencies({
    required this.repositories,
    required this.authService,
    required this.tripShareService,
  });

  final TripRepositories repositories;
  final AuthService authService;
  final TripShareService tripShareService;

  static Future<_AppDependencies> create(AppConfig config) async {
    if (config.dataSource == AppDataSource.mock) {
      final repositories = InMemoryTripRepositories();
      return _AppDependencies(
        repositories: repositories,
        authService: MockAuthService(),
        tripShareService: MockTripShareService(repositories),
      );
    }

    final client = await FirebaseClient.initialize(config);
    return _AppDependencies(
      repositories: FirestoreTripRepositories(
        client.firestore,
        currentUid: () => client.auth.currentUser?.uid ?? '',
      ),
      authService: FirebaseAuthService(
        auth: client.auth,
        firestore: client.firestore,
        googleServerClientId: config.googleServerClientId,
      ),
      tripShareService: FirebaseTripShareService(client.functions),
    );
  }
}

final class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error is AppError
                ? (error as AppError).message
                : '앱 설정을 확인해 주세요.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
