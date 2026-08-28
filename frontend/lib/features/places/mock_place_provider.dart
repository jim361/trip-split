import '../../data/mock/tokyo_trip_fixture.dart';
import '../../domain/models.dart';
import 'place_provider.dart';

/// 실제 Google API 없이 `tokyo-2026-11` 장소 검색 흐름을 검증합니다.
final class MockPlaceProvider implements PlaceProvider, PlaceLinkResolver {
  MockPlaceProvider({List<PlaceCandidate>? candidates, this.isAvailable = true})
    : _candidates = List.unmodifiable(candidates ?? _fixtureCandidates());

  final List<PlaceCandidate> _candidates;
  final bool isAvailable;

  @override
  Future<List<PlaceCandidate>> searchPlaces(PlaceSearchQuery query) async {
    final normalized = query.text.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '검색어를 입력해 주세요.',
        retryable: false,
        field: 'query',
      );
    }
    _ensureAvailable();

    return List.unmodifiable(
      _candidates.where((candidate) {
        final searchable = '${candidate.name} ${candidate.address ?? ''}'
            .toLowerCase();
        return searchable.contains(normalized);
      }),
    );
  }

  @override
  Future<PlaceCandidate> resolvePlaceLink(Uri url) async {
    _ensureAvailable();
    if (url.scheme != 'https' || url.host != 'maps.google.com') {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '지원하는 Google Maps URL을 확인해 주세요.',
        retryable: false,
        field: 'sourceUrl',
      );
    }

    for (final candidate in _candidates) {
      if (candidate.sourceUrl == url.toString()) {
        return candidate;
      }
    }

    final query = url.queryParameters['q']?.trim();
    if (query == null || query.isEmpty) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: 'Google Maps URL에서 장소 검색어를 찾을 수 없습니다.',
        retryable: false,
        field: 'sourceUrl',
      );
    }
    final matches = await searchPlaces(PlaceSearchQuery(text: query));
    if (matches.isNotEmpty) {
      final match = matches.first;
      return PlaceCandidate(
        name: match.name,
        address: match.address,
        lat: match.lat,
        lng: match.lng,
        provider: match.provider,
        source: 'googleMapsUrl',
        providerPlaceId: match.providerPlaceId,
        sourceUrl: url.toString(),
        memo: match.memo,
      );
    }
    throw const AppError(
      code: AppErrorCode.notFound,
      message: '링크의 장소를 찾을 수 없습니다. 검색 또는 직접 입력을 사용해 주세요.',
      retryable: false,
      field: 'sourceUrl',
    );
  }

  void _ensureAvailable() {
    if (isAvailable) return;
    throw const AppError(
      code: AppErrorCode.unavailable,
      message: '장소 검색을 잠시 사용할 수 없습니다.',
      retryable: true,
    );
  }
}

List<PlaceCandidate> _fixtureCandidates() => tokyoTripFixture.places
    .where((place) => place.provider == 'google')
    .map(PlaceCandidate.fromPlace)
    .toList(growable: false);
