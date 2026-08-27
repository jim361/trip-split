import type { TripRepositorySeed } from "../../services/repositories";
import type {
  Expense,
  ItineraryItem,
  ParsedReceipt,
  Participant,
  Place,
  ShareCode,
  Trip,
  TripMember,
  UserProfile,
} from "../../shared/types";

export const GANGNEUNG_TRIP_ID = "gangneung";

export const gangneungFixtureIds = {
  users: {
    owner: "user-owner",
    minsu: "user-minsu",
  },
  participants: {
    me: "participant-me",
    minsu: "participant-minsu",
    jiyeon: "participant-jiyeon",
    doyun: "participant-doyun",
  },
  places: {
    terraRosa: "place-terrarosa",
    hyeongjeKalguksu: "place-hyeongje-kalguksu",
    anmokBeach: "place-anmok-beach",
    gyeongpoPension: "place-gyeongpo-pension",
    centralMarket: "place-central-market",
    sheepRanch: "place-sheep-ranch",
  },
  itinerary: {
    depart: "itinerary-depart",
    terraRosa: "itinerary-terrarosa",
    lunch: "itinerary-lunch",
    anmokBeach: "itinerary-anmok-beach",
    checkIn: "itinerary-check-in",
    centralMarket: "itinerary-central-market",
    sheepRanch: "itinerary-sheep-ranch",
  },
  expenses: {
    lunch: "expense-lunch",
    lodging: "expense-lodging",
  },
  receiptItems: {
    sundubu: "receipt-item-sundubu",
    coffee: "receipt-item-coffee",
    potatoPancake: "receipt-item-potato-pancake",
  },
  shareCode: "GANG26",
} as const;

const createdAt = Date.UTC(2026, 5, 1, 0, 0, 0);
const updatedAt = Date.UTC(2026, 5, 20, 9, 0, 0);

const trip: Trip = {
  id: GANGNEUNG_TRIP_ID,
  title: "강릉 1박 2일 여행",
  regionType: "domestic",
  currency: "KRW",
  startDate: "2026-07-03",
  endDate: "2026-07-04",
  ownerUid: gangneungFixtureIds.users.owner,
  shareCode: gangneungFixtureIds.shareCode,
  createdAt,
  updatedAt,
};

const userProfiles: UserProfile[] = [
  {
    uid: gangneungFixtureIds.users.owner,
    displayName: "나",
    authProvider: "anonymous",
    createdAt,
    updatedAt,
  },
  {
    uid: gangneungFixtureIds.users.minsu,
    displayName: "민수",
    authProvider: "anonymous",
    createdAt,
    updatedAt,
  },
];

const members: TripMember[] = userProfiles.map((profile, index) => ({
  uid: profile.uid,
  tripId: GANGNEUNG_TRIP_ID,
  displayName: profile.displayName,
  role: "editor",
  joinedAt: createdAt + index * 60_000,
  lastActiveAt: updatedAt,
}));

const participants: Participant[] = [
  {
    id: gangneungFixtureIds.participants.me,
    tripId: GANGNEUNG_TRIP_ID,
    name: "나",
    color: "#E56B6F",
    linkedUid: gangneungFixtureIds.users.owner,
    isActive: true,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.participants.minsu,
    tripId: GANGNEUNG_TRIP_ID,
    name: "민수",
    color: "#457B9D",
    linkedUid: gangneungFixtureIds.users.minsu,
    isActive: true,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.participants.jiyeon,
    tripId: GANGNEUNG_TRIP_ID,
    name: "지연",
    color: "#2A9D8F",
    isActive: true,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.participants.doyun,
    tripId: GANGNEUNG_TRIP_ID,
    name: "도윤",
    color: "#F4A261",
    isActive: true,
    createdAt,
    updatedAt,
  },
];

const places: Place[] = [
  {
    id: gangneungFixtureIds.places.terraRosa,
    tripId: GANGNEUNG_TRIP_ID,
    name: "테라로사 커피공장 강릉본점",
    address: "강원 강릉시 구정면 현천길 7",
    lat: 37.696236,
    lng: 128.892876,
    provider: "naver",
    source: "naverSearch",
    providerPlaceId: "11677535",
    addedBy: gangneungFixtureIds.users.owner,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.places.hyeongjeKalguksu,
    tripId: GANGNEUNG_TRIP_ID,
    name: "형제칼국수",
    address: "강원 강릉시 강릉대로204번길 2",
    lat: 37.752486,
    lng: 128.888024,
    provider: "naver",
    source: "naverLink",
    providerPlaceId: "11852337",
    sourceUrl: "https://naver.me/example-kalguksu",
    addedBy: gangneungFixtureIds.users.owner,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.places.anmokBeach,
    tripId: GANGNEUNG_TRIP_ID,
    name: "안목해변",
    address: "강원 강릉시 창해로14번길",
    lat: 37.771284,
    lng: 128.947862,
    provider: "naver",
    source: "naverSearch",
    addedBy: gangneungFixtureIds.users.minsu,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.places.gyeongpoPension,
    tripId: GANGNEUNG_TRIP_ID,
    name: "경포 그곳에가면펜션",
    address: "강원 강릉시 해안로 381-2",
    lat: 37.796123,
    lng: 128.908404,
    provider: "manual",
    source: "manual",
    addedBy: gangneungFixtureIds.users.owner,
    memo: "16시 체크인",
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.places.centralMarket,
    tripId: GANGNEUNG_TRIP_ID,
    name: "강릉중앙시장",
    address: "강원 강릉시 금성로 21",
    lat: 37.754037,
    lng: 128.898567,
    provider: "naver",
    source: "naverSearch",
    addedBy: gangneungFixtureIds.users.minsu,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.places.sheepRanch,
    tripId: GANGNEUNG_TRIP_ID,
    name: "대관령양떼목장",
    address: "강원 평창군 대관령면 대관령마루길 483-32",
    lat: 37.687707,
    lng: 128.750628,
    provider: "naver",
    source: "naverSearch",
    addedBy: gangneungFixtureIds.users.owner,
    createdAt,
    updatedAt,
  },
];

const itinerary: ItineraryItem[] = [
  {
    id: gangneungFixtureIds.itinerary.depart,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-03",
    startTime: "08:00",
    title: "수원 출발",
    memo: "휴게소에서 한 번 쉬기",
    order: 0,
    updatedBy: gangneungFixtureIds.users.owner,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.itinerary.terraRosa,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-03",
    startTime: "11:00",
    placeId: gangneungFixtureIds.places.terraRosa,
    title: "테라로사 커피공장 강릉본점",
    order: 1,
    updatedBy: gangneungFixtureIds.users.owner,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.itinerary.lunch,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-03",
    startTime: "12:10",
    placeId: gangneungFixtureIds.places.hyeongjeKalguksu,
    title: "형제칼국수 점심",
    order: 2,
    updatedBy: gangneungFixtureIds.users.owner,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.itinerary.anmokBeach,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-03",
    startTime: "13:30",
    placeId: gangneungFixtureIds.places.anmokBeach,
    title: "안목해변 산책",
    order: 3,
    updatedBy: gangneungFixtureIds.users.minsu,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.itinerary.checkIn,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-03",
    startTime: "16:10",
    placeId: gangneungFixtureIds.places.gyeongpoPension,
    title: "숙소 체크인",
    order: 4,
    updatedBy: gangneungFixtureIds.users.minsu,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.itinerary.centralMarket,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-04",
    startTime: "09:30",
    placeId: gangneungFixtureIds.places.centralMarket,
    title: "강릉중앙시장",
    order: 0,
    updatedBy: gangneungFixtureIds.users.owner,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.itinerary.sheepRanch,
    tripId: GANGNEUNG_TRIP_ID,
    date: "2026-07-04",
    startTime: "13:00",
    placeId: gangneungFixtureIds.places.sheepRanch,
    title: "대관령양떼목장",
    order: 1,
    updatedBy: gangneungFixtureIds.users.owner,
    updatedAt,
  },
];

const expenses: Expense[] = [
  {
    id: gangneungFixtureIds.expenses.lunch,
    tripId: GANGNEUNG_TRIP_ID,
    title: "형제칼국수 점심",
    category: "식비",
    expenseDate: "2026-07-03",
    totalAmount: 33_000,
    currency: "KRW",
    payer: {
      participantId: gangneungFixtureIds.participants.me,
      amount: 33_000,
    },
    consumers: [
      gangneungFixtureIds.participants.me,
      gangneungFixtureIds.participants.minsu,
      gangneungFixtureIds.participants.jiyeon,
    ],
    allocationMethod: "itemized",
    allocatedAmounts: [
      { participantId: gangneungFixtureIds.participants.me, amount: 17_000 },
      { participantId: gangneungFixtureIds.participants.minsu, amount: 5_000 },
      {
        participantId: gangneungFixtureIds.participants.jiyeon,
        amount: 11_000,
      },
    ],
    receiptItems: [
      {
        id: gangneungFixtureIds.receiptItems.sundubu,
        kind: "item",
        name: "순두부",
        amount: 12_000,
        consumers: [gangneungFixtureIds.participants.me],
        allocationMethod: "equal",
        allocatedAmounts: [{ participantId: gangneungFixtureIds.participants.me, amount: 12_000 }],
        source: "ocr",
        sortOrder: 0,
      },
      {
        id: gangneungFixtureIds.receiptItems.coffee,
        kind: "item",
        name: "커피",
        amount: 6_000,
        consumers: [gangneungFixtureIds.participants.jiyeon],
        allocationMethod: "equal",
        allocatedAmounts: [
          {
            participantId: gangneungFixtureIds.participants.jiyeon,
            amount: 6_000,
          },
        ],
        source: "ocr",
        sortOrder: 1,
      },
      {
        id: gangneungFixtureIds.receiptItems.potatoPancake,
        kind: "item",
        name: "감자전",
        amount: 15_000,
        consumers: [
          gangneungFixtureIds.participants.me,
          gangneungFixtureIds.participants.minsu,
          gangneungFixtureIds.participants.jiyeon,
        ],
        allocationMethod: "equal",
        allocatedAmounts: [
          { participantId: gangneungFixtureIds.participants.me, amount: 5_000 },
          {
            participantId: gangneungFixtureIds.participants.minsu,
            amount: 5_000,
          },
          {
            participantId: gangneungFixtureIds.participants.jiyeon,
            amount: 5_000,
          },
        ],
        source: "ocr",
        sortOrder: 2,
      },
    ],
    source: "ocr",
    placeId: gangneungFixtureIds.places.hyeongjeKalguksu,
    itineraryItemId: gangneungFixtureIds.itinerary.lunch,
    createdBy: gangneungFixtureIds.users.owner,
    updatedBy: gangneungFixtureIds.users.owner,
    createdAt,
    updatedAt,
  },
  {
    id: gangneungFixtureIds.expenses.lodging,
    tripId: GANGNEUNG_TRIP_ID,
    title: "숙소",
    category: "숙박",
    expenseDate: "2026-07-03",
    totalAmount: 180_000,
    currency: "KRW",
    payer: {
      participantId: gangneungFixtureIds.participants.minsu,
      amount: 180_000,
    },
    consumers: [
      gangneungFixtureIds.participants.me,
      gangneungFixtureIds.participants.minsu,
      gangneungFixtureIds.participants.jiyeon,
      gangneungFixtureIds.participants.doyun,
    ],
    allocationMethod: "equal",
    allocatedAmounts: [
      { participantId: gangneungFixtureIds.participants.me, amount: 45_000 },
      { participantId: gangneungFixtureIds.participants.minsu, amount: 45_000 },
      {
        participantId: gangneungFixtureIds.participants.jiyeon,
        amount: 45_000,
      },
      { participantId: gangneungFixtureIds.participants.doyun, amount: 45_000 },
    ],
    receiptItems: [],
    source: "manual",
    placeId: gangneungFixtureIds.places.gyeongpoPension,
    itineraryItemId: gangneungFixtureIds.itinerary.checkIn,
    memo: "1박 숙박비",
    createdBy: gangneungFixtureIds.users.minsu,
    updatedBy: gangneungFixtureIds.users.minsu,
    createdAt,
    updatedAt,
  },
];

const shareCodes: ShareCode[] = [
  {
    code: gangneungFixtureIds.shareCode,
    tripId: GANGNEUNG_TRIP_ID,
    createdBy: gangneungFixtureIds.users.owner,
    createdAt,
    isActive: true,
    useCount: 1,
  },
];

const parsedReceipt: ParsedReceipt = {
  rawText: "형제칼국수\n순두부 12,000\n커피 6,000\n감자전 15,000\n합계 33,000",
  merchantName: "형제칼국수",
  expenseDate: "2026-07-03",
  totalAmountCandidate: 33_000,
  items: [
    { name: "순두부", amount: 12_000, confidence: 0.98, sourceOrder: 0 },
    { name: "커피", amount: 6_000, confidence: 0.95, sourceOrder: 1 },
    { name: "감자전", amount: 15_000, confidence: 0.97, sourceOrder: 2 },
  ],
  warnings: [],
};

export type GangneungTripFixture = {
  trip: Trip;
  userProfiles: UserProfile[];
  members: TripMember[];
  participants: Participant[];
  places: Place[];
  itinerary: ItineraryItem[];
  expenses: Expense[];
  shareCodes: ShareCode[];
  parsedReceipt: ParsedReceipt;
};

export const gangneungTripFixture: GangneungTripFixture = {
  trip,
  userProfiles,
  members,
  participants,
  places,
  itinerary,
  expenses,
  shareCodes,
  parsedReceipt,
};

export const gangneungTripRepositorySeed: TripRepositorySeed = {
  userProfiles,
  trips: [trip],
  members,
  participants,
  places,
  itinerary,
  expenses,
  shareCodes,
};
