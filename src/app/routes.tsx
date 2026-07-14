import { BrowserRouter, Navigate, Route, Routes, useParams } from "react-router-dom";

import { HomePage } from "../pages/HomePage";
import { NotFoundPage } from "../pages/NotFoundPage";
import { ItineraryPage } from "../pages/trip/ItineraryPage";
import { MapPage } from "../pages/trip/MapPage";
import { ReceiptsPage } from "../pages/trip/ReceiptsPage";
import { SettlementPage } from "../pages/trip/SettlementPage";
import { ConnectedTripShell } from "../pages/trip/ConnectedTripShell";
import { TripProvider } from "./providers";

function TripRoute() {
  const { tripId } = useParams<{ tripId: string }>();

  if (!tripId) return <Navigate to="/" replace />;

  return (
    <TripProvider key={tripId} tripId={tripId}>
      <ConnectedTripShell />
    </TripProvider>
  );
}

/**
 * Router-agnostic route tree. Tests and embedded hosts can provide their own
 * router while the production entry point uses AppRouter below.
 */
export function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/trips/:tripId" element={<TripRoute />}>
        <Route index element={<Navigate to="itinerary" replace />} />
        <Route path="itinerary" element={<ItineraryPage />} />
        <Route path="map" element={<MapPage />} />
        <Route path="settlement" element={<SettlementPage />} />
        <Route path="receipts" element={<ReceiptsPage />} />
      </Route>
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}

export function AppRouter() {
  return (
    <BrowserRouter basename={import.meta.env.BASE_URL}>
      <AppRoutes />
    </BrowserRouter>
  );
}
