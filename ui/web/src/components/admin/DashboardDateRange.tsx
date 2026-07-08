"use client";

import { cn } from "@/lib/utils";
import type { DashboardDays } from "@/hooks/admin/use-dashboard";

const OPTIONS: { value: DashboardDays; label: string }[] = [
  { value: 7, label: "7 ngày" },
  { value: 30, label: "30 ngày" },
  { value: 90, label: "90 ngày" },
];

interface DashboardDateRangeProps {
  value: DashboardDays;
  onChange: (days: DashboardDays) => void;
  className?: string;
}

export function DashboardDateRange({ value, onChange, className }: DashboardDateRangeProps) {
  return (
    <div className={cn("inline-flex rounded-lg border border-gray-200 bg-white p-1", className)}>
      {OPTIONS.map((opt) => (
        <button
          key={opt.value}
          type="button"
          onClick={() => onChange(opt.value)}
          className={cn(
            "px-3 py-1.5 text-sm font-medium rounded-md transition-colors",
            value === opt.value
              ? "bg-primary text-white shadow-sm"
              : "text-gray-600 hover:bg-gray-50"
          )}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
