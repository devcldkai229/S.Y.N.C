const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5057";

function getAuthToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("sync_admin_token");
}

/** Backend wraps every response in ApiResponse<T> = { success, message, data, errors }. */
interface ApiEnvelope<T> {
  success: boolean;
  message: string;
  data: T;
  errors?: unknown;
  pagination?: PaginationMetadata;
}

export interface PaginationMetadata {
  pageNumber:      number;
  pageSize:        number;
  totalRecords:    number;
  totalPages:      number;
  hasPreviousPage: boolean;
  hasNextPage:     boolean;
}

export interface Paged<T> {
  items:      T[];
  pagination: PaginationMetadata;
}

function isEnvelope(value: unknown): value is ApiEnvelope<unknown> {
  return (
    typeof value === "object" &&
    value !== null &&
    "success" in value &&
    "data" in value
  );
}

/** Returns the inner `data` payload when the backend envelope is present; otherwise the raw value. */
function unwrap<T>(parsed: unknown): T {
  return isEnvelope(parsed) ? (parsed.data as T) : (parsed as T);
}

async function rawRequest(endpoint: string, options?: RequestInit): Promise<unknown> {
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
    // Surface the backend message when the envelope is present.
    let message = `${response.status} ${response.statusText}`;
    try {
      const parsed = JSON.parse(text);
      if (parsed?.message) message = parsed.message;
    } catch {
      if (text) message = text;
    }
    throw new Error(message);
  }

  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const parsed = await rawRequest(endpoint, options);
  return unwrap<T>(parsed);
}

async function requestFormData<T>(endpoint: string, body: FormData, method = "POST"): Promise<T> {
  const token = getAuthToken();
  const headers: Record<string, string> = {};
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(`${API_BASE_URL}${endpoint}`, { method, headers, body });

  if (response.status === 401) {
    if (typeof window !== "undefined") {
      localStorage.removeItem("sync_admin_token");
      window.location.href = "/admin/login";
    }
    throw new Error("Unauthorized");
  }

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(text || `${response.status} ${response.statusText}`);
  }

  const text = await response.text();
  return unwrap<T>(text ? JSON.parse(text) : null);
}

export const api = {
  get: <T>(endpoint: string, options?: RequestInit) =>
    request<T>(endpoint, { method: "GET", ...options }),

  /** For PagedApiResponse endpoints — returns both items (data) and pagination metadata. */
  getPaged: async <T>(endpoint: string, options?: RequestInit): Promise<Paged<T>> => {
    const parsed = await rawRequest(endpoint, { method: "GET", ...options });
    const env = (isEnvelope(parsed) ? parsed : { data: [], pagination: undefined }) as ApiEnvelope<T[]>;
    return {
      items: (env.data ?? []) as T[],
      pagination:
        env.pagination ?? {
          pageNumber: 1,
          pageSize: (env.data as T[])?.length ?? 0,
          totalRecords: (env.data as T[])?.length ?? 0,
          totalPages: 1,
          hasPreviousPage: false,
          hasNextPage: false,
        },
    };
  },

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
