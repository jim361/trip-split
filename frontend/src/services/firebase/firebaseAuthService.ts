import {
  GoogleAuthProvider,
  linkWithPopup,
  onAuthStateChanged,
  signInAnonymously,
  type User,
} from "firebase/auth";
import { doc, getDoc, serverTimestamp, setDoc } from "firebase/firestore";

import type { AuthErrorListener, AuthService, AuthStateListener, AuthUser } from "../auth";
import { createAppError } from "../../shared/contracts";
import { getFirebaseClient } from "./client";
import { mapFirebaseError } from "./errorMapper";

function toAuthUser(user: User): AuthUser {
  return {
    uid: user.uid,
    displayName: user.displayName?.trim() || `여행자 ${user.uid.slice(0, 6)}`,
    ...(user.email ? { email: user.email } : {}),
    ...(user.photoURL ? { photoURL: user.photoURL } : {}),
    isAnonymous: user.isAnonymous,
  };
}

async function upsertUserProfile(user: User): Promise<void> {
  const { firestore } = getFirebaseClient();
  const reference = doc(firestore, "users", user.uid);
  const snapshot = await getDoc(reference);
  const value = toAuthUser(user);

  await setDoc(
    reference,
    {
      displayName: value.displayName,
      ...(value.email ? { email: value.email } : {}),
      ...(value.photoURL ? { photoURL: value.photoURL } : {}),
      authProvider: value.isAnonymous ? "anonymous" : "google",
      ...(snapshot.exists() ? {} : { createdAt: serverTimestamp() }),
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  );
}

export class FirebaseAuthService implements AuthService {
  subscribe(listener: AuthStateListener, onError: AuthErrorListener) {
    const { auth } = getFirebaseClient();
    return onAuthStateChanged(
      auth,
      (user) => listener(user ? toAuthUser(user) : null),
      (error) => onError(mapFirebaseError(error)),
    );
  }

  async ensureAnonymousSession(): Promise<AuthUser> {
    try {
      const { auth } = getFirebaseClient();
      const user = auth.currentUser ?? (await signInAnonymously(auth)).user;
      await upsertUserProfile(user);
      return toAuthUser(user);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  async linkGoogleAccount(): Promise<AuthUser> {
    try {
      const { auth } = getFirebaseClient();
      const currentUser = auth.currentUser;

      if (!currentUser) {
        throw createAppError("unauthenticated", "로그인 세션이 필요합니다.", {
          retryable: false,
        });
      }

      if (!currentUser.isAnonymous) {
        return toAuthUser(currentUser);
      }

      const provider = new GoogleAuthProvider();
      provider.setCustomParameters({ prompt: "select_account" });
      const linked = await linkWithPopup(currentUser, provider);
      await upsertUserProfile(linked.user);
      return toAuthUser(linked.user);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}
