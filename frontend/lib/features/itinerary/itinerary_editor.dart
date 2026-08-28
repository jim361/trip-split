import '../../domain/models.dart';

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
