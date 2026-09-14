import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../shared/theme/app_theme.dart';
import 'itinerary_plan_controls.dart';

const _headerHeight = 40.0;
const _overviewBodyHeight = 216.0;
const _timeAxisWidth = 64.0;
const _minimumVisibleHours = 6;

/// 날짜 열과 시간 축을 함께 보여주는 여행 일정표입니다.
final class TripTimetable extends StatefulWidget {
  const TripTimetable({required this.trip, required this.itinerary, super.key});

  final Trip trip;
  final List<ItineraryItem> itinerary;

  @override
  State<TripTimetable> createState() => _TripTimetableState();
}

final class _TripTimetableState extends State<TripTimetable> {
  String _selectedPlan = 'A';

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary
        .where((item) => item.planId == _selectedPlan)
        .toList();
    final dates = tripDatesFor(widget.trip, itinerary);
    if (dates.isEmpty) {
      return const _EmptyTimetable();
    }

    final scheduled = <ItineraryItem>[];
    final other = <ItineraryItem>[];
    for (final item in itinerary) {
      final minutes = _minutes(item.startTime);
      if (dates.contains(item.date) && minutes != null) {
        scheduled.add(item);
      } else {
        other.add(item);
      }
    }
    scheduled.sort(_compareItinerary);
    other.sort(_compareItinerary);
    final selectedDate = scheduled.isEmpty ? dates.first : scheduled.first.date;
    final (firstHour, lastHour) = _visibleHours(scheduled);
    final hourHeight = _overviewBodyHeight / (lastHour - firstHour);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 390.0;
        final dayWidth = ((availableWidth - _timeAxisWidth) / dates.length)
            .clamp(120.0, 124.0)
            .toDouble();
        final gridWidth = _timeAxisWidth + dayWidth * dates.length;
        const gridHeight = _headerHeight + _overviewBodyHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ItineraryPlanSelector(
              selected: _selectedPlan,
              onSelected: (plan) => setState(() => _selectedPlan = plan),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              key: const Key('trip-timetable-scroll'),
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                key: const Key('trip-timetable-grid'),
                width: gridWidth,
                height: gridHeight,
                child: _TimetableGrid(
                  dates: dates,
                  selectedDate: selectedDate,
                  itinerary: scheduled,
                  dayWidth: dayWidth,
                  firstHour: firstHour,
                  lastHour: lastHour,
                  hourHeight: hourHeight,
                ),
              ),
            ),
            if (other.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('시간 미정', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in other)
                Container(
                  key: ValueKey('timetable-unscheduled-${item.id}'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: itineraryCategoryStyle(item.category).$2,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Text(
                    '${item.date}  ${itineraryCategoryStyle(item.category).$1} · ${item.title}',
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

final class _TimetableGrid extends StatelessWidget {
  const _TimetableGrid({
    required this.dates,
    required this.selectedDate,
    required this.itinerary,
    required this.dayWidth,
    required this.firstHour,
    required this.lastHour,
    required this.hourHeight,
  });

  final List<String> dates;
  final String selectedDate;
  final List<ItineraryItem> itinerary;
  final double dayWidth;
  final int firstHour;
  final int lastHour;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = _timeAxisWidth + dayWidth * dates.length;
    const height = _headerHeight + _overviewBodyHeight;
    final labelStep = hourHeight < 20 ? 2 : 1;

    return Semantics(
      label: '여행 날짜별 시간표',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: _timeAxisWidth,
              height: _headerHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    right: BorderSide(color: colors.outlineVariant),
                    bottom: BorderSide(
                      color: colors.onSurface,
                      width: AppTheme.sectionStroke,
                    ),
                  ),
                ),
              ),
            ),
            for (final entry in dates.indexed)
              Positioned(
                left: _timeAxisWidth + entry.$1 * dayWidth,
                top: 0,
                width: dayWidth,
                height: _headerHeight,
                child: Container(
                  key: ValueKey('timetable-day-${entry.$2}'),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.$2 == selectedDate
                        ? AppTheme.primaryPressed
                        : colors.surface,
                    border: Border(
                      left: BorderSide(
                        color: entry.$2 == selectedDate
                            ? colors.primary
                            : colors.outlineVariant,
                        width: entry.$2 == selectedDate
                            ? AppTheme.frameStroke
                            : AppTheme.rowStroke,
                      ),
                      right: entry.$2 == selectedDate
                          ? BorderSide(
                              color: colors.primary,
                              width: AppTheme.frameStroke,
                            )
                          : BorderSide.none,
                      bottom: BorderSide(
                        color: colors.onSurface,
                        width: AppTheme.sectionStroke,
                      ),
                    ),
                  ),
                  child: Text(
                    _dateLabel(entry.$2),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: entry.$2 == selectedDate
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: _timeAxisWidth + dates.indexOf(selectedDate) * dayWidth,
              top: _headerHeight,
              width: dayWidth,
              height: _overviewBodyHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.06),
                  border: Border(
                    left: BorderSide(
                      color: colors.primary,
                      width: AppTheme.frameStroke,
                    ),
                    right: BorderSide(
                      color: colors.primary,
                      width: AppTheme.frameStroke,
                    ),
                  ),
                ),
              ),
            ),
            for (var hour = firstHour; hour < lastHour; hour++) ...[
              Positioned(
                left: 0,
                top: _headerHeight + (hour - firstHour) * hourHeight,
                width: width,
                height: 1,
                child: ColoredBox(color: colors.outlineVariant),
              ),
              if ((hour - firstHour) % labelStep == 0)
                Positioned(
                  left: 0,
                  top: _headerHeight + (hour - firstHour) * hourHeight + 2,
                  width: _timeAxisWidth - 5,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
            ],
            Positioned(
              left: 0,
              top: height - 1,
              width: width,
              height: 1,
              child: ColoredBox(color: colors.outlineVariant),
            ),
            for (final entry in dates.indexed)
              Positioned(
                left: _timeAxisWidth + entry.$1 * dayWidth,
                top: _headerHeight,
                width: 1,
                height: height - _headerHeight,
                child: ColoredBox(color: colors.outlineVariant),
              ),
            for (final item in itinerary)
              _TimetableBlock(
                item: item,
                dateIndex: dates.indexOf(item.date),
                dayWidth: dayWidth,
                firstHour: firstHour,
                lastHour: lastHour,
                hourHeight: hourHeight,
              ),
          ],
        ),
      ),
    );
  }
}

final class _TimetableBlock extends StatelessWidget {
  const _TimetableBlock({
    required this.item,
    required this.dateIndex,
    required this.dayWidth,
    required this.firstHour,
    required this.lastHour,
    required this.hourHeight,
  });

  final ItineraryItem item;
  final int dateIndex;
  final double dayWidth;
  final int firstHour;
  final int lastHour;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final start = _minutes(item.startTime)!;
    final parsedEnd = _minutes(item.endTime);
    final end = parsedEnd != null && parsedEnd > start ? parsedEnd : start + 60;
    final visibleEnd = end.clamp(start + 1, lastHour * 60);
    final height = (((visibleEnd - start) / 60) * hourHeight - 2)
        .clamp(40.0, double.infinity)
        .toDouble();
    final top =
        _headerHeight + ((start - firstHour * 60) / 60) * hourHeight + 1;
    final colors = Theme.of(context).colorScheme;
    final (categoryLabel, categoryColor) = itineraryCategoryStyle(
      item.category,
    );
    return Positioned(
      left: _timeAxisWidth + dateIndex * dayWidth + 4,
      top: top,
      width: dayWidth - 8,
      height: height,
      child: Semantics(
        label:
            '$categoryLabel ${item.startTime}${item.endTime == null ? '' : '부터 ${item.endTime}까지'} ${item.title}',
        child: Container(
          key: ValueKey('timetable-item-${item.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: categoryColor,
            border: Border.all(color: colors.onSurface),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$categoryLabel · ${item.startTime}',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant, fontSize: 9),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyTimetable extends StatelessWidget {
  const _EmptyTimetable();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface,
        width: AppTheme.frameStroke,
      ),
    ),
    child: const Text('아직 등록된 일정이 없습니다.'),
  );
}

List<String> tripDatesFor(Trip trip, List<ItineraryItem> itinerary) {
  final start = DateTime.tryParse(trip.startDate);
  final end = DateTime.tryParse(trip.endDate);
  if (start != null && end != null && !end.isBefore(start)) {
    final result = <String>[];
    for (
      var date = start;
      !date.isAfter(end) && result.length < 31;
      date = date.add(const Duration(days: 1))
    ) {
      result.add(_isoDate(date));
    }
    return result;
  }

  return itinerary.map((item) => item.date).toSet().toList()..sort();
}

(int, int) _visibleHours(List<ItineraryItem> itinerary) {
  if (itinerary.isEmpty) return (8, 20);

  var firstMinute = 24 * 60;
  var lastMinute = 0;
  for (final item in itinerary) {
    final start = _minutes(item.startTime)!;
    final parsedEnd = _minutes(item.endTime);
    final end = parsedEnd != null && parsedEnd > start ? parsedEnd : start + 60;
    if (start < firstMinute) firstMinute = start;
    if (end > lastMinute) lastMinute = end;
  }

  var firstHour = (firstMinute ~/ 60).clamp(0, 23).toInt();
  var lastHour = ((lastMinute + 59) ~/ 60).clamp(firstHour + 1, 24).toInt();
  if (lastHour < 24) lastHour++;
  while (lastHour - firstHour < _minimumVisibleHours) {
    if (lastHour < 24) {
      lastHour++;
    } else if (firstHour > 0) {
      firstHour--;
    } else {
      break;
    }
  }
  return (firstHour, lastHour);
}

int? _minutes(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

int _compareItinerary(ItineraryItem left, ItineraryItem right) {
  final byDate = left.date.compareTo(right.date);
  if (byDate != 0) return byDate;
  final byOrder = left.order.compareTo(right.order);
  return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
}

String _dateLabel(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}.${date.day.toString().padLeft(2, '0')} ${weekdays[date.weekday - 1]}';
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
