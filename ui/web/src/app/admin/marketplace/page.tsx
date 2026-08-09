"use client";

import { useState } from "react";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Store, CheckCircle, XCircle, PauseCircle, Star, Users, ShoppingBag, Package, MessageSquare } from "lucide-react";
import { format } from "date-fns";
import {
  usePartners,
  useUpdatePartnerStatus,
  PARTNER_STATUS_LABELS,
  PARTNER_TYPE_LABELS,
  type PartnerDto,
  type PartnerStatus,
} from "@/hooks/admin/use-partners";
import { useFoodMenuItems, FOOD_CATEGORY_LABELS, type FoodMenuItemDto } from "@/hooks/admin/use-food-menu-items";
import { useAffiliateProducts, AFFILIATE_CATEGORY_LABELS, type AffiliateProductDto } from "@/hooks/admin/use-affiliate-products";
import { useReviews, REVIEW_TARGET_LABELS, type ReviewDto } from "@/hooks/admin/use-reviews";

// ── Helpers ───────────────────────────────────────────────────────────────────
function PartnerStatusBadge({ status }: { status: PartnerStatus }) {
  const cfg: Record<PartnerStatus, { icon: React.ReactNode; cls: string }> = {
    PendingApproval: { icon: <PauseCircle className="w-3 h-3" />, cls: "bg-yellow-100 text-yellow-800 border-yellow-200" },
    Active:          { icon: <CheckCircle className="w-3 h-3" />, cls: "bg-green-100 text-green-800 border-green-200"  },
    Suspended:       { icon: <XCircle    className="w-3 h-3" />, cls: "bg-red-100 text-red-800 border-red-200"         },
    Closed:          { icon: <XCircle    className="w-3 h-3" />, cls: "bg-gray-100 text-gray-600 border-gray-200"      },
  };
  const { icon, cls } = cfg[status] ?? cfg.Closed;
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border ${cls}`}>
      {icon} {PARTNER_STATUS_LABELS[status]}
    </span>
  );
}

function AvailabilityBadge({ status }: { status: string }) {
  const cls =
    status === "Available" ? "bg-green-100 text-green-800" :
    status === "SoldOut"   ? "bg-red-100 text-red-800"     :
                             "bg-gray-100 text-gray-600";
  const label = status === "Available" ? "Còn hàng" : status === "SoldOut" ? "Hết hàng" : "Ẩn";
  return <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${cls}`}>{label}</span>;
}

function RatingStars({ value, count }: { value: number; count: number }) {
  return (
    <span className="flex items-center gap-1 text-sm">
      <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
      <span className="font-medium">{value.toFixed(1)}</span>
      <span className="text-muted-foreground text-xs">({count})</span>
    </span>
  );
}

const fmt = (n: number) => new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(n);

// ── Partners Tab ───────────────────────────────────────────────────────────────
function PartnersTab() {
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [actionTarget, setActionTarget] = useState<{ partner: PartnerDto; nextStatus: PartnerStatus } | null>(null);

  const { data, isLoading } = usePartners({ pageSize: 200 });
  const updateStatus = useUpdatePartnerStatus();

  const allPartners = data?.items ?? [];
  const filtered = allPartners.filter(p => {
    if (typeFilter !== "all" && p.type !== typeFilter) return false;
    if (statusFilter !== "all" && p.status !== statusFilter) return false;
    return true;
  });

  // Quick stats
  const counts = allPartners.reduce<Record<string, number>>((acc, p) => {
    acc[p.status] = (acc[p.status] ?? 0) + 1;
    return acc;
  }, {});

  const columns: ColumnDef<PartnerDto>[] = [
    {
      id: "info",
      header: "Đối tác",
      cell: ({ row }) => {
        const p = row.original;
        const initials = p.name.slice(0, 2).toUpperCase();
        return (
          <div className="flex items-center gap-3">
            <Avatar className="w-9 h-9 rounded-lg">
              {p.logoUrl && <AvatarImage src={p.logoUrl} />}
              <AvatarFallback className="rounded-lg text-xs bg-primary/10 text-primary font-semibold">{initials}</AvatarFallback>
            </Avatar>
            <div>
              <p className="font-medium text-sm">{p.name}</p>
              <p className="text-xs text-muted-foreground">{p.email}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "type",
      header: "Loại",
      cell: ({ row }) => <Badge variant="outline" className="text-xs">{PARTNER_TYPE_LABELS[row.original.type]}</Badge>,
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <PartnerStatusBadge status={row.original.status} />,
    },
    {
      id: "rating",
      header: "Đánh giá",
      cell: ({ row }) => <RatingStars value={row.original.ratingAverage} count={row.original.ratingCount} />,
    },
    {
      accessorKey: "commissionRate",
      header: "Hoa hồng",
      cell: ({ row }) => (
        <span className="font-mono text-sm">{(row.original.commissionRate * 100).toFixed(1)}%</span>
      ),
    },
    {
      id: "actions",
      header: "Thao tác",
      cell: ({ row }) => {
        const p = row.original;
        return (
          <div className="flex items-center gap-1.5">
            {p.status === "PendingApproval" && (
              <Button
                size="sm"
                variant="outline"
                className="text-green-600 border-green-200 hover:bg-green-50 h-7 text-xs px-2"
                onClick={() => setActionTarget({ partner: p, nextStatus: "Active" })}
              >
                <CheckCircle className="w-3 h-3 mr-1" /> Duyệt
              </Button>
            )}
            {p.status === "Active" && (
              <Button
                size="sm"
                variant="outline"
                className="text-red-600 border-red-200 hover:bg-red-50 h-7 text-xs px-2"
                onClick={() => setActionTarget({ partner: p, nextStatus: "Suspended" })}
              >
                <PauseCircle className="w-3 h-3 mr-1" /> Tạm dừng
              </Button>
            )}
            {p.status === "Suspended" && (
              <Button
                size="sm"
                variant="outline"
                className="text-blue-600 border-blue-200 hover:bg-blue-50 h-7 text-xs px-2"
                onClick={() => setActionTarget({ partner: p, nextStatus: "Active" })}
              >
                <CheckCircle className="w-3 h-3 mr-1" /> Kích hoạt
              </Button>
            )}
          </div>
        );
      },
    },
  ];

  return (
    <div className="space-y-4">
      {/* Quick stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: "Chờ duyệt", value: counts.PendingApproval ?? 0, color: "text-yellow-600" },
          { label: "Hoạt động", value: counts.Active ?? 0,          color: "text-green-600"  },
          { label: "Tạm dừng",  value: counts.Suspended ?? 0,       color: "text-red-600"    },
          { label: "Tổng",      value: allPartners.length,           color: "text-primary"    },
        ].map(s => (
          <Card key={s.label} className="shadow-none">
            <CardContent className="pt-4 pb-3">
              <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
              <p className="text-xs text-muted-foreground mt-0.5">{s.label}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-center gap-2 flex-wrap">
        <Select value={typeFilter} onValueChange={(v) => setTypeFilter(v || "")}>
          <SelectTrigger className="w-44 h-8 text-sm">
            <SelectValue placeholder="Loại đối tác" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả loại</SelectItem>
            {Object.entries(PARTNER_TYPE_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v || "")}>
          <SelectTrigger className="w-40 h-8 text-sm">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả</SelectItem>
            {Object.entries(PARTNER_STATUS_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={filtered} searchPlaceholder="Tìm đối tác..." />
      )}

      <ConfirmDialog
        open={!!actionTarget}
        onOpenChange={o => !o && setActionTarget(null)}
        title={actionTarget?.nextStatus === "Active" ? "Phê duyệt đối tác" : "Tạm dừng đối tác"}
        description={
          actionTarget?.nextStatus === "Active"
            ? `Phê duyệt "${actionTarget?.partner.name}" để bắt đầu hoạt động trên SYNC Marketplace?`
            : `Tạm dừng "${actionTarget?.partner.name}"? Đối tác sẽ không thể nhận đơn hàng mới.`
        }
        confirmLabel={actionTarget?.nextStatus === "Active" ? "Phê duyệt" : "Tạm dừng"}
        loading={updateStatus.isPending}
        onConfirm={() => {
          if (!actionTarget) return;
          updateStatus.mutate(
            { id: actionTarget.partner.id, status: actionTarget.nextStatus },
            { onSuccess: () => setActionTarget(null) },
          );
        }}
      />
    </div>
  );
}

// ── Food Menu Tab ──────────────────────────────────────────────────────────────
function FoodMenuTab() {
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const { data, isLoading } = useFoodMenuItems({ pageSize: 200 });

  const items = data?.items ?? [];
  const filtered = items.filter(i => categoryFilter === "all" || i.category === categoryFilter);

  const columns: ColumnDef<FoodMenuItemDto>[] = [
    {
      id: "name",
      header: "Món ăn",
      cell: ({ row }) => {
        const i = row.original;
        return (
          <div className="flex items-center gap-3">
            {i.imageUrls[0] ? (
              <img src={i.imageUrls[0]} alt={i.nameVi} className="w-10 h-10 rounded-lg object-cover" />
            ) : (
              <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                <ShoppingBag className="w-4 h-4 text-muted-foreground" />
              </div>
            )}
            <div>
              <p className="font-medium text-sm">{i.nameVi}</p>
              <p className="text-xs text-muted-foreground">{i.nameEn}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "category",
      header: "Danh mục",
      cell: ({ row }) => (
        <Badge variant="outline" className="text-xs">{FOOD_CATEGORY_LABELS[row.original.category] ?? row.original.category}</Badge>
      ),
    },
    {
      accessorKey: "price",
      header: "Giá",
      cell: ({ row }) => <span className="font-medium text-sm">{fmt(row.original.price)}</span>,
    },
    {
      id: "nutrition",
      header: "Macro (100g)",
      cell: ({ row }) => {
        const n = row.original.nutrition;
        if (!n) return <span className="text-muted-foreground text-xs">—</span>;
        return (
          <div className="text-xs space-y-0.5">
            <p><span className="text-orange-600 font-medium">{n.calories}</span> kcal</p>
            <p className="text-muted-foreground">P:{n.proteinGram}g C:{n.carbGram}g F:{n.fatGram}g</p>
          </div>
        );
      },
    },
    {
      accessorKey: "availability",
      header: "Trạng thái",
      cell: ({ row }) => <AvailabilityBadge status={row.original.availability} />,
    },
    {
      id: "rating",
      header: "Đánh giá",
      cell: ({ row }) => <RatingStars value={row.original.ratingAverage} count={row.original.ratingCount} />,
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <Select value={categoryFilter} onValueChange={(v) => setCategoryFilter(v || "")}>
          <SelectTrigger className="w-48 h-8 text-sm">
            <SelectValue placeholder="Danh mục" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả danh mục</SelectItem>
            {Object.entries(FOOD_CATEGORY_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{filtered.length} món ăn</span>
      </div>
      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={filtered} searchPlaceholder="Tìm món ăn..." />
      )}
    </div>
  );
}

// ── Affiliate Products Tab ─────────────────────────────────────────────────────
function AffiliateTab() {
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const { data, isLoading } = useAffiliateProducts({ pageSize: 200 });

  const items = data?.items ?? [];
  const filtered = items.filter(i => categoryFilter === "all" || i.category === categoryFilter);

  const columns: ColumnDef<AffiliateProductDto>[] = [
    {
      id: "name",
      header: "Sản phẩm",
      cell: ({ row }) => {
        const p = row.original;
        return (
          <div className="flex items-center gap-3">
            {p.imageUrls[0] ? (
              <img src={p.imageUrls[0]} alt={p.nameVi} className="w-10 h-10 rounded-lg object-cover" />
            ) : (
              <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                <Package className="w-4 h-4 text-muted-foreground" />
              </div>
            )}
            <div>
              <p className="font-medium text-sm">{p.nameVi}</p>
              <p className="text-xs text-muted-foreground">{p.brandName}</p>
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "category",
      header: "Danh mục",
      cell: ({ row }) => (
        <Badge variant="outline" className="text-xs">{AFFILIATE_CATEGORY_LABELS[row.original.category] ?? row.original.category}</Badge>
      ),
    },
    {
      accessorKey: "price",
      header: "Giá",
      cell: ({ row }) => <span className="font-medium text-sm">{fmt(row.original.price)}</span>,
    },
    {
      accessorKey: "commissionRate",
      header: "Hoa hồng",
      cell: ({ row }) => (
        <span className="font-mono text-sm font-medium text-green-600">{(row.original.commissionRate * 100).toFixed(1)}%</span>
      ),
    },
    {
      accessorKey: "availability",
      header: "Trạng thái",
      cell: ({ row }) => <AvailabilityBadge status={row.original.availability} />,
    },
    {
      id: "rating",
      header: "Đánh giá",
      cell: ({ row }) => <RatingStars value={row.original.ratingAverage} count={row.original.ratingCount} />,
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <Select value={categoryFilter} onValueChange={(v) => setCategoryFilter(v || "")}>
          <SelectTrigger className="w-52 h-8 text-sm">
            <SelectValue placeholder="Danh mục" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả danh mục</SelectItem>
            {Object.entries(AFFILIATE_CATEGORY_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{filtered.length} sản phẩm</span>
      </div>
      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={filtered} searchPlaceholder="Tìm sản phẩm..." />
      )}
    </div>
  );
}

// ── Reviews Tab ────────────────────────────────────────────────────────────────
function ReviewsTab() {
  const [targetTypeFilter, setTargetTypeFilter] = useState<string>("all");
  const { data, isLoading } = useReviews({ pageSize: 100 });

  const reviews = data?.items ?? [];
  const filtered = reviews.filter(r => targetTypeFilter === "all" || r.targetType === targetTypeFilter);

  const columns: ColumnDef<ReviewDto>[] = [
    {
      id: "author",
      header: "Người đánh giá",
      cell: ({ row }) => {
        const r = row.original;
        const initials = (r.authorSnapshot.fullName || "?").slice(0, 2).toUpperCase();
        return (
          <div className="flex items-center gap-2">
            <Avatar className="w-8 h-8">
              {r.authorSnapshot.avatarUrl && <AvatarImage src={r.authorSnapshot.avatarUrl} />}
              <AvatarFallback className="text-xs bg-primary/10 text-primary">{initials}</AvatarFallback>
            </Avatar>
            <span className="text-sm font-medium">{r.authorSnapshot.fullName || "Ẩn danh"}</span>
          </div>
        );
      },
    },
    {
      accessorKey: "targetType",
      header: "Đối tượng",
      cell: ({ row }) => (
        <Badge variant="outline" className="text-xs">{REVIEW_TARGET_LABELS[row.original.targetType]}</Badge>
      ),
    },
    {
      accessorKey: "rating",
      header: "Rating",
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          {Array.from({ length: 5 }).map((_, i) => (
            <Star key={i} className={`w-3 h-3 ${i < row.original.rating ? "fill-yellow-400 text-yellow-400" : "text-gray-200"}`} />
          ))}
          <span className="text-xs ml-1 font-medium">{row.original.rating}/5</span>
        </div>
      ),
    },
    {
      accessorKey: "comment",
      header: "Nội dung",
      cell: ({ row }) => (
        <p className="text-sm text-muted-foreground max-w-xs truncate">{row.original.comment || "—"}</p>
      ),
    },
    {
      accessorKey: "isVerifiedPurchase",
      header: "Đã mua",
      cell: ({ row }) => (
        <Badge variant={row.original.isVerifiedPurchase ? "default" : "secondary"} className="text-xs">
          {row.original.isVerifiedPurchase ? "Đã xác thực" : "Chưa xác thực"}
        </Badge>
      ),
    },
    {
      accessorKey: "createdAt",
      header: "Ngày",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">{format(new Date(row.original.createdAt), "dd/MM/yyyy")}</span>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <Select value={targetTypeFilter} onValueChange={(v) => setTargetTypeFilter(v || "")}>
          <SelectTrigger className="w-44 h-8 text-sm">
            <SelectValue placeholder="Loại đối tượng" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả loại</SelectItem>
            {Object.entries(REVIEW_TARGET_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{filtered.length} đánh giá</span>
      </div>
      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={filtered} searchPlaceholder="Tìm đánh giá..." />
      )}
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────
export default function MarketplacePage() {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
          <Store className="w-4 h-4 text-primary" />
        </div>
        <div>
          <h1 className="text-lg font-bold">Marketplace</h1>
          <p className="text-xs text-muted-foreground">Quản lý đối tác, thực đơn và sản phẩm affiliate</p>
        </div>
      </div>

      <Tabs defaultValue="partners">
        <TabsList className="w-full justify-start">
          <TabsTrigger value="partners" className="gap-1.5">
            <Users className="w-3.5 h-3.5" /> Đối tác
          </TabsTrigger>
          <TabsTrigger value="menu" className="gap-1.5">
            <ShoppingBag className="w-3.5 h-3.5" /> Thực đơn
          </TabsTrigger>
          <TabsTrigger value="affiliate" className="gap-1.5">
            <Package className="w-3.5 h-3.5" /> Affiliate
          </TabsTrigger>
          <TabsTrigger value="reviews" className="gap-1.5">
            <MessageSquare className="w-3.5 h-3.5" /> Đánh giá
          </TabsTrigger>
        </TabsList>

        <TabsContent value="partners" className="mt-4"><PartnersTab /></TabsContent>
        <TabsContent value="menu"     className="mt-4"><FoodMenuTab /></TabsContent>
        <TabsContent value="affiliate" className="mt-4"><AffiliateTab /></TabsContent>
        <TabsContent value="reviews"  className="mt-4"><ReviewsTab /></TabsContent>
      </Tabs>
    </div>
  );
}
