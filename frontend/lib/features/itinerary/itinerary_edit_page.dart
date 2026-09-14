import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'itinerary_plan_controls.dart';
import '../places/place_provider.dart';
import '../places/places_page.dart';
import '../places/mock_place_provider.dart';

class ItineraryEditPage extends StatefulWidget {
  const ItineraryEditPage({
    super.key,
    required this.tripId,
    required this.repositories,
    required this.date,
    required this.planId,
    required this.places,
    this.item,
    this.placeProvider,
    this.placeLinkResolver,
  });

  final EntityId tripId;
  final TripRepositories repositories;
  final LocalDate date;
  final String planId;
  final List<Place> places;
  final ItineraryItem? item;
  final PlaceProvider? placeProvider;
  final PlaceLinkResolver? placeLinkResolver;

  @override
  State<ItineraryEditPage> createState() => _ItineraryEditPageState();
}

class _ItineraryEditPageState extends State<ItineraryEditPage> {
  late final Map<String, TextEditingController> _fields;
  late final Stream<List<Place>> _places;
  late String _planId;
  late String _category;
  String? _placeId;
  AppError? _error;
  bool _busy = false;
  bool _dirty = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _fields = {
      'title': TextEditingController(text: item?.title ?? ''),
      'date': TextEditingController(text: item?.date ?? widget.date),
      'startTime': TextEditingController(text: item?.startTime ?? ''),
      'endTime': TextEditingController(text: item?.endTime ?? ''),
      'memo': TextEditingController(text: item?.memo ?? ''),
    };
    _planId = item?.planId ?? widget.planId;
    _category = item?.category ?? 'other';
    _placeId = item?.placeId;
    _places = widget.repositories.watchPlaces(widget.tripId);
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {
    _dirty = true;
    _error = null;
  });

  @override
  Widget build(BuildContext context) => PopScope<String>(
    canPop: !_busy && !_dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) _close();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? '일정 추가' : '일정 편집'),
        leading: IconButton(
          tooltip: '편집 닫기',
          onPressed: _busy ? null : _close,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: StreamBuilder<List<Place>>(
              stream: _places,
              initialData: widget.places,
              builder: (context, snapshot) {
                final places = snapshot.data ?? widget.places;
                final missingPlace =
                    _placeId != null &&
                    !places.any((place) => place.id == _placeId);
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        key: const Key('itinerary-edit-fields'),
                        padding: const EdgeInsets.all(16),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          _textField('title', '일정 제목', maxLength: 160),
                          TextButton.icon(
                            onPressed: _busy ? null : _addPlace,
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('보관함에서 장소 추가·선택'),
                          ),
                          const SizedBox(height: 16),
                          _fieldPair(
                            _textField(
                              'date',
                              '날짜',
                              hint: 'YYYY-MM-DD',
                              keyboard: TextInputType.datetime,
                              suffix: IconButton(
                                tooltip: '날짜 선택',
                                onPressed: _busy ? null : _pickDate,
                                icon: const Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              key: ValueKey('edit-plan-$_planId'),
                              initialValue: _planId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '계획',
                              ),
                              items: [
                                for (final plan in itineraryPlanIds)
                                  DropdownMenuItem(
                                    value: plan,
                                    child: Text('$plan안'),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) {
                                      _planId = value!;
                                      _changed();
                                    },
                            ),
                          ),
                          _fieldPair(
                            _timeField('startTime', '시작 시간'),
                            _timeField('endTime', '종료 시간'),
                          ),
                          _fieldPair(
                            DropdownButtonFormField<String>(
                              key: const Key('edit-category'),
                              initialValue: _category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '유형',
                              ),
                              items: [
                                for (final category in itineraryCategories)
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      itineraryCategoryStyle(category).$1,
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) {
                                      _category = value!;
                                      _changed();
                                    },
                            ),
                            DropdownButtonFormField<String>(
                              key: ValueKey('edit-place-${_placeId ?? ''}'),
                              initialValue: _placeId ?? '',
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: '연결 장소',
                                errorText: _error?.field == 'placeId'
                                    ? _error?.message
                                    : null,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('장소 없음'),
                                ),
                                if (missingPlace)
                                  DropdownMenuItem(
                                    value: _placeId,
                                    child: const Text(
                                      '삭제된 장소 · 연결 해제 필요',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                for (final place in places)
                                  DropdownMenuItem(
                                    value: place.id,
                                    child: Text(
                                      place.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) {
                                      _placeId = value == '' ? null : value;
                                      _changed();
                                    },
                            ),
                          ),
                          Text(
                            snapshot.hasError
                                ? '장소 목록을 불러오지 못했습니다.'
                                : '시간과 장소는 비워 두어도 됩니다.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          _textField('memo', '메모 (선택)', maxLines: 3),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error case final error?) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                error.message,
                                key: const Key('itinerary-edit-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          FilledButton(
                            key: const Key('itinerary-save'),
                            onPressed: _busy
                                ? null
                                : () => _save(places, snapshot.hasError),
                            child: Text(_busy ? '처리 중…' : '저장'),
                          ),
                          if (widget.item != null)
                            TextButton(
                              key: const Key('itinerary-delete'),
                              onPressed: _busy ? null : _delete,
                              child: const Text('일정 삭제'),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _fieldPair(Widget first, Widget second) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth < 328 * textScale) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 16), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    ),
  );

  Widget _timeField(String field, String label) => _textField(
    field,
    label,
    hint: 'HH:mm',
    keyboard: TextInputType.datetime,
    suffix: IconButton(
      tooltip: '$label 선택',
      onPressed: _busy ? null : () => _pickTime(field),
      icon: const Icon(Icons.schedule),
    ),
  );

  Widget _textField(
    String field,
    String label, {
    String? hint,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboard,
    Widget? suffix,
  }) => TextField(
    key: ValueKey('edit-$field'),
    controller: _fields[field],
    enabled: !_busy,
    onChanged: (_) => _changed(),
    maxLength: maxLength,
    maxLines: maxLines,
    keyboardType: keyboard,
    style: Theme.of(context).textTheme.bodyMedium,
    textInputAction: maxLines > 1
        ? TextInputAction.newline
        : TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      errorText: _error?.field == field ? _error?.message : null,
    ),
  );

  ItineraryItemDraft _draft(int order) => ItineraryItemDraft(
    title: _fields['title']!.text,
    date: _fields['date']!.text,
    planId: _planId,
    category: _category,
    startTime: _fields['startTime']!.text,
    endTime: _fields['endTime']!.text,
    placeId: _placeId,
    memo: _fields['memo']!.text,
    order: order,
  );

  Future<void> _save(List<Place> places, bool placesFailed) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    await _run(() async {
      final input = _draft(0);
      if (_placeId != null &&
          (placesFailed || !places.any((place) => place.id == _placeId))) {
        throw const AppError(
          code: AppErrorCode.invalidArgument,
          message: '연결할 장소를 다시 선택하거나 연결을 해제해 주세요.',
          retryable: false,
          field: 'placeId',
        );
      }
      final items = await widget.repositories
          .watchItinerary(widget.tripId)
          .first;
      final original = widget.item;
      ItineraryItem? current;
      if (original != null) {
        for (final item in items) {
          if (item.id == original.id) current = item;
        }
        if (current == null) {
          throw const AppError(
            code: AppErrorCode.notFound,
            message: '이 일정은 이미 삭제됐습니다. 목록으로 돌아가 확인해 주세요.',
            retryable: false,
          );
        }
      }
      var order = 0;
      if (current != null &&
          current.date == input.date &&
          current.planId == input.planId) {
        order = current.order;
      } else {
        for (final item in items) {
          if (item.id != original?.id &&
              item.date == input.date &&
              item.planId == input.planId &&
              item.order >= order) {
            order = item.order + 1;
          }
        }
      }
      if (original == null) {
        await widget.repositories.createItineraryItem(
          widget.tripId,
          _draft(order),
        );
      } else {
        await widget.repositories.updateItineraryItem(
          widget.tripId,
          original.id,
          _draft(order),
        );
      }
      if (mounted) Navigator.of(context).pop('일정을 저장했습니다.');
    });
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
      if (mounted) {
        setState(() {
          _error = error is AppError
              ? error
              : const AppError(
                  code: AppErrorCode.unknown,
                  message: '저장하지 못했습니다. 입력을 확인하고 다시 시도해 주세요.',
                  retryable: false,
                );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    if (_confirming) return false;
    _confirming = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    _confirming = false;
    return result ?? false;
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_dirty &&
        !await _confirm('편집을 그만둘까요?', '저장하지 않은 변경 내용이 사라집니다.', '나가기')) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addPlace() async {
    final trip = await widget.repositories.watchTrip(widget.tripId).first;
    if (!mounted || trip == null) return;
    final place = await Navigator.of(context).push<Place>(
      MaterialPageRoute(
        builder: (_) => PlacesPage(
          trip: trip,
          repositories: widget.repositories,
          selectPlace: true,
          provider: widget.placeProvider ?? MockPlaceProvider(),
          linkResolver: widget.placeLinkResolver ?? MockPlaceProvider(),
        ),
      ),
    );
    if (place != null && mounted) {
      _placeId = place.id;
      _changed();
    }
  }

  Future<void> _delete() async {
    if (_busy || !await _confirm('일정을 삭제할까요?', '삭제한 일정은 되돌릴 수 없습니다.', '삭제')) {
      return;
    }
    if (!mounted) return;
    await _run(() async {
      await widget.repositories.deleteItineraryItem(
        widget.tripId,
        widget.item!.id,
      );
      if (mounted) Navigator.of(context).pop('일정을 삭제했습니다.');
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          (DateTime.tryParse(_fields['date']!.text) ??
                  DateTime.parse(widget.date))
              .clampDate(DateTime(2000), DateTime(2100, 12, 31)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null && mounted) {
      _fields['date']!.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _changed();
    }
  }

  Future<void> _pickTime(String field) async {
    final text = _fields[field]!.text;
    final valid = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(text);
    final time = await showTimePicker(
      context: context,
      initialTime: valid
          ? TimeOfDay(
              hour: int.parse(text.substring(0, 2)),
              minute: int.parse(text.substring(3)),
            )
          : const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      _fields[field]!.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      _changed();
    }
  }
}

extension on DateTime {
  DateTime clampDate(DateTime first, DateTime last) => isBefore(first)
      ? first
      : isAfter(last)
      ? last
      : this;
}
