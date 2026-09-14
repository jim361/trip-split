import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/firebase/firebase_client.dart';
import 'data/firebase/firestore_trip_repositories.dart';
import 'data/mock/in_memory_trip_repositories.dart';
import 'domain/models.dart';
import 'domain/repositories.dart';
import 'features/places/place_provider.dart';
import 'features/places/mock_place_provider.dart';
import 'features/places/firebase_place_provider.dart';
import 'features/receipts/receipt_parser.dart';
import 'features/receipts/mock_receipt_parser.dart';
import 'features/receipts/firebase_receipt_parser.dart';
import 'platform/app_config.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/mock_auth_service.dart';
import 'services/trip_share_service.dart';
import 'shared/theme/app_theme.dart';
import 'platform/google_map_adapter.dart';
import 'platform/android_actions.dart';
import 'services/google_account_service.dart';
import 'features/sheets/google_sheets_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final config = AppConfig.fromEnvironment();
    final googleAccount = GoogleAccountService(
      serverClientId: config.googleServerClientId,
    );
    final dependencies = await _AppDependencies.create(config, googleAccount);
    final maps = config.enableGoogleMaps ? GoogleMapAdapter() : null;
    final sheets = config.enableGoogleSheets
        ? GoogleSheetsService(
            authorize: googleAccount.authorizeSheets,
            loadRecovery: AndroidActions.loadSheetRecovery,
            saveRecovery: AndroidActions.saveSheetRecovery,
          )
        : null;
    runApp(
      TripSplitApp(
        repositories: dependencies.repositories,
        authService: dependencies.authService,
        tripShareService: dependencies.tripShareService,
        dataSourceLabel: config.dataSource.name,
        placeProvider: dependencies.placeProvider,
        placeLinkResolver: dependencies.placeLinkResolver,
        receiptParser: dependencies.receiptParser,
        mapViewBuilder: maps?.build,
        sheetsService: sheets,
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
    required this.placeProvider,
    required this.placeLinkResolver,
    required this.receiptParser,
  });

  final TripRepositories repositories;
  final AuthService authService;
  final TripShareService tripShareService;
  final PlaceProvider placeProvider;
  final PlaceLinkResolver placeLinkResolver;
  final ReceiptParser receiptParser;

  static Future<_AppDependencies> create(
    AppConfig config,
    GoogleAccountService googleAccount,
  ) async {
    if (config.dataSource == AppDataSource.mock) {
      final repositories = InMemoryTripRepositories();
      return _AppDependencies(
        repositories: repositories,
        authService: MockAuthService(),
        tripShareService: MockTripShareService(repositories),
        placeProvider: MockPlaceProvider(),
        placeLinkResolver: MockPlaceProvider(),
        receiptParser: const MockReceiptParser(),
      );
    }

    final client = await FirebaseClient.initialize(config);
    return _AppDependencies(
      repositories: FirestoreTripRepositories(
        client.firestore,
        currentUid: () => client.auth.currentUser?.uid ?? '',
        functions: client.functions,
      ),
      authService: FirebaseAuthService(
        auth: client.auth,
        firestore: client.firestore,
        googleServerClientId: config.googleServerClientId,
        googleAccount: googleAccount,
      ),
      tripShareService: FirebaseTripShareService(client.functions),
      placeProvider: FirebasePlaceProvider(client.functions),
      placeLinkResolver: FirebasePlaceProvider(client.functions),
      receiptParser: FirebaseReceiptParser(client.functions),
    );
  }
}

final class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
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
