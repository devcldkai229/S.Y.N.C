import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Privacy Policy | SYNC",
  description: "SYNC Lifestyle privacy policy.",
};

export default function EnPrivacyPage() {
  return <LegalDocPage doc="privacy" locale="en" />;
}
