import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../shared/widgets/edit_frame.dart';

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({
    required this.tripId,
    required this.currentUid,
    required this.repositories,
    super.key,
  });
  final String tripId, currentUid;
  final TripRepositories repositories;
  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  late final Stream<List<Participant>> _participants;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _participants = widget.repositories.watchParticipants(widget.tripId);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Participant? participant]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ParticipantEditPage(
          tripId: widget.tripId,
          repositories: widget.repositories,
          participant: participant,
        ),
      ),
    );
  }

  Future<void> _link(Participant? participant) async {
    if (!await confirmAction(
          context,
          participant == null
              ? '내 계정 연결을 해제할까요?'
              : '${participant.name}님이 본인인가요?',
          '개인 소비와 정산 요약의 기준이 바뀝니다. 기존 지출은 유지됩니다.',
        ) ||
        !mounted) {
      return;
    }
    await _run(
      () =>
          widget.repositories.linkMyParticipant(widget.tripId, participant?.id),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('정산 참여자')),
    body: StreamBuilder<List<Participant>>(
      stream: _participants,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '로그인하지 않은 동행도 정산에 포함할 수 있습니다. 본인의 참여자에 계정을 연결하면 개인 소비를 확인할 수 있어요.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('participant-add'),
            onPressed: _busy ? null : () => _edit(),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('참여자 추가'),
          ),
          if (_busy || !snapshot.hasData && !snapshot.hasError)
            const LinearProgressIndicator(),
          if (_error != null || snapshot.hasError)
            Text(
              _error ?? actionError(snapshot.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          for (final p in snapshot.data ?? <Participant>[])
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: ValueKey('participant-${p.id}'),
                    onTap: _busy ? null : () => _edit(p),
                    leading: Icon(
                      p.linkedUid == widget.currentUid
                          ? Icons.person
                          : Icons.person_outline,
                    ),
                    title: Text('${p.name}${p.isActive ? '' : ' · 비활성'}'),
                    subtitle: Text(
                      p.linkedUid == widget.currentUid
                          ? '내 계정 연결됨'
                          : p.linkedUid == null
                          ? '계정 연결 없음'
                          : '다른 계정 연결됨',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                  ),
                  if (p.isActive && p.linkedUid == null)
                    TextButton(
                      onPressed: _busy ? null : () => _link(p),
                      child: const Text('내 계정 연결'),
                    ),
                  if (p.linkedUid == widget.currentUid)
                    TextButton(
                      onPressed: _busy ? null : () => _link(null),
                      child: const Text('내 계정 연결 해제'),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class ParticipantEditPage extends StatefulWidget {
  const ParticipantEditPage({
    required this.tripId,
    required this.repositories,
    this.participant,
    super.key,
  });
  final String tripId;
  final TripRepositories repositories;
  final Participant? participant;
  @override
  State<ParticipantEditPage> createState() => _ParticipantEditPageState();
}

class _ParticipantEditPageState extends State<ParticipantEditPage> {
  late final TextEditingController _name;
  late bool _active;
  late String? _color;
  bool _busy = false, _dirty = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.participant?.name ?? '');
    _active = widget.participant?.isActive ?? true;
    _color = widget.participant?.color;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!_active &&
        widget.participant?.isActive == true &&
        !await confirmAction(
          context,
          '참여자를 비활성화할까요?',
          '기존 지출은 유지되며 새 지출의 결제자·소비자 선택에서 제외됩니다.',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = ParticipantDraft(
        name: _name.text.trim(),
        color: _color,
        isActive: _active,
      )..validate();
      if (widget.participant == null) {
        await widget.repositories.createParticipant(widget.tripId, draft);
      } else {
        await widget.repositories.updateParticipant(
          widget.tripId,
          widget.participant!.id,
          draft,
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
    title: widget.participant == null ? '참여자 추가' : '참여자 편집',
    busy: _busy,
    dirty: _dirty,
    error: _error,
    onSave: _save,
    children: [
      TextField(
        key: const Key('participant-name'),
        controller: _name,
        enabled: !_busy,
        maxLength: 80,
        onChanged: (_) => setState(() => _dirty = true),
        decoration: const InputDecoration(labelText: '이름 · 필수'),
      ),
      const Text('표시 색상'),
      Wrap(
        spacing: 8,
        children: [
          for (final color in [
            '#1D4ED8',
            '#6F6A52',
            '#676762',
            '#BE185D',
            '#047857',
          ])
            ChoiceChip(
              label: Icon(
                Icons.circle,
                color: Color(
                  int.parse(color.substring(1), radix: 16) + 0xff000000,
                ),
              ),
              selected: _color == color,
              onSelected: _busy
                  ? null
                  : (_) => setState(() {
                      _color = color;
                      _dirty = true;
                    }),
            ),
        ],
      ),
      if (widget.participant != null)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('정산 참여 중'),
          subtitle: const Text('끄면 새 지출 선택에서 제외됩니다.'),
          value: _active,
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _active = value;
                  _dirty = true;
                }),
        ),
    ],
  );
}
