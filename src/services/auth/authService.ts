import type { AppError, Unsubscribe } from "../../shared/contracts";

export type AuthUser = {
  uid: string;
  displayName: string;
  email?: string;
  photoURL?: string;
  isAnonymous: boolean;
};

export type AuthStateListener = (user: AuthUser | null) => void;
export type AuthErrorListener = (error: AppError) => void;

export interface AuthService {
  subscribe(listener: AuthStateListener, onError: AuthErrorListener): Unsubscribe;
  ensureAnonymousSession(): Promise<AuthUser>;
  linkGoogleAccount(): Promise<AuthUser>;
}
