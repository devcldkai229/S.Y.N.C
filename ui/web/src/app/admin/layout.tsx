"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuthStore } from "@/stores/auth.store";
import { isAdminRole } from "@/lib/jwt";
import { AdminSidebar } from "@/components/admin/AdminSidebar";
import { AdminTopbar } from "@/components/admin/AdminTopbar";
import { Toaster } from "@/components/ui/sonner";
import { Loader2 } from "lucide-react";

function AdminBootScreen() {
  return (
    <div className="flex h-screen items-center justify-center bg-gray-50">
      <Loader2 className="h-8 w-8 animate-spin text-primary" aria-label="Đang tải" />
    </div>
  );
}

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { isAuthenticated, user, loadFromStorage } = useAuthStore();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    loadFromStorage();
    setReady(true);
  }, [loadFromStorage]);

  const isLogin = pathname === "/admin/login";
  const canAccess = isAuthenticated && isAdminRole(user?.role);

  useEffect(() => {
    if (!ready || isLogin) return;
    if (!canAccess) {
      router.replace("/admin/login");
    }
  }, [ready, isLogin, canAccess, router]);

  // Redirect signed-in admins away from the login screen (avoids odd half-states).
  useEffect(() => {
    if (!ready || !isLogin) return;
    if (canAccess) {
      router.replace("/admin/dashboard");
    }
  }, [ready, isLogin, canAccess, router]);

  if (isLogin) {
    if (!ready) return <AdminBootScreen />;
    if (canAccess) return <AdminBootScreen />;
    return (
      <>
        {children}
        <Toaster />
      </>
    );
  }

  if (!ready || !canAccess) {
    return <AdminBootScreen />;
  }

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      <AdminSidebar />
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        <AdminTopbar />
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
      <Toaster />
    </div>
  );
}
