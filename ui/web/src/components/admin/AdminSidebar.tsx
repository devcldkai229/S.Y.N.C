"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard, Users, Dumbbell, CreditCard, Megaphone,
  LogOut, ChevronLeft, ChevronRight, ClipboardList,
  ListChecks, Bell, Send, MessagesSquare, Store, ShoppingCart,
  Wallet, ArrowLeftRight, Salad, Trophy,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth.store";
import { Button } from "@/components/ui/button";
import { SyncLogo } from "@/components/ui/SyncLogo";
import { useState } from "react";

type NavItem  = { href: string; label: string; icon: React.ElementType };
type NavGroup = { section: string; items: NavItem[] };

const NAV_GROUPS: NavGroup[] = [
  {
    section: "Tổng quan",
    items: [
      { href: "/admin/dashboard", label: "Tổng quan",  icon: LayoutDashboard },
      { href: "/admin/users",     label: "Người dùng", icon: Users },
    ],
  },
  {
    section: "Commerce",
    items: [
      { href: "/admin/marketplace",  label: "Marketplace",  icon: Store },
      { href: "/admin/orders",       label: "Đơn hàng",     icon: ShoppingCart },
      { href: "/admin/commissions",  label: "Hoa hồng",     icon: Wallet },
    ],
  },
  {
    section: "Payment",
    items: [
      { href: "/admin/transactions",      label: "Giao dịch",    icon: ArrowLeftRight },
      { href: "/admin/subscriptions",     label: "Gói đăng ký",  icon: ClipboardList },
      { href: "/admin/subscription-plans",label: "Gói dịch vụ",  icon: CreditCard },
      { href: "/admin/promotions",        label: "Khuyến mãi",   icon: Megaphone },
    ],
  },
  {
    section: "Content",
    items: [
      { href: "/admin/exercises",         label: "Bài tập",        icon: Dumbbell },
      { href: "/admin/workout-templates", label: "Mẫu buổi tập",   icon: ListChecks },
      { href: "/admin/nutrition",         label: "Dinh dưỡng",     icon: Salad },
    ],
  },
  {
    section: "Engagement",
    items: [
      { href: "/admin/achievements", label: "Thành tựu",  icon: Trophy },
      { href: "/admin/community",    label: "Cộng đồng",  icon: MessagesSquare },
      { href: "/admin/content-reports", label: "Báo cáo", icon: ClipboardList },
    ],
  },
  {
    section: "Notifications",
    items: [
      { href: "/admin/notification-templates", label: "Mẫu thông báo", icon: Bell },
      { href: "/admin/notifications",          label: "Gửi thông báo", icon: Send },
    ],
  },
];

export function AdminSidebar() {
  const pathname = usePathname() ?? "";
  const router   = useRouter();
  const logout   = useAuthStore((s) => s.logout);
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
      <div className={cn("flex items-center gap-2 px-4 h-14 border-b border-border shrink-0", collapsed && "justify-center px-0")}>
        {collapsed ? (
          <Image
            src="/images/favicon-32.png"
            alt="SYNC"
            width={28}
            height={28}
            className="h-7 w-7 rounded"
          />
        ) : (
          <SyncLogo height={28} className="h-7 w-auto" />
        )}
      </div>

      {/* Nav */}
      <nav className="flex-1 py-3 overflow-y-auto overflow-x-hidden">
        {NAV_GROUPS.map((group) => (
          <div key={group.section} className="mb-1">
            {/* Section label */}
            {!collapsed && (
              <p className="px-4 py-1.5 text-[10px] font-semibold uppercase tracking-widest text-muted-foreground/60">
                {group.section}
              </p>
            )}
            {collapsed && <div className="mx-2 my-1 h-px bg-border" />}

            <div className="px-2 space-y-0.5">
              {group.items.map(({ href, label, icon: Icon }) => {
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
            </div>
          </div>
        ))}
      </nav>

      {/* Logout */}
      <div className="p-2 border-t border-border shrink-0">
        <Button
          variant="ghost"
          size="sm"
          className={cn(
            "w-full text-muted-foreground hover:text-destructive",
            collapsed ? "justify-center px-0" : "justify-start gap-3"
          )}
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
