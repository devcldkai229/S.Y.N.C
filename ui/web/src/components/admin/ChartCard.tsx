"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import type { ReactNode } from "react";

interface ChartCardProps {
  title: string;
  children: ReactNode;
  isLoading?: boolean;
  isError?: boolean;
  isEmpty?: boolean;
  emptyMessage?: string;
  onRetry?: () => void;
  className?: string;
  action?: ReactNode;
}

export function ChartCard({
  title,
  children,
  isLoading,
  isError,
  isEmpty,
  emptyMessage = "Chưa có dữ liệu trong khoảng thời gian này",
  onRetry,
  className,
  action,
}: ChartCardProps) {
  return (
    <Card className={cn(className)}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-semibold">{title}</CardTitle>
        {action}
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[220px] w-full rounded-lg" />
        ) : isError ? (
          <div className="flex flex-col items-center justify-center h-[220px] gap-2 text-sm text-muted-foreground">
            <p>Không tải được dữ liệu</p>
            {onRetry && (
              <button type="button" onClick={onRetry} className="text-primary hover:underline text-xs">
                Thử lại
              </button>
            )}
          </div>
        ) : isEmpty ? (
          <div className="flex items-center justify-center h-[220px] text-sm text-muted-foreground">
            {emptyMessage}
          </div>
        ) : (
          children
        )}
      </CardContent>
    </Card>
  );
}
