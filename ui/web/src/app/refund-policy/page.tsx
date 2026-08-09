import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Chính sách hoàn tiền & huỷ | SYNC",
  description: "Chính sách hoàn tiền, huỷ gói Premium/Ultra và đơn hàng thực phẩm trên SYNC.",
};

export default function RefundPolicyPage() {
  return <LegalDocPage doc="refund" locale="vi" />;
}
