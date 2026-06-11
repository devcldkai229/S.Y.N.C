import { getUserToken } from "@/stores/user-auth.store";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5057";

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const token = getUserToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options?.headers as Record<string, string>),
  };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(`${API_BASE_URL}${endpoint}`, { ...options, headers });

  if (response.status === 401) {
    if (typeof window !== "undefined") {
      localStorage.removeItem("sync_token");
      localStorage.removeItem("sync_user");
      window.location.href = "/login?redirect=" + encodeURIComponent(window.location.pathname);
    }
    throw new Error("Unauthorized");
  }

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    let message = `API error ${response.status}`;
    try {
      const json = JSON.parse(text);
      message = json.message ?? message;
    } catch { /* ignore */ }
    throw new Error(message);
  }

  const text = await response.text();
  return text ? (JSON.parse(text) as T) : ({} as T);
}

export const userApi = {
  get:  <T>(endpoint: string, options?: RequestInit) =>
    request<T>(endpoint, { method: "GET", ...options }),
  post: <T>(endpoint: string, body: unknown, options?: RequestInit) =>
    request<T>(endpoint, { method: "POST", body: JSON.stringify(body), ...options }),
};
