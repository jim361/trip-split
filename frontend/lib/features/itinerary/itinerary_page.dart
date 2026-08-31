import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';

import '../../shared/theme/app_theme.dart';
import '../map/map_render_model.dart';
import 'itinerary_plan_controls.dart';
import 'trip_timetable.dart' show tripDatesFor;

// [TASK-04 / TASK-05 · 일정·지도] 날짜별 일정과 지도 mock의 화면 경계입니다.
class ItineraryPage extends StatefulWidget {
  const ItineraryPage({
    super.key,
    required this.trip,
    required this.places,
    required this.itinerary,
    required this.selectedDate,
    required this.mapExpanded,
    required this.onToggleMap,
  });

  final Trip trip;
  final List<Place> places;
  final List<ItineraryItem> itinerary;
  final String? selectedDate;
  final bool mapExpanded;
  final ValueChanged<String> onToggleMap;

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  String? _selectedDate;
  String _selectedPlan = 'A';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant ItineraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != null) {
      _selectedDate = widget.selectedDate;
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
    final selectedItinerary =
        widget.itinerary
            .where(
              (item) =>
                  item.planId == _selectedPlan && item.date == selectedDate,
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
          onToggle: () => widget.onToggleMap(selectedDate),
        );
        final schedule = _DaySchedule(
          date: selectedDate,
          itinerary: selectedItinerary,
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                    children: [
                      Text(
                        'DAY ${selectedDay.toString().padLeft(2, '0')} / ROUTE',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dateLongLabel(selectedDate),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      schedule,
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          key: const Key('itinerary-compact-layout'),
          padding: const EdgeInsets.only(bottom: 96),
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
            const _RoutePanelHeader(),
            schedule,
          ],
        );
      },
    );
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
  const _DaySchedule({required this.date, required this.itinerary});

  final String date;
  final List<ItineraryItem> itinerary;

  @override
  Widget build(BuildContext context) {
    if (itinerary.isEmpty) {
      return Container(
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
      );
    }

    return Column(
      children: [
        for (final entry in itinerary.indexed)
          _DayScheduleRow(
            item: entry.$2,
            number: entry.$1 + 1,
            showTopBorder: entry.$1 == 0,
          ),
      ],
    );
  }
}

class _DayScheduleRow extends StatelessWidget {
  const _DayScheduleRow({
    required this.item,
    required this.number,
    required this.showTopBorder,
  });

  final ItineraryItem item;
  final int number;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (categoryLabel, categoryColor) = itineraryCategoryStyle(
      item.category,
    );
    return Container(
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
        ],
      ),
    );
  }
}

class _RoutePanelHeader extends StatelessWidget {
  const _RoutePanelHeader();

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
        Text('오늘의 동선', style: Theme.of(context).textTheme.labelLarge),
        const _RouteAction(icon: Icons.bookmark_border, label: '장소 보관함'),
        const _RouteAction(
          icon: Icons.map_outlined,
          label: 'Google Maps로 열기',
          primary: true,
        ),
      ],
    ),
  );
}

class _RouteAction extends StatelessWidget {
  const _RouteAction({
    required this.icon,
    required this.label,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = primary ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      label: label,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: primary ? colors.primary : colors.surface,
          border: Border.all(
            color: primary ? colors.primary : colors.onSurface,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockMap extends StatelessWidget {
  const _MockMap({
    required this.tripTitle,
    required this.model,
    required this.expanded,
    required this.onToggle,
  });

  final String tripTitle;
  final MapRenderModel model;
  final bool expanded;
  final VoidCallback onToggle;

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
                    left: points[entry.$1].dx - 15,
                    top: points[entry.$1].dy - 15,
                    child: Tooltip(
                      message: entry.$2.placeName,
                      child: Container(
                        key: ValueKey('map-pin-${entry.$2.itineraryItemId}'),
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
