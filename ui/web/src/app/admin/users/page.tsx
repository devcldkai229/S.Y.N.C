"use client";

import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { StatusBadge } from "@/components/admin/StatusBadge";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
  DropdownMenuLabel,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Eye, Ban, CheckCircle2, Shield } from "lucide-react";
import {
  useUsers,
  useUpdateUserStatus,
  useUpdateUserRole,
  AdminUserListItem,
} from "@/hooks/admin/use-users";
import { Skeleton } from "@/components/ui/skeleton";
import { format } from "date-fns";

const ROLE_COLORS: Record<string, string> = {
  SystemAdmin: "bg-purple-100 text-purple-700 border-purple-200",
  Partner:     "bg-blue-100 text-blue-700 border-blue-200",
  User:        "bg-gray-100 text-gray-600 border-gray-200",
};

const ROLE_LABELS: Record<string, string> = {
  SystemAdmin: "Quản trị viên",
  Partner:     "Đối tác",
  User:        "Người dùng",
};

export default function UsersPage() {
  const router = useRouter();
  const { data, isLoading } = useUsers();
  const updateStatus = useUpdateUserStatus();
  const updateRole   = useUpdateUserRole();

  const columns: ColumnDef<AdminUserListItem>[] = [
    {
      accessorKey: "fullName",
      header: "Người dùng",
      cell: ({ row }) => {
        const initials = (row.original.fullName || "?").split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase();
        return (
          <div className="flex items-center gap-3">
            <Avatar className="w-8 h-8">
              <AvatarFallback className="text-xs bg-primary/10 text-primary">{initials}</AvatarFallback>
            </Avatar>
            <div>
              <p className="font-medium text-sm">{row.original.fullName}</p>
              <p className="text-xs text-muted-foreground">{row.original.email}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "role",
      header: "Vai trò",
      cell: ({ row }) => (
        <Badge variant="outline" className={`text-xs ${ROLE_COLORS[row.original.role] ?? ""}`}>
          {ROLE_LABELS[row.original.role] ?? row.original.role}
        </Badge>
      ),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "subscriptionTier",
      header: "Gói",
      cell: ({ row }) => <span className="text-sm">{row.original.subscriptionTier}</span>,
    },
    {
      accessorKey: "lastActiveAt",
      header: "Hoạt động cuối",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {row.original.lastActiveAt ? format(new Date(row.original.lastActiveAt), "dd/MM/yyyy") : "—"}
        </span>
      ),
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const u = row.original;
        const isSuspended = u.status === "Suspended";
        return (
          <DropdownMenu>
            <DropdownMenuTrigger className="inline-flex h-8 w-8 items-center justify-center rounded-md hover:bg-muted transition-colors">
              <MoreHorizontal className="w-4 h-4" />
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={() => router.push(`/admin/users/${u.id}`)}>
                <Eye className="w-4 h-4 mr-2" /> Xem chi tiết
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              {isSuspended ? (
                <DropdownMenuItem onClick={() => updateStatus.mutate({ id: u.id, status: "Active" })}>
                  <CheckCircle2 className="w-4 h-4 mr-2" /> Kích hoạt
                </DropdownMenuItem>
              ) : (
                <DropdownMenuItem className="text-destructive" onClick={() => updateStatus.mutate({ id: u.id, status: "Suspended" })}>
                  <Ban className="w-4 h-4 mr-2" /> Tạm khóa
                </DropdownMenuItem>
              )}
              <DropdownMenuSeparator />
              <DropdownMenuLabel className="text-xs text-muted-foreground">Đổi vai trò</DropdownMenuLabel>
              {(["User", "Partner", "SystemAdmin"] as const).map((r) => (
                <DropdownMenuItem key={r} disabled={u.role === r} onClick={() => updateRole.mutate({ id: u.id, role: r })}>
                  <Shield className="w-4 h-4 mr-2" /> {ROLE_LABELS[r]}
                </DropdownMenuItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-xs text-muted-foreground">{data?.length ?? 0} người dùng</p>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={data ?? []} searchPlaceholder="Tìm theo tên hoặc email..." />
      )}
    </div>
  );
}
