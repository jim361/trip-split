import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, type Auth } from "firebase/auth";
import { connectFirestoreEmulator, getFirestore, type Firestore } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, type Functions } from "firebase/functions";

import { createAppError } from "../../shared/contracts";

export type FirebaseClient = {
  app: FirebaseApp;
  auth: Auth;
  firestore: Firestore;
  functions: Functions;
};

let client: FirebaseClient | undefined;
let emulatorsConnected = false;

type FirebaseConfigKey =
  "VITE_FIREBASE_API_KEY" | "VITE_FIREBASE_AUTH_DOMAIN" | "VITE_FIREBASE_PROJECT_ID";

function isEmulatorEnabled() {
  return import.meta.env.VITE_USE_FIREBASE_EMULATORS === "true";
}

function getConfigValue(key: FirebaseConfigKey, fallback?: string): string {
  const value = import.meta.env[key] ?? fallback;

  if (!value) {
    throw createAppError("invalid-argument", `Firebase 환경변수 ${key}가 필요합니다.`, {
      retryable: false,
      field: key,
    });
  }

  return value;
}

export function getFirebaseClient(): FirebaseClient {
  if (client) {
    return client;
  }

  const emulator = isEmulatorEnabled();
  const projectId = getConfigValue(
    "VITE_FIREBASE_PROJECT_ID",
    emulator ? "demo-trip-split" : undefined,
  );
  const app = getApps().length
    ? getApp()
    : initializeApp({
        apiKey: getConfigValue("VITE_FIREBASE_API_KEY", emulator ? "demo-api-key" : undefined),
        authDomain: getConfigValue("VITE_FIREBASE_AUTH_DOMAIN", emulator ? "localhost" : undefined),
        projectId,
        storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
        messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
        appId: import.meta.env.VITE_FIREBASE_APP_ID,
      });

  const auth = getAuth(app);
  const firestore = getFirestore(app);
  const functions = getFunctions(
    app,
    import.meta.env.VITE_FIREBASE_FUNCTIONS_REGION ?? "asia-northeast3",
  );

  if (emulator && !emulatorsConnected) {
    connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
    connectFirestoreEmulator(firestore, "127.0.0.1", 8080);
    connectFunctionsEmulator(functions, "127.0.0.1", 5001);
    emulatorsConnected = true;
  }

  client = { app, auth, firestore, functions };
  return client;
}
