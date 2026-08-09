"use client";

import { useMemo, useState } from "react";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";
import {
  useAdminContentReports,
  useResolveContentReport,
  type AdminContentReportDto,
  type ReportStatus,
} from "@/hooks/admin/use-content-reports";

const STATUS_OPTIONS: Array<ReportStatus | "All"> = [
  "All",
  "Pending",
  "Reviewed",
  "Actioned",
  "Dismissed",
];

export default function AdminContentReportsPage() {
  const [status, setStatus] = useState<string>("Pending");
  const { data, isLoading } = useAdminContentReports({
    status: status === "All" ? undefined : status,
  });
  const resolve = useResolveContentReport();

  const columns = useMemo<ColumnDef<AdminContentReportDto>[]>(
    () => [
      {
        accessorKey: "createdAt",
        header: "Thời gian",
        cell: ({ row }) => format(new Date(row.original.createdAt), "dd/MM/yyyy HH:mm"),
      },
      {
        accessorKey: "targetType",
        header: "Loại",
        cell: ({ row }) => <Badge variant="outline">{row.original.targetType}</Badge>,
      },
      {
        accessorKey: "reason",
        header: "Lý do",
      },
      {
        accessorKey: "status",
        header: "Trạng thái",
        cell: ({ row }) => <Badge>{row.original.status}</Badge>,
      },
      {
        id: "target",
        header: "Target",
        cell: ({ row }) => (
          <span className="font-mono text-xs break-all">{row.original.targetId}</span>
        ),
      },
      {
        id: "actions",
        header: "Xử lý",
        cell: ({ row }) => {
          const r = row.original;
          const busy = resolve.isPending;
          return (
            <div className="flex flex-wrap gap-1">
              <Button
                size="sm"
                variant="outline"
                disabled={busy || r.status === "Dismissed"}
                onClick={() => resolve.mutate({ id: r.id, status: "Dismissed" })}
              >
                Bỏ qua
              </Button>
              <Button
                size="sm"
                variant="outline"
                disabled={busy || r.status === "Reviewed"}
                onClick={() => resolve.mutate({ id: r.id, status: "Reviewed" })}
              >
                Đã xem
              </Button>
              <Button
                size="sm"
                disabled={busy || r.status === "Actioned"}
                onClick={() =>
                  resolve.mutate({
                    id: r.id,
                    status: "Actioned",
                    hidePost: r.targetType === "Post",
                  })
                }
              >
                Ẩn / Actioned
              </Button>
            </div>
          );
        },
      },
    ],
    [resolve],
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Báo cáo nội dung</h1>
          <p className="text-sm text-muted-foreground">
            Duyệt report UGC / AI content (SLA cơ bản).
          </p>
        </div>
        <Select
          value={status}
          onValueChange={(value) => {
            if (value != null) setStatus(value);
          }}
        >
          <SelectTrigger className="w-40">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>
                {s}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <DataTable columns={columns} data={data?.items ?? []} />
      {isLoading && <p className="text-sm text-muted-foreground">Đang tải…</p>}
      {!isLoading && (data?.items?.length ?? 0) === 0 && (
        <p className="text-sm text-muted-foreground text-center py-8">Không có báo cáo.</p>
      )}
    </div>
  );
}
