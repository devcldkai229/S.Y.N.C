import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Điều khoản dịch vụ | SYNC",
  description: "Điều khoản dịch vụ nền tảng SYNC Lifestyle.",
};

export default function TermsPage() {
  return <LegalDocPage doc="terms" locale="vi" />;
}
