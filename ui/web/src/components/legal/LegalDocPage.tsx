import { marked, Renderer } from "marked";
import {
  type LegalDocKey,
  type LegalLocale,
  legalDocTitle,
  loadLegalMarkdown,
  stripLeadingH1,
} from "@/lib/legal/load-doc";
import { LegalPageShell } from "@/components/legal/LegalPageShell";

function slugify(raw: string): string {
  return raw
    .replace(/[đĐ]/g, "d")
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .slice(0, 80);
}

function extractMeta(markdown: string): {
  meta: { label: string; value: string }[];
  body: string;
} {
  const lines = markdown.split("\n");
  const meta: { label: string; value: string }[] = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    if (!line) {
      i += 1;
      continue;
    }
    const m = line.match(/^\*\*([^*]+):\*\*\s*(.+)$/);
    if (m) {
      meta.push({ label: m[1].trim(), value: m[2].replace(/\*+/g, "").trim() });
      i += 1;
      continue;
    }
    break;
  }
  while (i < lines.length && /^(-{3,}|\*{3,}|_{3,})$/.test(lines[i].trim())) {
    i += 1;
  }
  return { meta, body: lines.slice(i).join("\n").trimStart() };
}

function extractToc(markdown: string): { id: string; text: string; level: 2 | 3 }[] {
  const toc: { id: string; text: string; level: 2 | 3 }[] = [];
  const used = new Set<string>();
  for (const line of markdown.split("\n")) {
    const m = line.match(/^(#{2,3})\s+(.+)$/);
    if (!m) continue;
    const level = m[1].length as 2 | 3;
    const text = m[2]
      .replace(/[#*_`]/g, "")
      .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
      .trim();
    let id = slugify(text) || `section-${toc.length + 1}`;
    if (used.has(id)) {
      let n = 2;
      while (used.has(`${id}-${n}`)) n += 1;
      id = `${id}-${n}`;
    }
    used.add(id);
    toc.push({ id, text, level });
  }
  return toc;
}

const localeHref: Record<LegalDocKey, { vi: string; en: string }> = {
  privacy: { vi: "/privacy", en: "/en/privacy" },
  terms: { vi: "/terms", en: "/en/terms" },
  health: { vi: "/health-disclaimer", en: "/en/health-disclaimer" },
  deletion: { vi: "/account-deletion", en: "/en/account-deletion" },
  community: { vi: "/community-standards", en: "/en/community-standards" },
  contact: { vi: "/contact", en: "/contact" },
};

export async function LegalDocPage({
  doc,
  locale = "vi",
}: {
  doc: LegalDocKey;
  locale?: LegalLocale;
}) {
  const title = legalDocTitle(doc, locale);
  const raw = stripLeadingH1(loadLegalMarkdown(doc, locale));
  const { meta, body } = extractMeta(raw);
  const toc = extractToc(body);

  let headingCursor = 0;
  const renderer = new Renderer();
  renderer.heading = function heading({ tokens, depth }) {
    const inner = this.parser.parseInline(tokens);
    if (depth === 2 || depth === 3) {
      const entry = toc[headingCursor];
      const id = entry?.id ?? `section-${headingCursor + 1}`;
      headingCursor += 1;
      return `<h${depth} id="${id}">${inner}</h${depth}>\n`;
    }
    return `<h${depth}>${inner}</h${depth}>\n`;
  };

  const html = await marked.parse(body, {
    gfm: true,
    breaks: false,
    renderer,
  });

  const href = localeHref[doc][locale === "en" ? "en" : "vi"];

  return (
    <LegalPageShell title={title} locale={locale} activeHref={href} meta={meta} toc={toc}>
      <div dangerouslySetInnerHTML={{ __html: html }} />
    </LegalPageShell>
  );
}
