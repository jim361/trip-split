import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../shared/theme/app_theme.dart';

class ItineraryPlanSelector extends StatelessWidget {
  const ItineraryPlanSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SegmentedButton<String>(
      segments: [
        for (final plan in itineraryPlanIds)
          ButtonSegment(
            value: plan,
            label: Text('$plan안', key: ValueKey('itinerary-plan-$plan')),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onSelected(values.single),
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(88, AppTheme.minimumTouchTarget),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    ),
  );
}

(String, Color) itineraryCategoryStyle(String category) => switch (category) {
  'flight' => ('항공', const Color(0xFFAEC9DE)),
  'transport' => ('이동', const Color(0xFFF2DE9B)),
  'meal' => ('식사', const Color(0xFFC6B8DB)),
  'activity' => ('관광·활동', const Color(0xFFBFD2B0)),
  'stay' => ('숙박·휴식', const Color(0xFFECC49F)),
  _ => ('기타', const Color(0xFFE1E3DE)),
};
