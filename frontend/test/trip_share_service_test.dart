import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/mock/in_memory_trip_repositories.dart';
import 'package:trip_split/data/mock/tokyo_trip_fixture.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/services/trip_share_service.dart';

CreateTripCommand _validCommand({
  List<String> participantNames = const ['나', '동행 2'],
  String defaultCurrency = 'JPY',
}) => CreateTripCommand(
  title: '2026 도쿄 여행',
  countryCode: 'JP',
  timeZone: 'Asia/Tokyo',
  mapProvider: 'google',
  defaultCurrency: defaultCurrency,
  startDate: '2026-11-10',
  endDate: '2026-11-14',
  participantNames: participantNames,
);

void main() {
  test('createTrip은 canonical 필드와 참여자 이름을 전송한다', () {
    final json = _validCommand().toJson();

    expect(json['countryCode'], 'JP');
    expect(json['timeZone'], 'Asia/Tokyo');
    expect(json['mapProvider'], 'google');
    expect(json['defaultCurrency'], 'JPY');
    expect(json['participantNames'], ['나', '동행 2']);
  });

  test('mock 여행 생성 결과와 repository stream이 같은 데이터를 반환한다', () async {
    final repositories = InMemoryTripRepositories(now: () => 1234);
    addTearDown(repositories.close);
    final service = MockTripShareService(repositories);

    final created = await service.createTrip(_validCommand());
    final trip = await repositories.watchTrip(created.tripId).first;
    final participants = await repositories
        .watchParticipants(created.tripId)
        .first;

    expect(trip?.title, '2026 도쿄 여행');
    expect(trip?.shareCode, created.shareCode);
    expect(participants.map((value) => value.name), ['나', '동행 2']);
    expect(participants.first.linkedUid, repositories.actorUid);
  });

  test('mock 정산 참여자는 10명 이상이어도 입력 순서를 유지한다', () async {
    final repositories = InMemoryTripRepositories();
    addTearDown(repositories.close);
    final service = MockTripShareService(repositories);
    final names = List.generate(12, (index) => '인원 ${index + 1}');

    final created = await service.createTrip(
      _validCommand(participantNames: names),
    );
    final participants = await repositories
        .watchParticipants(created.tripId)
        .first;

    expect(participants.map((value) => value.name), names);
  });

  test('mock 공유 코드 재생성은 이전 코드를 비활성화한다', () async {
    final repositories = InMemoryTripRepositories();
    addTearDown(repositories.close);
    final service = MockTripShareService(repositories);
    final oldCode = tokyoTripFixture.trip.shareCode;

    final regenerated = await service.createShareCode(tokyoTripId);
    final trip = await repositories.watchTrip(tokyoTripId).first;

    expect(regenerated.shareCode, isNot(oldCode));
    expect(trip?.shareCode, regenerated.shareCode);
    await expectLater(
      service.joinTrip(oldCode),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.notFound,
        ),
      ),
    );
  });

  test('mock 공유 코드 입장은 actor를 같은 여행 member로 등록한다', () async {
    final repositories = InMemoryTripRepositories(actorUid: 'mock-guest');
    addTearDown(repositories.close);
    final service = MockTripShareService(repositories);

    final joined = await service.joinTrip(' tky-26jp ', displayName: '게스트');
    final members = await repositories.watchMembers(joined.tripId).first;

    expect(joined.tripId, tokyoTripId);
    expect(joined.shareCode, tokyoTripFixture.trip.shareCode);
    expect(
      members,
      contains(
        isA<TripMember>()
            .having((value) => value.uid, 'uid', 'mock-guest')
            .having((value) => value.displayName, 'displayName', '게스트'),
      ),
    );
  });

  test('빈 참여자 이름은 invalid-argument로 거부한다', () async {
    final repositories = InMemoryTripRepositories();
    addTearDown(repositories.close);
    final service = MockTripShareService(repositories);
    final command = CreateTripCommand(
      title: '2026 도쿄 여행',
      countryCode: 'JP',
      timeZone: 'Asia/Tokyo',
      mapProvider: 'google',
      defaultCurrency: 'JPY',
      startDate: '2026-11-10',
      endDate: '2026-11-14',
      participantNames: const [''],
    );

    await expectLater(
      service.createTrip(command),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'participantNames'),
      ),
    );
  });

  test('현재 지원하지 않는 기본 통화는 거부한다', () async {
    final repositories = InMemoryTripRepositories();
    addTearDown(repositories.close);
    final service = MockTripShareService(repositories);

    await expectLater(
      service.createTrip(_validCommand(defaultCurrency: 'USD')),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'defaultCurrency'),
      ),
    );
  });
}
