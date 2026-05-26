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
import { useExercises, useDeleteExercise, ExerciseCatalogDto } from "@/hooks/admin/use-exercises";
import { Skeleton } from "@/components/ui/skeleton";

export default function ExercisesPage() {
  const router  = useRouter();
  const { data, isLoading } = useExercises({ pageSize: 200 });
  const deleteMutation      = useDeleteExercise();

  const [deleteTarget, setDeleteTarget] = useState<ExerciseCatalogDto | null>(null);

  const columns: ColumnDef<ExerciseCatalogDto>[] = [
    {
      accessorKey: "exerciseCode",
      header: "Code",
      cell: ({ row }) => <span className="font-mono text-xs">{row.original.exerciseCode}</span>,
    },
    {
      accessorKey: "nameVi",
      header: "Name (VI)",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.nameVi}</p>
          <p className="text-xs text-muted-foreground">{row.original.nameEn}</p>
        </div>
      ),
    },
    {
      accessorKey: "category",
      header: "Category",
      cell: ({ row }) => <Badge variant="outline" className="text-xs">{row.original.category}</Badge>,
    },
    {
      accessorKey: "difficulty",
      header: "Difficulty",
      cell: ({ row }) => <span className="text-sm">{row.original.difficulty}</span>,
    },
    {
      accessorKey: "bodyRegion",
      header: "Body Region",
      cell: ({ row }) => <span className="text-sm text-muted-foreground">{row.original.bodyRegion}</span>,
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
            <DropdownMenuItem onClick={() => router.push(`/admin/exercises/${row.original.id}`)}>
              <Pencil className="w-4 h-4 mr-2" /> Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              className="text-destructive"
              onClick={() => setDeleteTarget(row.original)}
            >
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
        <div>
          <p className="text-xs text-muted-foreground">{data?.totalCount ?? 0} exercises total</p>
        </div>
        <Button size="sm" onClick={() => router.push("/admin/exercises/new")}>
          <Plus className="w-4 h-4 mr-2" /> New Exercise
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable
          columns={columns}
          data={data?.items ?? []}
          searchPlaceholder="Search exercises..."
        />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Delete Exercise"
        description={`Are you sure you want to delete "${deleteTarget?.nameEn}"? This action cannot be undone.`}
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
