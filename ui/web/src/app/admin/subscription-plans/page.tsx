"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { StatusBadge } from "@/components/admin/StatusBadge";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Plus, Pencil, Trash2 } from "lucide-react";
import {
  useSubscriptionPlans,
  useDeleteSubscriptionPlan,
  SubscriptionPlanDto,
} from "@/hooks/admin/use-subscription-plans";
import { Skeleton } from "@/components/ui/skeleton";

function formatVND(amount: number) {
  return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(amount);
}

export default function SubscriptionPlansPage() {
  const router  = useRouter();
  const { data, isLoading }  = useSubscriptionPlans();
  const deleteMutation       = useDeleteSubscriptionPlan();
  const [deleteTarget, setDeleteTarget] = useState<SubscriptionPlanDto | null>(null);

  const columns: ColumnDef<SubscriptionPlanDto>[] = [
    {
      accessorKey: "name",
      header: "Name",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.name}</p>
          {row.original.description && (
            <p className="text-xs text-muted-foreground truncate max-w-xs">{row.original.description}</p>
          )}
        </div>
      ),
    },
    {
      accessorKey: "monthlyPrice",
      header: "Monthly",
      cell: ({ row }) => <span className="text-sm font-medium">{formatVND(row.original.monthlyPrice)}</span>,
    },
    {
      accessorKey: "yearlyPrice",
      header: "Yearly",
      cell: ({ row }) => <span className="text-sm font-medium">{formatVND(row.original.yearlyPrice)}</span>,
    },
    {
      accessorKey: "aiUsageLimitPerMonth",
      header: "AI Limit/Mo",
      cell: ({ row }) => <span className="text-sm">{row.original.aiUsageLimitPerMonth}</span>,
    },
    {
      accessorKey: "isActive",
      header: "Status",
      cell: ({ row }) => <StatusBadge status={row.original.isActive} />,
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <DropdownMenu>
          <DropdownMenuTrigger className="inline-flex h-8 w-8 items-center justify-center rounded-md hover:bg-muted transition-colors">
            <MoreHorizontal className="w-4 h-4" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => router.push(`/admin/subscription-plans/${row.original.id}`)}>
              <Pencil className="w-4 h-4 mr-2" /> Edit
            </DropdownMenuItem>
            <DropdownMenuItem className="text-destructive" onClick={() => setDeleteTarget(row.original)}>
              <Trash2 className="w-4 h-4 mr-2" /> Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-xs text-muted-foreground">{data?.length ?? 0} plans total</p>
        <Button size="sm" onClick={() => router.push("/admin/subscription-plans/new")}>
          <Plus className="w-4 h-4 mr-2" /> New Plan
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={data ?? []} searchPlaceholder="Search plans..." />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Delete Plan"
        description={`Delete "${deleteTarget?.name}"? This is a soft delete.`}
        confirmLabel="Delete"
        loading={deleteMutation.isPending}
        onConfirm={() => {
          if (!deleteTarget) return;
          deleteMutation.mutate(deleteTarget.id, { onSuccess: () => setDeleteTarget(null) });
        }}
      />
    </div>
  );
}
