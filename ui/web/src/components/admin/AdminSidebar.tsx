"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard, Users, Dumbbell, CreditCard, Megaphone, LogOut, Zap,
  ChevronLeft, ChevronRight,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth.store";
import { useState } from "react";

const NAV_ITEMS = [
  { href: "/admin/dashboard",           label: "Dashboard",   icon: LayoutDashboard },
  { href: "/admin/users",               label: "Users",       icon: Users },
  { href: "/admin/exercises",           label: "Exercises",   icon: Dumbbell },
  { href: "/admin/subscription-plans",  label: "Plans",       icon: CreditCard },
  { href: "/admin/promotions",          label: "Promotions",  icon: Megaphone },
];

export function AdminSidebar() {
  const pathname  = usePathname() ?? "";
  const router    = useRouter();
  const logout    = useAuthStore((s) => s.logout);
  const user      = useAuthStore((s) => s.user);
  const [collapsed, setCollapsed] = useState(false);

  const handleLogout = () => {
    logout();
    router.push("/admin/login");
  };

  const initials = user?.fullName
    ? user.fullName.trim().split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase()
    : "AD";

  return (
    <aside
      className={cn(
        "relative flex flex-col bg-white border-r border-gray-100 transition-all duration-300 shrink-0",
        collapsed ? "w-16" : "w-60"
      )}
    >
      {/* Logo */}
      <div
        className={cn(
          "flex items-center gap-2.5 px-5 h-16 border-b border-gray-100",
          collapsed && "justify-center px-0"
        )}
      >
        <div className="w-8 h-8 bg-primary rounded-xl flex items-center justify-center shrink-0">
          <Zap className="w-4 h-4 text-white fill-white" />
        </div>
        {!collapsed && (
          <div className="flex items-center gap-1.5 min-w-0">
            <span className="font-bold text-base tracking-tight text-gray-900">SYNC</span>
            <span className="text-[10px] font-semibold bg-primary/10 text-primary px-1.5 py-0.5 rounded-full shrink-0">
              Admin
            </span>
          </div>
        )}
      </div>

      {/* Nav */}
      <nav className="flex-1 py-5 space-y-0.5 px-3 overflow-hidden">
        {!collapsed && (
          <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-widest px-3 pb-2">
            Menu
          </p>
        )}
        {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || pathname.startsWith(href + "/");
          return (
            <Link
              key={href}
              href={href}
              title={collapsed ? label : undefined}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all",
                active
                  ? "bg-primary text-white shadow-sm shadow-primary/20"
                  : "text-gray-500 hover:bg-gray-50 hover:text-gray-900",
                collapsed && "justify-center px-0"
              )}
            >
              <Icon className="w-4 h-4 shrink-0" />
              {!collapsed && <span>{label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* User info + logout */}
      <div className="p-3 border-t border-gray-100 space-y-1">
        {!collapsed && user && (
          <div className="flex items-center gap-2.5 px-3 py-2 mb-1">
            <div className="w-7 h-7 rounded-full bg-primary flex items-center justify-center text-white text-xs font-bold shrink-0">
              {initials}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-gray-800 truncate">{user.fullName}</p>
              <p className="text-[10px] text-gray-400 truncate">{user.email}</p>
            </div>
          </div>
        )}
        <button
          onClick={handleLogout}
          title={collapsed ? "Đăng xuất" : undefined}
          className={cn(
            "flex items-center gap-3 w-full px-3 py-2.5 rounded-xl text-sm font-medium text-gray-400 hover:bg-red-50 hover:text-red-500 transition-all",
            collapsed && "justify-center px-0"
          )}
        >
          <LogOut className="w-4 h-4 shrink-0" />
          {!collapsed && "Đăng xuất"}
        </button>
      </div>

      {/* Collapse toggle */}
      <button
        onClick={() => setCollapsed((c) => !c)}
        className="absolute -right-3 top-[4.25rem] z-10 w-6 h-6 rounded-full bg-white border border-gray-200 flex items-center justify-center shadow-sm hover:bg-gray-50 transition-colors"
      >
        {collapsed
          ? <ChevronRight className="w-3 h-3 text-gray-500" />
          : <ChevronLeft className="w-3 h-3 text-gray-500" />
        }
      </button>
    </aside>
  );
}
