"use client";

import { usePathname } from "next/navigation";
import { useAuthStore } from "@/stores/auth.store";
import { Bell, ChevronRight } from "lucide-react";

const BREADCRUMB_MAP: Record<string, string> = {
  "/admin/dashboard":           "Dashboard",
  "/admin/users":               "Users",
  "/admin/exercises":           "Exercises",
  "/admin/exercises/new":       "New Exercise",
  "/admin/subscription-plans":  "Subscription Plans",
  "/admin/promotions":          "Promotions",
  "/admin/promotions/new":      "New Campaign",
};

function getLabel(pathname: string): string {
  if (BREADCRUMB_MAP[pathname]) return BREADCRUMB_MAP[pathname];
  if (pathname.startsWith("/admin/exercises/"))          return "Edit Exercise";
  if (pathname.startsWith("/admin/subscription-plans/")) return "Edit Plan";
  if (pathname.startsWith("/admin/promotions/"))         return "Edit Campaign";
  if (pathname.startsWith("/admin/users/"))              return "User Detail";
  return "Admin";
}

export function AdminTopbar() {
  const pathname = usePathname() ?? "";
  const user     = useAuthStore((s) => s.user);

  const initials = user?.fullName
    ? user.fullName.split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase()
    : "AD";

  const label = getLabel(pathname);

  return (
    <header className="h-16 px-6 border-b border-gray-100 bg-white flex items-center justify-between shrink-0">
      {/* Breadcrumb */}
      <div className="flex items-center gap-1.5 text-sm">
        <span className="text-gray-400 font-medium">Admin</span>
        <ChevronRight className="w-3.5 h-3.5 text-gray-300" />
        <span className="text-gray-900 font-semibold">{label}</span>
      </div>

      {/* Right side */}
      <div className="flex items-center gap-3">
        <button className="relative w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 rounded-full bg-primary" />
        </button>

        <div className="flex items-center gap-2.5 pl-3 border-l border-gray-100">
          <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white text-xs font-bold shrink-0">
            {initials}
          </div>
          <div className="hidden sm:block">
            <p className="text-xs font-semibold text-gray-800 leading-none">{user?.fullName ?? "Admin"}</p>
            <p className="text-[11px] text-gray-400 mt-0.5">{user?.email}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
