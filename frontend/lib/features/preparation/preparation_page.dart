import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

// [TASK-04 · 여행 준비] 예약 정보와 출발 전 체크리스트의 mock 경계입니다.
class PreparationPage extends StatelessWidget {
  const PreparationPage({
    super.key,
    required this.trip,
    required this.itinerary,
  });

  final Trip trip;
  final List<ItineraryItem> itinerary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 96),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '02 / PREPARATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle,
              ),
            ),
            const SizedBox(width: 8),
            Text('여행 준비', style: textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '출발 전 준비',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const Text(
              '08',
              style: TextStyle(
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('5개 완료 · 3개 남음', style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.line,
            border: Border.all(color: AppTheme.ink),
          ),
          alignment: Alignment.centerLeft,
          child: const FractionallySizedBox(
            widthFactor: 0.625,
            heightFactor: 1,
            alignment: Alignment.centerLeft,
            child: ColoredBox(color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 48),
        const _PreparationPanel(
          title: '예약',
          rows: [
            _StatusRow('항공권 · 예약 완료', status: 'DONE'),
            _StatusRow('숙소 · 예약 완료', status: 'DONE'),
            _StatusRow('교통 패스 · 확인 필요', status: 'CHECK'),
          ],
        ),
        const SizedBox(height: 48),
        const _PreparationPanel(
          title: '체크리스트',
          rows: [
            _StatusRow('여권 유효기간 확인', status: 'DONE'),
            _StatusRow('eSIM 준비', status: 'TODO'),
            _StatusRow('엔화 준비', status: 'TODO'),
            _StatusRow('여행자 보험 확인', status: 'DONE'),
          ],
        ),
        const SizedBox(height: 48),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('준비 항목 추가'),
        ),
      ],
    );
  }
}

class _PreparationPanel extends StatelessWidget {
  const _PreparationPanel({required this.title, required this.rows});

  final String title;
  final List<_StatusRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.ink, width: AppTheme.sectionStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.ink,
                  width: AppTheme.sectionStroke,
                ),
              ),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index != rows.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label, {required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          _StatusBadge(status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final done = status == 'DONE';
    final todo = status == 'TODO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.ink
            : todo
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.white,
        border: Border.all(color: todo ? AppTheme.line : AppTheme.ink),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ).copyWith(color: done ? Colors.white : AppTheme.ink),
      ),
    );
  }
}

const _labelStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  height: 1,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
  fontFeatures: [FontFeature.tabularFigures()],
);
