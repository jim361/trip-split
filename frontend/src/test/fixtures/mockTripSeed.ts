import type { TripRepositorySeed } from "../../services/repositories";
import { gangneungTripRepositorySeed } from "./gangneungTrip";
import { tokyoTripRepositorySeed } from "./tokyoTrip";

export const mockTripRepositorySeed: TripRepositorySeed = {
  userProfiles: [...gangneungTripRepositorySeed.userProfiles],
  trips: [...gangneungTripRepositorySeed.trips, ...tokyoTripRepositorySeed.trips],
  members: [...gangneungTripRepositorySeed.members, ...tokyoTripRepositorySeed.members],
  participants: [
    ...gangneungTripRepositorySeed.participants,
    ...tokyoTripRepositorySeed.participants,
  ],
  places: [...gangneungTripRepositorySeed.places, ...tokyoTripRepositorySeed.places],
  itinerary: [...gangneungTripRepositorySeed.itinerary, ...tokyoTripRepositorySeed.itinerary],
  expenses: [...gangneungTripRepositorySeed.expenses, ...tokyoTripRepositorySeed.expenses],
  shareCodes: [...gangneungTripRepositorySeed.shareCodes, ...tokyoTripRepositorySeed.shareCodes],
};
