const DEVICE_KEY = "sync_admin_device_id";

/** Stable per-browser device id required by the IAM auth endpoints (LoginRequest.DeviceId). */
export function getOrCreateDeviceId(): string {
  if (typeof window === "undefined") return "web-admin";
  let id = localStorage.getItem(DEVICE_KEY);
  if (!id) {
    id = `web-admin-${(crypto.randomUUID?.() ?? Math.random().toString(36).slice(2))}`;
    localStorage.setItem(DEVICE_KEY, id);
  }
  return id;
}
