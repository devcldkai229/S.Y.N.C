"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Check, Loader2, Tag, Zap } from "lucide-react";
import { subscriptionService, SubscriptionPlan } from "@/services/subscription.service";
import { getUserToken } from "@/stores/user-auth.store";

const FREE_FEATURES = [
  "Truy cập bài tập cơ bản",
  "Theo dõi streak & thành tích",
  "Mạng xã hội cộng đồng",
];

export default function PricingSection() {
  const router = useRouter();

  const [plans,      setPlans]      = useState<SubscriptionPlan[]>([]);
  const [loading,    setLoading]    = useState(true);
  const [coupon,     setCoupon]     = useState("");
  const [purchasing, setPurchasing] = useState<string | null>(null);
  const [error,      setError]      = useState("");

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
      // Lưu orderCode để trang success có thể poll
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
      <div className="py-24 flex justify-center">
        <Loader2 className="w-6 h-6 animate-spin text-primary" />
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
    <section className="py-20 px-4 bg-white">
      <div className="max-w-4xl mx-auto">
        {/* Coupon input */}
        <div className="flex items-center justify-center gap-2 mb-10">
          <div className="relative">
            <Tag className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={coupon}
              onChange={(e) => setCoupon(e.target.value.toUpperCase())}
              placeholder="Mã khuyến mãi (tuỳ chọn)"
              className="pl-9 pr-4 py-2.5 text-sm border border-gray-200 rounded-xl bg-white outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 w-56 transition-all"
            />
          </div>
        </div>

        {error && (
          <p className="text-center text-sm text-red-600 bg-red-50 border border-red-100 rounded-xl px-4 py-2.5 mb-6">
            {error}
          </p>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Free plan */}
          <div className="rounded-2xl border border-gray-100 p-8">
            <div className="inline-flex px-3 py-1 text-xs font-bold tracking-widest bg-gray-100 text-gray-500 rounded-full mb-4">
              FREE
            </div>
            <div className="text-4xl font-black text-gray-900 mb-1">0 ₫</div>
            <p className="text-sm text-gray-500 mb-6">mãi mãi</p>
            <ul className="space-y-3 mb-8">
              {FREE_FEATURES.map((f) => (
                <li key={f} className="flex items-center gap-2.5 text-sm text-gray-600">
                  <Check className="w-4 h-4 text-gray-400 shrink-0" />
                  {f}
                </li>
              ))}
            </ul>
            <div className="w-full text-center py-3 rounded-full border border-gray-200 text-sm font-medium text-gray-500">
              Gói hiện tại
            </div>
          </div>

          {/* Premium plan(s) */}
          {premiumPlans.map((plan) => {
            const features = plan.features?.length
              ? plan.features
              : buildFeatures(plan);
            const isPurchasing = purchasing === plan.id;

            return (
              <div
                key={plan.id}
                className="rounded-2xl bg-gradient-to-br from-primary to-primary/80 p-8 text-white relative overflow-hidden shadow-xl shadow-primary/25"
              >
                <div className="absolute top-0 right-0 w-48 h-48 rounded-full bg-white/5 -translate-y-1/2 translate-x-1/2" />
                <div className="relative">
                  <div className="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-bold tracking-widest bg-white/20 rounded-full mb-4">
                    <Zap className="w-3 h-3 fill-white" />
                    PREMIUM
                  </div>
                  <div className="text-4xl font-black mb-1">
                    {plan.monthlyPrice.toLocaleString("vi-VN")} ₫
                  </div>
                  <p className="text-sm text-white/70 mb-6">mỗi tháng</p>
                  <ul className="space-y-3 mb-8">
                    {features.map((f) => (
                      <li key={f} className="flex items-center gap-2.5 text-sm text-white/90">
                        <Check className="w-4 h-4 text-white shrink-0" />
                        {f}
                      </li>
                    ))}
                  </ul>
                  <button
                    onClick={() => handleSubscribe(plan)}
                    disabled={isPurchasing || !plan.id}
                    className="w-full flex items-center justify-center gap-2 bg-white text-primary py-3.5 rounded-full font-bold text-sm hover:bg-gray-50 transition-colors disabled:opacity-60 disabled:cursor-not-allowed shadow-md"
                  >
                    {isPurchasing && <Loader2 className="w-4 h-4 animate-spin" />}
                    {isPurchasing ? "Đang xử lý..." : "Nâng cấp ngay"}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

function buildFeatures(plan: SubscriptionPlan): string[] {
  return [
    "Tất cả tính năng Free",
    "Thông báo AI cá nhân hóa",
    plan.premiumWorkoutAccess && "Bài tập nâng cao",
    plan.priorityAiResponses  && "AI phản hồi ưu tiên",
    plan.aiUsageLimitPerMonth === 0 && "AI không giới hạn",
  ].filter(Boolean) as string[];
}
