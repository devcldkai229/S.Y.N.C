import { marked } from "marked";
import {
  type LegalDocKey,
  type LegalLocale,
  legalDocTitle,
  loadLegalMarkdown,
  stripLeadingH1,
} from "@/lib/legal/load-doc";
import { LegalPageShell } from "@/components/legal/LegalPageShell";

marked.setOptions({
  gfm: true,
  breaks: false,
});

export async function LegalDocPage({
  doc,
  locale = "vi",
}: {
  doc: LegalDocKey;
  locale?: LegalLocale;
}) {
  const title = legalDocTitle(doc, locale);
  const md = stripLeadingH1(loadLegalMarkdown(doc, locale));
  const html = await marked.parse(md);

  return (
    <LegalPageShell title={title} locale={locale}>
      <div
        className="legal-md prose-table:text-sm"
        // Content is trusted first-party Markdown from the monorepo Legal Pack.
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </LegalPageShell>
  );
}
