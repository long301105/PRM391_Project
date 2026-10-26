import { api } from "@/lib/api";
import type { AccountResponse, LoginResponse } from "./types";

export async function login(email: string, password: string): Promise<LoginResponse> {
  return api.post<LoginResponse>("/auth/login", { email: email.trim(), password });
}

export async function logout(): Promise<void> {
  await api.post<void>("/auth/logout");
}

export async function fetchCurrentAccount(): Promise<AccountResponse> {
  return api.get<AccountResponse>("/accounts/me");
}
