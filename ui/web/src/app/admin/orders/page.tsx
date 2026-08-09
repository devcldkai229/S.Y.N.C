"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { ShoppingCart, Bot, TrendingUp, Clock, Eye } from "lucide-react";
import { format } from "date-fns";
import {
  useOrders,
  ORDER_STATUS_LABELS,
  ORDER_STATUS_COLORS,
  type OrderDto,
  type OrderStatus,
} from "@/hooks/admin/use-orders";

const ALL_STATUSES: OrderStatus[] = [
  "Pending", "Confirmed", "Preparing", "ReadyForPickup", "PickedUp",
  "Delivering", "Delivered", "Completed", "Cancelled", "Refunded",
];

const fmt = (n: number) => new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(n);

function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const cls = ORDER_STATUS_COLORS[status] ?? "bg-gray-100 text-gray-600";
  return (
    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${cls}`}>
      {ORDER_STATUS_LABELS[status]}
    </span>
  );
}

function PaymentStatusBadge({ status }: { status: string }) {
  const cfg: Record<string, string> = {
    Paid:     "bg-green-100 text-green-800",
    Unpaid:   "bg-red-100 text-red-800",
    Refunded: "bg-blue-100 text-blue-800",
    Failed:   "bg-red-100 text-red-800",
  };
  const labels: Record<string, string> = {
    Paid: "Đã thanh toán", Unpaid: "Chưa TT", Refunded: "Đã hoàn", Failed: "Thất bại",
  };
  return (
    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${cfg[status] ?? "bg-gray-100 text-gray-600"}`}>
      {labels[status] ?? status}
    </span>
  );
}

export default function OrdersPage() {
  const router = useRouter();
  const [statusFilter, setStatusFilter] = useState<string>("all");

  const { data, isLoading } = useOrders({ pageSize: 100 });
  const allOrders = data?.items ?? [];

  const filtered = allOrders.filter(o =>
    statusFilter === "all" || o.status === statusFilter
  );

  // Stats
  const active   = allOrders.filter(o => !["Completed", "Cancelled", "Refunded"].includes(o.status)).length;
  const aiOrders = allOrders.filter(o => o.isAiInitiated).length;
  const totalRev = allOrders.filter(o => o.status === "Completed").reduce((s, o) => s + o.totalAmount, 0);

  const columns: ColumnDef<OrderDto>[] = [
    {
      accessorKey: "orderCode",
      header: "Mã đơn",
      cell: ({ row }) => (
        <span className="font-mono text-xs font-semibold">{row.original.orderCode}</span>
      ),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <OrderStatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "paymentStatus",
      header: "Thanh toán",
      cell: ({ row }) => <PaymentStatusBadge status={row.original.paymentStatus} />,
    },
    {
      accessorKey: "totalAmount",
      header: "Tổng tiền",
      cell: ({ row }) => (
        <span className="font-medium text-sm">{fmt(row.original.totalAmount)}</span>
      ),
    },
    {
      id: "items",
      header: "Số món",
      cell: ({ row }) => (
        <span className="text-sm text-muted-foreground">{row.original.items.length} món</span>
      ),
    },
    {
      accessorKey: "isAiInitiated",
      header: "AI",
      cell: ({ row }) =>
        row.original.isAiInitiated ? (
          <Badge className="text-xs bg-purple-100 text-purple-800 border-purple-200 gap-1">
            <Bot className="w-3 h-3" /> AI
          </Badge>
        ) : null,
    },
    {
      accessorKey: "placedAt",
      header: "Đặt lúc",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {format(new Date(row.original.placedAt), "dd/MM/yyyy HH:mm")}
        </span>
      ),
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7"
          onClick={() => router.push(`/admin/orders/${row.original.id}`)}
        >
          <Eye className="w-4 h-4" />
        </Button>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
          <ShoppingCart className="w-4 h-4 text-primary" />
        </div>
        <div>
          <h1 className="text-lg font-bold">Quản lý đơn hàng</h1>
          <p className="text-xs text-muted-foreground">Theo dõi tất cả đơn hàng trên hệ thống</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: "Tổng đơn",       value: allOrders.length,           icon: ShoppingCart, color: "text-primary"  },
          { label: "Đang xử lý",     value: active,                     icon: Clock,        color: "text-blue-600" },
          { label: "Đơn AI",         value: aiOrders,                   icon: Bot,          color: "text-purple-600"},
          { label: "Doanh thu",      value: fmt(totalRev),              icon: TrendingUp,   color: "text-green-600"},
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

      {/* Filter */}
      <div className="flex items-center gap-2">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v || "")}>
          <SelectTrigger className="w-44 h-8 text-sm">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả trạng thái</SelectItem>
            {ALL_STATUSES.map(s => (
              <SelectItem key={s} value={s}>{ORDER_STATUS_LABELS[s]}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{filtered.length} đơn hàng</span>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={filtered} searchPlaceholder="Tìm mã đơn..." />
      )}
    </div>
  );
}
