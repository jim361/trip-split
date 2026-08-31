import 'package:flutter/material.dart';

import '../../app/auth_session_gate.dart';
import '../../domain/models.dart';
import '../../services/trip_share_service.dart';
import '../../shared/theme/app_theme.dart';
import '../itinerary/trip_timetable.dart';

/// [TASK-02 · 여행 시작] 도쿄 기본값으로 여행 생성과 공유 코드 입장을 제공합니다.
final class TripHomePage extends StatefulWidget {
  const TripHomePage({
    required this.tripShareService,
    required this.dataSourceLabel,
    required this.joinFirst,
    required this.featuredTrip,
    required this.featuredItinerary,
    super.key,
  });

  final TripShareService tripShareService;
  final String dataSourceLabel;
  final bool joinFirst;
  final Trip? featuredTrip;
  final List<ItineraryItem> featuredItinerary;

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
        leadingWidth: 64,
        leading: const Icon(Icons.menu, size: 20, semanticLabel: '메뉴'),
        centerTitle: true,
        title: Text(
          'TRIP SPLIT / MY TRIPS',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              key: const Key('trip-account-action'),
              tooltip: auth.user.isAnonymous
                  ? 'Google 계정 연결'
                  : auth.user.displayName,
              onPressed: auth.user.isAnonymous && !_linking
                  ? () => _linkGoogle(auth)
                  : null,
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
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                child: _linking
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        auth.user.isAnonymous
                            ? Icons.person_outline
                            : Icons.person,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final selector = _TripSelector(
              trip: widget.featuredTrip,
              onOpen: widget.featuredTrip == null
                  ? null
                  : () => _openTrip(widget.featuredTrip!.id),
            );
            final workspace = _TripWorkspace(
              trip: widget.featuredTrip,
              itinerary: widget.featuredItinerary,
              onOpen: widget.featuredTrip == null
                  ? null
                  : () => _openTrip(widget.featuredTrip!.id),
            );

            if (constraints.maxWidth >= AppTheme.expandedBreakpoint) {
              final controls = _controlWidgets(
                context,
                auth,
                joinFirst: widget.joinFirst,
              );
              return Row(
                key: const Key('trip-home-expanded'),
                children: [
                  SizedBox(
                    width: 360,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          selector,
                          const SizedBox(height: 20),
                          ...controls,
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
                      children: [workspace],
                    ),
                  ),
                ],
              );
            }

            final controls = _controlWidgets(
              context,
              auth,
              includeJoin: !widget.joinFirst,
              includeError: !widget.joinFirst,
            );

            return ListView(
              key: const Key('trip-home-compact'),
              padding: EdgeInsets.zero,
              children: [
                selector,
                if (widget.joinFirst) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: _JoinTripCard(
                      shareCode: _shareCode,
                      busy: _busy,
                      onJoin: _joinTrip,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _errorWidgets(context),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: workspace,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: controls,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _controlWidgets(
    BuildContext context,
    AuthSessionScope auth, {
    bool includeJoin = true,
    bool includeError = true,
    bool joinFirst = false,
  }) {
    final account = _AccountPanel(
      displayName: auth.user.displayName,
      uid: auth.user.uid,
      anonymous: auth.user.isAnonymous,
      linking: _linking,
      onLink: () => _linkGoogle(auth),
    );
    final create = _CreateTripCard(
      formKey: _createFormKey,
      title: _title,
      startDate: _startDate,
      endDate: _endDate,
      participants: _participants,
      busy: _busy,
      onAddParticipant: _addParticipant,
      onRemoveParticipant: _removeParticipant,
      onCreate: _createTrip,
    );
    final join = _JoinTripCard(
      shareCode: _shareCode,
      busy: _busy,
      onJoin: _joinTrip,
    );
    return [
      account,
      const SizedBox(height: 16),
      if (includeJoin && joinFirst) ...[join, const SizedBox(height: 16)],
      create,
      if (includeJoin && !joinFirst) ...[const SizedBox(height: 16), join],
      if (includeError) ..._errorWidgets(context),
    ];
  }

  List<Widget> _errorWidgets(BuildContext context) => [
    if (_error case final error?) ...[
      const SizedBox(height: 12),
      Text(
        error.message,
        key: const Key('trip-action-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ],
  ];

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

final class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.displayName,
    required this.uid,
    required this.anonymous,
    required this.linking,
    required this.onLink,
  });

  final String displayName;
  final String uid;
  final bool anonymous;
  final bool linking;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.person_outline),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                'uid $uid',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (anonymous)
          TextButton(
            key: const Key('link-google'),
            onPressed: linking ? null : onLink,
            child: Text(linking ? '연결 중' : 'Google 연결'),
          )
        else
          const Icon(Icons.verified_outlined, semanticLabel: 'Google 연결됨'),
      ],
    ),
  );
}

final class _TripSelector extends StatelessWidget {
  const _TripSelector({required this.trip, required this.onOpen});

  final Trip? trip;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = trip;
    if (value == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface,
              width: AppTheme.sectionStroke,
            ),
          ),
        ),
        child: const Text('여행을 만들거나 공유 코드로 참여해 주세요.'),
      );
    }

    return InkWell(
      key: ValueKey('trip-tile-${value.id}'),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface,
              width: AppTheme.sectionStroke,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tripPeriod(value),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                border: Border.all(color: theme.colorScheme.onSurface),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '동기화됨',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TripWorkspace extends StatelessWidget {
  const _TripWorkspace({
    required this.trip,
    required this.itinerary,
    required this.onOpen,
  });

  final Trip? trip;
  final List<ItineraryItem> itinerary;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final value = trip;
    if (value == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Text('선택된 여행이 없습니다.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '전체 일정표',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${_tripDayCount(value).toString().padLeft(2, '0')} DAYS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TripTimetable(trip: value, itinerary: itinerary),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('featured-trip-open'),
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('여행 열기'),
        ),
      ],
    );
  }
}

final class _JoinTripCard extends StatelessWidget {
  const _JoinTripCard({
    required this.shareCode,
    required this.busy,
    required this.onJoin,
  });

  final TextEditingController shareCode;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('공유 코드로 참여', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            key: const Key('share-code'),
            controller: shareCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '공유 코드',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('join-trip'),
            onPressed: busy ? null : onJoin,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('여행 참여'),
          ),
        ],
      ),
    ),
  );
}

int _tripDayCount(Trip trip) {
  final start = DateTime.tryParse(trip.startDate);
  final end = DateTime.tryParse(trip.endDate);
  if (start == null || end == null || end.isBefore(start)) return 0;
  return end.difference(start).inDays + 1;
}

String _tripPeriod(Trip trip) =>
    '${_monthDay(trip.startDate)} — ${_monthDay(trip.endDate)}';

String _monthDay(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
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
