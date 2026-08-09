import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Tiêu chuẩn cộng đồng | SYNC",
  description: "Tiêu chuẩn cộng đồng SYNC Social.",
};

export default function CommunityStandardsPage() {
  return <LegalDocPage doc="community" locale="vi" />;
}
