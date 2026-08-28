import { createContext, useContext, useEffect, useState, type ReactNode } from "react";

import type { AppError, EntityId } from "../../shared/contracts";
import type {
  Expense,
  ItineraryItem,
  Participant,
  Place,
  Trip,
  TripMember,
} from "../../shared/types";
import { useAuth } from "./AuthProvider";
import { usePlatformServices, type DataSource } from "./PlatformServicesProvider";

export type TripContextValue = {
  tripId: EntityId;
  trip: Trip | null;
  members: TripMember[];
  participants: Participant[];
  places: Place[];
  itinerary: ItineraryItem[];
  expenses: Expense[];
  isLoading: boolean;
  error: AppError | null;
  dataSource: DataSource;
};

const TripContext = createContext<TripContextValue | null>(null);

type TripDataState = Pick<
  TripContextValue,
  "trip" | "members" | "participants" | "places" | "itinerary" | "expenses"
>;

const EMPTY_DATA: TripDataState = {
  trip: null,
  members: [] as TripMember[],
  participants: [] as Participant[],
  places: [] as Place[],
  itinerary: [] as ItineraryItem[],
  expenses: [] as Expense[],
};

export function TripProvider({ tripId, children }: { tripId: EntityId; children: ReactNode }) {
  const { repositories, dataSource } = usePlatformServices();
  const { user, status: authStatus } = useAuth();
  const [data, setData] = useState(EMPTY_DATA);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<AppError | null>(null);

  useEffect(() => {
    if (authStatus !== "ready" || !user) return;

    let active = true;
    const pending = new Set(["trip", "members", "participants", "places", "itinerary", "expenses"]);
    const complete = (key: string) => {
      pending.delete(key);
      if (active && pending.size === 0) setIsLoading(false);
    };
    const onError = (nextError: AppError) => {
      if (!active) return;
      setError(nextError);
      setIsLoading(false);
    };

    const subscriptions = [
      repositories.trips.subscribeTrip(
        tripId,
        (trip) => {
          if (active) setData((current) => ({ ...current, trip }));
          complete("trip");
        },
        onError,
      ),
      repositories.members.subscribeMembers(
        tripId,
        (members) => {
          if (active) setData((current) => ({ ...current, members }));
          complete("members");
        },
        onError,
      ),
      repositories.participants.subscribeParticipants(
        tripId,
        (participants) => {
          if (active) setData((current) => ({ ...current, participants }));
          complete("participants");
        },
        onError,
      ),
      repositories.places.subscribePlaces(
        tripId,
        (places) => {
          if (active) setData((current) => ({ ...current, places }));
          complete("places");
        },
        onError,
      ),
      repositories.itinerary.subscribeItinerary(
        tripId,
        (itinerary) => {
          if (active) setData((current) => ({ ...current, itinerary }));
          complete("itinerary");
        },
        onError,
      ),
      repositories.expenses.subscribeExpenses(
        tripId,
        (expenses) => {
          if (active) setData((current) => ({ ...current, expenses }));
          complete("expenses");
        },
        onError,
      ),
    ];

    return () => {
      active = false;
      subscriptions.forEach((unsubscribe) => unsubscribe());
    };
  }, [authStatus, repositories, tripId, user]);

  return (
    <TripContext.Provider value={{ tripId, ...data, isLoading, error, dataSource }}>
      {children}
    </TripContext.Provider>
  );
}

export function useTripContext(): TripContextValue {
  const value = useContext(TripContext);
  if (!value) throw new Error("TripProvider가 필요합니다.");
  return value;
}
