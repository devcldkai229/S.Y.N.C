"use client";

import { useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Salad, Upload, Eye, CheckCircle, XCircle, Database, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/services/api";
import {
  useFoodItems,
  FOOD_CATEGORY_LABELS, DIETARY_TAG_LABELS, FOOD_SOURCE_LABELS,
  type FoodItemDto, type ImportSystemFoodItemsRequest,
} from "@/hooks/admin/use-food-items";
import { useRouter as useRouterNext } from "next/navigation";
import { useQueryClient } from "@tanstack/react-query";

// ── Import Dialog ─────────────────────────────────────────────────────────────
function ImportDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [json, setJson]       = useState("");
  const [loading, setLoading] = useState(false);
  const qc                    = useQueryClient();

  const handleImport = async () => {
    let parsed: ImportSystemFoodItemsRequest;
    try {
      const raw = JSON.parse(json);
      parsed = Array.isArray(raw) ? { items: raw } : raw;
    } catch {
      toast.error("JSON không hợp lệ");
      return;
    }

    setLoading(true);
    try {
      const count = await api.post<number>("/api/v1/nutrition/foods/admin/import", parsed);
      toast.success(`Đã import ${count} thực phẩm thành công`);
      qc.invalidateQueries({ queryKey: ["admin", "food-items"] });
      setJson("");
      onClose();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Import thất bại");
    } finally {
      setLoading(false);
    }
  };

  const exampleJson = JSON.stringify([{
    nameVi: "Ức gà luộc",
    nameEn: "Boiled chicken breast",
    slug: "uc-ga-luoc",
    category: "Protein",
    brand: null,
    barcode: null,
    servingSizeGram: 100,
    caloriesPer100g: 165,
    proteinPer100g: 31,
    carbPer100g: 0,
    fatPer100g: 3.6,
    dietaryTags: ["HighProtein", "LowFat"],
    isVerified: true,
  }], null, 2);

  return (
    <Dialog open={open} onOpenChange={o => !o && onClose()}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Upload className="w-4 h-4" /> Import thực phẩm hệ thống
          </DialogTitle>
        </DialogHeader>
        <div className="space-y-3">
          <div className="space-y-1">
            <Label>JSON (array hoặc object với property "items")</Label>
            <Textarea
              rows={14}
              className="font-mono text-xs"
              placeholder={exampleJson}
              value={json}
              onChange={e => setJson(e.target.value)}
            />
          </div>
          <div className="rounded-lg border border-blue-200 bg-blue-50 p-3">
            <p className="text-xs text-blue-800 font-medium mb-1">Required fields per item:</p>
            <p className="text-xs text-blue-700 font-mono">
              nameVi, nameEn, slug, category, servingSizeGram, caloriesPer100g, proteinPer100g, carbPer100g, fatPer100g
            </p>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={loading}>Hủy</Button>
          <Button onClick={handleImport} disabled={loading || !json.trim()}>
            {loading ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Upload className="w-4 h-4 mr-2" />}
            Import
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ── Page ─────────────────────────────────────────────────────────────────────
export default function NutritionPage() {
  const router              = useRouter();
  const [catFilter, setCat] = useState<string>("all");
  const [sourceFilter, setSrc] = useState<string>("all");
  const [importOpen, setImportOpen] = useState(false);

  const { data, isLoading } = useFoodItems({ pageSize: 200 });
  const foods = data?.items ?? [];

  const filtered = foods.filter(f => {
    if (catFilter !== "all" && f.category !== catFilter)   return false;
    if (sourceFilter !== "all" && f.source !== sourceFilter) return false;
    return true;
  });

  // Stats
  const verified   = foods.filter(f => f.isVerified).length;
  const userSub    = foods.filter(f => f.source === "UserSubmitted").length;
  const categories = [...new Set(foods.map(f => f.category))].length;

  const columns: ColumnDef<FoodItemDto>[] = [
    {
      id: "name",
      header: "Thực phẩm",
      cell: ({ row }) => {
        const f = row.original;
        return (
          <div className="flex items-center gap-3">
            {f.imageUrl ? (
              <img src={f.imageUrl} alt={f.nameVi} className="w-9 h-9 rounded-lg object-cover" />
            ) : (
              <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center">
                <Salad className="w-4 h-4 text-muted-foreground" />
              </div>
            )}
            <div>
              <p className="font-medium text-sm">{f.nameVi}</p>
              <p className="text-xs text-muted-foreground">{f.nameEn}</p>
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
      id: "macros",
      header: "Macro (per 100g)",
      cell: ({ row }) => {
        const f = row.original;
        return (
          <div className="text-xs space-y-0.5">
            <p><span className="text-orange-600 font-semibold">{f.caloriesPer100g}</span> kcal</p>
            <p className="text-muted-foreground">
              P:{f.proteinPer100g}g · C:{f.carbPer100g}g · F:{f.fatPer100g}g
            </p>
          </div>
        );
      },
    },
    {
      accessorKey: "source",
      header: "Nguồn",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">{FOOD_SOURCE_LABELS[row.original.source] ?? row.original.source}</span>
      ),
    },
    {
      accessorKey: "isVerified",
      header: "Xác thực",
      cell: ({ row }) =>
        row.original.isVerified
          ? <CheckCircle className="w-4 h-4 text-green-500" />
          : <XCircle     className="w-4 h-4 text-muted-foreground" />,
    },
    {
      id: "tags",
      header: "Tags",
      cell: ({ row }) => (
        <div className="flex flex-wrap gap-1 max-w-32">
          {row.original.dietaryTags.slice(0, 2).map(t => (
            <span key={t} className="px-1.5 py-0.5 rounded bg-primary/10 text-primary text-[10px] font-medium">
              {DIETARY_TAG_LABELS[t as keyof typeof DIETARY_TAG_LABELS] ?? t}
            </span>
          ))}
          {row.original.dietaryTags.length > 2 && (
            <span className="text-[10px] text-muted-foreground">+{row.original.dietaryTags.length - 2}</span>
          )}
        </div>
      ),
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7"
          onClick={() => router.push(`/admin/nutrition/${row.original.id}`)}
        >
          <Eye className="w-4 h-4" />
        </Button>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
            <Salad className="w-4 h-4 text-primary" />
          </div>
          <div>
            <h1 className="text-lg font-bold">Cơ sở dữ liệu dinh dưỡng</h1>
            <p className="text-xs text-muted-foreground">Quản lý thư viện thực phẩm toàn hệ thống</p>
          </div>
        </div>
        <Button size="sm" onClick={() => setImportOpen(true)}>
          <Upload className="w-4 h-4 mr-2" /> Import thực phẩm
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: "Tổng thực phẩm",   value: foods.length,  icon: Database,      color: "text-primary"  },
          { label: "Đã xác thực",      value: verified,      icon: CheckCircle,   color: "text-green-600"},
          { label: "User đóng góp",    value: userSub,       icon: Salad,         color: "text-blue-600" },
          { label: "Danh mục",         value: categories,    icon: Database,      color: "text-purple-600"},
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
        <Select value={catFilter} onValueChange={(v) => setCat(v || "")}>
          <SelectTrigger className="w-48 h-8 text-sm"><SelectValue placeholder="Danh mục" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả danh mục</SelectItem>
            {Object.entries(FOOD_CATEGORY_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={sourceFilter} onValueChange={(v) => setSrc(v || "")}>
          <SelectTrigger className="w-40 h-8 text-sm"><SelectValue placeholder="Nguồn" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả nguồn</SelectItem>
            {Object.entries(FOOD_SOURCE_LABELS).map(([k, v]) => (
              <SelectItem key={k} value={k}>{v}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <span className="text-xs text-muted-foreground">{filtered.length} thực phẩm</span>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 7 }).map((_, i) => <Skeleton key={i} className="h-14 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={filtered} searchPlaceholder="Tìm thực phẩm..." />
      )}

      <ImportDialog open={importOpen} onClose={() => setImportOpen(false)} />
    </div>
  );
}
