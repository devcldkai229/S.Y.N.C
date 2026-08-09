import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Tuyên bố miễn trừ y tế | SYNC",
  description: "Tuyên bố miễn trừ trách nhiệm y tế — CYN AI và nội dung thể hình/dinh dưỡng không thay thế tư vấn y khoa.",
};

export default function HealthDisclaimerPage() {
  return <LegalDocPage doc="health" locale="vi" />;
}
