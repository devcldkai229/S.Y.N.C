import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Account Deletion | SYNC",
  description: "How to delete your SYNC account and what data is affected.",
};

export default function EnDeletionPage() {
  return <LegalDocPage doc="deletion" locale="en" />;
}
