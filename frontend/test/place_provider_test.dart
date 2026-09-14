import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/places/mock_place_provider.dart';
import 'package:trip_split/features/places/place_provider.dart';

void main() {
  test('도쿄 fixture 검색 결과를 repository에 저장하고 stream으로 읽는다', () async {
    final provider = MockPlaceProvider();
    final repositories = InMemoryTripRepositories(now: () => 1234);
    addTearDown(repositories.close);
    final places = StreamIterator(repositories.watchPlaces(tokyoTripId));
    addTearDown(places.cancel);

    expect(await places.moveNext(), isTrue);
    expect(places.current, hasLength(4));
    final nextUpdate = places.moveNext();
    await Future<void>.delayed(Duration.zero);

    final results = await provider.searchPlaces(
      tripId: tokyoTripId,
      query: const PlaceSearchQuery(text: '센소지'),
    );
    final created = await repositories.createPlace(
      tokyoTripId,
      results.single.toDraft(),
    );

    expect(created.name, '센소지');
    expect(created.provider, 'google');
    expect(created.providerPlaceId, 'mock-google-sensoji');
    expect(created.addedBy, tokyoOwnerUid);
    expect(created.createdAt, 1234);
    expect(await nextUpdate, isTrue);
    expect(places.current, hasLength(5));
  });

  test('mock 검색 후보는 공통 도쿄 fixture의 출처를 그대로 사용한다', () async {
    final results = await MockPlaceProvider().searchPlaces(
      tripId: tokyoTripId,
      query: const PlaceSearchQuery(text: 'Ueno'),
    );

    expect(results.single.providerPlaceId, 'mock-google-ueno');
    expect(results.single.source, 'googleMapsUrl');
  });

  test('일치하는 장소가 없으면 빈 결과를 반환한다', () async {
    final results = await MockPlaceProvider().searchPlaces(
      tripId: tokyoTripId,
      query: const PlaceSearchQuery(text: '파리 에펠탑'),
    );

    expect(results, isEmpty);
  });

  test('빈 검색어는 invalid-argument로 거부한다', () async {
    await expectLater(
      MockPlaceProvider().searchPlaces(
        tripId: tokyoTripId,
        query: const PlaceSearchQuery(text: '  '),
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'query')
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });

  test('직접 입력은 manual draft로 정규화하고 빈 선택 문자열은 제거한다', () {
    final draft = PlaceCandidate.manual(
      name: ' 도쿄 타워 ',
      address: '  ',
      memo: ' 야경 ',
    ).toDraft();

    expect(draft.name, '도쿄 타워');
    expect(draft.provider, 'manual');
    expect(draft.source, 'manual');
    expect(draft.address, isNull);
    expect(draft.memo, '야경');
  });

  test('draft는 provider/source와 좌표 불변식을 검증한다', () {
    expect(
      () => const PlaceCandidate(
        name: '잘못된 provider',
        provider: 'unknown',
        source: 'googleSearch',
      ).toDraft(),
      throwsA(_invalidField('provider')),
    );
    expect(
      () => const PlaceCandidate(
        name: '잘못된 출처',
        provider: 'manual',
        source: 'googleSearch',
      ).toDraft(),
      throwsA(_invalidField('source')),
    );
    expect(
      () => const PlaceCandidate(
        name: '좌표 오류 장소',
        provider: 'google',
        source: 'googleSearch',
        lat: 35,
      ).toDraft(),
      throwsA(_invalidField('coordinates')),
    );
    expect(
      () => const PlaceCandidate(
        name: '범위 밖 장소',
        provider: 'google',
        source: 'googleSearch',
        lat: 91,
        lng: 139,
      ).toDraft(),
      throwsA(_invalidField('coordinates')),
    );
    expect(
      () => PlaceCandidate.manual(name: List.filled(161, '가').join()).toDraft(),
      throwsA(_invalidField('name')),
    );
  });

  test('지원하는 Google Maps URL을 후보로 바꾼다', () async {
    final result = await MockPlaceProvider().resolvePlaceLink(
      tripId: tokyoTripId,
      url: Uri.parse('https://maps.google.com/?q=Ueno+Station'),
    );

    expect(result.name, '우에노역');
    expect(result.source, 'googleMapsUrl');
    expect(result.sourceUrl, 'https://maps.google.com/?q=Ueno+Station');
  });

  test('링크 해석 실패는 검색 또는 직접 입력 fallback용 오류를 반환한다', () async {
    final provider = MockPlaceProvider();

    await expectLater(
      provider.resolvePlaceLink(
        tripId: tokyoTripId,
        url: Uri.parse('https://example.com/place'),
      ),
      throwsA(_invalidField('sourceUrl')),
    );
    await expectLater(
      provider.resolvePlaceLink(
        tripId: tokyoTripId,
        url: Uri.parse('https://maps.google.com/?q=Unknown+Place'),
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.notFound)
            .having((error) => error.field, 'field', 'sourceUrl'),
      ),
    );
  });

  test('검색 provider 장애는 재시도 가능한 unavailable로 변환한다', () async {
    await expectLater(
      MockPlaceProvider(isAvailable: false).searchPlaces(
        tripId: tokyoTripId,
        query: const PlaceSearchQuery(text: '우에노'),
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.unavailable)
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
  });

  test('여행 범위가 없는 장소 요청은 provider 호출 전에 거부한다', () async {
    await expectLater(
      MockPlaceProvider().searchPlaces(
        tripId: ' ',
        query: const PlaceSearchQuery(text: '우에노'),
      ),
      throwsA(_invalidField('tripId')),
    );
  });
}

Matcher _invalidField(String field) => isA<AppError>()
    .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
    .having((error) => error.field, 'field', field);
