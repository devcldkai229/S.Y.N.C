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
import { MoreHorizontal, Plus, Pencil, Trash2, Power } from "lucide-react";
import {
  useNotificationTemplates,
  useDeleteNotificationTemplate,
  useToggleTemplateStatus,
  NotificationTemplateDto,
} from "@/hooks/admin/use-notification-templates";
import { Skeleton } from "@/components/ui/skeleton";

export default function NotificationTemplatesPage() {
  const router = useRouter();
  const { data, isLoading } = useNotificationTemplates();
  const deleteMutation = useDeleteNotificationTemplate();
  const toggleMutation = useToggleTemplateStatus();
  const [deleteTarget, setDeleteTarget] = useState<NotificationTemplateDto | null>(null);

  const columns: ColumnDef<NotificationTemplateDto>[] = [
    {
      accessorKey: "templateCode",
      header: "Mã",
      cell: ({ row }) => <span className="font-mono text-xs">{row.original.templateCode}</span>,
    },
    {
      accessorKey: "name",
      header: "Tên",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.name}</p>
          <p className="text-xs text-muted-foreground truncate max-w-xs">{row.original.defaultTitle}</p>
        </div>
      ),
    },
    {
      accessorKey: "channel",
      header: "Kênh",
      cell: ({ row }) => <Badge variant="outline" className="text-xs">{row.original.channel}</Badge>,
    },
    {
      accessorKey: "isActive",
      header: "Trạng thái",
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
            <DropdownMenuItem onClick={() => router.push(`/admin/notification-templates/${row.original.id}`)}>
              <Pencil className="w-4 h-4 mr-2" /> Sửa
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => toggleMutation.mutate(row.original.id)}>
              <Power className="w-4 h-4 mr-2" /> Bật/tắt
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
        <p className="text-xs text-muted-foreground">{data?.length ?? 0} mẫu thông báo</p>
        <Button size="sm" onClick={() => router.push("/admin/notification-templates/new")}>
          <Plus className="w-4 h-4 mr-2" /> Tạo mẫu
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={data ?? []} searchPlaceholder="Tìm mẫu thông báo..." />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Xóa mẫu thông báo"
        description={`Xóa mẫu "${deleteTarget?.name}"?`}
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
