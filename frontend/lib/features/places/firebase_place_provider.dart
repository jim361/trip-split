import 'package:cloud_functions/cloud_functions.dart';

import '../../data/firebase/firebase_error_mapper.dart';
import '../../domain/models.dart';
import 'place_provider.dart';

class FirebasePlaceProvider implements PlaceProvider, PlaceLinkResolver {
  const FirebasePlaceProvider(this.functions);
  final FirebaseFunctions functions;
  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required EntityId tripId,
    required PlaceSearchQuery query,
  }) async {
    try {
      final result = await functions
          .httpsCallable('searchPlaces')
          .call<Object?>({'tripId': tripId, 'query': query.text});
      if (result.data is! List) throw const FormatException('장소 목록 응답 형식');
      return (result.data as List).map(placeCandidateFromData).toList();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<PlaceCandidate> resolvePlaceLink({
    required EntityId tripId,
    required Uri url,
  }) async {
    try {
      final result = await functions
          .httpsCallable('parsePlaceLink')
          .call<Object?>({'tripId': tripId, 'url': url.toString()});
      return placeCandidateFromData(result.data);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

PlaceCandidate placeCandidateFromData(Object? data) {
  if (data is! Map) throw const FormatException('장소 응답 형식');
  final candidate = PlaceCandidate(
    name: data['name'] as String,
    provider: data['provider'] as String,
    source: data['source'] as String,
    address: data['address'] as String?,
    lat: (data['lat'] as num?)?.toDouble(),
    lng: (data['lng'] as num?)?.toDouble(),
    providerPlaceId: data['providerPlaceId'] as String?,
    sourceUrl: data['sourceUrl'] as String?,
    memo: data['memo'] as String?,
  );
  candidate.toDraft();
  return candidate;
}
