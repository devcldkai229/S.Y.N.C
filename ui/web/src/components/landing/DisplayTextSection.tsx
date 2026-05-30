"use client";

import { motion } from "framer-motion";
import Link from "next/link";

export default function DisplayTextSection() {
  return (
    <section className="bg-gray-950 overflow-hidden">
      {/* Top nav row — mirrors the Antigravity "Experience liftoff" row */}
      <div className="max-w-7xl mx-auto px-6 pt-16 pb-6 flex items-end justify-between border-b border-gray-800">
        <motion.p
          className="text-gray-400 text-sm"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          Bắt đầu hành trình
        </motion.p>
        <div className="flex gap-8 text-sm">
          {[
              { label: "Tính năng", href: "#features" },
              { label: "Bảng giá", href: "/subscription" },
              { label: "Blog", href: "#" },
              { label: "Liên hệ", href: "#" },
            ].map((item, i) => (
            <motion.div
              key={item}
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: i * 0.07 }}
            >
              <Link href={item.href} className="text-gray-500 hover:text-white transition-colors">
                {item.label}
              </Link>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Giant display text — Antigravity style */}
      <div className="px-4 md:px-6 pb-0 pt-4 overflow-hidden">
        <motion.h2
          className="display-text font-bold text-white tracking-[-0.04em] leading-[0.85] whitespace-nowrap"
          initial={{ opacity: 0, y: 60 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
        >
          <span className="text-primary">SYNC</span>
        </motion.h2>
      </div>

      {/* Bottom bar */}
      <div className="max-w-7xl mx-auto px-6 py-8 flex flex-col md:flex-row items-center justify-between gap-4 border-t border-gray-800 mt-6">
        <p className="text-sm text-gray-600">© 2026 SYNC. Tất cả quyền được bảo lưu.</p>
        <div className="flex items-center gap-6 text-sm">
          {["Bảo mật", "Điều khoản", "Cookie"].map((item) => (
            <Link key={item} href="#" className="text-gray-600 hover:text-white transition-colors">
              {item}
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
