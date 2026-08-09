"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent } from "@/components/ui/card";
import { AlertCircle, Plus, Pencil, Trash2, Trophy, Star, Zap, Coins } from "lucide-react";
import { useAchievements, useDeleteAchievement, type AchievementDto } from "@/hooks/admin/use-achievements";

export default function AchievementsPage() {
  const router = useRouter();
  const { data, isLoading, isError } = useAchievements();
  const deleteAchievement = useDeleteAchievement();
  const [deleteTarget, setDeleteTarget] = useState<AchievementDto | null>(null);

  const achievements = data ?? [];
  const totalXP    = achievements.reduce((s, a) => s + a.xpReward, 0);
  const totalCoins = achievements.reduce((s, a) => s + a.coinReward, 0);

  const columns: ColumnDef<AchievementDto>[] = [
    {
      id: "icon",
      header: "Icon",
      cell: ({ row }) => {
        const a = row.original;
        return a.iconUrl ? (
          <img src={a.iconUrl} alt={a.name} className="w-10 h-10 rounded-xl object-contain" />
        ) : (
          <div className="w-10 h-10 rounded-xl bg-yellow-100 flex items-center justify-center">
            <Trophy className="w-5 h-5 text-yellow-600" />
          </div>
        );
      },
    },
    {
      accessorKey: "code",
      header: "Code",
      cell: ({ row }) => (
        <span className="font-mono text-xs font-semibold text-muted-foreground">{row.original.code}</span>
      ),
    },
    {
      accessorKey: "name",
      header: "Tên",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.name}</p>
          <p className="text-xs text-muted-foreground truncate max-w-48">{row.original.description}</p>
        </div>
      ),
    },
    {
      accessorKey: "xpReward",
      header: "XP",
      cell: ({ row }) => (
        <span className="flex items-center gap-1 text-sm font-medium text-blue-600">
          <Zap className="w-3.5 h-3.5" /> {row.original.xpReward}
        </span>
      ),
    },
    {
      accessorKey: "coinReward",
      header: "Coins",
      cell: ({ row }) => (
        <span className="flex items-center gap-1 text-sm font-medium text-yellow-600">
          <Star className="w-3.5 h-3.5 fill-yellow-400" /> {row.original.coinReward}
        </span>
      ),
    },
    {
      id: "requirement",
      header: "Điều kiện",
      cell: ({ row }) => {
        const req = row.original.requirementJson;
        if (!req) return <span className="text-muted-foreground text-xs">—</span>;
        try {
          const parsed = JSON.parse(req);
          return (
            <span className="text-xs text-muted-foreground font-mono truncate max-w-32 block">
              {Object.entries(parsed).map(([k, v]) => `${k}:${v}`).join(", ")}
            </span>
          );
        } catch {
          return <span className="text-xs text-muted-foreground truncate max-w-32 block">{req}</span>;
        }
      },
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7"
            onClick={() => router.push(`/admin/achievements/${row.original.id}`)}
          >
            <Pencil className="w-3.5 h-3.5" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-destructive hover:text-destructive"
            onClick={() => setDeleteTarget(row.original)}
          >
            <Trash2 className="w-3.5 h-3.5" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
            <Trophy className="w-4 h-4 text-yellow-600" />
          </div>
          <div>
            <h1 className="text-lg font-bold">Thành tựu</h1>
            <p className="text-xs text-muted-foreground">Quản lý hệ thống gamification</p>
          </div>
        </div>
        <Button size="sm" onClick={() => router.push("/admin/achievements/new")}>
          <Plus className="w-4 h-4 mr-2" /> Thêm thành tựu
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {[
          { label: "Tổng thành tựu",  value: achievements.length, icon: Trophy, color: "text-yellow-600", bg: "bg-yellow-100" },
          { label: "Tổng XP pool",    value: `${totalXP} XP`,     icon: Zap,    color: "text-blue-600",   bg: "bg-blue-100"   },
          { label: "Tổng Coin pool",  value: `${totalCoins} 🪙`,  icon: Star,   color: "text-amber-600",  bg: "bg-amber-100"  },
        ].map(s => (
          <Card key={s.label} className="shadow-none">
            <CardContent className="pt-4 pb-3 flex items-center gap-3">
              <div className={`w-9 h-9 rounded-xl ${s.bg} flex items-center justify-center shrink-0`}>
                <s.icon className={`w-4 h-4 ${s.color}`} />
              </div>
              <div>
                <p className={`text-xl font-bold ${s.color}`}>{s.value}</p>
                <p className="text-xs text-muted-foreground">{s.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {isError && (
        <div className="flex items-center gap-2 p-4 rounded-lg border border-yellow-200 bg-yellow-50 text-yellow-800 text-sm">
          <AlertCircle className="w-4 h-4 shrink-0" />
          AdminAchievementsController chưa được triển khai trong IAM service. Cần thêm: <code className="font-mono ml-1">GET /api/v1/iam/admin/achievements</code>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={achievements} searchPlaceholder="Tìm thành tựu..." />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={o => !o && setDeleteTarget(null)}
        title="Xóa thành tựu"
        description={`Xóa thành tựu "${deleteTarget?.name}"? Người dùng đã mở khóa sẽ không bị ảnh hưởng.`}
        confirmLabel="Xóa"
        loading={deleteAchievement.isPending}
        onConfirm={() => {
          if (!deleteTarget) return;
          deleteAchievement.mutate(deleteTarget.id, { onSuccess: () => setDeleteTarget(null) });
        }}
      />
    </div>
  );
}
