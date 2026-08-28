import '../../domain/models.dart';
import '../../domain/repositories.dart';

final _timePattern = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

ItineraryItemDraft validateItineraryItemDraft(ItineraryItemDraft draft) {
  final date = draft.date.trim();
  final title = draft.title.trim();
  final startTime = _optionalTime(draft.startTime, 'startTime');
  final endTime = _optionalTime(draft.endTime, 'endTime');

  if (!_isLocalDate(date)) {
    throw _invalid('date', '일정 날짜는 YYYY-MM-DD 형식의 실제 날짜여야 합니다.');
  }
  if (title.isEmpty) {
    throw _invalid('title', '일정 제목을 입력해 주세요.');
  }
  if (draft.order < 0) {
    throw _invalid('order', '일정 순서는 0 이상이어야 합니다.');
  }

  return ItineraryItemDraft(
    date: date,
    title: title,
    order: draft.order,
    startTime: startTime,
    endTime: endTime,
    placeId: _optionalTrim(draft.placeId),
    memo: _optionalTrim(draft.memo),
  );
}

List<ItineraryItem> normalizeItineraryOrders(List<ItineraryItem> items) {
  final sorted = [...items]
    ..sort((left, right) {
      final byDate = left.date.compareTo(right.date);
      if (byDate != 0) return byDate;
      final byOrder = left.order.compareTo(right.order);
      return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
    });

  LocalDate? currentDate;
  var nextOrder = 0;
  return List.unmodifiable(
    sorted.map((item) {
      if (item.date != currentDate) {
        currentDate = item.date;
        nextOrder = 0;
      }
      return _withOrder(item, nextOrder++);
    }),
  );
}

bool _isLocalDate(String value) {
  final match = _datePattern.firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}

String? _optionalTime(String? value, String field) {
  final normalized = _optionalTrim(value);
  if (normalized != null && !_timePattern.hasMatch(normalized)) {
    throw _invalid(field, '시간은 HH:mm 형식으로 입력해 주세요.');
  }
  return normalized;
}

String? _optionalTrim(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

AppError _invalid(String field, String message) => AppError(
  code: AppErrorCode.invalidArgument,
  message: message,
  retryable: false,
  field: field,
);

ItineraryItem _withOrder(ItineraryItem item, int order) => ItineraryItem(
  id: item.id,
  tripId: item.tripId,
  date: item.date,
  startTime: item.startTime,
  endTime: item.endTime,
  placeId: item.placeId,
  title: item.title,
  memo: item.memo,
  order: order,
  updatedBy: item.updatedBy,
  updatedAt: item.updatedAt,
);
