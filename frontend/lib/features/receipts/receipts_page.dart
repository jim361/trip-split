import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';

// [TASK-07 · 영수증 OCR] 외부 호출 전 검토 흐름만 보여 주는 mock 경계입니다.
class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({
    super.key,
    required this.trip,
    required this.onBackToSettlement,
  });

  final Trip trip;
  final VoidCallback onBackToSettlement;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('영수증 검토', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${trip.title} · ${trip.defaultCurrency}'),
        const SizedBox(height: 24),
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '일본어 영수증을 정산 자료로',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('촬영한 원문과 번역 결과를 사용자가 확인한 뒤 지출에 반영하는 흐름입니다.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(child: Text('1')),
                title: Text('영수증 촬영'),
                subtitle: Text('카메라와 갤러리 연결 예정'),
              ),
              Divider(height: 1),
              ListTile(
                leading: CircleAvatar(child: Text('2')),
                title: Text('OCR 및 번역 검토'),
                subtitle: Text('원문·번역·금액을 나란히 확인할 자리'),
              ),
              Divider(height: 1),
              ListTile(
                leading: CircleAvatar(child: Text('3')),
                title: Text('정산에 반영'),
                subtitle: Text('사용자가 확정한 값만 저장'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('영수증 추가 · 준비 중'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onBackToSettlement,
          icon: const Icon(Icons.arrow_back),
          label: const Text('정산으로 돌아가기'),
        ),
      ],
    );
  }
}
