"use client";

import { create } from "zustand";
import { devtools } from "zustand/middleware";

export interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  role: string;
}

interface AuthState {
  token: string | null;
  user: AdminUser | null;
  isAuthenticated: boolean;
  login: (token: string, user: AdminUser) => void;
  logout: () => void;
  loadFromStorage: () => void;
}

const TOKEN_KEY = "sync_admin_token";
const USER_KEY  = "sync_admin_user";

export const useAuthStore = create<AuthState>()(
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
            const user = JSON.parse(raw) as AdminUser;
            set({ token, user, isAuthenticated: true });
          } catch {
            localStorage.removeItem(TOKEN_KEY);
            localStorage.removeItem(USER_KEY);
          }
        }
      },
    }),
    { name: "auth-store" }
  )
);
