"use client";

import { useState } from "react";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeftRight, TrendingUp, TrendingDown, Bot, AlertCircle } from "lucide-react";
import { format } from "date-fns";
import {
  useTransactions,
  TX_STATUS_LABELS, TX_STATUS_COLORS, TX_TYPE_LABELS,
  PAYMENT_METHOD_LABELS, TX_PROVIDER_LABELS,
  type TransactionDto, type TxStatus, type TxType, type TxProvider,
} from "@/hooks/admin/use-transactions";

const fmt = (n: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(n);

function TxStatusBadge({ status }: { status: TxStatus }) {
  const cls = TX_STATUS_COLORS[status] ?? "bg-gray-100 text-gray-600";
  return <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${cls}`}>{TX_STATUS_LABELS[status]}</span>;
}

const ALL_STATUSES: TxStatus[] = ["Pending", "Processing", "Succeeded", "Failed", "Refunded", "Cancelled"];
const ALL_TYPES: TxType[]      = ["MealPurchase", "SupplementPurchase", "DigitalAssetPurchase", "Subscription", "WalletTopup", "Refund", "Reward"];
const ALL_PROVIDERS: TxProvider[] = ["InternalWallet", "GooglePlay", "PayOS", "Momo"];

export default function TransactionsPage() {
  const [statusFilter,   setStatusFilter]   = useState<string>("all");
  const [typeFilter,     setTypeFilter]     = useState<string>("all");
  const [providerFilter, setProviderFilter] = useState<string>("all");
  const [aiFilter,       setAiFilter]       = useState<string>("all");

  const { data, isLoading, isError } = useTransactions({
    status:        statusFilter   !== "all" ? statusFilter   as TxStatus   : undefined,
    type:          typeFilter     !== "all" ? typeFilter     as TxType     : undefined,
    provider:      providerFilter !== "all" ? providerFilter as TxProvider : undefined,
    isAiInitiated: aiFilter       === "ai"  ? true          : aiFilter === "manual" ? false : undefined,
    pageSize: 100,
  });

  const txs = data?.items ?? [];

  const succeeded = txs.filter(t => t.status === "Succeeded");
  const failed    = txs.filter(t => t.status === "Failed");
  const totalVol  = succeeded.reduce((s, t) => s + t.amount, 0);

  const columns: ColumnDef<TransactionDto>[] = [
    {
      accessorKey: "orderCode",
      header: "Order Code",
      cell: ({ row }) => (
        <span className="font-mono text-xs font-semibold">{row.original.orderCode}</span>
      ),
    },
    {
      accessorKey: "transactionType",
      header: "Loại",
      cell: ({ row }) => (
        <Badge variant="outline" className="text-xs">{TX_TYPE_LABELS[row.original.transactionType] ?? row.original.transactionType}</Badge>
      ),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <TxStatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "amount",
      header: "Số tiền",
      cell: ({ row }) => (
        <span className="font-medium text-sm">{fmt(row.original.amount)}</span>
      ),
    },
    {
      accessorKey: "paymentMethod",
      header: "Phương thức",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {PAYMENT_METHOD_LABELS[row.original.paymentMethod] ?? row.original.paymentMethod}
        </span>
      ),
    },
    {
      accessorKey: "provider",
      header: "Provider",
      cell: ({ row }) => (
        <span className="text-xs">{TX_PROVIDER_LABELS[row.original.provider] ?? row.original.provider}</span>
      ),
    },
    {
      accessorKey: "isAiInitiated",
      header: "AI",
      cell: ({ row }) =>
        row.original.isAiInitiated ? (
          <Badge className="text-xs bg-purple-100 text-purple-800 border-purple-200 gap-1 h-5">
            <Bot className="w-2.5 h-2.5" /> AI
          </Badge>
        ) : null,
    },
    {
      accessorKey: "createdAt",
      header: "Thời gian",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {format(new Date(row.original.createdAt), "dd/MM/yyyy HH:mm")}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
          <ArrowLeftRight className="w-4 h-4 text-primary" />
        </div>
        <div>
          <h1 className="text-lg font-bold">Giao dịch</h1>
          <p className="text-xs text-muted-foreground">Lịch sử giao dịch toàn hệ thống</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: "Tổng giao dịch",  value: txs.length,          icon: ArrowLeftRight, color: "text-primary"  },
          { label: "Thành công",       value: succeeded.length,    icon: TrendingUp,     color: "text-green-600"},
          { label: "Thất bại",         value: failed.length,       icon: TrendingDown,   color: "text-red-600"  },
          { label: "Tổng giá trị",    value: fmt(totalVol),       icon: TrendingUp,     color: "text-blue-600" },
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
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v || "")}>
          <SelectTrigger className="w-36 h-8 text-sm"><SelectValue placeholder="Trạng thái" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả TT</SelectItem>
            {ALL_STATUSES.map(s => <SelectItem key={s} value={s}>{TX_STATUS_LABELS[s]}</SelectItem>)}
          </SelectContent>
        </Select>

        <Select value={typeFilter} onValueChange={(v) => setTypeFilter(v || "")}>
          <SelectTrigger className="w-44 h-8 text-sm"><SelectValue placeholder="Loại giao dịch" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả loại</SelectItem>
            {ALL_TYPES.map(t => <SelectItem key={t} value={t}>{TX_TYPE_LABELS[t]}</SelectItem>)}
          </SelectContent>
        </Select>

        <Select value={providerFilter} onValueChange={(v) => setProviderFilter(v || "")}>
          <SelectTrigger className="w-36 h-8 text-sm"><SelectValue placeholder="Provider" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả</SelectItem>
            {ALL_PROVIDERS.map(p => <SelectItem key={p} value={p}>{TX_PROVIDER_LABELS[p]}</SelectItem>)}
          </SelectContent>
        </Select>

        <Select value={aiFilter} onValueChange={(v) => setAiFilter(v || "")}>
          <SelectTrigger className="w-32 h-8 text-sm"><SelectValue placeholder="AI/Manual" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả</SelectItem>
            <SelectItem value="ai">AI</SelectItem>
            <SelectItem value="manual">Thủ công</SelectItem>
          </SelectContent>
        </Select>

        <span className="text-xs text-muted-foreground">{txs.length} giao dịch</span>
      </div>

      {isError && (
        <div className="flex items-center gap-2 p-4 rounded-lg border border-yellow-200 bg-yellow-50 text-yellow-800 text-sm">
          <AlertCircle className="w-4 h-4 shrink-0" />
          Backend AdminTransactionsController chưa được triển khai. Endpoint cần thêm: <code className="font-mono ml-1">GET /api/v1/payment/admin/transactions</code>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 7 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={txs} searchPlaceholder="Tìm kiếm..." />
      )}
    </div>
  );
}
