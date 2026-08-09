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
 * Defaults: personal Play developer Nguyễn Quốc Khải (Mỏ Cày Bắc, Bến Tre).
 * Override any field via NEXT_PUBLIC_LEGAL_* for CI / other environments.
 */
export function getLegalPlaceholders(): LegalPlaceholderMap {
  const website = env("NEXT_PUBLIC_LEGAL_WEBSITE", "https://synctis.in").replace(/\/$/, "");
  const support = env("NEXT_PUBLIC_LEGAL_SUPPORT_EMAIL", "ngykhai229@gmail.com");
  const address = env(
    "NEXT_PUBLIC_LEGAL_REGISTERED_ADDRESS",
    "347, Ấp Tân Lợi, Tân Phú Tây, Mỏ Cày Bắc, Bến Tre, Việt Nam",
  );
  return {
    LEGAL_ENTITY_NAME: env("NEXT_PUBLIC_LEGAL_ENTITY_NAME", "Nguyễn Quốc Khải"),
    LEGAL_ENTITY_NAME_EN: env("NEXT_PUBLIC_LEGAL_ENTITY_NAME_EN", "devopsidian"),
    BUSINESS_REG_NO: env("NEXT_PUBLIC_LEGAL_BUSINESS_REG_NO", "Không áp dụng (cá nhân)"),
    BUSINESS_REG_DATE: env("NEXT_PUBLIC_LEGAL_BUSINESS_REG_DATE", "Không áp dụng (cá nhân)"),
    BUSINESS_REG_AUTHORITY: env(
      "NEXT_PUBLIC_LEGAL_BUSINESS_REG_AUTHORITY",
      "Không áp dụng (cá nhân)",
    ),
    REGISTERED_ADDRESS: address,
    MAILING_ADDRESS: env("NEXT_PUBLIC_LEGAL_MAILING_ADDRESS", address),
    REPRESENTATIVE_NAME: env("NEXT_PUBLIC_LEGAL_REPRESENTATIVE_NAME", "Nguyễn Quốc Khải"),
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
 */
export function applyLegalPlaceholders(markdown: string, map = getLegalPlaceholders()): string {
  let out = markdown;

  // Conditional sections first
  out = out.replace(/\{\{#([A-Z0-9_]+)\}\}([\s\S]*?)\{\{\/\1\}\}/g, (_m, key: string, body: string) => {
    const val = map[key] ?? "";
    return val ? body.replace(new RegExp(`\\{\\{${key}\\}\\}`, "g"), val) : "";
  });

  out = out.replace(/\{\{([A-Z0-9_]+)\}\}/g, (_m, key: string) => {
    if (key in map) return map[key] ?? "";
    return `{{${key}}}`;
  });

  return out;
}
