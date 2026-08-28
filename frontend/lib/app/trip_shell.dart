import 'package:flutter/material.dart';

import '../domain/repositories.dart';
import '../features/itinerary/itinerary_page.dart';
import '../features/preparation/preparation_page.dart';
import '../features/receipts/receipts_page.dart';
import '../features/settlement/settlement_page.dart';
import 'router.dart';
import 'trip_session.dart';

final class TripRouteHost extends StatefulWidget {
  const TripRouteHost({
    required this.location,
    required this.repositories,
    super.key,
  });

  final TripLocation location;
  final TripRepositories repositories;

  @override
  State<TripRouteHost> createState() => _TripRouteHostState();
}

final class _TripRouteHostState extends State<TripRouteHost> {
  late final TripSessionController _session;

  @override
  void initState() {
    super.initState();
    _session = TripSessionController(
      tripId: widget.location.tripId,
      repositories: widget.repositories,
    )..start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _session,
    builder: (context, _) {
      if (_session.error case final error?) {
        return _LoadState(
          icon: Icons.cloud_off_outlined,
          title: error.message,
          detail: error.retryable ? '잠시 후 다시 시도해 주세요.' : error.code.wireValue,
        );
      }
      if (_session.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final trip = _session.trip!;
      return TripShell(
        location: widget.location,
        tripTitle: trip.title,
        body: switch (widget.location.destination) {
          TripDestination.itinerary => ItineraryPage(
            trip: trip,
            places: _session.places,
            itinerary: _session.itinerary,
            mapExpanded: widget.location.mapExpanded,
            onToggleMap: () => _open(widget.location.toggleMap()),
          ),
          TripDestination.preparation => PreparationPage(
            trip: trip,
            itinerary: _session.itinerary,
          ),
          TripDestination.settlement => SettlementPage(
            trip: trip,
            participants: _session.participants,
            expenses: _session.expenses,
            onOpenReceipts: () =>
                _open(widget.location.forDestination(TripDestination.receipts)),
          ),
          TripDestination.receipts => ReceiptsPage(
            trip: trip,
            onBackToSettlement: () => _open(
              widget.location.forDestination(TripDestination.settlement),
            ),
          ),
        },
        onDestinationSelected: (destination) =>
            _open(widget.location.forDestination(destination)),
      );
    },
  );

  void _open(TripLocation location) {
    Navigator.of(context).pushReplacementNamed(location.canonicalPath);
  }
}

final class TripShell extends StatelessWidget {
  const TripShell({
    required this.location,
    required this.tripTitle,
    required this.body,
    required this.onDestinationSelected,
    super.key,
  });

  final TripLocation location;
  final String tripTitle;
  final Widget body;
  final ValueChanged<TripDestination> onDestinationSelected;

  int get _selectedIndex => switch (location.destination) {
    TripDestination.itinerary => 0,
    TripDestination.preparation => 1,
    TripDestination.settlement || TripDestination.receipts => 2,
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tripTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              'mock · ${location.tripId}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(label: Text('Android MVP')),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectIndex,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.route_outlined),
                        selectedIcon: Icon(Icons.route),
                        label: Text('일정·지도'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.checklist_outlined),
                        selectedIcon: Icon(Icons.checklist),
                        label: Text('준비'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: Icon(Icons.account_balance_wallet),
                        label: Text('비용'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: '일정·지도',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: '준비',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: '비용',
                ),
              ],
            ),
    );
  }

  void _selectIndex(int index) {
    onDestinationSelected(switch (index) {
      0 => TripDestination.itinerary,
      1 => TripDestination.preparation,
      _ => TripDestination.settlement,
    });
  }
}

final class _LoadState extends StatelessWidget {
  const _LoadState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
