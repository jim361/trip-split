import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';

import '../../domain/repositories.dart';
import '../../shared/theme/app_theme.dart';
import '../map/map_render_model.dart';
import '../places/place_provider.dart';
import '../places/mock_place_provider.dart';
import '../places/places_page.dart';
import '../../platform/android_actions.dart';
import '../../shared/widgets/edit_frame.dart';
import 'itinerary_edit_page.dart';
import 'itinerary_plan_controls.dart';
import 'trip_timetable.dart' show tripDatesFor;

// [TASK-04 / TASK-05 · 일정·지도] 날짜별 일정과 지도 mock의 화면 경계입니다.
class ItineraryPage extends StatefulWidget {
  const ItineraryPage({
    super.key,
    required this.trip,
    required this.repositories,
    required this.places,
    required this.itinerary,
    required this.selectedDate,
    this.selectedPlan = 'A',
    required this.mapExpanded,
    required this.onToggleMap,
    this.placeProvider,
    this.placeLinkResolver,
  });

  final Trip trip;
  final TripRepositories repositories;
  final List<Place> places;
  final List<ItineraryItem> itinerary;
  final String? selectedDate;
  final String selectedPlan;
  final bool mapExpanded;
  final void Function(String date, String planId) onToggleMap;
  final PlaceProvider? placeProvider;
  final PlaceLinkResolver? placeLinkResolver;

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  String? _selectedDate;
  String _selectedPlan = 'A';
  ItineraryOrderDraft? _pendingOrder;
  bool get _moving => _pendingOrder != null;
  bool _editing = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedPlan = widget.selectedPlan;
  }

  @override
  void didUpdateWidget(covariant ItineraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != null) {
      _selectedDate = widget.selectedDate;
    }
    if (widget.selectedPlan != oldWidget.selectedPlan) {
      _selectedPlan = widget.selectedPlan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = tripDatesFor(widget.trip, widget.itinerary);
    final selectedDate = dates.contains(_selectedDate)
        ? _selectedDate!
        : dates.isEmpty
        ? ''
        : dates.first;
    _selectedDate = selectedDate;
    final pending = _pendingOrder;
    final pendingIds =
        pending?.date == selectedDate && pending?.planId == _selectedPlan
        ? pending!.itemIds
        : const <String>[];
    final pendingPositions = {
      for (final entry in pendingIds.indexed) entry.$2: entry.$1,
    };
    final selectedItinerary =
        widget.itinerary
            .where(
              (item) =>
                  item.planId == _selectedPlan && item.date == selectedDate,
            )
            .map(
              (item) => pendingIds.isEmpty
                  ? item
                  : ItineraryItem(
                      id: item.id,
                      tripId: item.tripId,
                      date: item.date,
                      title: item.title,
                      order:
                          pendingPositions[item.id] ??
                          pendingIds.length + item.order,
                      updatedAt: item.updatedAt,
                      updatedBy: item.updatedBy,
                      planId: item.planId,
                      category: item.category,
                      startTime: item.startTime,
                      endTime: item.endTime,
                      placeId: item.placeId,
                      memo: item.memo,
                    ),
            )
            .toList()
          ..sort((left, right) {
            final byOrder = left.order.compareTo(right.order);
            return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
          });
    final mapModel = deriveMapRenderModel(
      places: widget.places,
      itinerary: selectedItinerary,
    );
    final selectedDay = dates.indexOf(selectedDate) + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = _ItineraryHeading(
          selectedDay: selectedDay,
          selectedDate: selectedDate,
        );
        final dayTabs = _DayTabs(
          dates: dates,
          selectedDate: selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        );
        final planSelector = ItineraryPlanSelector(
          selected: _selectedPlan,
          onSelected: (plan) => setState(() => _selectedPlan = plan),
        );
        final map = _MockMap(
          tripTitle: widget.trip.title,
          model: mapModel,
          expanded: widget.mapExpanded,
          onToggle: () => widget.onToggleMap(selectedDate, _selectedPlan),
          onSelect: (id) => _edit(
            selectedDate,
            selectedItinerary.firstWhere((item) => item.id == id),
          ),
        );
        final actions = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const Key('itinerary-add'),
                onPressed: _moving ? null : () => _edit(selectedDate),
                icon: const Icon(Icons.add),
                label: const Text('일정 추가'),
              ),
              if (MediaQuery.sizeOf(context).width >=
                  AppTheme.expandedBreakpoint)
                _RoutePanelHeader(
                  onPlaces: _openPlaces,
                  onMap: () => _openMap(selectedItinerary),
                ),
              if (selectedItinerary.length > 1)
                TextButton.icon(
                  onPressed: _moving
                      ? null
                      : () => _sortByTime(selectedItinerary),
                  icon: const Icon(Icons.schedule),
                  label: const Text('시간순으로 정렬'),
                ),
              if (selectedItinerary.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '일정을 꾹 눌러 끌면 순서를 바꿀 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_moving) const LinearProgressIndicator(),
              if (_error case final error?)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error.message,
                    key: const Key('itinerary-order-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
        final schedule = _DaySchedule(
          key: ValueKey('schedule-$selectedDate-$_selectedPlan'),
          date: selectedDate,
          itinerary: selectedItinerary,
          onEdit: _moving ? null : (item) => _edit(selectedDate, item),
          onReorder: _moving
              ? null
              : (from, to) => _reorder(selectedItinerary, from, to),
        );

        if (MediaQuery.sizeOf(context).width >= AppTheme.expandedBreakpoint) {
          return Row(
            key: const Key('itinerary-expanded-layout'),
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  children: [
                    heading,
                    const SizedBox(height: 16),
                    planSelector,
                    const SizedBox(height: 12),
                    dayTabs,
                    const SizedBox(height: 16),
                    map,
                  ],
                ),
              ),
              VerticalDivider(
                width: AppTheme.sectionStroke,
                thickness: AppTheme.sectionStroke,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              SizedBox(
                width: 400,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'DAY ${selectedDay.toString().padLeft(2, '0')} / ROUTE',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _dateLongLabel(selectedDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 20),
                              actions,
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                        sliver: schedule,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          key: const Key('itinerary-compact-layout'),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        heading,
                        const SizedBox(height: 16),
                        planSelector,
                        const SizedBox(height: 12),
                        dayTabs,
                      ],
                    ),
                  ),
                  map,
                  _RoutePanelHeader(
                    onPlaces: _openPlaces,
                    onMap: () => _openMap(selectedItinerary),
                  ),
                  actions,
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 96),
              sliver: schedule,
            ),
          ],
        );
      },
    );
  }

  Future<void> _edit(String date, [ItineraryItem? item]) async {
    if (_editing || _moving) return;
    _editing = true;
    ScaffoldMessenger.of(context).clearSnackBars();
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ItineraryEditPage(
          tripId: widget.trip.id,
          repositories: widget.repositories,
          date: date,
          planId: _selectedPlan,
          places: widget.places,
          placeProvider: widget.placeProvider,
          placeLinkResolver: widget.placeLinkResolver,
          item: item,
        ),
      ),
    );
    _editing = false;
    if (mounted && message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openPlaces() async {
    if (_editing || _moving) return;
    _editing = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlacesPage(
          trip: widget.trip,
          repositories: widget.repositories,
          provider: widget.placeProvider ?? MockPlaceProvider(),
          linkResolver: widget.placeLinkResolver ?? MockPlaceProvider(),
        ),
      ),
    );
    _editing = false;
  }

  Future<void> _openMap(List<ItineraryItem> items) async {
    final places = {for (final p in widget.places) p.id: p};
    final located = items
        .map((i) => places[i.placeId])
        .whereType<Place>()
        .where((p) => p.lat != null && p.lng != null)
        .toList();
    if (located.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('좌표가 연결된 일정을 먼저 추가해 주세요.')));
      return;
    }
    final destination = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('외부 지도에서 열 구간'),
        children: [
          for (var i = 0; i < located.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, i),
              child: Text(
                i == 0
                    ? '${located[i].name} 위치 보기'
                    : '${located[i - 1].name} → ${located[i].name}',
              ),
            ),
        ],
      ),
    );
    if (destination == null || !mounted) return;
    final place = located[destination];
    final query = destination == 0
        ? {'api': '1', 'query': '${place.lat},${place.lng}'}
        : {
            'api': '1',
            'origin':
                '${located[destination - 1].lat},${located[destination - 1].lng}',
            'destination': '${place.lat},${place.lng}',
          };
    try {
      await AndroidActions.openUrl(
        Uri.https(
          'www.google.com',
          destination == 0 ? '/maps/search/' : '/maps/dir/',
          query,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(actionError(error))));
      }
    }
  }

  Future<void> _sortByTime(List<ItineraryItem> items) async {
    if (_moving || _editing) return;
    if (!await confirmAction(
          context,
          '시간순으로 정렬할까요?',
          '같은 시간은 현재 순서를 유지하고, 시간이 없는 일정은 뒤에 둡니다.',
        ) ||
        !mounted) {
      return;
    }
    final original = {
      for (final (index, item) in items.indexed) item.id: index,
    };
    final ordered = [...items]
      ..sort((a, b) {
        final time = (a.startTime ?? '99:99').compareTo(b.startTime ?? '99:99');
        return time != 0 ? time : original[a.id]!.compareTo(original[b.id]!);
      });
    await _saveOrder(ordered);
  }

  Future<void> _reorder(List<ItineraryItem> items, int from, int to) async {
    if (_moving || _editing || from == to) return;
    final reordered = [...items];
    reordered.insert(to, reordered.removeAt(from));
    await _saveOrder(reordered);
  }

  Future<void> _saveOrder(List<ItineraryItem> reordered) async {
    final draft = ItineraryOrderDraft(
      date: reordered.first.date,
      planId: reordered.first.planId,
      itemIds: reordered.map((item) => item.id).toList(),
    );
    setState(() {
      _pendingOrder = draft;
      _error = null;
    });
    try {
      await widget.repositories.reorderItineraryItems(widget.trip.id, draft);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is AppError
              ? error
              : const AppError(
                  code: AppErrorCode.unknown,
                  message: '순서를 저장하지 못했습니다. 다시 시도해 주세요.',
                  retryable: false,
                );
        });
      }
    } finally {
      if (mounted) setState(() => _pendingOrder = null);
    }
  }
}

class _ItineraryHeading extends StatelessWidget {
  const _ItineraryHeading({
    required this.selectedDay,
    required this.selectedDate,
  });

  final int selectedDay;
  final String selectedDate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '${selectedDay.toString().padLeft(2, '0')} / ITINERARY MAP',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface),
        ),
        child: Text(
          _dateBadgeLabel(selectedDate),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ],
  );
}

class _DayTabs extends StatelessWidget {
  const _DayTabs({
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<String> dates;
  final String selectedDate;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final frameSide = BorderSide(color: colors.onSurface);
    return SizedBox(
      height: AppTheme.minimumTouchTarget,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleDays = dates.length.clamp(1, 3);
          final dayWidth = constraints.maxWidth / visibleDays;
          return ListView.builder(
            key: const Key('itinerary-day-tabs'),
            scrollDirection: Axis.horizontal,
            itemExtent: dayWidth,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final selected = date == selectedDate;
              return Material(
                color: selected ? colors.onSurface : colors.surface,
                child: InkWell(
                  key: ValueKey('itinerary-day-$date'),
                  onTap: () => onSelected(date),
                  child: Semantics(
                    selected: selected,
                    button: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: index == 0 ? frameSide : BorderSide.none,
                          top: frameSide,
                          right: frameSide,
                          bottom: frameSide,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}일차',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected
                                    ? colors.surface
                                    : colors.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule({
    super.key,
    required this.date,
    required this.itinerary,
    this.onEdit,
    this.onReorder,
  });

  final String date;
  final List<ItineraryItem> itinerary;
  final ValueChanged<ItineraryItem>? onEdit;
  final ReorderCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    if (itinerary.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          key: ValueKey('itinerary-day-empty-$date'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface,
              width: AppTheme.frameStroke,
            ),
          ),
          child: const Text('이 날짜에는 아직 일정이 없습니다.'),
        ),
      );
    }

    return SliverReorderableList(
      itemCount: itinerary.length,
      onReorderItem: (from, to) => onReorder?.call(from, to),
      proxyDecorator: (child, index, animation) =>
          Material(elevation: 6, child: child),
      itemBuilder: (context, index) {
        final item = itinerary[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(item.id),
          index: index,
          enabled: onReorder != null && itinerary.length > 1,
          child: _DayScheduleRow(
            item: item,
            number: index + 1,
            showTopBorder: index == 0,
            onEdit: onEdit == null ? null : () => onEdit!(item),
          ),
        );
      },
    );
  }
}

class _DayScheduleRow extends StatelessWidget {
  const _DayScheduleRow({
    required this.item,
    required this.number,
    required this.showTopBorder,
    this.onEdit,
  });

  final ItineraryItem item;
  final int number;
  final bool showTopBorder;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (categoryLabel, categoryColor) = itineraryCategoryStyle(
      item.category,
    );
    return Material(
      child: InkWell(
        onTap: onEdit,
        child: Container(
          key: ValueKey('itinerary-row-${item.id}'),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: showTopBorder
                  ? BorderSide(color: colors.outlineVariant)
                  : BorderSide.none,
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  item.startTime ?? '--:--',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryColor,
                  border: Border.all(color: colors.onSurface),
                ),
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      categoryLabel,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(Icons.drag_handle, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePanelHeader extends StatelessWidget {
  const _RoutePanelHeader({required this.onPlaces, required this.onMap});
  final VoidCallback onPlaces;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onPlaces,
          icon: const Icon(Icons.bookmark_border),
          label: const Text('장소 보관함'),
        ),
        FilledButton.icon(
          onPressed: onMap,
          icon: const Icon(Icons.map_outlined),
          label: const Text('지도 열기'),
        ),
      ],
    ),
  );
}

class _MockMap extends StatelessWidget {
  const _MockMap({
    required this.tripTitle,
    required this.model,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  final String tripTitle;
  final MapRenderModel model;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: '$tripTitle 일정 위치를 표시할 Google 지도 자리',
      container: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: expanded ? 420 : 280,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color: colors.onSurface,
              width: AppTheme.sectionStroke,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pins = model.pins.take(expanded ? 8 : 6).toList();
            final points = [
              for (var index = 0; index < pins.length; index++)
                _mapPoint(index, constraints.biggest),
            ];
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(
                      roadColor: colors.outlineVariant,
                      routeColor: colors.onSurface,
                      routePoints: points,
                    ),
                  ),
                ),
                for (final entry in pins.indexed)
                  Positioned(
                    left: points[entry.$1].dx - 24,
                    top: points[entry.$1].dy - 24,
                    child: Tooltip(
                      message: entry.$2.placeName,
                      child: SizedBox.square(
                        dimension: 48,
                        child: InkWell(
                          onTap: () => onSelect(entry.$2.itineraryItemId),
                          child: Center(
                            child: Container(
                              key: ValueKey(
                                'map-pin-${entry.$2.itineraryItemId}',
                              ),
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.onSurface,
                                  width: AppTheme.frameStroke,
                                ),
                              ),
                              child: Text(
                                entry.$2.number.toString().padLeft(2, '0'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: SizedBox.square(
                    dimension: AppTheme.minimumTouchTarget,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.onSurface),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: expanded ? '지도 접기' : '지도 확대',
                        onPressed: onToggle,
                        icon: Icon(
                          expanded
                              ? Icons.close_fullscreen
                              : Icons.open_in_full,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 16,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.94),
                      border: Border.all(color: colors.onSurface),
                    ),
                    child: Text(
                      _mapStatusText(model),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _mapStatusText(MapRenderModel model) => switch (model.emptyState) {
  MapEmptyState.noItinerary => '일정을 추가하면 지도에 표시됩니다.',
  MapEmptyState.noMappableItems => '좌표가 있는 일정 장소가 없습니다.',
  MapEmptyState.none =>
    'Google 지도 연동 예정 · 동선 ${model.segments.length}구간'
        '${model.missingLocations.isEmpty ? '' : ' · 지도 제외 ${model.missingLocations.length}건'}',
};

String _dateBadgeLabel(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}.${date.day.toString().padLeft(2, '0')} '
      '${weekdays[date.weekday - 1]}';
}

String _dateLongLabel(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

Offset _mapPoint(int index, Size size) {
  const positions = [
    (0.20, 0.22),
    (0.40, 0.58),
    (0.62, 0.48),
    (0.80, 0.76),
    (0.72, 0.24),
    (0.28, 0.80),
    (0.50, 0.32),
    (0.88, 0.48),
  ];
  final point = positions[index % positions.length];
  return Offset(size.width * point.$1, size.height * point.$2);
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({
    required this.roadColor,
    required this.routeColor,
    required this.routePoints,
  });

  final Color roadColor;
  final Color routeColor;
  final List<Offset> routePoints;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFE8E9E5), BlendMode.src);
    final road = Paint()
      ..color = roadColor.withValues(alpha: 0.58)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), road);
    }
    for (var y = 22.0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 34), road);
    }
    final arterial = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.48),
        width: size.width * 0.54,
        height: size.height * 0.68,
      ),
      arterial,
    );

    final route = Paint()
      ..color = routeColor
      ..strokeWidth = 2;
    for (var index = 1; index < routePoints.length; index++) {
      final start = routePoints[index - 1];
      final end = routePoints[index];
      final delta = end - start;
      final distance = delta.distance;
      if (distance == 0) continue;
      final direction = delta / distance;
      for (var offset = 0.0; offset < distance; offset += 10) {
        canvas.drawLine(
          start + direction * offset,
          start + direction * (offset + 5).clamp(0, distance),
          route,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.roadColor != roadColor ||
      oldDelegate.routeColor != routeColor ||
      oldDelegate.routePoints != routePoints;
}
