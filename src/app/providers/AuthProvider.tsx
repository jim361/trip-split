import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";

import type { AuthUser } from "../../services/auth";
import type { AppError } from "../../shared/contracts";
import { usePlatformServices } from "./PlatformServicesProvider";

export type AuthStatus = "loading" | "ready" | "linking" | "error";

export type AuthContextValue = {
  user: AuthUser | null;
  status: AuthStatus;
  error: AppError | null;
  linkGoogleAccount(): Promise<void>;
  retry(): Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { auth } = usePlatformServices();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [status, setStatus] = useState<AuthStatus>("loading");
  const [error, setError] = useState<AppError | null>(null);

  const startAnonymousSession = useCallback(async () => {
    try {
      const nextUser = await auth.ensureAnonymousSession();
      setUser(nextUser);
      setStatus("ready");
    } catch (nextError) {
      setError(nextError as AppError);
      setStatus("error");
    }
  }, [auth]);

  useEffect(() => {
    const unsubscribe = auth.subscribe(
      (nextUser) => {
        setUser(nextUser);
        if (nextUser) setStatus("ready");
      },
      (nextError) => {
        setError(nextError);
        setStatus("error");
      },
    );
    void auth
      .ensureAnonymousSession()
      .then((nextUser) => {
        setUser(nextUser);
        setStatus("ready");
      })
      .catch((nextError: AppError) => {
        setError(nextError);
        setStatus("error");
      });
    return unsubscribe;
  }, [auth]);

  const linkGoogleAccount = useCallback(async () => {
    setStatus("linking");
    setError(null);
    try {
      const nextUser = await auth.linkGoogleAccount();
      setUser(nextUser);
      setStatus("ready");
    } catch (nextError) {
      setError(nextError as AppError);
      setStatus("error");
    }
  }, [auth]);

  const retry = useCallback(async () => {
    setStatus("loading");
    setError(null);
    await startAnonymousSession();
  }, [startAnonymousSession]);

  return (
    <AuthContext.Provider
      value={{
        user,
        status,
        error,
        linkGoogleAccount,
        retry,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (!value) throw new Error("AuthProvider가 필요합니다.");
  return value;
}
