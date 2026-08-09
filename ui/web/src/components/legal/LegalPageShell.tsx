import Link from "next/link";
import { SyncLogo } from "@/components/ui/SyncLogo";

const NAV_VI = [
  { href: "/privacy", label: "Bảo mật" },
  { href: "/terms", label: "Điều khoản" },
  { href: "/health-disclaimer", label: "Y tế" },
  { href: "/refund-policy", label: "Hoàn tiền" },
  { href: "/account-deletion", label: "Xoá TK" },
  { href: "/community-standards", label: "Cộng đồng" },
  { href: "/contact", label: "Liên hệ" },
] as const;

const NAV_EN = [
  { href: "/en/privacy", label: "Privacy" },
  { href: "/en/terms", label: "Terms" },
  { href: "/en/health-disclaimer", label: "Health" },
  { href: "/en/refund-policy", label: "Refunds" },
  { href: "/en/account-deletion", label: "Delete account" },
  { href: "/en/community-standards", label: "Community" },
  { href: "/contact", label: "Contact" },
] as const;

export function LegalPageShell({
  title,
  children,
  locale = "vi",
}: {
  title: string;
  children: React.ReactNode;
  locale?: "vi" | "en";
}) {
  const nav = locale === "en" ? NAV_EN : NAV_VI;

  return (
    <div className="min-h-screen bg-gradient-to-b from-stone-50 to-white text-stone-900">
      <header className="border-b border-stone-200/80 bg-white/80 backdrop-blur">
        <div className="mx-auto flex max-w-3xl flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
          <Link href="/" className="inline-flex items-center">
            <SyncLogo height={28} className="h-7" />
          </Link>
          <nav className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-stone-600 sm:justify-end sm:text-sm">
            {nav.map((item) => (
              <Link key={item.href} href={item.href} className="hover:text-stone-900">
                {item.label}
              </Link>
            ))}
            {locale === "vi" ? (
              <Link href="/en/privacy" className="font-medium text-emerald-700 hover:text-emerald-900">
                EN
              </Link>
            ) : (
              <Link href="/privacy" className="font-medium text-emerald-700 hover:text-emerald-900">
                VI
              </Link>
            )}
          </nav>
        </div>
      </header>
      <main className="prose prose-stone mx-auto max-w-3xl px-4 py-10 prose-headings:scroll-mt-20 prose-headings:font-bold prose-a:text-emerald-700 prose-table:text-sm prose-th:text-left">
        <h1>{title}</h1>
        {children}
      </main>
    </div>
  );
}
