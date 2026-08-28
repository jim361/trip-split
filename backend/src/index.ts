import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

import { FUNCTIONS_REGION } from "./shared/env";

initializeApp();

setGlobalOptions({
  region: FUNCTIONS_REGION,
  maxInstances: 10,
  concurrency: 40,
});

export { createShareCode, createTrip, joinTrip } from "./share/trips";
