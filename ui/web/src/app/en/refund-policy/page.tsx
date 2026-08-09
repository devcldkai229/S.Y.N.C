import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Refund & Cancellation | SYNC",
  description: "SYNC refund and subscription cancellation policy.",
};

export default function EnRefundPage() {
  return <LegalDocPage doc="refund" locale="en" />;
}
