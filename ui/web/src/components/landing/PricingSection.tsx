"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Check, Loader2, Tag, Zap, X, Crown } from "lucide-react";
import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";
import { motion } from "framer-motion";
import { subscriptionService, SubscriptionPlan } from "@/services/subscription.service";
import { getUserToken } from "@/stores/user-auth.store";

const FREE_FEATURES = [
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
];

export default function PricingSection() {
  const router = useRouter();

  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [coupon, setCoupon] = useState("");
  const [purchasing, setPurchasing] = useState<string | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    subscriptionService.getPlans()
      .then((data) => setPlans(data.filter((p) => p.isActive)))
      .catch(() => setPlans([]))
      .finally(() => setLoading(false));
  }, []);

  const handleSubscribe = async (plan: SubscriptionPlan) => {
    if (!getUserToken()) {
      router.push(`/login?redirect=/subscription`);
      return;
    }
    setError("");
    setPurchasing(plan.id);
    try {
      const link = await subscriptionService.createPaymentLink(
        plan.id,
        coupon.trim() || undefined
      );
      // Save orderCode so that success page can poll
      sessionStorage.setItem("sync_pending_order", String(link.orderCode));
      window.location.href = link.checkoutUrl;
    } catch (e) {
      setError(e instanceof Error ? e.message : "Có lỗi xảy ra. Vui lòng thử lại.");
    } finally {
      setPurchasing(null);
    }
  };

  if (loading) {
    return (
      <div className="py-24 flex justify-center items-center">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  const premiumPlans = plans.length > 0 ? plans : [{
    id: "",
    name: "Premium",
    monthlyPrice: 99000,
    currency: "VND",
    aiUsageLimitPerMonth: 0,
    premiumWorkoutAccess: true,
    priorityAiResponses: true,
    isActive: true,
    features: ["Tất cả tính năng Free", "Thông báo AI cá nhân hóa", "Bài tập nâng cao", "AI phản hồi ưu tiên"],
  } as SubscriptionPlan];

  return (
    <section id="pricing" className="py-24 px-4 bg-white relative overflow-hidden">
      <div className="max-w-5xl mx-auto relative">
        {/* Header */}
        <FadeUp className="text-center mb-12">
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

        {/* Coupon input */}
        <FadeUp delay={0.1} className="flex items-center justify-center gap-2 mb-12">
          <div className="relative">
            <Tag className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={coupon}
              onChange={(e) => setCoupon(e.target.value.toUpperCase())}
              placeholder="Mã khuyến mãi (tuỳ chọn)"
              className="pl-10 pr-4 py-3 text-sm border border-gray-200 rounded-2xl bg-white outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 w-60 transition-all shadow-sm"
            />
          </div>
        </FadeUp>

        {error && (
          <FadeUp className="max-w-md mx-auto">
            <p className="text-center text-sm text-red-600 bg-red-50 border border-red-100 rounded-2xl px-4 py-3 mb-8">
              {error}
            </p>
          </FadeUp>
        )}

        {/* Cards */}
        <StaggerContainer
          className="grid grid-cols-1 md:grid-cols-2 gap-8 items-stretch"
          stagger={0.12}
        >
          {/* ── Free card ── */}
          <StaggerItem>
            <div className="h-full flex flex-col bg-white border-2 border-gray-200 rounded-3xl p-8 shadow-md hover:shadow-xl hover:-translate-y-1 transition-all duration-300">
              {/* Plan badge */}
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center">
                  <Zap className="w-5 h-5 text-gray-500" />
                </div>
                <span className="font-semibold text-gray-800 text-lg">Free</span>
              </div>

              {/* Price */}
              <div className="mb-2">
                <span className="text-5xl font-bold text-gray-900 tracking-tight">0</span>
                <span className="text-2xl font-semibold text-gray-400 ml-1">đ</span>
              </div>
              <p className="text-gray-400 text-sm mb-1">/ mãi mãi</p>
              <p className="text-gray-500 text-sm leading-relaxed mt-3 mb-8">
                Khởi đầu hành trình fitness của bạn hoàn toàn miễn phí.
              </p>

              {/* CTA */}
              <div className="w-full text-center bg-gray-100 border border-gray-200 text-gray-500 px-6 py-3.5 rounded-full font-medium mb-8">
                Gói hiện tại
              </div>

              {/* Features */}
              <div className="border-t border-gray-100 pt-6 flex-1">
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-4">Bao gồm</p>
                <ul className="space-y-3">
                  {FREE_FEATURES.map((f) => (
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

          {/* ── Premium / Pro plan(s) ── */}
          {premiumPlans.map((plan) => {
            const isPurchasing = purchasing === plan.id;
            const features = plan.features?.length
              ? plan.features
              : buildFeatures(plan);

            return (
              <StaggerItem key={plan.id}>
                <div
                  className="h-full flex flex-col rounded-3xl p-8 relative overflow-hidden hover:shadow-2xl hover:shadow-primary/30 hover:-translate-y-1 transition-all duration-300 text-white"
                  style={{
                    background: "linear-gradient(135deg, #1A8344 0%, #0f5c2e 100%)",
                  }}
                >
                  {/* Radial glow highlight */}
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
                      <Crown className="w-5 h-5 text-white" />
                    </div>
                    <span className="font-semibold text-white text-lg">{plan.name}</span>
                  </div>

                  {/* Price */}
                  <div className="mb-2 relative">
                    <span className="text-5xl font-bold text-white tracking-tight">
                      {plan.monthlyPrice.toLocaleString("vi-VN")}
                    </span>
                    <span className="text-2xl font-semibold text-white/60 ml-1">đ</span>
                  </div>
                  <p className="text-white/60 text-sm mb-1 relative">/ tháng</p>
                  <p className="text-white/75 text-sm leading-relaxed mt-3 mb-8 relative">
                    {plan.description || "Mở khóa toàn bộ sức mạnh AI để đạt đỉnh cao thể lực."}
                  </p>

                  {/* CTA */}
                  <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="relative mb-8">
                    <button
                      onClick={() => handleSubscribe(plan)}
                      disabled={isPurchasing || !plan.id}
                      className="w-full flex items-center justify-center gap-2 bg-white text-primary py-3.5 rounded-full font-semibold hover:bg-white/95 transition-colors duration-200 shadow-lg shadow-black/20 disabled:opacity-60 disabled:cursor-not-allowed"
                    >
                      {isPurchasing && <Loader2 className="w-4 h-4 animate-spin" />}
                      {isPurchasing ? "Đang xử lý..." : "Nâng cấp ngay"}
                    </button>
                  </motion.div>

                  {/* Features */}
                  <div className="border-t border-white/20 pt-6 relative flex-1">
                    <p className="text-xs font-semibold text-white/50 uppercase tracking-wide mb-4">Bao gồm tất cả</p>
                    <ul className="space-y-3">
                      {features.map((f) => (
                        <li key={f} className="flex items-start gap-3">
                          <span className="mt-0.5 w-4 h-4 rounded-full bg-white/20 flex items-center justify-center shrink-0">
                            <Check className="w-2.5 h-2.5 text-white" strokeWidth={3} />
                          </span>
                          <span className="text-sm text-white/85">{f}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </StaggerItem>
            );
          })}
        </StaggerContainer>

        {/* Bottom note */}
        <FadeUp delay={0.3}>
          <p className="text-center text-gray-400 text-sm mt-10">
            Hủy bất cứ lúc nào · Không cần thẻ tín dụng để bắt đầu · Thanh toán an toàn qua VNPay, Momo & PayOS
          </p>
        </FadeUp>
      </div>
    </section>
  );
}

function buildFeatures(plan: SubscriptionPlan): string[] {
  return [
    "Tất cả tính năng Free",
    "Thông báo AI cá nhân hóa",
    plan.premiumWorkoutAccess && "Bài tập nâng cao & video HD",
    plan.priorityAiResponses && "AI phản hồi ưu tiên",
    plan.aiUsageLimitPerMonth === 0 && "AI không giới hạn",
  ].filter(Boolean) as string[];
}
