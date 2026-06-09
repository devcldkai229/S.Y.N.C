"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { CheckCircle, Loader2, XCircle, ArrowRight } from "lucide-react";
import Link from "next/link";
import { subscriptionService } from "@/services/subscription.service";

function SuccessContent() {
  const searchParams = useSearchParams();
  const router       = useRouter();

  // PayOS trả về orderCode trên query string
  const orderCodeParam = searchParams?.get("orderCode");
  const orderCode = orderCodeParam
    ? Number(orderCodeParam)
    : Number(sessionStorage.getItem("sync_pending_order") ?? "0");

  const [status,  setStatus]  = useState<"polling" | "succeeded" | "failed">("polling");
  const [attempt, setAttempt] = useState(0);
  const MAX_ATTEMPTS = 12; // ~60s

  useEffect(() => {
    if (!orderCode) { setStatus("failed"); return; }

    let cancelled = false;

    const poll = async () => {
      for (let i = 0; i < MAX_ATTEMPTS; i++) {
        if (cancelled) return;
        const tx = await subscriptionService.getTransactionByOrderCode(orderCode);
        setAttempt(i + 1);

        if (tx?.status === "Succeeded") {
          sessionStorage.removeItem("sync_pending_order");
          setStatus("succeeded");
          return;
        }
        if (tx?.status === "Failed" || tx?.status === "Cancelled") {
          setStatus("failed");
          return;
        }
        // Pending — chờ 5s rồi thử lại
        await new Promise((r) => setTimeout(r, 5000));
      }
      // Timeout
      setStatus("failed");
    };

    poll();
    return () => { cancelled = true; };
  }, [orderCode]);

  if (status === "polling") {
    return (
      <div className="flex flex-col items-center gap-4">
        <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center">
          <Loader2 className="w-7 h-7 text-primary animate-spin" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900">Đang xác nhận thanh toán…</h1>
        <p className="text-gray-500 text-sm">
          Đang kiểm tra ({attempt}/{MAX_ATTEMPTS}). Vui lòng không đóng trang này.
        </p>
      </div>
    );
  }

  if (status === "succeeded") {
    return (
      <div className="flex flex-col items-center gap-4">
        <div className="w-16 h-16 rounded-full bg-green-50 flex items-center justify-center">
          <CheckCircle className="w-8 h-8 text-green-500" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900">Thanh toán thành công!</h1>
        <p className="text-gray-500 text-sm text-center max-w-xs">
          Tài khoản của bạn đã được nâng cấp lên Premium. Tận hưởng đầy đủ tính năng ngay bây giờ!
        </p>
        <Link
          href="/"
          className="mt-4 flex items-center gap-2 bg-primary text-white px-6 py-3 rounded-full font-medium text-sm hover:bg-primary/90 transition-colors shadow-md shadow-primary/20"
        >
          Về trang chủ <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-4">
      <div className="w-16 h-16 rounded-full bg-red-50 flex items-center justify-center">
        <XCircle className="w-8 h-8 text-red-400" />
      </div>
      <h1 className="text-2xl font-bold text-gray-900">Không thể xác nhận thanh toán</h1>
      <p className="text-gray-500 text-sm text-center max-w-xs">
        Nếu bạn đã chuyển khoản thành công, đăng nhập lại để kiểm tra hoặc liên hệ hỗ trợ.
      </p>
      <button
        onClick={() => router.push("/subscription")}
        className="mt-4 flex items-center gap-2 bg-primary text-white px-6 py-3 rounded-full font-medium text-sm hover:bg-primary/90 transition-colors"
      >
        Thử lại <ArrowRight className="w-4 h-4" />
      </button>
    </div>
  );
}

export default function PaymentSuccessPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <Suspense>
        <SuccessContent />
      </Suspense>
    </div>
  );
}
