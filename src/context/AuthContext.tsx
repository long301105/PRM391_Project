"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import { fetchCurrentAccount, login as loginApi, logout as logoutApi } from "@/api/auth";
import type { AccountResponse } from "@/api/types";
import { ApiError } from "@/lib/api";
import { LoginModal } from "@/components/LoginModal";

interface AuthContextValue {
  account: AccountResponse | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  checking: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  requireLogin: () => void;
  refresh: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [account, setAccount] = useState<AccountResponse | null>(null);
  const [checking, setChecking] = useState(true);
  const [loginOpen, setLoginOpen] = useState(false);

  const refresh = useCallback(async () => {
    try {
      setAccount(await fetchCurrentAccount());
    } catch (error) {
      if (!(error instanceof ApiError) || !error.isUnauthorized) {
        console.warn("[auth] không kiểm tra được phiên:", error);
      }
      setAccount(null);
    }
  }, []);

  useEffect(() => {
    let alive = true;
    (async () => {
      await refresh();
      if (alive) setChecking(false);
    })();
    return () => {
      alive = false;
    };
  }, [refresh]);

  const login = useCallback(
    async (email: string, password: string) => {
      await loginApi(email, password);
      await refresh();
      setLoginOpen(false);
    },
    [refresh]
  );

  const logout = useCallback(async () => {
    try {
      await logoutApi();
    } catch {
    }
    setAccount(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      account,
      isAuthenticated: account !== null,
      isAdmin: (account?.roleName ?? "").toUpperCase() === "ADMIN",
      checking,
      login,
      logout,
      requireLogin: () => setLoginOpen(true),
      refresh,
    }),
    [account, checking, login, logout, refresh]
  );

  return (
    <AuthContext.Provider value={value}>
      {children}
      {loginOpen && <LoginModal onClose={() => setLoginOpen(false)} />}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
