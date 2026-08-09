import fs from "fs";
import path from "path";
import { applyLegalPlaceholders } from "./placeholders";

export type LegalLocale = "vi" | "en";

/** Filenames under content/legal (without locale suffix where bilingual). */
export const LEGAL_DOCS = {
  privacy: { file: "01-privacy-policy", titleVi: "Chính sách quyền riêng tư", titleEn: "Privacy Policy" },
  terms: { file: "02-terms-of-service", titleVi: "Điều khoản dịch vụ", titleEn: "Terms of Service" },
  health: {
    file: "03-health-disclaimer",
    titleVi: "Tuyên bố miễn trừ y tế",
    titleEn: "Health Disclaimer",
  },
  refund: {
    file: "04-refund-cancellation",
    titleVi: "Chính sách hoàn tiền & huỷ",
    titleEn: "Refund & Cancellation Policy",
  },
  deletion: {
    file: "05-account-deletion",
    titleVi: "Xoá tài khoản & dữ liệu",
    titleEn: "Account & Data Deletion",
  },
  community: {
    file: "06-community-standards",
    titleVi: "Tiêu chuẩn cộng đồng",
    titleEn: "Community Standards",
  },
  contact: {
    file: "07-company-contact",
    titleVi: "Thông tin doanh nghiệp & liên hệ",
    titleEn: "Company & Contact",
    bilingualSingleFile: true,
  },
} as const;

export type LegalDocKey = keyof typeof LEGAL_DOCS;

function contentRoot(): string {
  // process.cwd() is ui/web when running next
  return path.join(process.cwd(), "content", "legal");
}

export function loadLegalMarkdown(doc: LegalDocKey, locale: LegalLocale = "vi"): string {
  const meta = LEGAL_DOCS[doc];
  const filename =
    "bilingualSingleFile" in meta && meta.bilingualSingleFile
      ? `${meta.file}.md`
      : `${meta.file}.${locale}.md`;
  const full = path.join(contentRoot(), filename);
  if (!fs.existsSync(full)) {
    throw new Error(`Legal document not found: ${filename}`);
  }
  const raw = fs.readFileSync(full, "utf8");
  return applyLegalPlaceholders(raw);
}

export function legalDocTitle(doc: LegalDocKey, locale: LegalLocale = "vi"): string {
  const meta = LEGAL_DOCS[doc];
  return locale === "en" ? meta.titleEn : meta.titleVi;
}

/** Drop leading AT1 (LegalPageShell already renders the page title). */
export function stripLeadingH1(markdown: string): string {
  return markdown.replace(/^#\s+[^\n]+\n+/, "");
}
