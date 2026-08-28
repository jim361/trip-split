enum TripDestination { itinerary, preparation, settlement, receipts }

final class TripLocation {
  const TripLocation({
    required this.tripId,
    required this.destination,
    this.mapExpanded = false,
  });

  static const defaultTripId = 'tokyo-2026-11';

  final String tripId;
  final TripDestination destination;
  final bool mapExpanded;

  static TripLocation? tryParse(String? routeName) {
    final uri = Uri.tryParse(routeName ?? '/');
    if (uri == null) return null;
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return const TripLocation(
        tripId: defaultTripId,
        destination: TripDestination.itinerary,
      );
    }
    if (segments.length < 2 || segments.first != 'trips') return null;

    final tripId = segments[1];
    if (tripId.isEmpty) return null;
    if (segments.length == 2) {
      return TripLocation(
        tripId: tripId,
        destination: TripDestination.itinerary,
      );
    }
    if (segments.length != 3) return null;

    return switch (segments[2]) {
      'itinerary' => TripLocation(
        tripId: tripId,
        destination: TripDestination.itinerary,
        mapExpanded: uri.queryParameters['map'] == 'expanded',
      ),
      'map' => TripLocation(
        tripId: tripId,
        destination: TripDestination.itinerary,
        mapExpanded: true,
      ),
      'preparation' => TripLocation(
        tripId: tripId,
        destination: TripDestination.preparation,
      ),
      'settlement' => TripLocation(
        tripId: tripId,
        destination: TripDestination.settlement,
      ),
      'receipts' => TripLocation(
        tripId: tripId,
        destination: TripDestination.receipts,
      ),
      _ => null,
    };
  }

  String get canonicalPath {
    final section = switch (destination) {
      TripDestination.itinerary => 'itinerary',
      TripDestination.preparation => 'preparation',
      TripDestination.settlement => 'settlement',
      TripDestination.receipts => 'receipts',
    };
    final query = destination == TripDestination.itinerary && mapExpanded
        ? '?map=expanded'
        : '';
    return '/trips/$tripId/$section$query';
  }

  TripLocation forDestination(TripDestination next) =>
      TripLocation(tripId: tripId, destination: next);

  TripLocation toggleMap() => TripLocation(
    tripId: tripId,
    destination: TripDestination.itinerary,
    mapExpanded: !mapExpanded,
  );
}
