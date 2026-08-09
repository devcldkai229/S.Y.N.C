"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Calendar, Crown, Loader2, ArrowRight, Zap } from "lucide-react";
import Navbar from "@/components/landing/Navbar";
import { getUserToken, useUserAuthStore } from "@/stores/user-auth.store";
import {
  isActivePaymentSubscription,
  isPaidSubscriptionTier,
  resolvePremiumAccess,
} from "@/lib/subscription-access";
import type { ActiveSubscription } from "@/services/subscription.service";

export default function ProfilePage() {
  const router = useRouter();
  const { user, loadFromStorage, updateSubscriptionTier } = useUserAuthStore();
  const [loading, setLoading] = useState(true);
  const [activeSub, setActiveSub] = useState<ActiveSubscription | null>(null);
  const [tier, setTier] = useState("Free");

  useEffect(() => {
    loadFromStorage();
  }, [loadFromStorage]);

  useEffect(() => {
    if (!getUserToken()) {
      router.replace("/login?redirect=/profile");
      return;
    }

    resolvePremiumAccess()
      .then((access) => {
        setActiveSub(access.activeSub);
        setTier(access.subscriptionTier);
        updateSubscriptionTier(access.subscriptionTier);
      })
      .catch(() => {
        setActiveSub(null);
        setTier("Free");
      })
      .finally(() => setLoading(false));
  }, [router, updateSubscriptionTier]);

  const hasPremium =
    isActivePaymentSubscription(activeSub) || isPaidSubscriptionTier(tier);
  const planName = activeSub?.subscriptionPlanName || (hasPremium ? tier : "Free");
  const expiry = activeSub?.expiredAt ? new Date(activeSub.expiredAt) : null;
  const isCancelled = activeSub?.status === "Cancelled";

  return (
    <div className="min-h-screen bg-[#FAFCFA]">
      <Navbar />
      <main className="pt-24 pb-16 px-4">
        <div className="max-w-lg mx-auto">
          <h1 className="font-heading text-2xl font-bold text-gray-900 mb-1">
            Hồ sơ của tôi
          </h1>
          {user && (
            <p className="text-sm text-gray-500 mb-8 truncate">
              {user.fullName}
              {user.email ? ` · ${user.email}` : ""}
            </p>
          )}

          {loading ? (
            <div className="flex items-center justify-center gap-2 py-16 text-gray-400 text-sm">
              <Loader2 className="w-5 h-5 animate-spin" />
              Đang tải gói đăng ký…
            </div>
          ) : (
            <div
              className={
                hasPremium
                  ? "rounded-3xl p-7 text-white shadow-xl shadow-primary/20"
                  : "rounded-3xl p-7 bg-white border border-gray-200 shadow-sm"
              }
              style={
                hasPremium
                  ? { background: "linear-gradient(135deg, #1A8344 0%, #0f5c2e 100%)" }
                  : undefined
              }
            >
              <div className="flex items-center gap-3 mb-6">
                <div
                  className={
                    hasPremium
                      ? "w-11 h-11 rounded-xl bg-white/20 flex items-center justify-center"
                      : "w-11 h-11 rounded-xl bg-gray-100 flex items-center justify-center"
                  }
                >
                  {hasPremium ? (
                    <Crown className="w-5 h-5 text-white" />
                  ) : (
                    <Zap className="w-5 h-5 text-gray-500" />
                  )}
                </div>
                <div>
                  <p
                    className={
                      hasPremium
                        ? "text-xs text-white/70 uppercase tracking-wide"
                        : "text-xs text-gray-400 uppercase tracking-wide"
                    }
                  >
                    Gói đăng ký hiện tại
                  </p>
                  <p
                    className={
                      hasPremium
                        ? "text-xl font-bold text-white"
                        : "text-xl font-bold text-gray-900"
                    }
                  >
                    {planName}
                  </p>
                </div>
                <span
                  className={
                    hasPremium
                      ? "ml-auto text-xs font-semibold bg-white/20 text-white px-3 py-1 rounded-full border border-white/30"
                      : "ml-auto text-xs font-semibold bg-gray-100 text-gray-600 px-3 py-1 rounded-full"
                  }
                >
                  Đang sử dụng
                </span>
              </div>

              {expiry && (
                <p
                  className={
                    hasPremium
                      ? "text-sm text-white/80 flex items-center gap-1.5 mb-6"
                      : "text-sm text-gray-500 flex items-center gap-1.5 mb-6"
                  }
                >
                  <Calendar className="w-4 h-4 shrink-0" />
                  {isCancelled ? "Hết hạn vào " : "Gia hạn / hết hạn: "}
                  {expiry.toLocaleDateString("vi-VN")}
                  {isCancelled ? " (đã huỷ gia hạn)" : ""}
                </p>
              )}

              {!hasPremium && (
                <p className="text-sm text-gray-500 mb-6 leading-relaxed">
                  Bạn đang dùng gói Free. Nâng cấp Premium để mở CYN không giới hạn,
                  Adaptive Coaching và Insight.
                </p>
              )}

              {hasPremium && !expiry && (
                <p className="text-sm text-white/80 mb-6 leading-relaxed">
                  Tài khoản đang có quyền Premium.
                </p>
              )}

              <Link
                href="/subscription"
                className={
                  hasPremium
                    ? "inline-flex items-center gap-2 text-sm font-medium text-white/90 hover:text-white transition-colors"
                    : "inline-flex items-center justify-center gap-2 w-full bg-primary text-white px-5 py-3 rounded-full text-sm font-semibold hover:bg-primary-dark transition-colors"
                }
              >
                {hasPremium ? "Xem bảng giá" : "Nâng cấp Premium"}
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
