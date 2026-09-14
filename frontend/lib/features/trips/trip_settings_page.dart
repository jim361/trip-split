import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../platform/android_actions.dart';
import '../../services/trip_share_service.dart';
import '../../shared/widgets/edit_frame.dart';

class TripSettingsPage extends StatefulWidget {
  const TripSettingsPage({
    required this.trip,
    required this.repositories,
    required this.shareService,
    super.key,
  });
  final Trip trip;
  final TripRepositories repositories;
  final TripShareService shareService;
  @override
  State<TripSettingsPage> createState() => _TripSettingsPageState();
}

class _TripSettingsPageState extends State<TripSettingsPage> {
  late final TextEditingController _title, _start, _end;
  late final Stream<Trip?> _trip;
  bool _busy = false, _dirty = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.trip.title);
    _start = TextEditingController(text: widget.trip.startDate);
    _end = TextEditingController(text: widget.trip.endDate);
    _trip = widget.repositories.watchTrip(widget.trip.id);
  }

  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
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

  Widget _field(TextEditingController controller, String label, String key) =>
      TextField(
        key: ValueKey(key),
        controller: controller,
        enabled: !_busy,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() => _dirty = true),
      );
  @override
  Widget build(BuildContext context) => StreamBuilder<Trip?>(
    stream: _trip,
    initialData: widget.trip,
    builder: (context, snapshot) {
      final trip = snapshot.data;
      return EditFrame(
        title: '여행 설정·공유',
        busy: _busy,
        dirty: _dirty,
        error: _error,
        onSave: trip == null || snapshot.hasError
            ? null
            : () => _run(() async {
                await widget.repositories.updateTrip(
                  widget.trip.id,
                  TripUpdate(
                    title: _title.text,
                    startDate: _start.text.trim(),
                    endDate: _end.text.trim(),
                  ),
                );
                if (context.mounted) Navigator.pop(context);
              }),
        children: [
          if (snapshot.hasError || trip == null)
            const Text('여행 정보를 확인할 수 없습니다. 목록에서 다시 열어 주세요.'),
          _field(_title, '여행 이름', 'trip-settings-title'),
          FieldPair(
            _field(_start, '시작일 · YYYY-MM-DD', 'trip-settings-start'),
            _field(_end, '종료일 · YYYY-MM-DD', 'trip-settings-end'),
          ),
          const Text('기간 밖의 기존 일정도 유지되며 일정 목록에서 계속 확인할 수 있습니다.'),
          Text(
            '${widget.trip.countryCode} · ${widget.trip.defaultCurrency} · ${widget.trip.timeZone}',
          ),
          const Divider(),
          Text('공유 코드', style: Theme.of(context).textTheme.titleLarge),
          if (trip != null) ...[
            SelectableText(
              trip.shareCode,
              key: const Key('settings-share-code'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await Clipboard.setData(
                            ClipboardData(text: trip.shareCode),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('공유 코드를 복사했습니다.')),
                            );
                          }
                        }),
                  icon: const Icon(Icons.copy),
                  label: const Text('코드 복사'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => AndroidActions.shareText(
                            '${trip.title}\nTrip Split 공유 코드: ${trip.shareCode}',
                          ),
                        ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('공유하기'),
                ),
              ],
            ),
            TextButton(
              key: const Key('share-code-regenerate'),
              onPressed: _busy
                  ? null
                  : () async {
                      if (await confirmAction(
                            context,
                            '공유 코드를 바꿀까요?',
                            '기존 코드로는 새로 참여할 수 없습니다. 이미 참여한 멤버는 유지됩니다.',
                          ) &&
                          mounted) {
                        await _run(() async {
                          await widget.shareService.createShareCode(
                            widget.trip.id,
                          );
                        });
                      }
                    },
              child: const Text('공유 코드 재생성'),
            ),
          ],
        ],
      );
    },
  );
}
