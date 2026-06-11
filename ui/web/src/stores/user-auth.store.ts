"use client";

import { create } from "zustand";
import { devtools } from "zustand/middleware";

export interface SyncUser {
  id: string;
  email: string;
  fullName: string;
  subscriptionTier?: string;
}

interface UserAuthState {
  token: string | null;
  user: SyncUser | null;
  isAuthenticated: boolean;
  login: (token: string, user: SyncUser) => void;
  logout: () => void;
  loadFromStorage: () => void;
}

const TOKEN_KEY = "sync_token";
const USER_KEY  = "sync_user";

export const useUserAuthStore = create<UserAuthState>()(
  devtools(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,

      login: (token, user) => {
        localStorage.setItem(TOKEN_KEY, token);
        localStorage.setItem(USER_KEY, JSON.stringify(user));
        set({ token, user, isAuthenticated: true });
      },

      logout: () => {
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(USER_KEY);
        set({ token: null, user: null, isAuthenticated: false });
      },

      loadFromStorage: () => {
        const token = localStorage.getItem(TOKEN_KEY);
        const raw   = localStorage.getItem(USER_KEY);
        if (token && raw) {
          try {
            const user = JSON.parse(raw) as SyncUser;
            set({ token, user, isAuthenticated: true });
          } catch {
            localStorage.removeItem(TOKEN_KEY);
            localStorage.removeItem(USER_KEY);
          }
        }
      },
    }),
    { name: "user-auth-store" }
  )
);

export function getUserToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}
