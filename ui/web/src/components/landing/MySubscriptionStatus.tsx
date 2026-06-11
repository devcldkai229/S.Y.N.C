"use client";

import { useEffect, useState } from "react";
import { Crown, Calendar, XCircle, Loader2 } from "lucide-react";
import { subscriptionService, ActiveSubscription } from "@/services/subscription.service";
import { getUserToken } from "@/stores/user-auth.store";

export default function MySubscriptionStatus() {
  const [sub,     setSub]     = useState<ActiveSubscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    if (!getUserToken()) { setLoading(false); return; }
    subscriptionService.getActiveSubscription()
      .then(setSub)
      .catch(() => setSub(null))
      .finally(() => setLoading(false));
  }, []);

  if (!getUserToken() || (!loading && !sub)) return null;

  const handleCancel = async () => {
    if (!confirm("Bạn sẽ giữ quyền Premium tới ngày hết hạn. Xác nhận huỷ?")) return;
    setCancelling(true);
    try {
      await subscriptionService.cancelSubscription();
      setMsg("Đã huỷ gia hạn. Gói vẫn còn hiệu lực tới ngày hết hạn.");
      const updated = await subscriptionService.getActiveSubscription();
      setSub(updated);
    } catch (e) {
      setMsg(e instanceof Error ? e.message : "Có lỗi xảy ra.");
    } finally {
      setCancelling(false);
    }
  };

  if (loading) {
    return (
      <div className="max-w-5xl mx-auto px-4 py-6">
        <div className="flex items-center gap-2 text-gray-400 text-sm">
          <Loader2 className="w-4 h-4 animate-spin" /> Đang tải gói của bạn...
        </div>
      </div>
    );
  }

  if (!sub) return null;

  const expiry  = sub.expiredAt ? new Date(sub.expiredAt) : null;
  const expired = expiry ? expiry < new Date() : false;
  const isCancelled = sub.status === "Cancelled";

  return (
    <div className="max-w-5xl mx-auto px-4 pt-8 pb-2">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4
                      bg-gradient-to-r from-primary/5 to-primary/10 border border-primary/20
                      rounded-2xl px-6 py-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
            <Crown className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-900">
              Gói {sub.subscriptionPlanName}
              {isCancelled && (
                <span className="ml-2 text-xs font-medium text-amber-600 bg-amber-50 px-2 py-0.5 rounded-full">
                  Đã huỷ gia hạn
                </span>
              )}
            </p>
            {expiry && (
              <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
                <Calendar className="w-3 h-3" />
                {expired ? "Đã hết hạn: " : (isCancelled ? "Hết hạn vào: " : "Gia hạn tiếp: ")}
                {expiry.toLocaleDateString("vi-VN")}
              </p>
            )}
            {msg && <p className="text-xs text-green-600 mt-1">{msg}</p>}
          </div>
        </div>

        {sub.status === "Active" && !isCancelled && (
          <button
            onClick={handleCancel}
            disabled={cancelling}
            className="flex items-center gap-1.5 text-sm text-red-500 hover:text-red-700
                       border border-red-200 hover:border-red-400 px-4 py-2 rounded-full
                       transition-colors disabled:opacity-50 shrink-0"
          >
            {cancelling ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <XCircle className="w-3.5 h-3.5" />}
            Huỷ gói
          </button>
        )}
      </div>
    </div>
  );
}
