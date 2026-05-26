import Link from "next/link";
import { Zap } from "lucide-react";

const links: Record<string, string[]> = {
  "Sản phẩm": ["Tính năng", "Cách hoạt động", "Bảng giá", "App mobile"],
  "Công ty": ["Về chúng tôi", "Blog", "Tuyển dụng", "Báo chí"],
  "Hỗ trợ": ["Trung tâm trợ giúp", "Liên hệ", "Chính sách bảo mật", "Điều khoản sử dụng"],
};

export default function Footer() {
  return (
    <footer className="bg-gray-950 text-gray-500 py-16 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          {/* Brand */}
          <div className="md:col-span-1">
            <Link href="/" className="inline-flex items-center gap-2 mb-4">
              <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                <Zap className="w-4 h-4 text-white fill-white" />
              </div>
              <span className="font-bold text-xl tracking-tight text-primary">
                SYNC
              </span>
            </Link>
            <p className="text-sm leading-relaxed text-gray-500">
              Người bạn đồng hành fitness AI để tập luyện thông minh hơn và dinh dưỡng tốt hơn.
            </p>
          </div>

          {/* Link groups */}
          {Object.entries(links).map(([group, items]) => (
            <div key={group}>
              <h4 className="text-white font-semibold text-sm mb-4">{group}</h4>
              <ul className="space-y-2.5">
                {items.map((item) => (
                  <li key={item}>
                    <Link href="#" className="text-sm hover:text-white transition-colors">
                      {item}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom bar */}
        <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-sm text-gray-600">© 2026 SYNC. Tất cả quyền được bảo lưu.</p>
          <div className="flex items-center gap-6 text-sm">
            {["Bảo mật", "Điều khoản", "Cookie"].map((item) => (
              <Link key={item} href="#" className="hover:text-white transition-colors">
                {item}
              </Link>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}
