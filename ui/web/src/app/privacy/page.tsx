import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Chính sách quyền riêng tư | SYNC",
  description: "Chính sách quyền riêng tư của nền tảng SYNC Lifestyle.",
};

export default function PrivacyPage() {
  return <LegalDocPage doc="privacy" locale="vi" />;
}
