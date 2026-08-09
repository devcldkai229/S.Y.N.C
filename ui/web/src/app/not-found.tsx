import Link from "next/link";
import { SyncLogo } from "@/components/ui/SyncLogo";

export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-stone-50 to-white px-4 text-stone-900">
      <Link href="/" className="mb-8">
        <SyncLogo height={32} className="h-8" />
      </Link>
      <p className="text-sm font-medium uppercase tracking-wide text-stone-500">404</p>
      <h1 className="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">
        Không tìm thấy trang
      </h1>
      <p className="mt-3 max-w-md text-center text-stone-600">
        Đường dẫn không tồn tại hoặc đã được di chuyển. Quay lại trang chủ SYNC.
      </p>
      <Link
        href="/"
        className="mt-8 rounded-full bg-stone-900 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-stone-800"
      >
        Về trang chủ
      </Link>
    </div>
  );
}
