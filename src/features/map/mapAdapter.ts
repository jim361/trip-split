import type { EntityId } from "../../shared/contracts";
import type { ItineraryItem, Place } from "../../shared/types";

export type MapPin = {
  itineraryItemId: EntityId;
  placeId: EntityId;
  lat: number;
  lng: number;
  label: number;
  date: string;
};

export type MapPolyline = {
  date: string;
  points: Array<{ lat: number; lng: number }>;
};

export type MapRenderModel = {
  pins: MapPin[];
  polylines: MapPolyline[];
};

export interface MapAdapter {
  render(places: Place[], itinerary: ItineraryItem[]): MapRenderModel;
  destroy(): void;
}

/** 실제 NAVER 지도 SDK 어댑터가 소비할 provider-neutral 입력을 만든다. */
export function createMapRenderModel(places: Place[], itinerary: ItineraryItem[]): MapRenderModel {
  const placeById = new Map(places.map((place) => [place.id, place]));
  const ordered = [...itinerary]
    .filter((item) => item.placeId)
    .sort((left, right) => left.date.localeCompare(right.date) || left.order - right.order);
  const dayCounts = new Map<string, number>();
  const pins: MapPin[] = [];

  for (const item of ordered) {
    const place = placeById.get(item.placeId!);
    if (!place || place.lat === undefined || place.lng === undefined) continue;
    const label = (dayCounts.get(item.date) ?? 0) + 1;
    dayCounts.set(item.date, label);
    pins.push({
      itineraryItemId: item.id,
      placeId: place.id,
      lat: place.lat,
      lng: place.lng,
      label,
      date: item.date,
    });
  }

  const polylines = [...new Set(pins.map((pin) => pin.date))].map((date) => ({
    date,
    points: pins.filter((pin) => pin.date === date).map(({ lat, lng }) => ({ lat, lng })),
  }));

  return { pins, polylines };
}
