import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Health Disclaimer | SYNC",
  description: "Medical disclaimer for SYNC lifestyle and CYN AI content.",
};

export default function EnHealthPage() {
  return <LegalDocPage doc="health" locale="en" />;
}
