import { httpsCallable } from "firebase/functions";

import type { AppError } from "../../shared/contracts";
import { gangneungTripFixture } from "../../test/fixtures/gangneungTrip";
import { getFirebaseClient } from "../firebase/client";
import { mapFirebaseError } from "../firebase/errorMapper";

export type CreateTripCommand = {
  title: string;
  startDate: string;
  endDate: string;
  displayName?: string;
};

export type CreateTripResult = {
  tripId: string;
  shareCode: string;
};

export type JoinTripResult = CreateTripResult & {
  title: string;
};

export interface TripSessionService {
  createTrip(input: CreateTripCommand): Promise<CreateTripResult>;
  createShareCode(tripId: string): Promise<CreateTripResult>;
  joinTrip(shareCode: string, displayName?: string): Promise<JoinTripResult>;
}

async function call<Input, Output>(name: string, input: Input): Promise<Output> {
  try {
    const callable = httpsCallable<Input, Output>(getFirebaseClient().functions, name);
    return (await callable(input)).data;
  } catch (error) {
    throw mapFirebaseError(error);
  }
}

export class FirebaseTripSessionService implements TripSessionService {
  createTrip(input: CreateTripCommand) {
    return call<CreateTripCommand, CreateTripResult>("createTrip", input);
  }

  createShareCode(tripId: string) {
    return call<{ tripId: string }, CreateTripResult>("createShareCode", { tripId });
  }

  joinTrip(shareCode: string, displayName?: string) {
    return call<{ shareCode: string; displayName?: string }, JoinTripResult>("joinTrip", {
      shareCode,
      ...(displayName ? { displayName } : {}),
    });
  }
}

export class MockTripSessionService implements TripSessionService {
  async createTrip(): Promise<CreateTripResult> {
    return {
      tripId: gangneungTripFixture.trip.id,
      shareCode: gangneungTripFixture.trip.shareCode,
    };
  }

  async createShareCode(): Promise<CreateTripResult> {
    return {
      tripId: gangneungTripFixture.trip.id,
      shareCode: "GANGNEW",
    };
  }

  async joinTrip(shareCode: string): Promise<JoinTripResult> {
    if (shareCode.trim().toUpperCase() !== gangneungTripFixture.trip.shareCode) {
      const error: AppError = {
        code: "not-found",
        message: "공유 코드를 찾을 수 없습니다.",
        retryable: false,
      };
      throw error;
    }

    return {
      tripId: gangneungTripFixture.trip.id,
      title: gangneungTripFixture.trip.title,
      shareCode: gangneungTripFixture.trip.shareCode,
    };
  }
}
