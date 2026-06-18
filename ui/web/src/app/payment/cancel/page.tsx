"use client";

import { useRouter } from "next/navigation";
import { XCircle, RefreshCw } from "lucide-react";

export default function PaymentCancelPage() {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="flex flex-col items-center gap-4 text-center max-w-sm">
        <div className="w-16 h-16 rounded-full bg-amber-50 flex items-center justify-center">
          <XCircle className="w-8 h-8 text-amber-400" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900">Thanh toán bị huỷ</h1>
        <p className="text-gray-500 text-sm">
          Bạn đã huỷ quá trình thanh toán. Không có khoản tiền nào bị trừ. Bạn có thể thử lại bất cứ lúc nào.
        </p>
        <button
          onClick={() => router.push("/subscription")}
          className="mt-4 flex items-center gap-2 bg-primary text-white px-6 py-3 rounded-full font-medium text-sm hover:bg-primary/90 transition-colors shadow-md shadow-primary/20"
        >
          <RefreshCw className="w-4 h-4" />
          Thử lại
        </button>
      </div>
    </div>
  );
}
