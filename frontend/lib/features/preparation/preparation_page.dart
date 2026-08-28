import 'package:flutter/material.dart';
import 'package:trip_split/domain/models.dart';

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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('여행 준비', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${trip.title} · 일정 ${itinerary.length}개'),
        const SizedBox(height: 24),
        Text('예약', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.flight_outlined),
                title: Text('항공권'),
                subtitle: Text('예약 번호와 출발 시간을 등록할 자리'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.hotel_outlined),
                title: Text('숙소'),
                subtitle: Text('주소와 체크인 정보를 등록할 자리'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('체크리스트', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Card(
          child: Column(
            children: [
              _ChecklistTile(label: '여권 유효기간 확인'),
              Divider(height: 1),
              _ChecklistTile(label: 'eSIM 또는 로밍 준비'),
              Divider(height: 1),
              _ChecklistTile(label: '엔화와 결제 수단 준비'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.radio_button_unchecked),
      title: Text(label),
      subtitle: const Text('체크 기능은 후속 구현'),
    );
  }
}
