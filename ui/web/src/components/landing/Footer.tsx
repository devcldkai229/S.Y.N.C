import Link from "next/link";
import { SyncLogo } from "@/components/ui/SyncLogo";

const links: Record<string, { label: string; href: string }[]> = {
  "Sản phẩm": [
    { label: "Tính năng", href: "/#features" },
    { label: "Cách hoạt động", href: "/#how-it-works" },
    { label: "Bảng giá", href: "/subscription" },
  ],
  "Công ty": [
    { label: "Liên hệ", href: "/contact" },
  ],
  "Hỗ trợ & pháp lý": [
    { label: "Chính sách bảo mật", href: "/privacy" },
    { label: "Điều khoản dịch vụ", href: "/terms" },
    { label: "Miễn trừ y tế", href: "/health-disclaimer" },
    { label: "Xoá tài khoản", href: "/account-deletion" },
    { label: "Tiêu chuẩn cộng đồng", href: "/community-standards" },
    { label: "English policies", href: "/en/privacy" },
  ],
};

export default function Footer() {
  return (
    <footer className="bg-gray-950 text-gray-500 py-16 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          <div className="md:col-span-1">
            <Link href="/" className="inline-flex items-center mb-4">
              <SyncLogo height={36} className="h-9" />
            </Link>
            <p className="text-sm leading-relaxed text-gray-500">
              Người bạn đồng hành fitness AI để tập luyện thông minh hơn và dinh dưỡng tốt hơn.
            </p>
          </div>

          {Object.entries(links).map(([group, items]) => (
            <div key={group}>
              <h4 className="text-white font-semibold text-sm mb-4">{group}</h4>
              <ul className="space-y-2.5">
                {items.map((item) => (
                  <li key={item.label}>
                    <Link
                      href={item.href}
                      className="text-sm hover:text-white transition-colors"
                    >
                      {item.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="border-t border-gray-800 pt-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-gray-600">
            © {new Date().getFullYear()} SYNC. Tất cả quyền được bảo lưu.
          </p>
          <p className="text-xs text-gray-600 text-center sm:text-right">
            Hỗ trợ: ngykhai229@gmail.com ·{" "}
            <Link href="/contact" className="hover:text-white">
              Thông tin doanh nghiệp
            </Link>
          </p>
        </div>
      </div>
    </footer>
  );
}
