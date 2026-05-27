const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5057";

function getAuthToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("sync_admin_token");
}

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const token = getAuthToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options?.headers as Record<string, string>),
  };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (response.status === 401) {
    if (typeof window !== "undefined") {
      localStorage.removeItem("sync_admin_token");
      window.location.href = "/admin/login";
    }
    throw new Error("Unauthorized");
  }

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(`API error: ${response.status} ${response.statusText} ${text}`);
  }

  const text = await response.text();
  return text ? (JSON.parse(text) as T) : ({} as T);
}

async function requestFormData<T>(endpoint: string, body: FormData, method = "POST"): Promise<T> {
  const token = getAuthToken();
  const headers: Record<string, string> = {};
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method,
    headers,
    body,
  });

  if (response.status === 401) {
    if (typeof window !== "undefined") {
      localStorage.removeItem("sync_admin_token");
      window.location.href = "/admin/login";
    }
    throw new Error("Unauthorized");
  }

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(`API error: ${response.status} ${response.statusText} ${text}`);
  }

  return response.json() as Promise<T>;
}

export const api = {
  get: <T>(endpoint: string, options?: RequestInit) =>
    request<T>(endpoint, { method: "GET", ...options }),

  post: <T>(endpoint: string, body: unknown, options?: RequestInit) =>
    request<T>(endpoint, { method: "POST", body: JSON.stringify(body), ...options }),

  put: <T>(endpoint: string, body: unknown, options?: RequestInit) =>
    request<T>(endpoint, { method: "PUT", body: JSON.stringify(body), ...options }),

  patch: <T>(endpoint: string, body: unknown, options?: RequestInit) =>
    request<T>(endpoint, { method: "PATCH", body: JSON.stringify(body), ...options }),

  delete: <T>(endpoint: string, options?: RequestInit) =>
    request<T>(endpoint, { method: "DELETE", ...options }),

  upload: <T>(endpoint: string, body: FormData, method?: string) =>
    requestFormData<T>(endpoint, body, method),
};
