import type { EntityId, OnData, OnError, Unsubscribe } from "../../shared/contracts";
import type {
  Expense,
  ItineraryItem,
  Participant,
  Place,
  ShareCode,
  Trip,
  TripMember,
  UserProfile,
} from "../../shared/types";

export type UpdateTripInput = Partial<
  Pick<Trip, "title" | "regionType" | "currency" | "startDate" | "endDate">
>;

export type UpsertUserProfileInput = Omit<UserProfile, "uid" | "createdAt" | "updatedAt">;

export type CreateParticipantInput = Omit<Participant, "id" | "tripId" | "createdAt" | "updatedAt">;
export type UpdateParticipantInput = Partial<CreateParticipantInput>;

export type CreatePlaceInput = Omit<Place, "id" | "tripId" | "addedBy" | "createdAt" | "updatedAt">;
export type UpdatePlaceInput = Partial<CreatePlaceInput>;

export type CreateItineraryItemInput = Omit<
  ItineraryItem,
  "id" | "tripId" | "updatedBy" | "updatedAt"
>;
export type UpdateItineraryItemInput = Partial<CreateItineraryItemInput>;

export type CreateExpenseInput = Omit<
  Expense,
  "id" | "tripId" | "createdBy" | "updatedBy" | "createdAt" | "updatedAt"
>;
export type UpdateExpenseInput = Partial<CreateExpenseInput>;

export interface UserProfilesRepository {
  subscribeUserProfile(
    uid: string,
    onData: OnData<UserProfile | null>,
    onError: OnError,
  ): Unsubscribe;
  upsertUserProfile(uid: string, input: UpsertUserProfileInput): Promise<UserProfile>;
}

/**
 * Trip creation and share-code rotation are callable Function operations.
 * This repository intentionally exposes only realtime reads and safe metadata edits.
 */
export interface TripsRepository {
  subscribeTrip(tripId: EntityId, onData: OnData<Trip | null>, onError: OnError): Unsubscribe;
  updateTrip(tripId: EntityId, input: UpdateTripInput): Promise<void>;
}

/** Membership writes are owned by createTrip/joinTrip callable Functions. */
export interface MembersRepository {
  subscribeMembers(tripId: EntityId, onData: OnData<TripMember[]>, onError: OnError): Unsubscribe;
}

export interface ParticipantsRepository {
  subscribeParticipants(
    tripId: EntityId,
    onData: OnData<Participant[]>,
    onError: OnError,
  ): Unsubscribe;
  createParticipant(tripId: EntityId, input: CreateParticipantInput): Promise<Participant>;
  updateParticipant(tripId: EntityId, id: EntityId, input: UpdateParticipantInput): Promise<void>;
  deleteParticipant(tripId: EntityId, id: EntityId): Promise<void>;
}

export interface PlacesRepository {
  subscribePlaces(tripId: EntityId, onData: OnData<Place[]>, onError: OnError): Unsubscribe;
  createPlace(tripId: EntityId, input: CreatePlaceInput): Promise<Place>;
  updatePlace(tripId: EntityId, id: EntityId, input: UpdatePlaceInput): Promise<void>;
  deletePlace(tripId: EntityId, id: EntityId): Promise<void>;
}

export interface ItineraryRepository {
  subscribeItinerary(
    tripId: EntityId,
    onData: OnData<ItineraryItem[]>,
    onError: OnError,
  ): Unsubscribe;
  createItineraryItem(tripId: EntityId, input: CreateItineraryItemInput): Promise<ItineraryItem>;
  updateItineraryItem(
    tripId: EntityId,
    id: EntityId,
    input: UpdateItineraryItemInput,
  ): Promise<void>;
  deleteItineraryItem(tripId: EntityId, id: EntityId): Promise<void>;
}

export interface ExpensesRepository {
  subscribeExpenses(tripId: EntityId, onData: OnData<Expense[]>, onError: OnError): Unsubscribe;
  createExpense(tripId: EntityId, input: CreateExpenseInput): Promise<Expense>;
  updateExpense(tripId: EntityId, id: EntityId, input: UpdateExpenseInput): Promise<void>;
  deleteExpense(tripId: EntityId, id: EntityId): Promise<void>;
}

export interface TripRepositories {
  userProfiles: UserProfilesRepository;
  trips: TripsRepository;
  members: MembersRepository;
  participants: ParticipantsRepository;
  places: PlacesRepository;
  itinerary: ItineraryRepository;
  expenses: ExpensesRepository;
}

/** Serializable data used to seed mocks and emulator helpers. */
export type TripRepositorySeed = {
  userProfiles: UserProfile[];
  trips: Trip[];
  members: TripMember[];
  participants: Participant[];
  places: Place[];
  itinerary: ItineraryItem[];
  expenses: Expense[];
  shareCodes: ShareCode[];
};
