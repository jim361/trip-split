import 'package:flutter/material.dart';

import '../domain/repositories.dart';
import 'router.dart';
import 'trip_shell.dart';

final class TripSplitApp extends StatelessWidget {
  const TripSplitApp({
    required this.repositories,
    this.initialRoute = '/trips/${TripLocation.defaultTripId}/itinerary',
    super.key,
  });

  final TripRepositories repositories;
  final String initialRoute;

  @override
  Widget build(BuildContext context) => MaterialApp(
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
  );

  Route<void> _routeFor(RouteSettings settings) {
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
