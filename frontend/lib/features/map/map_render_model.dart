import '../../domain/models.dart';

const _dateColors = [
  '#1A73E8',
  '#E56B6F',
  '#2A9D8F',
  '#F4A261',
  '#7B61FF',
  '#8D6E63',
];

enum MapEmptyState { none, noItinerary, noMappableItems }

enum MissingMapLocationReason {
  placeNotLinked,
  placeNotFound,
  coordinatesMissing,
}

final class MapCoordinate {
  const MapCoordinate({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

final class MapPin {
  const MapPin({
    required this.itineraryItemId,
    required this.placeId,
    required this.date,
    required this.number,
    required this.title,
    required this.placeName,
    required this.coordinate,
    required this.colorHex,
  });

  final EntityId itineraryItemId;
  final EntityId placeId;
  final LocalDate date;
  final int number;
  final String title;
  final String placeName;
  final MapCoordinate coordinate;
  final String colorHex;
}

final class MapRouteSegment {
  const MapRouteSegment({
    required this.date,
    required this.fromItineraryItemId,
    required this.toItineraryItemId,
    required this.from,
    required this.to,
    required this.colorHex,
  });

  final LocalDate date;
  final EntityId fromItineraryItemId;
  final EntityId toItineraryItemId;
  final MapCoordinate from;
  final MapCoordinate to;
  final String colorHex;
}

final class MissingMapLocation {
  const MissingMapLocation({
    required this.itineraryItemId,
    required this.date,
    required this.number,
    required this.title,
    required this.reason,
    this.placeId,
  });

  final EntityId itineraryItemId;
  final LocalDate date;
  final int number;
  final String title;
  final EntityId? placeId;
  final MissingMapLocationReason reason;
}

final class MapRenderModel {
  MapRenderModel._({
    required List<MapPin> pins,
    required List<MapRouteSegment> segments,
    required List<MissingMapLocation> missingLocations,
    required Map<LocalDate, String> colorByDate,
    required this.emptyState,
  }) : pins = List.unmodifiable(pins),
       segments = List.unmodifiable(segments),
       missingLocations = List.unmodifiable(missingLocations),
       colorByDate = Map.unmodifiable(colorByDate);

  final List<MapPin> pins;
  final List<MapRouteSegment> segments;
  final List<MissingMapLocation> missingLocations;
  final Map<LocalDate, String> colorByDate;
  final MapEmptyState emptyState;
}

MapRenderModel deriveMapRenderModel({
  required List<Place> places,
  required List<ItineraryItem> itinerary,
}) {
  final placesById = {for (final place in places) place.id: place};
  final sorted =
      [
        for (var index = 0; index < itinerary.length; index++)
          _IndexedItem(index, itinerary[index]),
      ]..sort((left, right) {
        final byDate = left.item.date.compareTo(right.item.date);
        if (byDate != 0) return byDate;
        final byOrder = left.item.order.compareTo(right.item.order);
        return byOrder != 0 ? byOrder : left.index.compareTo(right.index);
      });

  final dates = <LocalDate>[];
  for (final entry in sorted) {
    if (dates.isEmpty || dates.last != entry.item.date) {
      dates.add(entry.item.date);
    }
  }
  final colorByDate = {
    for (var index = 0; index < dates.length; index++)
      dates[index]: _dateColors[index % _dateColors.length],
  };

  final pins = <MapPin>[];
  final segments = <MapRouteSegment>[];
  final missingLocations = <MissingMapLocation>[];
  final nextNumberByDate = <LocalDate, int>{};
  final previousPinByDate = <LocalDate, MapPin>{};

  for (final entry in sorted) {
    final item = entry.item;
    final number = (nextNumberByDate[item.date] ?? 0) + 1;
    nextNumberByDate[item.date] = number;
    final place = item.placeId == null ? null : placesById[item.placeId];
    final reason = switch ((item.placeId, place?.lat, place?.lng)) {
      (null, _, _) => MissingMapLocationReason.placeNotLinked,
      (_, null, null) when place == null =>
        MissingMapLocationReason.placeNotFound,
      (_, null, _) ||
      (_, _, null) => MissingMapLocationReason.coordinatesMissing,
      _ => null,
    };

    if (reason != null) {
      missingLocations.add(
        MissingMapLocation(
          itineraryItemId: item.id,
          date: item.date,
          number: number,
          title: item.title,
          placeId: item.placeId,
          reason: reason,
        ),
      );
      continue;
    }

    final pin = MapPin(
      itineraryItemId: item.id,
      placeId: place!.id,
      date: item.date,
      number: number,
      title: item.title,
      placeName: place.name,
      coordinate: MapCoordinate(lat: place.lat!, lng: place.lng!),
      colorHex: colorByDate[item.date]!,
    );
    final previous = previousPinByDate[item.date];
    if (previous != null) {
      segments.add(
        MapRouteSegment(
          date: item.date,
          fromItineraryItemId: previous.itineraryItemId,
          toItineraryItemId: pin.itineraryItemId,
          from: previous.coordinate,
          to: pin.coordinate,
          colorHex: pin.colorHex,
        ),
      );
    }
    pins.add(pin);
    previousPinByDate[item.date] = pin;
  }

  return MapRenderModel._(
    pins: pins,
    segments: segments,
    missingLocations: missingLocations,
    colorByDate: colorByDate,
    emptyState: itinerary.isEmpty
        ? MapEmptyState.noItinerary
        : pins.isEmpty
        ? MapEmptyState.noMappableItems
        : MapEmptyState.none,
  );
}

final class _IndexedItem {
  const _IndexedItem(this.index, this.item);

  final int index;
  final ItineraryItem item;
}
