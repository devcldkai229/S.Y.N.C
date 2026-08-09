import Link from "next/link";
import { LucideIcon, TrendingUp, TrendingDown, AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";
import { Area, AreaChart, ResponsiveContainer } from "recharts";
import type { DailyPoint } from "@/hooks/admin/dashboard-types";

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  description?: string;
  trend?: { value: number; label: string };
  sparkline?: DailyPoint[];
  className?: string;
  color?: "green" | "blue" | "orange" | "purple";
  href?: string;
  /** When true, renders a "failed to load" state instead of the value — never silently falls back to 0. */
  error?: boolean;
}

const COLOR_MAP = {
  green:  { bg: "bg-primary/10",  icon: "text-primary" },
  blue:   { bg: "bg-blue-50",     icon: "text-blue-500" },
  orange: { bg: "bg-orange-50",   icon: "text-orange-500" },
  purple: { bg: "bg-violet-50",   icon: "text-violet-500" },
};

export function StatsCard({ title, value, icon: Icon, description, trend, sparkline, className, color = "green", href, error }: StatsCardProps) {
  const colors = COLOR_MAP[color];
  const content = (
    <div className={cn(
      "bg-white rounded-2xl border shadow-sm p-5 transition-shadow",
      error ? "border-red-100" : "border-gray-100 hover:shadow-md",
      className,
    )}>
      <div className="flex items-start justify-between mb-4">
        <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center", error ? "bg-red-50" : colors.bg)}>
          <Icon className={cn("w-5 h-5", error ? "text-red-400" : colors.icon)} />
        </div>
        {!error && trend && (
          <div
            className={cn(
              "flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full",
              trend.value >= 0 ? "bg-green-50 text-green-600" : "bg-red-50 text-red-500"
            )}
          >
            {trend.value >= 0
              ? <TrendingUp className="w-3 h-3" />
              : <TrendingDown className="w-3 h-3" />
            }
            {Math.abs(trend.value)}%
          </div>
        )}
      </div>
      {error ? (
        <>
          <p className="flex items-center gap-1.5 text-base font-semibold text-red-500 mb-1">
            <AlertTriangle className="w-4 h-4" /> Không tải được
          </p>
          <p className="text-sm font-medium text-gray-500">{title}</p>
        </>
      ) : (
        <>
          <p className="text-3xl font-bold text-gray-900 mb-1">{value}</p>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          {description && <p className="text-xs text-gray-400 mt-0.5">{description}</p>}
          {trend && <p className="text-xs text-gray-400 mt-1">{trend.label}</p>}
          {sparkline && sparkline.length > 0 && (
            <div className="h-10 mt-3 -mx-1">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={sparkline}>
                  <Area
                    type="monotone"
                    dataKey="value"
                    stroke="oklch(0.52 0.165 149)"
                    fill="oklch(0.52 0.165 149 / 0.15)"
                    strokeWidth={1.5}
                    dot={false}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          )}
        </>
      )}
    </div>
  );

  if (href) {
    return (
      <Link href={href} className="block focus:outline-none focus-visible:ring-2 focus-visible:ring-primary rounded-2xl">
        {content}
      </Link>
    );
  }
  return content;
}
