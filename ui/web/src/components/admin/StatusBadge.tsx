import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

type Status = "active" | "inactive" | "banned" | "suspended" | "running" | "upcoming" | "expired" | string;

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  active:    { label: "Active",    className: "bg-green-100 text-green-700 border-green-200" },
  inactive:  { label: "Inactive",  className: "bg-gray-100 text-gray-600 border-gray-200" },
  banned:    { label: "Banned",    className: "bg-red-100 text-red-700 border-red-200" },
  suspended: { label: "Suspended", className: "bg-orange-100 text-orange-700 border-orange-200" },
  running:   { label: "Running",   className: "bg-green-100 text-green-700 border-green-200" },
  upcoming:  { label: "Upcoming",  className: "bg-blue-100 text-blue-700 border-blue-200" },
  expired:   { label: "Expired",   className: "bg-gray-100 text-gray-500 border-gray-200" },
  true:      { label: "Active",    className: "bg-green-100 text-green-700 border-green-200" },
  false:     { label: "Inactive",  className: "bg-gray-100 text-gray-500 border-gray-200" },
};

interface StatusBadgeProps {
  status: Status | boolean;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const key   = String(status).toLowerCase();
  const entry = STATUS_MAP[key] ?? { label: String(status), className: "bg-gray-100 text-gray-600 border-gray-200" };

  return (
    <Badge variant="outline" className={cn("text-xs font-medium", entry.className, className)}>
      {entry.label}
    </Badge>
  );
}
