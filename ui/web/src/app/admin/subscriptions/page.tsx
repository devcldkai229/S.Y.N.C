"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { StatusBadge } from "@/components/admin/StatusBadge";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Plus, Pencil, Trash2 } from "lucide-react";
import {
  useUserSubscriptions,
  useDeleteUserSubscription,
  UserSubscriptionDto,
} from "@/hooks/admin/use-user-subscriptions";
import { Skeleton } from "@/components/ui/skeleton";
import { format } from "date-fns";

export default function SubscriptionsPage() {
  const router = useRouter();
  const { data, isLoading } = useUserSubscriptions();
  const deleteMutation = useDeleteUserSubscription();
  const [deleteTarget, setDeleteTarget] = useState<UserSubscriptionDto | null>(null);

  const columns: ColumnDef<UserSubscriptionDto>[] = [
    {
      accessorKey: "subscriptionPlanName",
      header: "Gói",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.subscriptionPlanName || "—"}</p>
          <p className="text-xs text-muted-foreground font-mono">{row.original.userId.slice(0, 8)}…</p>
        </div>
      ),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "managedBy",
      header: "Nguồn",
      cell: ({ row }) => <Badge variant="outline" className="text-xs">{row.original.managedBy}</Badge>,
    },
    {
      accessorKey: "autoRenew",
      header: "Tự gia hạn",
      cell: ({ row }) => (
        <span className="text-sm">{row.original.autoRenew ? "Có" : "Không"}</span>
      ),
    },
    {
      accessorKey: "startedAt",
      header: "Bắt đầu",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {format(new Date(row.original.startedAt), "dd/MM/yyyy")}
        </span>
      ),
    },
    {
      accessorKey: "expiredAt",
      header: "Hết hạn",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {row.original.expiredAt ? format(new Date(row.original.expiredAt), "dd/MM/yyyy") : "—"}
        </span>
      ),
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <DropdownMenu>
          <DropdownMenuTrigger className="inline-flex h-8 w-8 items-center justify-center rounded-md hover:bg-muted transition-colors">
            <MoreHorizontal className="w-4 h-4" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => router.push(`/admin/subscriptions/${row.original.id}`)}>
              <Pencil className="w-4 h-4 mr-2" /> Sửa
            </DropdownMenuItem>
            <DropdownMenuItem className="text-destructive" onClick={() => setDeleteTarget(row.original)}>
              <Trash2 className="w-4 h-4 mr-2" /> Xóa
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-xs text-muted-foreground">{data?.length ?? 0} gói đăng ký</p>
        <Button size="sm" onClick={() => router.push("/admin/subscriptions/new")}>
          <Plus className="w-4 h-4 mr-2" /> Tạo gói đăng ký
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={data ?? []} searchPlaceholder="Tìm theo gói hoặc người dùng..." />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Xóa gói đăng ký"
        description={`Xóa gói đăng ký "${deleteTarget?.subscriptionPlanName}"? Đây là xóa mềm.`}
        confirmLabel="Xóa"
        loading={deleteMutation.isPending}
        onConfirm={() => {
          if (!deleteTarget) return;
          deleteMutation.mutate(deleteTarget.id, { onSuccess: () => setDeleteTarget(null) });
        }}
      />
    </div>
  );
}
