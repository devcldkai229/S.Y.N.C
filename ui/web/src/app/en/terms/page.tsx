import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Terms of Service | SYNC",
  description: "SYNC Lifestyle terms of service.",
};

export default function EnTermsPage() {
  return <LegalDocPage doc="terms" locale="en" />;
}
