import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Liên hệ & thông tin doanh nghiệp | SYNC",
  description: "Thông tin pháp nhân, kênh hỗ trợ và liên hệ của SYNC.",
};

export default function ContactPage() {
  return <LegalDocPage doc="contact" locale="vi" />;
}
