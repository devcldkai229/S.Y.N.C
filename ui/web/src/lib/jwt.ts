// Claim URIs emitted by the IAM JwtTokenService (System.Security.Claims.ClaimTypes.*)
const ROLE_CLAIM = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role";
const NAME_CLAIM = "http://schemas.microsoft.com/ws/2008/06/identity/claims/name";
const NAMEID_CLAIM = "http://schemas.microsoft.com/ws/2008/06/identity/claims/nameidentifier";

export interface JwtClaims {
  role?:  string;
  name?:  string;
  email?: string;
  sub?:   string;
  exp?:   number;
  [key: string]: unknown;
}

/** Decode a JWT payload (no signature verification — display/routing only). */
export function decodeJwt(token: string): JwtClaims | null {
  try {
    const payload = token.split(".")[1];
    if (!payload) return null;
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const json = decodeURIComponent(
      atob(base64)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join("")
    );
    const raw = JSON.parse(json) as Record<string, unknown>;
    return {
      ...raw,
      role:  (raw[ROLE_CLAIM] ?? raw["role"]) as string | undefined,
      name:  (raw[NAME_CLAIM] ?? raw["name"]) as string | undefined,
      email: (raw["email"] ?? raw["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]) as string | undefined,
      sub:   (raw["sub"] ?? raw[NAMEID_CLAIM]) as string | undefined,
      exp:   raw["exp"] as number | undefined,
    };
  } catch {
    return null;
  }
}

/** Platform admin roles allowed into the dashboard. SystemAdmin is the canonical admin role. */
export const ADMIN_ROLES = ["SystemAdmin", "Admin", "Staff"];

export function isAdminRole(role?: string): boolean {
  return !!role && ADMIN_ROLES.includes(role);
}
