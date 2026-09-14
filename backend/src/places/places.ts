import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { appError, requireTripMember } from "../shared/callable";
import { asRecord, requireDocumentId, requireString } from "../shared/input";

export const demoPlaces = [
  { name: "나리타 국제공항", address: "Narita, Chiba, Japan", lat: 35.772, lng: 140.3929 },
  { name: "우에노역", address: "Ueno, Taito City, Tokyo", lat: 35.7138, lng: 139.7773 },
  { name: "우에노 숙소", address: "Taito City, Tokyo", lat: 35.711, lng: 139.779 },
  { name: "센소지", address: "Asakusa, Taito City, Tokyo", lat: 35.7148, lng: 139.7967 },
].map((place) => ({ ...place, provider: "google", source: "googleSearch" }));

export function searchDemoPlaces(query: string) {
  const text = query.trim().toLowerCase();
  return demoPlaces.filter((p) => `${p.name} ${p.address}`.toLowerCase().includes(text));
}

export function googleLinkQuery(value: string): string {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw appError("invalid-argument", "Google Maps 링크를 확인해 주세요.", { field: "sourceUrl" });
  }
  const allowedHost = ["maps.google.com", "www.google.com", "google.com"].includes(url.hostname);
  const allowedPath = url.hostname === "maps.google.com" || /^\/maps(?:\/|$)/.test(url.pathname);
  const query = url.searchParams.get("query") ?? url.searchParams.get("q");
  if (
    !allowedHost ||
    !allowedPath ||
    url.protocol !== "https:" ||
    url.username ||
    url.password ||
    url.port ||
    !query?.trim()
  ) {
    throw appError(
      "invalid-argument",
      "장소 검색어가 있는 일반 Google Maps 링크를 사용해 주세요. 단축 링크는 직접 검색해 주세요.",
      { field: "sourceUrl" },
    );
  }
  return query.trim();
}

async function checkProvider(tripId: string) {
  const trip = await getFirestore().doc(`trips/${tripId}`).get();
  if (trip.data()?.mapProvider !== "google")
    throw appError("invalid-argument", "Google 지도 여행만 지원합니다.");
  // 실제 provider 승인 전에는 Emulator에서만 fixture를 반환합니다.
  if (process.env.FUNCTIONS_EMULATOR !== "true") {
    throw appError(
      "unavailable",
      "장소 검색 연결이 준비되지 않았습니다. 직접 입력을 사용해 주세요.",
      { retryable: false },
    );
  }
}

export const searchPlaces = onCall(async (request) => {
  const input = asRecord(request.data);
  const tripId = requireDocumentId(input, "tripId");
  await requireTripMember(request, tripId);
  const query = requireString(input, "query", { maxLength: 160 });
  await checkProvider(tripId);
  return searchDemoPlaces(query);
});

export const parsePlaceLink = onCall(async (request) => {
  const input = asRecord(request.data);
  const tripId = requireDocumentId(input, "tripId");
  await requireTripMember(request, tripId);
  const url = requireString(input, "url", { maxLength: 2048 });
  const query = googleLinkQuery(url);
  await checkProvider(tripId);
  const candidate = searchDemoPlaces(query)[0];
  if (!candidate)
    throw appError(
      "not-found",
      "링크에서 장소를 찾지 못했습니다. 검색이나 직접 입력을 사용해 주세요.",
      { field: "sourceUrl" },
    );
  return { ...candidate, source: "googleMapsUrl", sourceUrl: url };
});
