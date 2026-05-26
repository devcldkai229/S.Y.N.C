"use client";

import { usePathname } from "next/navigation";
import { useAuthStore } from "@/stores/auth.store";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";

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

  return (
    <header className="h-14 px-4 border-b border-border bg-card flex items-center justify-between shrink-0">
      <div>
        <h1 className="text-sm font-semibold text-foreground">{getLabel(pathname)}</h1>
        <p className="text-xs text-muted-foreground">Admin Panel</p>
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
