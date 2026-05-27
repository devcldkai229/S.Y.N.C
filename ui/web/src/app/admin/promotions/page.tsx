"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { format } from "date-fns";
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
  usePromotionCampaigns,
  useDeletePromotionCampaign,
  campaignStatus,
  PromotionCampaignDto,
} from "@/hooks/admin/use-promotions";
import { Skeleton } from "@/components/ui/skeleton";

export default function PromotionsPage() {
  const router  = useRouter();
  const { data, isLoading }  = usePromotionCampaigns();
  const deleteMutation       = useDeletePromotionCampaign();
  const [deleteTarget, setDeleteTarget] = useState<PromotionCampaignDto | null>(null);

  const columns: ColumnDef<PromotionCampaignDto>[] = [
    {
      accessorKey: "name",
      header: "Name",
      cell: ({ row }) => <p className="font-medium text-sm">{row.original.name}</p>,
    },
    {
      accessorKey: "promotionType",
      header: "Type",
      cell: ({ row }) => <Badge variant="outline" className="text-xs">{row.original.promotionType}</Badge>,
    },
    {
      accessorKey: "value",
      header: "Value",
      cell: ({ row }) => (
        <span className="text-sm font-medium">
          {row.original.promotionType === "Percentage" ? `${row.original.value}%` : `${row.original.value.toLocaleString()}đ`}
        </span>
      ),
    },
    {
      accessorKey: "couponCode",
      header: "Coupon",
      cell: ({ row }) => row.original.couponCode
        ? <span className="font-mono text-xs bg-muted px-2 py-0.5 rounded">{row.original.couponCode}</span>
        : <span className="text-muted-foreground text-xs">—</span>,
    },
    {
      accessorKey: "startsAt",
      header: "Period",
      cell: ({ row }) => (
        <div className="text-xs text-muted-foreground">
          <p>{format(new Date(row.original.startsAt), "dd/MM/yyyy")}</p>
          <p>→ {format(new Date(row.original.endsAt), "dd/MM/yyyy")}</p>
        </div>
      ),
    },
    {
      id: "campaignStatus",
      header: "Status",
      cell: ({ row }) => <StatusBadge status={campaignStatus(row.original)} />,
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <DropdownMenu>
          <DropdownMenuTrigger className="inline-flex h-8 w-8 items-center justify-center rounded-md hover:bg-muted transition-colors">
            <MoreHorizontal className="w-4 h-4" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => router.push(`/admin/promotions/${row.original.id}`)}>
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
        <p className="text-xs text-muted-foreground">{data?.length ?? 0} campaigns total</p>
        <Button size="sm" onClick={() => router.push("/admin/promotions/new")}>
          <Plus className="w-4 h-4 mr-2" /> New Campaign
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={data ?? []} searchPlaceholder="Search campaigns..." />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Delete Campaign"
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
