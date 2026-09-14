import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/preparation.dart';
import '../../domain/repositories.dart';
import '../../shared/widgets/edit_frame.dart';

class PreparationPage extends StatefulWidget {
  const PreparationPage({
    required this.trip,
    required this.itinerary,
    required this.repositories,
    required this.participants,
    super.key,
  });
  final Trip trip;
  final List<ItineraryItem> itinerary;
  final TripRepositories repositories;
  final List<Participant> participants;
  @override
  State<PreparationPage> createState() => _PreparationPageState();
}

class _PreparationPageState extends State<PreparationPage> {
  late Stream<List<Reservation>> _reservations;
  late Stream<List<ChecklistItem>> _checklist;
  final _pending = <String>{};
  String? _error;
  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _reservations = widget.repositories.watchReservations(widget.trip.id);
    _checklist = widget.repositories.watchChecklist(widget.trip.id);
  }

  Future<void> _edit(
    bool reservation, {
    Reservation? booking,
    ChecklistItem? item,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PreparationEditPage(
          tripId: widget.trip.id,
          repositories: widget.repositories,
          reservation: reservation,
          booking: booking,
          item: item,
          participants: widget.participants,
          itinerary: widget.itinerary,
        ),
      ),
    );
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_pending.contains(key)) return;
    setState(() {
      _pending.add(key);
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  Future<void> _delete(String id, bool reservation, String title) async {
    if (!await confirmAction(context, '준비 항목을 삭제할까요?', title, action: '삭제') ||
        !mounted) {
      return;
    }
    await _run(
      id,
      () => reservation
          ? widget.repositories.deleteReservation(widget.trip.id, id)
          : widget.repositories.deleteChecklist(widget.trip.id, id),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Reservation>>(
    stream: _reservations,
    builder: (context, reservations) => StreamBuilder<List<ChecklistItem>>(
      stream: _checklist,
      builder: (context, checklist) {
        final bookings = reservations.data ?? [];
        final items = checklist.data ?? [];
        final total = bookings.length + items.length;
        final completed =
            bookings.where((r) => r.draft.status == 'booked').length +
            items.where((i) => i.draft.isDone).length;
        final loadError = reservations.error ?? checklist.error;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
          children: [
            Text(
              '02 / PREPARATION',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text('출발 전 준비', style: Theme.of(context).textTheme.headlineLarge),
            const Text('여행 준비'),
            const SizedBox(height: 12),
            Text('$completed개 완료 · ${total - completed}개 남음'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: total == 0 ? 0 : completed / total),
            if (loadError != null) ...[
              Text(actionError(loadError)),
              TextButton(
                onPressed: () => setState(_subscribe),
                child: const Text('다시 불러오기'),
              ),
            ] else if (!reservations.hasData || !checklist.hasData)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '예약',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  key: const Key('reservation-add'),
                  onPressed: () => _edit(true),
                  icon: const Icon(Icons.add),
                  label: const Text('예약 추가'),
                ),
              ],
            ),
            if (bookings.isEmpty && reservations.hasData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('항공·숙소·교통·티켓 예약을 모아 보세요.'),
              ),
            for (final booking in bookings)
              Card(
                child: ListTile(
                  key: ValueKey('reservation-${booking.id}'),
                  title: Text(booking.draft.title),
                  subtitle: Text(
                    '${reservationTypes[booking.draft.type]} · ${reservationStatuses[booking.draft.status]}',
                  ),
                  onTap: _pending.contains(booking.id)
                      ? null
                      : () => _edit(true, booking: booking),
                  trailing: IconButton(
                    tooltip: '${booking.draft.title} 삭제',
                    onPressed: _pending.contains(booking.id)
                        ? null
                        : () => _delete(booking.id, true, booking.draft.title),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '체크리스트',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  key: const Key('checklist-add'),
                  onPressed: () => _edit(false),
                  icon: const Icon(Icons.add),
                  label: const Text('항목 추가'),
                ),
              ],
            ),
            if (items.isEmpty && checklist.hasData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('준비물과 할 일을 추가해 보세요.'),
              ),
            for (final item in items)
              Card(
                child: ListTile(
                  key: ValueKey('checklist-${item.id}'),
                  leading: Checkbox(
                    value: item.draft.isDone,
                    onChanged: _pending.contains(item.id)
                        ? null
                        : (value) => _run(
                            item.id,
                            () => widget.repositories.setChecklistCompleted(
                              widget.trip.id,
                              item.id,
                              value!,
                            ),
                          ),
                  ),
                  title: Text(item.draft.title),
                  subtitle: Text(
                    '${item.draft.scope == 'shared' ? '공동' : '개인'} · ${_assignee(item.draft.assigneeParticipantId)}',
                  ),
                  onTap: _pending.contains(item.id)
                      ? null
                      : () => _edit(false, item: item),
                  trailing: IconButton(
                    tooltip: '${item.draft.title} 삭제',
                    onPressed: _pending.contains(item.id)
                        ? null
                        : () => _delete(item.id, false, item.draft.title),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
  String _assignee(String? id) {
    if (id == null) return '담당자 없음';
    return widget.participants.where((p) => p.id == id).firstOrNull?.name ??
        '참여자 정보 없음';
  }
}

class PreparationEditPage extends StatefulWidget {
  const PreparationEditPage({
    required this.tripId,
    required this.repositories,
    required this.reservation,
    required this.participants,
    required this.itinerary,
    this.booking,
    this.item,
    super.key,
  });
  final String tripId;
  final TripRepositories repositories;
  final bool reservation;
  final Reservation? booking;
  final ChecklistItem? item;
  final List<Participant> participants;
  final List<ItineraryItem> itinerary;
  @override
  State<PreparationEditPage> createState() => _PreparationEditPageState();
}

class _PreparationEditPageState extends State<PreparationEditPage> {
  late final TextEditingController _title, _url, _memo;
  late String _type, _status, _scope;
  String? _assignee, _itineraryId;
  bool _busy = false, _dirty = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(
      text: widget.booking?.draft.title ?? widget.item?.draft.title ?? '',
    );
    _url = TextEditingController(text: widget.booking?.draft.url ?? '');
    _memo = TextEditingController(text: widget.booking?.draft.memo ?? '');
    _type = widget.booking?.draft.type ?? 'flight';
    _status = widget.booking?.draft.status ?? 'planned';
    _scope = widget.item?.draft.scope ?? 'shared';
    _assignee = widget.item?.draft.assigneeParticipantId;
    _itineraryId = widget.booking?.draft.itineraryItemId;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _changed() => setState(() {
    _dirty = true;
    _error = null;
  });
  Widget _select(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> change,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList(),
    onChanged: _busy
        ? null
        : (v) {
            change(v!);
            _changed();
          },
  );
  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.reservation) {
        await widget.repositories.saveReservation(
          widget.tripId,
          ReservationDraft(
            title: _title.text,
            type: _type,
            status: _status,
            url: _url.text,
            memo: _memo.text,
            itineraryItemId: _itineraryId,
          ),
          id: widget.booking?.id,
        );
      } else {
        await widget.repositories.saveChecklist(
          widget.tripId,
          ChecklistDraft(
            title: _title.text,
            scope: _scope,
            assigneeParticipantId: _assignee,
            isDone: widget.item?.draft.isDone ?? false,
          ),
          id: widget.item?.id,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => EditFrame(
    title: widget.reservation ? '예약 정보' : '체크리스트 항목',
    busy: _busy,
    dirty: _dirty,
    error: _error,
    onSave: _save,
    children: [
      TextField(
        key: const Key('preparation-title'),
        controller: _title,
        enabled: !_busy,
        onChanged: (_) => _changed(),
        decoration: const InputDecoration(labelText: '제목 · 필수'),
      ),
      if (widget.reservation) ...[
        FieldPair(
          _select('예약 유형', _type, reservationTypes, (v) => _type = v),
          _select('예약 상태', _status, reservationStatuses, (v) => _status = v),
        ),
        TextField(
          key: const Key('reservation-url'),
          controller: _url,
          enabled: !_busy,
          onChanged: (_) => _changed(),
          decoration: const InputDecoration(labelText: '예약 URL · 선택'),
        ),
        TextField(
          controller: _memo,
          enabled: !_busy,
          onChanged: (_) => _changed(),
          maxLines: 3,
          decoration: const InputDecoration(labelText: '메모 · 선택'),
        ),
        _select('연결 일정 · 선택', _itineraryId ?? '', {
          '': '연결 안 함',
          for (final item in widget.itinerary)
            item.id: '${item.date} ${item.title}',
          if (_itineraryId != null &&
              !widget.itinerary.any((i) => i.id == _itineraryId))
            _itineraryId!: '삭제된 일정 · 연결 해제 필요',
        }, (v) => _itineraryId = v.isEmpty ? null : v),
      ] else ...[
        FieldPair(
          _select('구분', _scope, const {
            'shared': '공동',
            'personal': '개인',
          }, (v) => _scope = v),
          _select('담당자 · 선택', _assignee ?? '', {
            '': '담당자 없음',
            for (final p in widget.participants)
              p.id: '${p.name}${p.isActive ? '' : ' (비활성)'}',
          }, (v) => _assignee = v.isEmpty ? null : v),
        ),
        const Text('개인 항목도 여행 멤버 모두에게 보입니다. 구분과 담당자별로 준비할 일을 나누는 용도입니다.'),
      ],
    ],
  );
}
