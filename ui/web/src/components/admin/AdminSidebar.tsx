"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  Dumbbell,
  CreditCard,
  Megaphone,
  LogOut,
  Zap,
  ChevronLeft,
  ChevronRight,
  ClipboardList,
  ListChecks,
  Bell,
  Send,
  MessagesSquare,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth.store";
import { Button } from "@/components/ui/button";
import { useState } from "react";

const NAV_ITEMS = [
  { href: "/admin/dashboard",              label: "Tổng quan",        icon: LayoutDashboard },
  { href: "/admin/users",                  label: "Người dùng",       icon: Users },
  { href: "/admin/subscriptions",          label: "Gói đăng ký",      icon: ClipboardList },
  { href: "/admin/subscription-plans",     label: "Gói dịch vụ",      icon: CreditCard },
  { href: "/admin/promotions",             label: "Khuyến mãi",       icon: Megaphone },
  { href: "/admin/exercises",              label: "Bài tập",          icon: Dumbbell },
  { href: "/admin/workout-templates",      label: "Mẫu buổi tập",     icon: ListChecks },
  { href: "/admin/notification-templates", label: "Mẫu thông báo",    icon: Bell },
  { href: "/admin/notifications",          label: "Gửi thông báo",    icon: Send },
  { href: "/admin/community",              label: "Cộng đồng",        icon: MessagesSquare },
];

export function AdminSidebar() {
  const pathname   = usePathname() ?? "";
  const router     = useRouter();
  const logout     = useAuthStore((s) => s.logout);
  const [collapsed, setCollapsed] = useState(false);

  const handleLogout = () => {
    logout();
    router.push("/admin/login");
  };

  return (
    <aside
      className={cn(
        "relative flex flex-col bg-card border-r border-border transition-all duration-300 shrink-0",
        collapsed ? "w-16" : "w-56"
      )}
    >
      {/* Logo */}
      <div className={cn("flex items-center gap-2 px-4 h-14 border-b border-border", collapsed && "justify-center px-0")}>
        <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center shrink-0">
          <Zap className="w-4 h-4 text-primary-foreground fill-current" />
        </div>
        {!collapsed && <span className="font-bold text-lg tracking-tight">SYNC</span>}
      </div>

      {/* Nav */}
      <nav className="flex-1 py-4 space-y-1 px-2 overflow-hidden">
        {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || pathname.startsWith(href + "/");
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors",
                active
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground",
                collapsed && "justify-center px-0"
              )}
              title={collapsed ? label : undefined}
            >
              <Icon className="w-4 h-4 shrink-0" />
              {!collapsed && label}
            </Link>
          );
        })}
      </nav>

      {/* Logout */}
      <div className="p-2 border-t border-border">
        <Button
          variant="ghost"
          size="sm"
          className={cn("w-full text-muted-foreground hover:text-destructive", collapsed ? "justify-center px-0" : "justify-start gap-3")}
          onClick={handleLogout}
          title={collapsed ? "Đăng xuất" : undefined}
        >
          <LogOut className="w-4 h-4 shrink-0" />
          {!collapsed && "Đăng xuất"}
        </Button>
      </div>

      {/* Collapse toggle */}
      <button
        onClick={() => setCollapsed((c) => !c)}
        className="absolute -right-3 top-16 z-10 w-6 h-6 rounded-full bg-card border border-border flex items-center justify-center shadow-sm hover:bg-muted transition-colors"
      >
        {collapsed ? <ChevronRight className="w-3 h-3" /> : <ChevronLeft className="w-3 h-3" />}
      </button>
    </aside>
  );
}
