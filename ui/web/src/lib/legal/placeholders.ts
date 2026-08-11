/**
 * Legal document placeholders — keep in sync with docs/legal/00-README.md §2.
 * Override via NEXT_PUBLIC_LEGAL_* env vars before Google Play publish.
 */
export type LegalPlaceholderMap = Record<string, string>;

function env(key: string, fallback: string): string {
  const v = process.env[key];
  return v && v.trim() ? v.trim() : fallback;
}

/**
 * Public legal identity. Do NOT put home street addresses here — use support email/phone.
 * Vietnamese names stay in this UTF-8 source file (avoid corrupted shell .env overrides).
 */
export function getLegalPlaceholders(): LegalPlaceholderMap {
  const website = env("NEXT_PUBLIC_LEGAL_WEBSITE", "https://synctis.in").replace(/\/$/, "");
  const support = env("NEXT_PUBLIC_LEGAL_SUPPORT_EMAIL", "ngykhai229@gmail.com");
  // Empty by default: never publish residential street address on public legal pages.
  const address = env("NEXT_PUBLIC_LEGAL_REGISTERED_ADDRESS", "");
  const entityVi = env("NEXT_PUBLIC_LEGAL_ENTITY_NAME", "Nguyễn Quốc Khải");
  const entityEn = env("NEXT_PUBLIC_LEGAL_ENTITY_NAME_EN", "Nguyen Quoc Khai");
  return {
    LEGAL_ENTITY_NAME: entityVi,
    LEGAL_ENTITY_NAME_EN: entityEn,
    BUSINESS_REG_NO: env("NEXT_PUBLIC_LEGAL_BUSINESS_REG_NO", "Không áp dụng (cá nhân)"),
    BUSINESS_REG_DATE: env("NEXT_PUBLIC_LEGAL_BUSINESS_REG_DATE", "Không áp dụng (cá nhân)"),
    BUSINESS_REG_AUTHORITY: env(
      "NEXT_PUBLIC_LEGAL_BUSINESS_REG_AUTHORITY",
      "Không áp dụng (cá nhân)",
    ),
    REGISTERED_ADDRESS: address,
    MAILING_ADDRESS: env("NEXT_PUBLIC_LEGAL_MAILING_ADDRESS", address),
    REPRESENTATIVE_NAME: env("NEXT_PUBLIC_LEGAL_REPRESENTATIVE_NAME", entityVi),
    SUPPORT_EMAIL: support,
    PRIVACY_EMAIL: env("NEXT_PUBLIC_LEGAL_PRIVACY_EMAIL", support),
    ABUSE_EMAIL: env("NEXT_PUBLIC_LEGAL_ABUSE_EMAIL", support),
    BUSINESS_EMAIL: env("NEXT_PUBLIC_LEGAL_BUSINESS_EMAIL", support),
    SECURITY_EMAIL: env("NEXT_PUBLIC_LEGAL_SECURITY_EMAIL", support),
    DPO_NAME: env(
      "NEXT_PUBLIC_LEGAL_DPO_NAME",
      "Người kiểm soát dữ liệu cá nhân (developer cá nhân)",
    ),
    SUPPORT_PHONE: env("NEXT_PUBLIC_LEGAL_SUPPORT_PHONE", "0978504380"),
    WEBSITE: website,
    EFFECTIVE_DATE: env("NEXT_PUBLIC_LEGAL_EFFECTIVE_DATE", "09/08/2026"),
    PLAY_PACKAGE_NAME: env("NEXT_PUBLIC_LEGAL_PLAY_PACKAGE_NAME", "com.sync.sync_app"),
    PLAY_DEVELOPER_ACCOUNT: env("NEXT_PUBLIC_LEGAL_PLAY_DEVELOPER_ACCOUNT", support),
    DUNS_NUMBER: env("NEXT_PUBLIC_LEGAL_DUNS_NUMBER", "Không áp dụng (cá nhân)"),
    YEAR: String(new Date().getFullYear()),
  };
}

/**
 * Apply `{{KEY}}` and simple Mustache sections `{{#KEY}}...{{/KEY}}`
 * (section included only when value is non-empty).
 * Also strips standalone empty-placeholder residues (blank address lines, empty table cells).
 */
export function applyLegalPlaceholders(markdown: string, map = getLegalPlaceholders()): string {
  let out = markdown;

  out = out.replace(/\{\{#([A-Z0-9_]+)\}\}([\s\S]*?)\{\{\/\1\}\}/g, (_m, key: string, body: string) => {
    const val = map[key] ?? "";
    return val ? body.replace(new RegExp(`\\{\\{${key}\\}\\}`, "g"), val) : "";
  });

  out = out.replace(/\{\{([A-Z0-9_]+)\}\}/g, (_m, key: string) => {
    if (key in map) return map[key] ?? "";
    return `{{${key}}}`;
  });

  // Drop markdown table rows whose value cell is empty after substitution.
  out = out.replace(/^\|[^|\n]+\|\s*\|\s*$/gm, "");
  // "Label |   " style remnants with only whitespace value
  out = out.replace(/^\|([^|\n]+)\|\s*\|\s*$/gm, "");
  // Em-dash / empty address trailing segments: "Name — " at end of line
  out = out.replace(/\s+[—–-]\s*$/gm, "");
  // Consecutive blank lines
  out = out.replace(/\n{3,}/g, "\n\n");

  return out;
}
