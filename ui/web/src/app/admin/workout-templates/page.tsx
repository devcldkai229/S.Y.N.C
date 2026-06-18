"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
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
  useWorkoutTemplates,
  useDeleteWorkoutTemplate,
  WorkoutTemplateDto,
} from "@/hooks/admin/use-workout-templates";
import { Skeleton } from "@/components/ui/skeleton";

export default function WorkoutTemplatesPage() {
  const router = useRouter();
  const { data, isLoading } = useWorkoutTemplates();
  const deleteMutation = useDeleteWorkoutTemplate();
  const [deleteTarget, setDeleteTarget] = useState<WorkoutTemplateDto | null>(null);

  const columns: ColumnDef<WorkoutTemplateDto>[] = [
    {
      accessorKey: "name",
      header: "Tên mẫu",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.name}</p>
          <p className="text-xs text-muted-foreground">{row.original.goal}</p>
        </div>
      ),
    },
    {
      accessorKey: "difficulty",
      header: "Độ khó",
      cell: ({ row }) => <Badge variant="outline" className="text-xs">{row.original.difficulty}</Badge>,
    },
    {
      accessorKey: "estimatedDurationMinutes",
      header: "Thời lượng",
      cell: ({ row }) => <span className="text-sm">{row.original.estimatedDurationMinutes}′</span>,
    },
    {
      id: "blocks",
      header: "Số block",
      cell: ({ row }) => <span className="text-sm">{row.original.sessions?.length ?? 0}</span>,
    },
    {
      accessorKey: "isSystemTemplate",
      header: "Loại",
      cell: ({ row }) => (
        <Badge variant="outline" className="text-xs">
          {row.original.isSystemTemplate ? "Hệ thống" : "Người dùng"}
        </Badge>
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
            <DropdownMenuItem onClick={() => router.push(`/admin/workout-templates/${row.original.id}`)}>
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
        <p className="text-xs text-muted-foreground">{data?.pagination.totalRecords ?? 0} mẫu buổi tập</p>
        <Button size="sm" onClick={() => router.push("/admin/workout-templates/new")}>
          <Plus className="w-4 h-4 mr-2" /> Tạo mẫu
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={data?.items ?? []} searchPlaceholder="Tìm mẫu buổi tập..." />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Xóa mẫu buổi tập"
        description={`Xóa "${deleteTarget?.name}"?`}
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
