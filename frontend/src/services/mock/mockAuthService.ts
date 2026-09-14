import type { AuthService, AuthStateListener, AuthUser } from "../auth";

export class MockAuthService implements AuthService {
  private user: AuthUser;
  private readonly listeners = new Set<AuthStateListener>();

  constructor(
    initialUser: AuthUser = {
      uid: "user-owner",
      displayName: "나",
      isAnonymous: true,
    },
  ) {
    this.user = structuredClone(initialUser);
  }

  subscribe(listener: AuthStateListener) {
    this.listeners.add(listener);
    queueMicrotask(() => listener(structuredClone(this.user)));

    return () => {
      this.listeners.delete(listener);
    };
  }

  async ensureAnonymousSession(): Promise<AuthUser> {
    this.emit();
    return structuredClone(this.user);
  }

  async linkGoogleAccount(): Promise<AuthUser> {
    this.user = {
      ...this.user,
      displayName: "나 (Google 연결)",
      email: "demo@example.com",
      isAnonymous: false,
    };
    this.emit();
    return structuredClone(this.user);
  }

  private emit() {
    for (const listener of this.listeners) {
      listener(structuredClone(this.user));
    }
  }
}
