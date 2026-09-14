import 'package:flutter/material.dart';

import '../../app/trip_session.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../shared/widgets/edit_frame.dart';
import 'place_provider.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    required this.trip,
    required this.repositories,
    required this.provider,
    required this.linkResolver,
    this.selectPlace = false,
    super.key,
  });
  final Trip trip;
  final TripRepositories repositories;
  final PlaceProvider provider;
  final PlaceLinkResolver linkResolver;
  final bool selectPlace;
  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  late final TripSessionController _session;
  final _query = TextEditingController();
  List<PlaceCandidate>? _results;
  String? _error;
  bool _busy = false;
  int _mode = 0;
  @override
  void initState() {
    super.initState();
    _session = TripSessionController(
      tripId: widget.trip.id,
      repositories: widget.repositories,
    )..start();
  }

  @override
  void dispose() {
    _session.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_busy) return;
    final text = _query.text.trim();
    if (text.isEmpty) {
      setState(() => _error = _mode == 0 ? '검색어를 입력해 주세요.' : '지도 링크를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
    });
    try {
      final results = _mode == 0
          ? await widget.provider.searchPlaces(
              tripId: widget.trip.id,
              query: PlaceSearchQuery(text: text),
            )
          : [
              await widget.linkResolver.resolvePlaceLink(
                tripId: widget.trip.id,
                url: Uri.parse(text),
              ),
            ];
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit({Place? place, PlaceCandidate? candidate}) async {
    if (_busy) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    final result = await Navigator.of(context).push<Place>(
      MaterialPageRoute(
        builder: (_) => PlaceEditPage(
          trip: widget.trip,
          repositories: widget.repositories,
          place: place,
          candidate: candidate,
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (widget.selectPlace) {
      Navigator.pop(context, result);
      return;
    }
    setState(() {
      _results = null;
      _query.clear();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('장소를 저장했습니다.')));
  }

  Future<void> _delete(Place place) async {
    if (_busy) return;
    final references = [
      ..._session.itinerary
          .where((i) => i.placeId == place.id)
          .map((i) => '일정: ${i.title}'),
      ..._session.expenses
          .where((e) => e.placeId == place.id)
          .map((e) => '지출: ${e.title}'),
    ];
    if (references.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('연결된 장소입니다'),
          content: Text('먼저 아래 항목에서 장소 연결을 해제해 주세요.\n${references.join('\n')}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    if (!await confirmAction(context, '장소를 삭제할까요?', place.name, action: '삭제') ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repositories.deletePlace(widget.trip.id, place.id);
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.selectPlace ? '연결할 장소 선택' : '장소 보관함')),
    body: AnimatedBuilder(
      animation: _session,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            widget.trip.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('장소 검색')),
              ButtonSegment(value: 1, label: Text('지도 링크')),
            ],
            selected: {_mode},
            onSelectionChanged: _busy
                ? null
                : (value) => setState(() {
                    _mode = value.first;
                    _results = null;
                    _error = null;
                    _query.clear();
                  }),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('place-query'),
            controller: _query,
            enabled: !_busy,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: _mode == 0 ? '장소 이름 또는 주소' : 'Google Maps 링크',
              suffixIcon: IconButton(
                tooltip: '검색 실행',
                onPressed: _busy ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('place-manual-add'),
            onPressed: _busy ? null : () => _edit(),
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('장소 직접 입력'),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_results != null) ...[
            const SizedBox(height: 24),
            Text(
              '검색 결과 ${_results!.length}개',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_results!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('검색 결과가 없습니다. 다른 검색어나 직접 입력을 사용해 주세요.'),
              ),
            for (final candidate in _results!)
              Card(
                child: ListTile(
                  title: Text(candidate.name),
                  subtitle: Text(candidate.address ?? '주소 정보 없음'),
                  trailing: const Icon(Icons.add_location_alt_outlined),
                  onTap: _busy ? null : () => _edit(candidate: candidate),
                ),
              ),
          ],
          const SizedBox(height: 24),
          Text(
            '저장한 장소 ${_session.places.length}개',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_session.isLoading) const LinearProgressIndicator(),
          if (_session.error != null) Text(_session.error!.message),
          if (!_session.isLoading &&
              _session.error == null &&
              _session.places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('아직 저장한 장소가 없습니다. 검색하거나 직접 입력해 보세요.'),
            ),
          for (final place in _session.places)
            Card(
              child: ListTile(
                key: ValueKey('place-${place.id}'),
                isThreeLine: true,
                title: Text(place.name),
                subtitle: Text(
                  '${place.address ?? '주소 없음'}\n${place.lat == null ? '좌표 없음 · 일정에는 연결 가능' : '지도 표시 가능'}${place.memo == null ? '' : '\n${place.memo}'}',
                ),
                onTap: _busy
                    ? null
                    : () => widget.selectPlace
                          ? Navigator.pop(context, place)
                          : _edit(place: place),
                trailing: widget.selectPlace
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: '${place.name} 삭제',
                        onPressed: _busy ? null : () => _delete(place),
                        icon: const Icon(Icons.delete_outline),
                      ),
              ),
            ),
        ],
      ),
    ),
  );
}

class PlaceEditPage extends StatefulWidget {
  const PlaceEditPage({
    required this.trip,
    required this.repositories,
    this.place,
    this.candidate,
    super.key,
  });
  final Trip trip;
  final TripRepositories repositories;
  final Place? place;
  final PlaceCandidate? candidate;
  @override
  State<PlaceEditPage> createState() => _PlaceEditPageState();
}

class _PlaceEditPageState extends State<PlaceEditPage> {
  late final PlaceCandidate _candidate;
  late final Map<String, TextEditingController> _fields;
  bool _dirty = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _candidate = widget.place != null
        ? PlaceCandidate.fromPlace(widget.place!)
        : widget.candidate ?? PlaceCandidate.manual(name: '');
    _fields = {
      for (final e in {
        'name': _candidate.name,
        'address': _candidate.address ?? '',
        'lat': _candidate.lat?.toString() ?? '',
        'lng': _candidate.lng?.toString() ?? '',
        'memo': _candidate.memo ?? '',
      }.entries)
        e.key: TextEditingController(text: e.value),
    };
  }

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String id,
    String label, {
    bool number = false,
    int lines = 1,
  }) => TextField(
    key: ValueKey('place-field-$id'),
    controller: _fields[id],
    enabled: !_busy,
    maxLines: lines,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : null,
    onChanged: (_) => setState(() {
      _dirty = true;
      _error = null;
    }),
    decoration: InputDecoration(labelText: label),
  );
  double? _coordinate(String field) {
    final text = _fields[field]!.text.trim();
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null || !number.isFinite) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '좌표는 숫자로 입력해 주세요.',
        retryable: false,
      );
    }
    return number;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = PlaceDraft(
        name: _fields['name']!.text,
        address: _fields['address']!.text,
        lat: _coordinate('lat'),
        lng: _coordinate('lng'),
        memo: _fields['memo']!.text,
        provider: _candidate.provider,
        source: _candidate.source,
        providerPlaceId: _candidate.providerPlaceId,
        sourceUrl: _candidate.sourceUrl,
      );
      if (draft.provider != 'manual' &&
          draft.provider != widget.trip.mapProvider) {
        throw const AppError(
          code: AppErrorCode.invalidArgument,
          message: '이 여행에서 사용하는 지도와 다른 장소입니다.',
          retryable: false,
        );
      }
      Place result;
      if (widget.place == null) {
        result = await widget.repositories.createPlace(widget.trip.id, draft);
      } else {
        await widget.repositories.updatePlace(
          widget.trip.id,
          widget.place!.id,
          draft,
        );
        result = (await widget.repositories.watchPlaces(widget.trip.id).first)
            .firstWhere((place) => place.id == widget.place!.id);
      }
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted) setState(() => _error = actionError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => EditFrame(
    title: widget.place == null ? '장소 추가' : '장소 편집',
    busy: _busy,
    dirty: _dirty,
    error: _error,
    onSave: _save,
    children: [
      _field('name', '장소 이름 · 필수'),
      _field('address', '주소 · 선택'),
      FieldPair(
        _field('lat', '위도 · 선택', number: true),
        _field('lng', '경도 · 선택', number: true),
      ),
      const Text('좌표 없이도 장소와 일정을 저장할 수 있습니다.'),
      _field('memo', '메모 · 선택', lines: 3),
      Text('출처: ${_candidate.provider}'),
    ],
  );
}
