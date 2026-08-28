import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';

// [TASK-04 / TASK-05 · 일정·지도] 날짜별 일정과 지도 mock의 화면 경계입니다.
class ItineraryPage extends StatelessWidget {
  const ItineraryPage({
    super.key,
    required this.trip,
    required this.places,
    required this.itinerary,
    required this.mapExpanded,
    required this.onToggleMap,
  });

  final Trip trip;
  final List<Place> places;
  final List<ItineraryItem> itinerary;
  final bool mapExpanded;
  final VoidCallback onToggleMap;

  @override
  Widget build(BuildContext context) {
    final placeById = {for (final place in places) place.id: place};
    final dates = itinerary.map((item) => item.date).toSet().toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(trip.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${trip.startDate} — ${trip.endDate}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _MockMap(places: places, expanded: mapExpanded, onToggle: onToggleMap),
        const SizedBox(height: 24),
        Text('일정', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (dates.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('아직 등록된 일정이 없습니다.'),
            ),
          )
        else
          for (final date in dates) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(date, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final item
                in itinerary.where((item) => item.date == date).toList()
                  ..sort((a, b) => a.order.compareTo(b.order)))
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(item.startTime?.split(':').first ?? '·'),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    [
                      item.startTime,
                      placeById[item.placeId]?.name,
                      item.memo,
                    ].whereType<String>().join(' · '),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class _MockMap extends StatelessWidget {
  const _MockMap({
    required this.places,
    required this.expanded,
    required this.onToggle,
  });

  final List<Place> places;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: '도쿄 일정 위치를 표시할 Google 지도 자리',
      container: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: expanded ? 420 : 176,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapGridPainter(colors.outlineVariant),
              ),
            ),
            for (final entry in places.take(4).indexed)
              Positioned(
                left: 28 + (entry.$1 % 2) * 128,
                top: 34 + (entry.$1 ~/ 2) * (expanded ? 140 : 58),
                child: Tooltip(
                  message: entry.$2.name,
                  child: Icon(
                    Icons.location_on,
                    color: colors.primary,
                    size: 34,
                  ),
                ),
              ),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Google 지도 연동 예정'),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: FilledButton.tonalIcon(
                onPressed: onToggle,
                icon: Icon(
                  expanded ? Icons.close_fullscreen : Icons.open_in_full,
                ),
                label: Text(expanded ? '지도 접기' : '지도 확대'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var x = 24.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x + 48, size.height), paint);
    }
    for (var y = 28.0; y < size.height; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 24), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
