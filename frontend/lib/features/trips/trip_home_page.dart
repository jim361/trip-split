import 'package:flutter/material.dart';

import '../../app/auth_session_gate.dart';
import '../../domain/models.dart';
import '../../services/trip_share_service.dart';

/// [TASK-02 · 여행 시작] 도쿄 기본값으로 여행 생성과 공유 코드 입장을 제공합니다.
final class TripHomePage extends StatefulWidget {
  const TripHomePage({
    required this.tripShareService,
    required this.dataSourceLabel,
    super.key,
  });

  final TripShareService tripShareService;
  final String dataSourceLabel;

  @override
  State<TripHomePage> createState() => _TripHomePageState();
}

final class _TripHomePageState extends State<TripHomePage> {
  final _createFormKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: '2026년 11월 도쿄 여행');
  final _startDate = TextEditingController(text: '2026-11-25');
  final _endDate = TextEditingController(text: '2026-12-01');
  final _shareCode = TextEditingController();
  final List<TextEditingController> _participants = [
    TextEditingController(text: '나'),
    TextEditingController(text: '동행 2'),
    TextEditingController(text: '동행 3'),
  ];
  bool _busy = false;
  bool _linking = false;
  AppError? _error;

  @override
  void dispose() {
    _title.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _shareCode.dispose();
    for (final controller in _participants) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthSessionScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Split'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Chip(label: Text(widget.dataSourceLabel))),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '여행을 한곳에서 준비해요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('일정·지도, 준비, 비용을 같은 여행 세션에서 관리합니다.'),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(auth.user.displayName),
                subtitle: Text('uid ${auth.user.uid}'),
                trailing: auth.user.isAnonymous
                    ? TextButton(
                        key: const Key('link-google'),
                        onPressed: _linking ? null : () => _linkGoogle(auth),
                        child: Text(_linking ? '연결 중' : 'Google 연결'),
                      )
                    : const Chip(label: Text('Google 연결됨')),
              ),
            ),
            const SizedBox(height: 12),
            _CreateTripCard(
              formKey: _createFormKey,
              title: _title,
              startDate: _startDate,
              endDate: _endDate,
              participants: _participants,
              busy: _busy,
              onAddParticipant: _addParticipant,
              onRemoveParticipant: _removeParticipant,
              onCreate: _createTrip,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '공유 코드로 참여',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('share-code'),
                      controller: _shareCode,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: '공유 코드',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('join-trip'),
                      onPressed: _busy ? null : _joinTrip,
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('여행 참여'),
                    ),
                  ],
                ),
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error.message,
                key: const Key('trip-action-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createTrip() async {
    if (!_createFormKey.currentState!.validate()) return;
    await _run(() async {
      final result = await widget.tripShareService.createTrip(
        CreateTripCommand(
          title: _title.text.trim(),
          countryCode: 'JP',
          timeZone: 'Asia/Tokyo',
          mapProvider: 'google',
          defaultCurrency: 'JPY',
          startDate: _startDate.text.trim(),
          endDate: _endDate.text.trim(),
          participantNames: _participants
              .map((value) => value.text.trim())
              .toList(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공유 코드 ${result.shareCode}가 생성됐습니다.')),
      );
      _openTrip(result.tripId);
    });
  }

  Future<void> _joinTrip() => _run(() async {
    final result = await widget.tripShareService.joinTrip(_shareCode.text);
    if (mounted) _openTrip(result.tripId);
  });

  Future<void> _linkGoogle(AuthSessionScope auth) async {
    setState(() => _linking = true);
    try {
      await auth.linkGoogleAccount();
    } catch (error) {
      _setError(error);
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      _setError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = error is AppError
          ? error
          : const AppError(
              code: AppErrorCode.unknown,
              message: '요청을 처리하지 못했습니다.',
              retryable: false,
            );
    });
  }

  void _openTrip(String tripId) {
    Navigator.of(context).pushReplacementNamed('/trips/$tripId/itinerary');
  }

  void _addParticipant() {
    if (_participants.length >= 20) return;
    setState(() {
      _participants.add(
        TextEditingController(text: '동행 ${_participants.length + 1}'),
      );
    });
  }

  void _removeParticipant(int index) {
    if (_participants.length == 1) return;
    setState(() => _participants.removeAt(index).dispose());
  }
}

final class _CreateTripCard extends StatelessWidget {
  const _CreateTripCard({
    required this.formKey,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.busy,
    required this.onAddParticipant,
    required this.onRemoveParticipant,
    required this.onCreate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController startDate;
  final TextEditingController endDate;
  final List<TextEditingController> participants;
  final bool busy;
  final VoidCallback onAddParticipant;
  final ValueChanged<int> onRemoveParticipant;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('새 해외여행', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('일본 · Asia/Tokyo · JPY · Google Maps'),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('trip-title'),
              controller: title,
              decoration: const InputDecoration(
                labelText: '여행 이름',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('start-date'),
                    controller: startDate,
                    decoration: const InputDecoration(
                      labelText: '시작일',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('end-date'),
                    controller: endDate,
                    decoration: const InputDecoration(
                      labelText: '종료일',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '정산 인원 ${participants.length}명',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('add-participant'),
                  onPressed: onAddParticipant,
                  tooltip: '인원 추가',
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                ),
              ],
            ),
            for (var index = 0; index < participants.length; index++) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: Key('participant-$index'),
                      controller: participants[index],
                      decoration: InputDecoration(
                        labelText: '인원 ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      validator: _required,
                    ),
                  ),
                  IconButton(
                    onPressed: participants.length == 1
                        ? null
                        : () => onRemoveParticipant(index),
                    tooltip: '인원 삭제',
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('create-trip'),
              onPressed: busy ? null : onCreate,
              icon: const Icon(Icons.flight_takeoff),
              label: Text(busy ? '처리 중' : '여행 만들기'),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? '필수 입력입니다.' : null;
