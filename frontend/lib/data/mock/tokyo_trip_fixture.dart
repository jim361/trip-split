import '../../domain/models.dart';

const tokyoTripId = 'tokyo-2026-11';
const tokyoOwnerUid = 'tokyo-owner';

abstract final class TokyoFixtureIds {
  static const participantMe = 'tokyo-participant-me';
  static const participantFriend1 = 'tokyo-participant-friend-1';
  static const participantFriend2 = 'tokyo-participant-friend-2';
  static const narita = 'tokyo-place-narita';
  static const ueno = 'tokyo-place-ueno';
  static const hotel = 'tokyo-place-hotel';
  static const sensoji = 'tokyo-place-sensoji';
  static const arrival = 'tokyo-itinerary-arrival';
  static const transfer = 'tokyo-itinerary-transfer';
  static const checkIn = 'tokyo-itinerary-check-in';
  static const asakusa = 'tokyo-itinerary-asakusa';
  static const dinnerExpense = 'tokyo-expense-dinner';
}

final class TokyoTripFixture {
  TokyoTripFixture({
    required this.trip,
    required List<UserProfile> userProfiles,
    required List<TripMember> members,
    required List<ShareCode> shareCodes,
    required List<Participant> participants,
    required List<Place> places,
    required List<ItineraryItem> itinerary,
    required List<Expense> expenses,
  }) : userProfiles = List.unmodifiable(userProfiles),
       members = List.unmodifiable(members),
       shareCodes = List.unmodifiable(shareCodes),
       participants = List.unmodifiable(participants),
       places = List.unmodifiable(places),
       itinerary = List.unmodifiable(itinerary),
       expenses = List.unmodifiable(expenses);

  final Trip trip;
  final List<UserProfile> userProfiles;
  final List<TripMember> members;
  final List<ShareCode> shareCodes;
  final List<Participant> participants;
  final List<Place> places;
  final List<ItineraryItem> itinerary;
  final List<Expense> expenses;
}

final _createdAt = DateTime.utc(2026, 8, 28).millisecondsSinceEpoch;
final _updatedAt = DateTime.utc(2026, 8, 28, 9).millisecondsSinceEpoch;

final tokyoTripFixture = TokyoTripFixture(
  trip: Trip(
    id: tokyoTripId,
    title: '2026년 11월 도쿄 여행',
    countryCode: 'JP',
    timeZone: 'Asia/Tokyo',
    mapProvider: 'google',
    defaultCurrency: 'JPY',
    startDate: '2026-11-25',
    endDate: '2026-12-01',
    ownerUid: tokyoOwnerUid,
    shareCode: 'TKY26JP',
    createdAt: _createdAt,
    updatedAt: _updatedAt,
  ),
  userProfiles: [
    UserProfile(
      uid: tokyoOwnerUid,
      displayName: '나',
      authProvider: 'anonymous',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
  ],
  members: [
    TripMember(
      uid: tokyoOwnerUid,
      tripId: tokyoTripId,
      displayName: '나',
      role: 'editor',
      joinedAt: _createdAt,
      lastActiveAt: _updatedAt,
    ),
  ],
  shareCodes: [
    ShareCode(
      code: 'TKY26JP',
      tripId: tokyoTripId,
      createdBy: tokyoOwnerUid,
      createdAt: _createdAt,
      isActive: true,
      useCount: 0,
    ),
  ],
  participants: [
    Participant(
      id: TokyoFixtureIds.participantMe,
      tripId: tokyoTripId,
      name: '나',
      color: '#1D4ED8',
      linkedUid: tokyoOwnerUid,
      isActive: true,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
    Participant(
      id: TokyoFixtureIds.participantFriend1,
      tripId: tokyoTripId,
      name: '동행 2',
      color: '#6F6A52',
      isActive: true,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
    Participant(
      id: TokyoFixtureIds.participantFriend2,
      tripId: tokyoTripId,
      name: '동행 3',
      color: '#676762',
      isActive: true,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
  ],
  places: [
    Place(
      id: TokyoFixtureIds.narita,
      tripId: tokyoTripId,
      name: '나리타 국제공항',
      address: 'Narita, Chiba, Japan',
      lat: 35.772,
      lng: 140.3929,
      provider: 'google',
      source: 'googleSearch',
      providerPlaceId: 'mock-google-narita',
      addedBy: tokyoOwnerUid,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
    Place(
      id: TokyoFixtureIds.ueno,
      tripId: tokyoTripId,
      name: '우에노역',
      address: 'Ueno, Taito City, Tokyo',
      lat: 35.7138,
      lng: 139.7773,
      provider: 'google',
      source: 'googleMapsUrl',
      providerPlaceId: 'mock-google-ueno',
      sourceUrl: 'https://maps.google.com/?q=Ueno+Station',
      addedBy: tokyoOwnerUid,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
    Place(
      id: TokyoFixtureIds.hotel,
      tripId: tokyoTripId,
      name: '우에노 숙소',
      address: 'Taito City, Tokyo',
      lat: 35.7108,
      lng: 139.7752,
      provider: 'manual',
      source: 'manual',
      memo: '17시 체크인',
      addedBy: tokyoOwnerUid,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
    Place(
      id: TokyoFixtureIds.sensoji,
      tripId: tokyoTripId,
      name: '센소지',
      address: '2 Chome-3-1 Asakusa, Taito City, Tokyo',
      lat: 35.7148,
      lng: 139.7967,
      provider: 'google',
      source: 'googleSearch',
      providerPlaceId: 'mock-google-sensoji',
      addedBy: tokyoOwnerUid,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
  ],
  itinerary: [
    ItineraryItem(
      id: TokyoFixtureIds.arrival,
      tripId: tokyoTripId,
      date: '2026-11-25',
      startTime: '13:40',
      endTime: '14:30',
      placeId: TokyoFixtureIds.narita,
      title: '나리타 공항 도착',
      category: 'flight',
      order: 0,
      updatedBy: tokyoOwnerUid,
      updatedAt: _updatedAt,
    ),
    ItineraryItem(
      id: TokyoFixtureIds.transfer,
      tripId: tokyoTripId,
      date: '2026-11-25',
      startTime: '15:10',
      endTime: '16:00',
      placeId: TokyoFixtureIds.ueno,
      title: '스카이라이너로 우에노 이동',
      category: 'transport',
      order: 1,
      updatedBy: tokyoOwnerUid,
      updatedAt: _updatedAt,
    ),
    ItineraryItem(
      id: TokyoFixtureIds.checkIn,
      tripId: tokyoTripId,
      date: '2026-11-25',
      startTime: '17:00',
      endTime: '17:30',
      placeId: TokyoFixtureIds.hotel,
      title: '숙소 체크인',
      category: 'stay',
      order: 2,
      updatedBy: tokyoOwnerUid,
      updatedAt: _updatedAt,
    ),
    ItineraryItem(
      id: TokyoFixtureIds.asakusa,
      tripId: tokyoTripId,
      date: '2026-11-26',
      startTime: '09:30',
      endTime: '11:30',
      placeId: TokyoFixtureIds.sensoji,
      title: '아사쿠사 산책',
      category: 'activity',
      order: 0,
      updatedBy: tokyoOwnerUid,
      updatedAt: _updatedAt,
    ),
  ],
  expenses: [
    Expense(
      id: TokyoFixtureIds.dinnerExpense,
      tripId: tokyoTripId,
      title: '우에노 저녁',
      category: 'food',
      expenseDate: '2026-11-25',
      totalAmount: 4500,
      currency: 'JPY',
      payer: const ExpensePayer(
        participantId: TokyoFixtureIds.participantMe,
        amount: 4500,
      ),
      consumers: const [
        TokyoFixtureIds.participantMe,
        TokyoFixtureIds.participantFriend1,
        TokyoFixtureIds.participantFriend2,
      ],
      allocationMethod: 'equal',
      allocatedAmounts: const [
        MoneyAllocation(
          participantId: TokyoFixtureIds.participantMe,
          amount: 1500,
        ),
        MoneyAllocation(
          participantId: TokyoFixtureIds.participantFriend1,
          amount: 1500,
        ),
        MoneyAllocation(
          participantId: TokyoFixtureIds.participantFriend2,
          amount: 1500,
        ),
      ],
      receiptItems: const [],
      source: 'manual',
      createdBy: tokyoOwnerUid,
      updatedBy: tokyoOwnerUid,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
    ),
  ],
);
