import Link from "next/link";
import { SyncLogo } from "@/components/ui/SyncLogo";

const NAV_VI = [
  { href: "/privacy", label: "Quyền riêng tư" },
  { href: "/terms", label: "Điều khoản" },
  { href: "/health-disclaimer", label: "Miễn trừ y tế" },
  { href: "/account-deletion", label: "Xoá tài khoản" },
  { href: "/community-standards", label: "Cộng đồng" },
  { href: "/contact", label: "Liên hệ" },
] as const;

const NAV_EN = [
  { href: "/en/privacy", label: "Privacy" },
  { href: "/en/terms", label: "Terms" },
  { href: "/en/health-disclaimer", label: "Health" },
  { href: "/en/account-deletion", label: "Delete account" },
  { href: "/en/community-standards", label: "Community" },
  { href: "/contact", label: "Contact" },
] as const;

export type LegalPageShellProps = {
  title: string;
  children: React.ReactNode;
  locale?: "vi" | "en";
  /** Current document path for nav highlight, e.g. /privacy */
  activeHref?: string;
  /** Optional meta chips under the title */
  meta?: { label: string; value: string }[];
  /** In-doc table of contents (## / ###) */
  toc?: { id: string; text: string; level: 2 | 3 }[];
};

export function LegalPageShell({
  title,
  children,
  locale = "vi",
  activeHref,
  meta = [],
  toc = [],
}: LegalPageShellProps) {
  const nav = locale === "en" ? NAV_EN : NAV_VI;
  const isEn = locale === "en";

  return (
    <div className="legal-site relative min-h-screen text-stone-900">
      <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden>
        <div className="legal-site-glow absolute -left-24 top-0 h-[28rem] w-[28rem] rounded-full bg-[#1A8344]/[0.09] blur-3xl" />
        <div className="legal-site-glow-alt absolute -right-16 top-40 h-[22rem] w-[22rem] rounded-full bg-[#21a356]/[0.07] blur-3xl" />
        <div className="legal-site-mesh absolute inset-0 opacity-[0.35]" />
      </div>

      <header className="sticky top-0 z-40 border-b border-stone-200/70 bg-white/85 backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3.5 sm:px-6">
          <div className="flex items-center gap-3">
            <Link href="/" className="inline-flex shrink-0 items-center" aria-label="SYNC home">
              <SyncLogo height={30} className="h-7 sm:h-8" />
            </Link>
            <span className="hidden h-5 w-px bg-stone-200 sm:block" aria-hidden />
            <p className="hidden text-[11px] font-semibold uppercase tracking-[0.14em] text-stone-500 sm:block">
              {isEn ? "Legal center" : "Trung tâm pháp lý"}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Link
              href="/"
              className="hidden rounded-full px-3 py-1.5 text-sm text-stone-600 transition hover:bg-stone-100 hover:text-stone-900 sm:inline"
            >
              {isEn ? "Home" : "Trang chủ"}
            </Link>
            {isEn ? (
              <Link
                href="/privacy"
                className="rounded-full border border-stone-200 bg-white px-3 py-1.5 text-xs font-semibold text-stone-700 transition hover:border-[#1A8344]/40 hover:text-[#146634]"
              >
                VI
              </Link>
            ) : (
              <Link
                href="/en/privacy"
                className="rounded-full border border-stone-200 bg-white px-3 py-1.5 text-xs font-semibold text-stone-700 transition hover:border-[#1A8344]/40 hover:text-[#146634]"
              >
                EN
              </Link>
            )}
          </div>
        </div>

        <div className="border-t border-stone-100/90">
          <nav
            className="mx-auto flex max-w-6xl gap-1.5 overflow-x-auto px-4 py-2.5 sm:px-6 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            aria-label={isEn ? "Legal documents" : "Tài liệu pháp lý"}
          >
            {nav.map((item) => {
              const active = activeHref === item.href || activeHref?.startsWith(`${item.href}/`);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={[
                    "shrink-0 rounded-full px-3.5 py-1.5 text-[13px] font-medium transition",
                    active
                      ? "bg-[#1A8344] text-white shadow-sm shadow-[#1A8344]/25"
                      : "bg-stone-100/80 text-stone-600 hover:bg-stone-200/80 hover:text-stone-900",
                  ].join(" ")}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>
      </header>

      <div className="relative mx-auto grid max-w-6xl gap-8 px-4 py-10 sm:px-6 lg:grid-cols-[220px_minmax(0,1fr)] lg:py-14">
        {/* TOC — desktop */}
        <aside className="hidden lg:block">
          <div className="sticky top-36 space-y-4">
            <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-stone-400">
              {isEn ? "On this page" : "Mục lục"}
            </p>
            {toc.length > 0 ? (
              <ul className="space-y-1 border-l border-stone-200 pl-3">
                {toc.map((item) => (
                  <li key={item.id}>
                    <a
                      href={`#${item.id}`}
                      className={[
                        "block border-l-2 border-transparent py-1 text-[13px] leading-snug text-stone-500 transition hover:border-[#1A8344] hover:text-[#146634]",
                        item.level === 3 ? "pl-3 text-[12px]" : "pl-0 font-medium",
                      ].join(" ")}
                    >
                      {item.text}
                    </a>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-stone-400">
                {isEn ? "Scroll to read the full document." : "Cuộn để đọc toàn bộ tài liệu."}
              </p>
            )}
            <div className="rounded-2xl border border-stone-200/80 bg-white/70 p-4 shadow-sm shadow-stone-900/5">
              <p className="text-xs font-semibold text-stone-800">
                {isEn ? "Need help?" : "Cần hỗ trợ?"}
              </p>
              <p className="mt-1 text-xs leading-relaxed text-stone-500">
                {isEn
                  ? "Questions about these policies or your data rights."
                  : "Câu hỏi về chính sách hoặc quyền dữ liệu cá nhân."}
              </p>
              <Link
                href="/contact"
                className="mt-3 inline-flex text-xs font-semibold text-[#1A8344] hover:text-[#146634]"
              >
                {isEn ? "Contact us →" : "Liên hệ chúng tôi →"}
              </Link>
            </div>
          </div>
        </aside>

        <main className="min-w-0">
          <article className="overflow-hidden rounded-3xl border border-stone-200/80 bg-white shadow-[0_1px_0_rgba(15,23,42,0.04),0_24px_48px_-28px_rgba(15,23,42,0.18)]">
            <div className="border-b border-stone-100 bg-gradient-to-br from-[#f0faf4] via-white to-white px-6 py-8 sm:px-10 sm:py-10">
              <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#1A8344]">
                SYNC · {isEn ? "Official policy" : "Tài liệu chính thức"}
              </p>
              <h1 className="font-heading mt-3 text-balance text-3xl font-bold tracking-tight text-stone-900 sm:text-4xl">
                {title}
              </h1>
              {meta.length > 0 && (
                <dl className="mt-6 flex flex-wrap gap-2">
                  {meta.map((item) => (
                    <div
                      key={`${item.label}-${item.value}`}
                      className="inline-flex items-center gap-2 rounded-full border border-stone-200/90 bg-white px-3 py-1.5 text-xs text-stone-600 shadow-sm shadow-stone-900/5"
                    >
                      <dt className="font-medium text-stone-400">{item.label}</dt>
                      <dd className="font-semibold text-stone-800">{item.value}</dd>
                    </div>
                  ))}
                </dl>
              )}
            </div>

            {/* Mobile TOC */}
            {toc.length > 0 && (
              <details className="border-b border-stone-100 bg-stone-50/80 px-6 py-3 lg:hidden">
                <summary className="cursor-pointer list-none text-sm font-semibold text-stone-700 [&::-webkit-details-marker]:hidden">
                  {isEn ? "Contents" : "Mục lục"} · {toc.filter((t) => t.level === 2).length}{" "}
                  {isEn ? "sections" : "mục"}
                </summary>
                <ul className="mt-3 space-y-1.5 pb-2">
                  {toc
                    .filter((t) => t.level === 2)
                    .map((item) => (
                      <li key={item.id}>
                        <a href={`#${item.id}`} className="text-sm text-[#1A8344] hover:underline">
                          {item.text}
                        </a>
                      </li>
                    ))}
                </ul>
              </details>
            )}

            <div className="legal-doc px-6 py-8 sm:px-10 sm:py-10">{children}</div>
          </article>

          <footer className="mt-8 flex flex-col gap-3 border-t border-stone-200/70 pt-6 text-sm text-stone-500 sm:flex-row sm:items-center sm:justify-between">
            <p>
              © {new Date().getFullYear()} SYNC.{" "}
              {isEn
                ? "These pages are part of the official legal pack."
                : "Trang thuộc bộ tài liệu pháp lý chính thức."}
            </p>
            <div className="flex gap-4">
              <Link href="/privacy" className="hover:text-[#146634]">
                {isEn ? "Privacy" : "Bảo mật"}
              </Link>
              <Link href="/terms" className="hover:text-[#146634]">
                {isEn ? "Terms" : "Điều khoản"}
              </Link>
              <Link href="/contact" className="hover:text-[#146634]">
                {isEn ? "Contact" : "Liên hệ"}
              </Link>
            </div>
          </footer>
        </main>
      </div>
    </div>
  );
}
