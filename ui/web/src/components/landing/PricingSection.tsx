"use client";

import Link from "next/link";
import { Check, X, Zap, Crown } from "lucide-react";
import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";
import { motion } from "framer-motion";

const freePlan = {
  name: "Free",
  price: "0",
  unit: "đ",
  period: "mãi mãi",
  description: "Khởi đầu hành trình fitness của bạn hoàn toàn miễn phí.",
  cta: "Bắt đầu miễn phí",
  ctaHref: "/register",
  icon: Zap,
  features: [
    { label: "Tạo tài khoản cá nhân", included: true },
    { label: "5 lần hỏi AI Coach mỗi tháng", included: true },
    { label: "Nhật ký tập luyện cơ bản", included: true },
    { label: "Theo dõi tiến trình cơ bản", included: true },
    { label: "Truy cập cộng đồng", included: true },
    { label: "AI Coach không giới hạn", included: false },
    { label: "Kế hoạch tập cá nhân hóa", included: false },
    { label: "Planner dinh dưỡng", included: false },
    { label: "Phân tích nâng cao", included: false },
    { label: "Hỗ trợ ưu tiên 24/7", included: false },
  ],
};

const proPlan = {
  name: "Pro",
  price: "99.000",
  unit: "đ",
  period: "tháng",
  description: "Mở khóa toàn bộ sức mạnh AI để đạt đỉnh cao thể lực.",
  cta: "Nâng cấp ngay",
  ctaHref: "/register?plan=pro",
  icon: Crown,
  features: [
    { label: "Tạo tài khoản cá nhân", included: true },
    { label: "AI Coach không giới hạn 24/7", included: true },
    { label: "Nhật ký tập luyện đầy đủ", included: true },
    { label: "Theo dõi tiến trình nâng cao", included: true },
    { label: "Truy cập cộng đồng & thử thách", included: true },
    { label: "Kế hoạch tập thông minh cá nhân hóa", included: true },
    { label: "Planner dinh dưỡng & macro", included: true },
    { label: "Phân tích hiệu suất chuyên sâu", included: true },
    { label: "Đồng bộ thiết bị đeo thể thao", included: true },
    { label: "Hỗ trợ ưu tiên 24/7", included: true },
  ],
};

export default function PricingSection() {
  return (
    <section id="pricing" className="py-24 px-4 bg-white relative overflow-hidden">
      <div className="max-w-5xl mx-auto relative">
        {/* Header */}
        <FadeUp className="text-center mb-16">
          <p className="text-primary font-medium text-sm mb-3 uppercase tracking-wide">Bảng giá</p>
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-5 tracking-tight">
            Chọn gói phù hợp
            <br />
            với <span className="text-primary">hành trình của bạn</span>
          </h2>
          <p className="text-gray-400 text-lg max-w-xl mx-auto leading-relaxed">
            Bắt đầu miễn phí, nâng cấp khi bạn sẵn sàng. Không cam kết dài hạn.
          </p>
        </FadeUp>

        {/* Cards */}
        <StaggerContainer
          className="grid grid-cols-1 md:grid-cols-2 gap-6 items-stretch"
          stagger={0.12}
        >
          {/* ── Free card ── light card with visible border + shadow */}
          <StaggerItem>
            <div className="h-full flex flex-col bg-white border-2 border-gray-200 rounded-3xl p-8 shadow-md hover:shadow-xl hover:-translate-y-1 transition-all duration-300">
              {/* Plan badge */}
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center">
                  <freePlan.icon className="w-5 h-5 text-gray-500" />
                </div>
                <span className="font-semibold text-gray-800 text-lg">{freePlan.name}</span>
              </div>

              {/* Price */}
              <div className="mb-2">
                <span className="text-5xl font-bold text-gray-900 tracking-tight">{freePlan.price}</span>
                <span className="text-2xl font-semibold text-gray-400 ml-1">{freePlan.unit}</span>
              </div>
              <p className="text-gray-400 text-sm mb-1">/ {freePlan.period}</p>
              <p className="text-gray-500 text-sm leading-relaxed mt-3 mb-8">{freePlan.description}</p>

              {/* CTA */}
              <Link
                href={freePlan.ctaHref}
                className="block w-full text-center bg-gray-100 border border-gray-200 text-gray-700 px-6 py-3.5 rounded-full font-medium hover:bg-gray-200 transition-all duration-200 mb-8"
              >
                {freePlan.cta}
              </Link>

              {/* Features */}
              <div className="border-t border-gray-100 pt-6">
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-4">Bao gồm</p>
                <ul className="space-y-3">
                  {freePlan.features.map((f) => (
                    <li key={f.label} className="flex items-start gap-3">
                      {f.included ? (
                        <span className="mt-0.5 w-4 h-4 rounded-full bg-primary-50 flex items-center justify-center shrink-0">
                          <Check className="w-2.5 h-2.5 text-primary" strokeWidth={3} />
                        </span>
                      ) : (
                        <span className="mt-0.5 w-4 h-4 rounded-full bg-gray-100 flex items-center justify-center shrink-0">
                          <X className="w-2.5 h-2.5 text-gray-300" strokeWidth={3} />
                        </span>
                      )}
                      <span className={`text-sm ${f.included ? "text-gray-700" : "text-gray-300"}`}>
                        {f.label}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </StaggerItem>

          {/* ── Pro card ── brand green gradient */}
          <StaggerItem>
            <div
              className="h-full flex flex-col rounded-3xl p-8 relative overflow-hidden hover:shadow-2xl hover:shadow-primary/30 hover:-translate-y-1 transition-all duration-300"
              style={{
                background: "linear-gradient(135deg, #1A8344 0%, #0f5c2e 100%)",
              }}
            >
              {/* Subtle inner highlight */}
              <div
                className="absolute inset-0 pointer-events-none rounded-3xl"
                style={{
                  background:
                    "radial-gradient(ellipse at 70% 0%, rgba(255,255,255,0.15) 0%, transparent 55%)",
                }}
              />

              {/* Popular badge */}
              <div className="absolute top-6 right-6">
                <span className="text-xs font-semibold bg-white/20 text-white px-3 py-1 rounded-full border border-white/30">
                  Phổ biến nhất
                </span>
              </div>

              {/* Plan badge */}
              <div className="flex items-center gap-3 mb-6 relative">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <proPlan.icon className="w-5 h-5 text-white" />
                </div>
                <span className="font-semibold text-white text-lg">{proPlan.name}</span>
              </div>

              {/* Price */}
              <div className="mb-2 relative">
                <span className="text-5xl font-bold text-white tracking-tight">{proPlan.price}</span>
                <span className="text-2xl font-semibold text-white/60 ml-1">{proPlan.unit}</span>
              </div>
              <p className="text-white/60 text-sm mb-1 relative">/ {proPlan.period}</p>
              <p className="text-white/75 text-sm leading-relaxed mt-3 mb-8 relative">{proPlan.description}</p>

              {/* CTA */}
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="relative mb-8">
                <Link
                  href={proPlan.ctaHref}
                  className="block w-full text-center bg-white text-primary px-6 py-3.5 rounded-full font-semibold hover:bg-white/90 transition-colors duration-200 shadow-lg shadow-black/20"
                >
                  {proPlan.cta}
                </Link>
              </motion.div>

              {/* Features */}
              <div className="border-t border-white/20 pt-6 relative">
                <p className="text-xs font-semibold text-white/50 uppercase tracking-wide mb-4">Bao gồm tất cả</p>
                <ul className="space-y-3">
                  {proPlan.features.map((f) => (
                    <li key={f.label} className="flex items-start gap-3">
                      <span className="mt-0.5 w-4 h-4 rounded-full bg-white/20 flex items-center justify-center shrink-0">
                        <Check className="w-2.5 h-2.5 text-white" strokeWidth={3} />
                      </span>
                      <span className="text-sm text-white/85">{f.label}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </StaggerItem>
        </StaggerContainer>

        {/* Bottom note */}
        <FadeUp delay={0.3}>
          <p className="text-center text-gray-400 text-sm mt-10">
            Hủy bất cứ lúc nào · Không cần thẻ tín dụng để bắt đầu · Thanh toán an toàn qua VNPay & Momo
          </p>
        </FadeUp>
      </div>
    </section>
  );
}
