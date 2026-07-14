import {
  createAppError,
  type EntityId,
  type OnData,
  type OnError,
  type Unsubscribe,
} from "../../shared/contracts";
import type {
  Expense,
  ItineraryItem,
  Participant,
  Place,
  Trip,
  TripMember,
  UserProfile,
} from "../../shared/types";
import type {
  CreateExpenseInput,
  CreateItineraryItemInput,
  CreateParticipantInput,
  CreatePlaceInput,
  ExpensesRepository,
  ItineraryRepository,
  MembersRepository,
  ParticipantsRepository,
  PlacesRepository,
  TripRepositories,
  TripRepositorySeed,
  TripsRepository,
  UpdateExpenseInput,
  UpdateItineraryItemInput,
  UpdateParticipantInput,
  UpdatePlaceInput,
  UpdateTripInput,
  UpsertUserProfileInput,
  UserProfilesRepository,
} from "../repositories";

type MockEntityKind = "participant" | "place" | "itinerary" | "expense";

export type InMemoryRepositoriesOptions = {
  getActorUid?: () => string | null;
  now?: () => number;
  idFactory?: (kind: MockEntityKind) => EntityId;
};

type Subscriber<T> = {
  onData: OnData<T>;
  onError: OnError;
};

function clone<T>(value: T): T {
  return structuredClone(value);
}

function sortById<T extends { id: string }>(values: T[]): T[] {
  return values.sort((left, right) => left.id.localeCompare(right.id));
}

function notFound(entityName: string, id: string) {
  return createAppError("not-found", `${entityName}을(를) 찾을 수 없습니다.`, {
    retryable: false,
    details: { id },
  });
}

export class InMemoryTripRepositories implements TripRepositories {
  readonly userProfiles: UserProfilesRepository;
  readonly trips: TripsRepository;
  readonly members: MembersRepository;
  readonly participants: ParticipantsRepository;
  readonly places: PlacesRepository;
  readonly itinerary: ItineraryRepository;
  readonly expenses: ExpensesRepository;

  private readonly state: TripRepositorySeed;
  private readonly getActorUid: () => string | null;
  private readonly now: () => number;
  private readonly idFactory: (kind: MockEntityKind) => EntityId;
  private readonly userSubscribers = new Map<string, Set<Subscriber<UserProfile | null>>>();
  private readonly tripSubscribers = new Map<EntityId, Set<Subscriber<Trip | null>>>();
  private readonly memberSubscribers = new Map<EntityId, Set<Subscriber<TripMember[]>>>();
  private readonly participantSubscribers = new Map<EntityId, Set<Subscriber<Participant[]>>>();
  private readonly placeSubscribers = new Map<EntityId, Set<Subscriber<Place[]>>>();
  private readonly itinerarySubscribers = new Map<EntityId, Set<Subscriber<ItineraryItem[]>>>();
  private readonly expenseSubscribers = new Map<EntityId, Set<Subscriber<Expense[]>>>();

  constructor(seed: TripRepositorySeed, options: InMemoryRepositoriesOptions = {}) {
    this.state = clone(seed);
    this.getActorUid = options.getActorUid ?? (() => this.state.userProfiles[0]?.uid ?? null);
    this.now = options.now ?? Date.now;

    let nextId = 1;
    this.idFactory = options.idFactory ?? ((kind) => `mock-${kind}-${nextId++}`);

    this.userProfiles = {
      subscribeUserProfile: (uid, onData, onError) =>
        this.subscribe(
          this.userSubscribers,
          uid,
          () => this.state.userProfiles.find((profile) => profile.uid === uid) ?? null,
          onData,
          onError,
        ),
      upsertUserProfile: (uid, input) => this.upsertUserProfile(uid, input),
    };

    this.trips = {
      subscribeTrip: (tripId, onData, onError) =>
        this.subscribe(
          this.tripSubscribers,
          tripId,
          () => this.state.trips.find((trip) => trip.id === tripId) ?? null,
          onData,
          onError,
        ),
      updateTrip: (tripId, input) => this.updateTrip(tripId, input),
    };

    this.members = {
      subscribeMembers: (tripId, onData, onError) =>
        this.subscribe(
          this.memberSubscribers,
          tripId,
          () =>
            this.state.members
              .filter((member) => member.tripId === tripId)
              .sort(
                (left, right) =>
                  left.joinedAt - right.joinedAt || left.uid.localeCompare(right.uid),
              ),
          onData,
          onError,
        ),
    };

    this.participants = {
      subscribeParticipants: (tripId, onData, onError) =>
        this.subscribe(
          this.participantSubscribers,
          tripId,
          () =>
            sortById(
              this.state.participants.filter((participant) => participant.tripId === tripId),
            ),
          onData,
          onError,
        ),
      createParticipant: (tripId, input) => this.createParticipant(tripId, input),
      updateParticipant: (tripId, id, input) => this.updateParticipant(tripId, id, input),
      deleteParticipant: (tripId, id) => this.deleteParticipant(tripId, id),
    };

    this.places = {
      subscribePlaces: (tripId, onData, onError) =>
        this.subscribe(
          this.placeSubscribers,
          tripId,
          () => sortById(this.state.places.filter((place) => place.tripId === tripId)),
          onData,
          onError,
        ),
      createPlace: (tripId, input) => this.createPlace(tripId, input),
      updatePlace: (tripId, id, input) => this.updatePlace(tripId, id, input),
      deletePlace: (tripId, id) => this.deletePlace(tripId, id),
    };

    this.itinerary = {
      subscribeItinerary: (tripId, onData, onError) =>
        this.subscribe(
          this.itinerarySubscribers,
          tripId,
          () =>
            this.state.itinerary
              .filter((item) => item.tripId === tripId)
              .sort(
                (left, right) =>
                  left.date.localeCompare(right.date) ||
                  left.order - right.order ||
                  left.id.localeCompare(right.id),
              ),
          onData,
          onError,
        ),
      createItineraryItem: (tripId, input) => this.createItineraryItem(tripId, input),
      updateItineraryItem: (tripId, id, input) => this.updateItineraryItem(tripId, id, input),
      deleteItineraryItem: (tripId, id) => this.deleteItineraryItem(tripId, id),
    };

    this.expenses = {
      subscribeExpenses: (tripId, onData, onError) =>
        this.subscribe(
          this.expenseSubscribers,
          tripId,
          () =>
            this.state.expenses
              .filter((expense) => expense.tripId === tripId)
              .sort(
                (left, right) =>
                  left.expenseDate.localeCompare(right.expenseDate) ||
                  left.createdAt - right.createdAt ||
                  left.id.localeCompare(right.id),
              ),
          onData,
          onError,
        ),
      createExpense: (tripId, input) => this.createExpense(tripId, input),
      updateExpense: (tripId, id, input) => this.updateExpense(tripId, id, input),
      deleteExpense: (tripId, id) => this.deleteExpense(tripId, id),
    };
  }

  snapshot(): TripRepositorySeed {
    return clone(this.state);
  }

  private subscribe<K, T>(
    registry: Map<K, Set<Subscriber<T>>>,
    key: K,
    read: () => T,
    onData: OnData<T>,
    onError: OnError,
  ): Unsubscribe {
    const subscriber = { onData, onError };
    const subscribers = registry.get(key) ?? new Set<Subscriber<T>>();
    subscribers.add(subscriber);
    registry.set(key, subscribers);

    try {
      onData(clone(read()));
    } catch (error) {
      onError(
        createAppError("unknown", "mock 데이터를 읽지 못했습니다.", {
          retryable: false,
          details: { cause: String(error) },
        }),
      );
    }

    return () => {
      subscribers.delete(subscriber);
      if (subscribers.size === 0) {
        registry.delete(key);
      }
    };
  }

  private emit<K, T>(registry: Map<K, Set<Subscriber<T>>>, key: K, read: () => T): void {
    const subscribers = registry.get(key);
    if (subscribers === undefined) {
      return;
    }

    for (const subscriber of subscribers) {
      try {
        subscriber.onData(clone(read()));
      } catch (error) {
        subscriber.onError(
          createAppError("unknown", "mock 데이터를 읽지 못했습니다.", {
            retryable: false,
            details: { cause: String(error) },
          }),
        );
      }
    }
  }

  private requireActorUid(): string {
    const actorUid = this.getActorUid();
    if (actorUid === null || actorUid.trim().length === 0) {
      throw createAppError("unauthenticated", "로그인이 필요합니다.", {
        retryable: false,
      });
    }

    return actorUid;
  }

  private requireTrip(tripId: EntityId): void {
    if (!this.state.trips.some((trip) => trip.id === tripId)) {
      throw notFound("여행", tripId);
    }
  }

  private async upsertUserProfile(
    uid: string,
    input: UpsertUserProfileInput,
  ): Promise<UserProfile> {
    const actorUid = this.requireActorUid();
    if (actorUid !== uid) {
      throw createAppError("permission-denied", "다른 사용자의 프로필은 수정할 수 없습니다.", {
        retryable: false,
      });
    }

    const timestamp = this.now();
    const index = this.state.userProfiles.findIndex((profile) => profile.uid === uid);
    const profile: UserProfile = {
      uid,
      ...clone(input),
      createdAt: index === -1 ? timestamp : this.state.userProfiles[index].createdAt,
      updatedAt: timestamp,
    };

    if (index === -1) {
      this.state.userProfiles.push(profile);
    } else {
      this.state.userProfiles[index] = profile;
    }

    this.emit(
      this.userSubscribers,
      uid,
      () => this.state.userProfiles.find((value) => value.uid === uid) ?? null,
    );
    return clone(profile);
  }

  private async updateTrip(tripId: EntityId, input: UpdateTripInput): Promise<void> {
    this.requireActorUid();
    const trip = this.state.trips.find((value) => value.id === tripId);
    if (trip === undefined) {
      throw notFound("여행", tripId);
    }

    Object.assign(trip, clone(input), { updatedAt: this.now() });
    this.emit(
      this.tripSubscribers,
      tripId,
      () => this.state.trips.find((value) => value.id === tripId) ?? null,
    );
  }

  private async createParticipant(
    tripId: EntityId,
    input: CreateParticipantInput,
  ): Promise<Participant> {
    this.requireActorUid();
    this.requireTrip(tripId);
    this.assertLinkedUidAvailable(tripId, input.linkedUid);
    const timestamp = this.now();
    const participant: Participant = {
      id: this.idFactory("participant"),
      tripId,
      ...clone(input),
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.state.participants.push(participant);
    this.emitParticipants(tripId);
    return clone(participant);
  }

  private async updateParticipant(
    tripId: EntityId,
    id: EntityId,
    input: UpdateParticipantInput,
  ): Promise<void> {
    this.requireActorUid();
    const participant = this.state.participants.find(
      (value) => value.tripId === tripId && value.id === id,
    );
    if (participant === undefined) {
      throw notFound("참여자", id);
    }

    this.assertLinkedUidAvailable(tripId, input.linkedUid, id);
    Object.assign(participant, clone(input), { updatedAt: this.now() });
    this.emitParticipants(tripId);
  }

  private async deleteParticipant(tripId: EntityId, id: EntityId): Promise<void> {
    this.requireActorUid();
    const index = this.state.participants.findIndex(
      (value) => value.tripId === tripId && value.id === id,
    );
    if (index === -1) {
      throw notFound("참여자", id);
    }

    const referenced = this.state.expenses.some(
      (expense) =>
        expense.tripId === tripId &&
        (expense.payer.participantId === id || expense.consumers.includes(id)),
    );
    if (referenced) {
      throw createAppError(
        "conflict",
        "지출에서 사용 중인 참여자는 삭제할 수 없습니다. 대신 비활성화해 주세요.",
        { retryable: false, details: { participantId: id } },
      );
    }

    this.state.participants.splice(index, 1);
    this.emitParticipants(tripId);
  }

  private assertLinkedUidAvailable(
    tripId: EntityId,
    linkedUid: string | undefined,
    exceptParticipantId?: EntityId,
  ): void {
    if (linkedUid === undefined) {
      return;
    }

    const isMember = this.state.members.some(
      (member) => member.tripId === tripId && member.uid === linkedUid,
    );
    if (!isMember) {
      throw createAppError("invalid-argument", "연결할 여행 멤버를 찾을 수 없습니다.", {
        retryable: false,
        field: "linkedUid",
      });
    }

    const duplicated = this.state.participants.some(
      (participant) =>
        participant.tripId === tripId &&
        participant.id !== exceptParticipantId &&
        participant.linkedUid === linkedUid,
    );
    if (duplicated) {
      throw createAppError(
        "conflict",
        "한 여행 멤버는 하나의 정산 참여자에만 연결할 수 있습니다.",
        { retryable: false, field: "linkedUid" },
      );
    }
  }

  private emitParticipants(tripId: EntityId): void {
    this.emit(this.participantSubscribers, tripId, () =>
      sortById(this.state.participants.filter((participant) => participant.tripId === tripId)),
    );
  }

  private async createPlace(tripId: EntityId, input: CreatePlaceInput): Promise<Place> {
    const actorUid = this.requireActorUid();
    this.requireTrip(tripId);
    const timestamp = this.now();
    const place: Place = {
      id: this.idFactory("place"),
      tripId,
      ...clone(input),
      addedBy: actorUid,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.state.places.push(place);
    this.emitPlaces(tripId);
    return clone(place);
  }

  private async updatePlace(
    tripId: EntityId,
    id: EntityId,
    input: UpdatePlaceInput,
  ): Promise<void> {
    this.requireActorUid();
    const place = this.state.places.find((value) => value.tripId === tripId && value.id === id);
    if (place === undefined) {
      throw notFound("장소", id);
    }

    Object.assign(place, clone(input), { updatedAt: this.now() });
    this.emitPlaces(tripId);
  }

  private async deletePlace(tripId: EntityId, id: EntityId): Promise<void> {
    this.requireActorUid();
    const index = this.state.places.findIndex(
      (value) => value.tripId === tripId && value.id === id,
    );
    if (index === -1) {
      throw notFound("장소", id);
    }

    this.state.places.splice(index, 1);
    this.emitPlaces(tripId);
  }

  private emitPlaces(tripId: EntityId): void {
    this.emit(this.placeSubscribers, tripId, () =>
      sortById(this.state.places.filter((place) => place.tripId === tripId)),
    );
  }

  private async createItineraryItem(
    tripId: EntityId,
    input: CreateItineraryItemInput,
  ): Promise<ItineraryItem> {
    const actorUid = this.requireActorUid();
    this.requireTrip(tripId);
    const item: ItineraryItem = {
      id: this.idFactory("itinerary"),
      tripId,
      ...clone(input),
      updatedBy: actorUid,
      updatedAt: this.now(),
    };
    this.state.itinerary.push(item);
    this.emitItinerary(tripId);
    return clone(item);
  }

  private async updateItineraryItem(
    tripId: EntityId,
    id: EntityId,
    input: UpdateItineraryItemInput,
  ): Promise<void> {
    const actorUid = this.requireActorUid();
    const item = this.state.itinerary.find((value) => value.tripId === tripId && value.id === id);
    if (item === undefined) {
      throw notFound("일정", id);
    }

    Object.assign(item, clone(input), {
      updatedBy: actorUid,
      updatedAt: this.now(),
    });
    this.emitItinerary(tripId);
  }

  private async deleteItineraryItem(tripId: EntityId, id: EntityId): Promise<void> {
    this.requireActorUid();
    const index = this.state.itinerary.findIndex(
      (value) => value.tripId === tripId && value.id === id,
    );
    if (index === -1) {
      throw notFound("일정", id);
    }

    this.state.itinerary.splice(index, 1);
    this.emitItinerary(tripId);
  }

  private emitItinerary(tripId: EntityId): void {
    this.emit(this.itinerarySubscribers, tripId, () =>
      this.state.itinerary
        .filter((item) => item.tripId === tripId)
        .sort(
          (left, right) =>
            left.date.localeCompare(right.date) ||
            left.order - right.order ||
            left.id.localeCompare(right.id),
        ),
    );
  }

  private async createExpense(tripId: EntityId, input: CreateExpenseInput): Promise<Expense> {
    const actorUid = this.requireActorUid();
    this.requireTrip(tripId);
    const timestamp = this.now();
    const expense: Expense = {
      id: this.idFactory("expense"),
      tripId,
      ...clone(input),
      createdBy: actorUid,
      updatedBy: actorUid,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.state.expenses.push(expense);
    this.emitExpenses(tripId);
    return clone(expense);
  }

  private async updateExpense(
    tripId: EntityId,
    id: EntityId,
    input: UpdateExpenseInput,
  ): Promise<void> {
    const actorUid = this.requireActorUid();
    const expense = this.state.expenses.find((value) => value.tripId === tripId && value.id === id);
    if (expense === undefined) {
      throw notFound("지출", id);
    }

    Object.assign(expense, clone(input), {
      updatedBy: actorUid,
      updatedAt: this.now(),
    });
    this.emitExpenses(tripId);
  }

  private async deleteExpense(tripId: EntityId, id: EntityId): Promise<void> {
    this.requireActorUid();
    const index = this.state.expenses.findIndex(
      (value) => value.tripId === tripId && value.id === id,
    );
    if (index === -1) {
      throw notFound("지출", id);
    }

    this.state.expenses.splice(index, 1);
    this.emitExpenses(tripId);
  }

  private emitExpenses(tripId: EntityId): void {
    this.emit(this.expenseSubscribers, tripId, () =>
      this.state.expenses
        .filter((expense) => expense.tripId === tripId)
        .sort(
          (left, right) =>
            left.expenseDate.localeCompare(right.expenseDate) ||
            left.createdAt - right.createdAt ||
            left.id.localeCompare(right.id),
        ),
    );
  }
}

export function createInMemoryTripRepositories(
  seed: TripRepositorySeed,
  options?: InMemoryRepositoriesOptions,
): InMemoryTripRepositories {
  return new InMemoryTripRepositories(seed, options);
}
