import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Community Standards | SYNC",
  description: "SYNC Social community standards and reporting.",
};

export default function EnCommunityPage() {
  return <LegalDocPage doc="community" locale="en" />;
}
