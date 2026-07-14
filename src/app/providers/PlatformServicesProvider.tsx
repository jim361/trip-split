import { createContext, useContext, useState, type ReactNode } from "react";

import type { AuthService } from "../../services/auth";
import { getFirebaseClient } from "../../services/firebase/client";
import { FirebaseAuthService } from "../../services/firebase/firebaseAuthService";
import { createFirestoreTripRepositories } from "../../services/firebase/firestoreRepositories";
import {
  FirebaseTripSessionService,
  MockTripSessionService,
  type TripSessionService,
} from "../../services/functions/tripSessionService";
import { createInMemoryTripRepositories } from "../../services/mock";
import { MockAuthService } from "../../services/mock/mockAuthService";
import type { TripRepositories } from "../../services/repositories";
import { gangneungTripRepositorySeed } from "../../test/fixtures/gangneungTrip";

export type DataSource = "mock" | "firebase";

export type PlatformServices = {
  dataSource: DataSource;
  auth: AuthService;
  repositories: TripRepositories;
  tripSessions: TripSessionService;
};

const PlatformServicesContext = createContext<PlatformServices | null>(null);

function createDefaultServices(): PlatformServices {
  const dataSource = import.meta.env.VITE_DATA_SOURCE === "firebase" ? "firebase" : "mock";

  if (dataSource === "firebase") {
    const client = getFirebaseClient();
    return {
      dataSource,
      auth: new FirebaseAuthService(),
      repositories: createFirestoreTripRepositories(client.firestore, {
        getActorUid: () => client.auth.currentUser?.uid ?? null,
      }),
      tripSessions: new FirebaseTripSessionService(),
    };
  }

  return {
    dataSource,
    auth: new MockAuthService(),
    repositories: createInMemoryTripRepositories(gangneungTripRepositorySeed, {
      getActorUid: () => "user-owner",
    }),
    tripSessions: new MockTripSessionService(),
  };
}

export function PlatformServicesProvider({
  children,
  services,
}: {
  children: ReactNode;
  services?: PlatformServices;
}) {
  const [value] = useState(() => services ?? createDefaultServices());
  return (
    <PlatformServicesContext.Provider value={value}>{children}</PlatformServicesContext.Provider>
  );
}

export function usePlatformServices(): PlatformServices {
  const services = useContext(PlatformServicesContext);
  if (!services) throw new Error("PlatformServicesProvider가 필요합니다.");
  return services;
}
