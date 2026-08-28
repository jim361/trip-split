import 'package:flutter/material.dart';

import '../domain/repositories.dart';
import '../features/trips/trip_home_page.dart';
import '../services/auth_service.dart';
import '../services/trip_share_service.dart';
import 'auth_session_gate.dart';
import 'router.dart';
import 'trip_shell.dart';

final class TripSplitApp extends StatelessWidget {
  const TripSplitApp({
    required this.repositories,
    required this.authService,
    required this.tripShareService,
    required this.dataSourceLabel,
    this.initialRoute = '/',
    super.key,
  });

  final TripRepositories repositories;
  final AuthService authService;
  final TripShareService tripShareService;
  final String dataSourceLabel;
  final String initialRoute;

  @override
  Widget build(BuildContext context) => AuthSessionGate(
    authService: authService,
    child: MaterialApp(
      title: 'Trip Split',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff176b5b),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff6f7f3),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (name) => [_routeFor(RouteSettings(name: name))],
      onGenerateRoute: _routeFor,
    ),
  );

  Route<void> _routeFor(RouteSettings settings) {
    if (settings.name == null || settings.name == '/') {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/'),
        builder: (_) => TripHomePage(
          tripShareService: tripShareService,
          dataSourceLabel: dataSourceLabel,
        ),
      );
    }
    final location = TripLocation.tryParse(settings.name);
    if (location == null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const _NotFoundPage(),
      );
    }
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: location.canonicalPath),
      builder: (_) =>
          TripRouteHost(location: location, repositories: repositories),
    );
  }
}

final class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('페이지를 찾을 수 없습니다.')));
}
