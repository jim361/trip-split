import { httpsCallable } from "firebase/functions";

import type { AppError } from "../../shared/contracts";
import type { CurrencyCode } from "../../shared/types";
import { gangneungTripFixture } from "../../test/fixtures/gangneungTrip";
import { TOKYO_TRIP_ID, tokyoTripFixture } from "../../test/fixtures/tokyoTrip";
import { getFirebaseClient } from "../firebase/client";
import { mapFirebaseError } from "../firebase/errorMapper";
import type { InMemoryTripRepositories } from "../mock";

export type CreateTripCommand = {
  title: string;
  startDate: string;
  endDate: string;
  displayName?: string;
  regionType?: "domestic" | "international";
  currency?: CurrencyCode;
  participantCount?: number;
};

export type CreateTripResult = {
  tripId: string;
  shareCode: string;
};

export type JoinTripResult = CreateTripResult & {
  title: string;
};

/** [TASK-02 · 여행 생성·공유] mock과 Firebase Callable이 함께 지키는 프론트엔드 계약입니다. */
export interface TripSessionService {
  createTrip(input: CreateTripCommand): Promise<CreateTripResult>;
  createShareCode(tripId: string): Promise<CreateTripResult>;
  joinTrip(shareCode: string, displayName?: string): Promise<JoinTripResult>;
}

const DAY_IN_MILLIS = 86_400_000;

function invalidArgument(message: string, field: string): AppError {
  return {
    code: "invalid-argument",
    message,
    retryable: false,
    field,
  };
}

function parseLocalDate(value: string, field: string): number {
  const timestamp = Date.parse(`${value}T00:00:00Z`);
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(value) ||
    Number.isNaN(timestamp) ||
    new Date(timestamp).toISOString().slice(0, 10) !== value
  ) {
    throw invalidArgument("여행 날짜 형식을 확인해 주세요.", field);
  }
  return timestamp;
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
  constructor(private readonly repositories?: InMemoryTripRepositories) {}

  async createTrip(input: CreateTripCommand): Promise<CreateTripResult> {
    const title = input.title.trim();
    if (!title || title.length > 80) {
      throw invalidArgument("여행 이름은 1자부터 80자까지 입력해 주세요.", "title");
    }

    const startAt = parseLocalDate(input.startDate, "startDate");
    const endAt = parseLocalDate(input.endDate, "endDate");
    if (startAt > endAt) {
      throw invalidArgument("종료일은 시작일보다 빠를 수 없습니다.", "endDate");
    }

    const participantCount = input.participantCount ?? 1;
    if (!Number.isInteger(participantCount) || participantCount < 1 || participantCount > 20) {
      throw invalidArgument("정산 인원은 1명부터 20명까지 설정할 수 있습니다.", "participantCount");
    }

    if (this.repositories) {
      await this.repositories.trips.updateTrip(TOKYO_TRIP_ID, {
        title,
        startDate: input.startDate,
        endDate: input.endDate,
        regionType: input.regionType ?? tokyoTripFixture.trip.regionType,
        currency: input.currency ?? tokyoTripFixture.trip.currency,
      });

      const fixtureStartAt = parseLocalDate(tokyoTripFixture.trip.startDate, "startDate");
      const lastDayOffset = Math.floor((endAt - startAt) / DAY_IN_MILLIS);
      const orderByDate = new Map<string, number>();
      for (const item of tokyoTripFixture.itinerary) {
        const fixtureDateAt = parseLocalDate(item.date, "startDate");
        const fixtureDayOffset = Math.floor((fixtureDateAt - fixtureStartAt) / DAY_IN_MILLIS);
        const nextDateAt = startAt + Math.min(fixtureDayOffset, lastDayOffset) * DAY_IN_MILLIS;
        const date = new Date(nextDateAt).toISOString().slice(0, 10);
        const order = orderByDate.get(date) ?? 0;
        orderByDate.set(date, order + 1);
        await this.repositories.itinerary.updateItineraryItem(TOKYO_TRIP_ID, item.id, {
          date,
          order,
        });
      }

      const existing = this.repositories
        .snapshot()
        .participants.filter((participant) => participant.tripId === TOKYO_TRIP_ID)
        .sort(
          (left, right) =>
            Number(Boolean(right.linkedUid)) - Number(Boolean(left.linkedUid)) ||
            left.createdAt - right.createdAt ||
            left.id.localeCompare(right.id),
        );
      const colors = ["#1A73E8", "#E56B6F", "#2A9D8F", "#F4A261", "#7B61FF"];

      for (let index = 0; index < participantCount; index += 1) {
        const current = existing[index];
        const name = index === 0 ? "나" : `동행 ${index + 1}`;
        if (current) {
          await this.repositories.participants.updateParticipant(TOKYO_TRIP_ID, current.id, {
            name,
            isActive: true,
          });
        } else {
          await this.repositories.participants.createParticipant(TOKYO_TRIP_ID, {
            name,
            color: colors[index % colors.length],
            isActive: true,
          });
        }
      }

      for (const participant of existing.slice(participantCount)) {
        await this.repositories.participants.updateParticipant(TOKYO_TRIP_ID, participant.id, {
          isActive: false,
        });
      }
    }

    return {
      tripId: tokyoTripFixture.trip.id,
      shareCode: tokyoTripFixture.trip.shareCode,
    };
  }

  async createShareCode(tripId: string): Promise<CreateTripResult> {
    return {
      tripId,
      shareCode: tripId === TOKYO_TRIP_ID ? "TOKYONEW" : "GANGNEW",
    };
  }

  async joinTrip(shareCode: string): Promise<JoinTripResult> {
    const normalized = shareCode.trim().toUpperCase();
    const fixture =
      normalized === tokyoTripFixture.trip.shareCode
        ? tokyoTripFixture
        : normalized === gangneungTripFixture.trip.shareCode
          ? gangneungTripFixture
          : null;

    if (!fixture) {
      const error: AppError = {
        code: "not-found",
        message: "공유 코드를 찾을 수 없습니다.",
        retryable: false,
      };
      throw error;
    }

    return {
      tripId: fixture.trip.id,
      title: fixture.trip.title,
      shareCode: fixture.trip.shareCode,
    };
  }
}
