"use client";

import { usePathname } from "next/navigation";
import { useAuthStore } from "@/stores/auth.store";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";

const BREADCRUMB_MAP: Record<string, string> = {
  "/admin/dashboard":                "Tổng quan",
  "/admin/users":                    "Người dùng",
  "/admin/subscriptions":            "Gói đăng ký người dùng",
  "/admin/subscriptions/new":        "Tạo gói đăng ký",
  "/admin/exercises":                "Bài tập",
  "/admin/exercises/new":            "Thêm bài tập",
  "/admin/subscription-plans":       "Gói dịch vụ",
  "/admin/subscription-plans/new":   "Tạo gói dịch vụ",
  "/admin/promotions":               "Khuyến mãi",
  "/admin/promotions/new":           "Tạo chiến dịch",
  "/admin/workout-templates":        "Mẫu buổi tập",
  "/admin/workout-templates/new":    "Tạo mẫu buổi tập",
  "/admin/notification-templates":   "Mẫu thông báo",
  "/admin/notification-templates/new": "Tạo mẫu thông báo",
  "/admin/notifications":            "Gửi thông báo",
  "/admin/community":                "Cộng đồng",
};

function getLabel(pathname: string): string {
  if (BREADCRUMB_MAP[pathname]) return BREADCRUMB_MAP[pathname];
  if (pathname.startsWith("/admin/exercises/"))            return "Sửa bài tập";
  if (pathname.startsWith("/admin/subscription-plans/"))   return "Sửa gói dịch vụ";
  if (pathname.startsWith("/admin/promotions/"))           return "Sửa chiến dịch";
  if (pathname.startsWith("/admin/subscriptions/"))        return "Sửa gói đăng ký";
  if (pathname.startsWith("/admin/workout-templates/"))    return "Sửa mẫu buổi tập";
  if (pathname.startsWith("/admin/notification-templates/")) return "Sửa mẫu thông báo";
  if (pathname.startsWith("/admin/users/"))                return "Chi tiết người dùng";
  return "Quản trị";
}

export function AdminTopbar() {
  const pathname = usePathname() ?? "";
  const user     = useAuthStore((s) => s.user);

  const initials = user?.fullName
    ? user.fullName.split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase()
    : "AD";

  return (
    <header className="h-14 px-4 border-b border-border bg-card flex items-center justify-between shrink-0">
      <div>
        <h1 className="text-sm font-semibold text-foreground">{getLabel(pathname)}</h1>
        <p className="text-xs text-muted-foreground">Trang quản trị</p>
      </div>

      <div className="flex items-center gap-2">
        <Button variant="ghost" size="icon" className="text-muted-foreground relative">
          <Bell className="w-4 h-4" />
        </Button>

        <div className="flex items-center gap-2">
          <Avatar className="w-7 h-7">
            <AvatarFallback className="text-xs bg-primary text-primary-foreground">
              {initials}
            </AvatarFallback>
          </Avatar>
          <div className="hidden sm:block">
            <p className="text-xs font-medium leading-none">{user?.fullName ?? "Admin"}</p>
            <p className="text-xs text-muted-foreground">{user?.email}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
