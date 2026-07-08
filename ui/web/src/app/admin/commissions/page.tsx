"use client";

import { useState } from "react";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Wallet, TrendingUp, CheckCircle, DollarSign } from "lucide-react";
import { format } from "date-fns";
import {
  useCommissions,
  useCommissionRevenueSummary,
  useMarkCommissionPaid,
  COMMISSION_SOURCE_LABELS,
  COMMISSION_STATUS_LABELS,
  COMMISSION_STATUS_COLORS,
  type CommissionRecordDto,
  type CommissionSource,
  type CommissionStatus,
} from "@/hooks/admin/use-commissions";

const fmt = (n: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(n);

function CommissionStatusBadge({ status }: { status: CommissionStatus }) {
  const cls = COMMISSION_STATUS_COLORS[status] ?? "bg-gray-100 text-gray-600";
  return (
    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${cls}`}>
      {COMMISSION_STATUS_LABELS[status]}
    </span>
  );
}

export default function CommissionsPage() {
  const [sourceFilter, setSourceFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [markTarget, setMarkTarget]     = useState<CommissionRecordDto | null>(null);

  const filterParams = {
    source: sourceFilter !== "all" ? sourceFilter as CommissionSource : undefined,
    status: statusFilter !== "all" ? statusFilter as CommissionStatus : undefined,
    pageSize: 100,
  };

  const { data, isLoading }     = useCommissions(filterParams);
  const { data: summary }       = useCommissionRevenueSummary(filterParams);
  const markPaid                = useMarkCommissionPaid();

  const commissions = data?.items ?? [];

  const columns: ColumnDef<CommissionRecordDto>[] = [
    {
      accessorKey: "source",
      header: "Nguồn",
      cell: ({ row }) => (
        <Badge variant="outline" className="text-xs">
          {COMMISSION_SOURCE_LABELS[row.original.source]}
        </Badge>
      ),
    },
    {
      accessorKey: "partnerId",
      header: "Partner ID",
      cell: ({ row }) => (
        <span className="font-mono text-xs text-muted-foreground truncate max-w-28 block">
          {row.original.partnerId}
        </span>
      ),
    },
    {
      accessorKey: "grossAmount",
      header: "Doanh thu",
      cell: ({ row }) => (
        <span className="text-sm font-medium">{fmt(row.original.grossAmount)}</span>
      ),
    },
    {
      accessorKey: "commissionRate",
      header: "Tỉ lệ",
      cell: ({ row }) => (
        <span className="font-mono text-sm">{(row.original.commissionRate * 100).toFixed(1)}%</span>
      ),
    },
    {
      accessorKey: "commissionAmount",
      header: "Hoa hồng",
      cell: ({ row }) => (
        <span className="text-sm font-semibold text-green-700">
          {fmt(row.original.commissionAmount)}
        </span>
      ),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <CommissionStatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "createdAt",
      header: "Ngày tạo",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {format(new Date(row.original.createdAt), "dd/MM/yyyy")}
        </span>
      ),
    },
    {
      id: "actions",
      cell: ({ row }) =>
        row.original.status === "Confirmed" ? (
          <Button
            size="sm"
            variant="outline"
            className="h-7 text-xs px-2 text-green-600 border-green-200 hover:bg-green-50"
            onClick={() => setMarkTarget(row.original)}
          >
            <CheckCircle className="w-3 h-3 mr-1" /> Đánh dấu đã TT
          </Button>
        ) : null,
    },
  ];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
          <Wallet className="w-4 h-4 text-primary" />
        </div>
        <div>
          <h1 className="text-lg font-bold">Hoa hồng</h1>
          <p className="text-xs text-muted-foreground">Theo dõi và đối soát hoa hồng đối tác</p>
        </div>
      </div>

      {/* Revenue summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {[
          {
            label: "Tổng doanh thu",
            value: summary ? fmt(summary.totalGross) : "—",
            icon: TrendingUp,
            color: "text-blue-600",
          },
          {
            label: "Tổng hoa hồng",
            value: summary ? fmt(summary.totalCommission) : "—",
            icon: DollarSign,
            color: "text-green-600",
          },
          {
            label: "Số bản ghi",
            value: summary?.recordCount ?? commissions.length,
            icon: Wallet,
            color: "text-primary",
          },
        ].map(s => (
          <Card key={s.label} className="shadow-none">
            <CardContent className="pt-4 pb-3 flex items-start justify-between">
              <div>
                <p className={`text-xl font-bold ${s.color}`}>{s.value}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{s.label}</p>
              </div>
              <s.icon className={`w-5 h-5 ${s.color} opacity-60`} />
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-center gap-2 flex-wrap">
        <Select value={sourceFilter} onValueChange={(v) => setSourceFilter(v || "")}>
          <SelectTrigger className="w-40 h-8 text-sm">
            <SelectValue placeholder="Nguồn" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả nguồn</SelectItem>
            {Object.entries(COMMISSION_SOURCE_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v || "")}>
          <SelectTrigger className="w-40 h-8 text-sm">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả TT</SelectItem>
            {Object.entries(COMMISSION_STATUS_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <span className="text-xs text-muted-foreground">{commissions.length} bản ghi</span>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}
        </div>
      ) : (
        <DataTable columns={columns} data={commissions} searchPlaceholder="Tìm kiếm..." />
      )}

      <ConfirmDialog
        open={!!markTarget}
        onOpenChange={o => !o && setMarkTarget(null)}
        title="Đánh dấu đã thanh toán"
        description={`Xác nhận đã thanh toán hoa hồng ${markTarget ? fmt(markTarget.commissionAmount) : ""} cho partner?`}
        confirmLabel="Xác nhận"
        loading={markPaid.isPending}
        onConfirm={() => {
          if (!markTarget) return;
          markPaid.mutate(
            { id: markTarget.id, paidAt: new Date().toISOString() },
            { onSuccess: () => setMarkTarget(null) },
          );
        }}
      />
    </div>
  );
}
