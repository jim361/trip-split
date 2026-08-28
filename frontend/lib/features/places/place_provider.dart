import '../../domain/models.dart';
import '../../domain/repositories.dart';

/// [TASK-03 · 장소 검색] 외부 provider에 넘기는 최소 질의 계약입니다.
final class PlaceSearchQuery {
  const PlaceSearchQuery({required this.text});

  final String text;
}

/// 외부 검색 결과에서 저장소 ID·시간·사용자를 뺈 장소 후보입니다.
final class PlaceCandidate {
  const PlaceCandidate({
    required this.name,
    required this.provider,
    required this.source,
    this.address,
    this.lat,
    this.lng,
    this.providerPlaceId,
    this.sourceUrl,
    this.memo,
  });

  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String provider;
  final String source;
  final String? providerPlaceId;
  final String? sourceUrl;
  final String? memo;

  factory PlaceCandidate.fromPlace(
    Place place, {
    String? providerPlaceId,
    String? source,
    String? sourceUrl,
  }) => PlaceCandidate(
    name: place.name,
    address: place.address,
    lat: place.lat,
    lng: place.lng,
    provider: place.provider,
    source: source ?? place.source,
    providerPlaceId: providerPlaceId ?? place.providerPlaceId,
    sourceUrl: sourceUrl ?? place.sourceUrl,
    memo: place.memo,
  );

  factory PlaceCandidate.manual({
    required String name,
    String? address,
    double? lat,
    double? lng,
    String? memo,
  }) => PlaceCandidate(
    name: name,
    address: address,
    lat: lat,
    lng: lng,
    provider: 'manual',
    source: 'manual',
    memo: memo,
  );

  PlaceDraft toDraft() => PlaceDraft(
    name: name,
    address: address,
    lat: lat,
    lng: lng,
    provider: provider,
    source: source,
    providerPlaceId: providerPlaceId,
    sourceUrl: sourceUrl,
    memo: memo,
  );
}

abstract interface class PlaceProvider {
  Future<List<PlaceCandidate>> searchPlaces(PlaceSearchQuery query);
}

abstract interface class PlaceLinkResolver {
  Future<PlaceCandidate> resolvePlaceLink(Uri url);
}
