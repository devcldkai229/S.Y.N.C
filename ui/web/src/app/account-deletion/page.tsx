import type { Metadata } from "next";
import { LegalDocPage } from "@/components/legal/LegalDocPage";

export const metadata: Metadata = {
  title: "Xoá tài khoản | SYNC",
  description: "Hướng dẫn xoá tài khoản & dữ liệu SYNC (URL xoá tài khoản cho Google Play).",
};

export default function AccountDeletionPage() {
  return <LegalDocPage doc="deletion" locale="vi" />;
}
