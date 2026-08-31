import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/repositories.dart';
import '../features/itinerary/itinerary_page.dart';
import '../features/preparation/preparation_page.dart';
import '../features/receipts/receipts_page.dart';
import '../features/settlement/settlement_page.dart';
import '../shared/theme/app_theme.dart';
import 'auth_session_gate.dart';
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
      final auth = AuthSessionScope.of(context);
      return TripShell(
        location: widget.location,
        tripTitle: trip.title,
        userId: auth.user.uid,
        shareCode: trip.shareCode,
        body: switch (widget.location.destination) {
          TripDestination.itinerary => ItineraryPage(
            trip: trip,
            places: _session.places,
            itinerary: _session.itinerary,
            selectedDate: widget.location.selectedDate,
            mapExpanded: widget.location.mapExpanded,
            onToggleMap: (selectedDate) =>
                _open(widget.location.toggleMap(selectedDate: selectedDate)),
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
    required this.userId,
    required this.shareCode,
    required this.body,
    required this.onDestinationSelected,
    super.key,
  });

  final TripLocation location;
  final String tripTitle;
  final String userId;
  final String shareCode;
  final Widget body;
  final ValueChanged<TripDestination> onDestinationSelected;

  int get _selectedIndex => switch (location.destination) {
    TripDestination.itinerary => 0,
    TripDestination.preparation => 1,
    TripDestination.settlement || TripDestination.receipts => 2,
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= AppTheme.mediumBreakpoint;
    final extendedRail = width >= AppTheme.expandedBreakpoint;
    final sectionLine = BorderSide(
      color: Theme.of(context).colorScheme.onSurface,
      width: AppTheme.sectionStroke,
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppTheme.appBarHeight,
        centerTitle: true,
        leading: IconButton(
          tooltip: '여행 선택',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/trips'),
          icon: const Icon(Icons.menu, size: 20),
        ),
        title: const Text(
          'TRIP SPLIT / MY TRIPS',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: '공유 코드 $shareCode 복사',
              onPressed: () => _copyShareCode(context),
              style: IconButton.styleFrom(
                fixedSize: const Size.square(AppTheme.minimumTouchTarget),
                minimumSize: const Size.square(AppTheme.minimumTouchTarget),
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
              ),
              icon: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.ink),
                ),
                child: const Icon(Icons.person_outline, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: showRail
            ? Row(
                key: Key(
                  extendedRail ? 'trip-shell-expanded' : 'trip-shell-medium',
                ),
                children: [
                  NavigationRail(
                    extended: extendedRail,
                    minExtendedWidth: 224,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectIndex,
                    labelType: extendedRail
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    groupAlignment: -1,
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
                  VerticalDivider(
                    width: AppTheme.sectionStroke,
                    thickness: AppTheme.sectionStroke,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: showRail
          ? null
          : _MobileDestinationBar(
              selectedIndex: _selectedIndex,
              topBorder: sectionLine,
              onSelected: _selectIndex,
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

  Future<void> _copyShareCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: shareCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('공유 코드 $shareCode를 복사했습니다.')));
  }
}

final class _MobileDestinationBar extends StatelessWidget {
  const _MobileDestinationBar({
    required this.selectedIndex,
    required this.topBorder,
    required this.onSelected,
  });

  final int selectedIndex;
  final BorderSide topBorder;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    (Icons.map_outlined, Icons.map, '일정·지도'),
    (Icons.inventory_2_outlined, Icons.inventory_2, '준비'),
    (Icons.payments_outlined, Icons.payments, '비용'),
  ];

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('trip-mobile-navigation'),
    color: Colors.white,
    child: Container(
      height: AppTheme.navigationHeight,
      decoration: BoxDecoration(border: Border(top: topBorder)),
      child: Row(
        children: [
          for (var index = 0; index < _destinations.length; index++)
            Expanded(
              child: _DestinationCell(
                icon: _destinations[index].$1,
                selectedIcon: _destinations[index].$2,
                label: _destinations[index].$3,
                selected: index == selectedIndex,
                showDivider: index > 0,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    ),
  );
}

final class _DestinationCell extends StatelessWidget {
  const _DestinationCell({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryPressed : colors.surface,
            border: showDivider
                ? const Border(left: BorderSide(color: AppTheme.ink))
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: foreground,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
