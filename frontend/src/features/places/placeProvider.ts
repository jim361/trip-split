import type { EntityId } from "../../shared/contracts";
import type { Place } from "../../shared/types";

export type PlaceCandidate = Omit<Place, "id" | "tripId" | "createdAt" | "updatedAt" | "addedBy">;

export interface PlaceProvider {
  searchPlaces(query: string): Promise<PlaceCandidate[]>;
  parsePlaceLink(url: string): Promise<PlaceCandidate[]>;
  getPlaceDetail(providerPlaceId: EntityId): Promise<PlaceCandidate>;
}

export class MockPlaceProvider implements PlaceProvider {
  constructor(private readonly candidates: PlaceCandidate[]) {}

  async searchPlaces(query: string): Promise<PlaceCandidate[]> {
    const normalized = query.trim().toLocaleLowerCase("ko-KR");
    return this.candidates.filter((candidate) =>
      `${candidate.name} ${candidate.address ?? ""}`
        .toLocaleLowerCase("ko-KR")
        .includes(normalized),
    );
  }

  async parsePlaceLink(): Promise<PlaceCandidate[]> {
    return this.candidates.slice(0, 1);
  }

  async getPlaceDetail(providerPlaceId: EntityId): Promise<PlaceCandidate> {
    const candidate = this.candidates.find((value) => value.providerPlaceId === providerPlaceId);
    if (!candidate) {
      throw new Error("mock 장소를 찾을 수 없습니다.");
    }
    return candidate;
  }
}
