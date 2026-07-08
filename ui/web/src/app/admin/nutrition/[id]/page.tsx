"use client";

import { useParams, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, AlertCircle, Salad, CheckCircle, XCircle } from "lucide-react";
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from "recharts";
import { useFoodItem, FOOD_CATEGORY_LABELS, DIETARY_TAG_LABELS, FOOD_SOURCE_LABELS } from "@/hooks/admin/use-food-items";

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between py-2 gap-4">
      <span className="text-sm text-muted-foreground shrink-0">{label}</span>
      <span className="text-sm font-medium text-right">{value}</span>
    </div>
  );
}

const MACRO_COLORS = ["#f97316", "#3b82f6", "#22c55e"];

export default function FoodItemDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params?.id as string;
  const router   = useRouter();
  const { data: food, isLoading, isError } = useFoodItem(id);

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48 rounded-lg" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Skeleton className="h-64 rounded-xl" />
          <Skeleton className="h-64 rounded-xl" />
        </div>
      </div>
    );
  }

  if (isError || !food) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-3 text-muted-foreground">
        <AlertCircle className="w-10 h-10" />
        <p>Không tìm thấy thực phẩm.</p>
        <Button variant="outline" size="sm" onClick={() => router.back()}>Quay lại</Button>
      </div>
    );
  }

  // Macro pie data (proportion by calories: protein 4 cal/g, carb 4 cal/g, fat 9 cal/g)
  const macroData = [
    { name: "Protein",  value: Math.round(food.proteinPer100g * 4),   grams: food.proteinPer100g  },
    { name: "Carbs",    value: Math.round(food.carbPer100g   * 4),   grams: food.carbPer100g    },
    { name: "Fat",      value: Math.round(food.fatPer100g    * 9),   grams: food.fatPer100g     },
  ].filter(d => d.value > 0);

  return (
    <div className="space-y-4 max-w-3xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => router.back()}>
          <ArrowLeft className="w-4 h-4" />
        </Button>
        <div className="flex items-center gap-3 flex-1">
          {food.imageUrl ? (
            <img src={food.imageUrl} alt={food.nameVi} className="w-12 h-12 rounded-xl object-cover" />
          ) : (
            <div className="w-12 h-12 rounded-xl bg-muted flex items-center justify-center">
              <Salad className="w-6 h-6 text-muted-foreground" />
            </div>
          )}
          <div>
            <h1 className="text-lg font-bold">{food.nameVi}</h1>
            <p className="text-sm text-muted-foreground">{food.nameEn}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="outline">{FOOD_CATEGORY_LABELS[food.category] ?? food.category}</Badge>
          {food.isVerified
            ? <span className="flex items-center gap-1 text-xs text-green-600"><CheckCircle className="w-3.5 h-3.5" /> Đã xác thực</span>
            : <span className="flex items-center gap-1 text-xs text-muted-foreground"><XCircle className="w-3.5 h-3.5" /> Chưa xác thực</span>
          }
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Left: Macro chart */}
        <Card className="shadow-none">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold">Phân bổ Macro (per 100g)</CardTitle>
          </CardHeader>
          <CardContent>
            {/* Calorie highlight */}
            <div className="text-center mb-4">
              <p className="text-4xl font-bold text-orange-500">{food.caloriesPer100g}</p>
              <p className="text-sm text-muted-foreground">kcal per 100g</p>
            </div>

            {/* Macro bars */}
            <div className="space-y-3 mb-4">
              {[
                { label: "Protein",  value: food.proteinPer100g, color: "bg-blue-500",   pct: Math.round((food.proteinPer100g * 4 / food.caloriesPer100g) * 100) },
                { label: "Carbs",    value: food.carbPer100g,    color: "bg-green-500",  pct: Math.round((food.carbPer100g   * 4 / food.caloriesPer100g) * 100) },
                { label: "Fat",      value: food.fatPer100g,     color: "bg-orange-500", pct: Math.round((food.fatPer100g    * 9 / food.caloriesPer100g) * 100) },
              ].map(m => (
                <div key={m.label}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="font-medium">{m.label}</span>
                    <span className="text-muted-foreground">{m.value}g ({m.pct}%)</span>
                  </div>
                  <div className="w-full h-2 bg-muted rounded-full overflow-hidden">
                    <div className={`h-full ${m.color} rounded-full`} style={{ width: `${m.pct}%` }} />
                  </div>
                </div>
              ))}
            </div>

            {macroData.length > 0 && (
              <ResponsiveContainer width="100%" height={160}>
                <PieChart>
                  <Pie data={macroData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={60}>
                    {macroData.map((_, i) => <Cell key={i} fill={MACRO_COLORS[i % MACRO_COLORS.length]} />)}
                  </Pie>
                  <Tooltip formatter={(v, n) => [`${v} kcal`, n]} />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Right: Details */}
        <div className="space-y-4">
          <Card className="shadow-none">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-semibold">Thông tin chung</CardTitle>
            </CardHeader>
            <CardContent className="divide-y divide-border/50">
              <InfoRow label="Tên VI"       value={food.nameVi} />
              <InfoRow label="Tên EN"       value={food.nameEn} />
              {food.brand   && <InfoRow label="Thương hiệu" value={food.brand} />}
              {food.barcode && <InfoRow label="Barcode"     value={<span className="font-mono">{food.barcode}</span>} />}
              <InfoRow label="Khẩu phần"   value={`${food.servingSizeGram}g${food.servingDescription ? ` (${food.servingDescription})` : ""}`} />
              <InfoRow label="Nguồn dữ liệu" value={FOOD_SOURCE_LABELS[food.source] ?? food.source} />
            </CardContent>
          </Card>

          {/* Micronutrients */}
          {(food.fiberPer100g || food.sugarPer100g || food.sodiumMgPer100g) && (
            <Card className="shadow-none">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-semibold">Vi chất (per 100g)</CardTitle>
              </CardHeader>
              <CardContent className="divide-y divide-border/50">
                {food.fiberPer100g    != null && <InfoRow label="Chất xơ"  value={`${food.fiberPer100g}g`} />}
                {food.sugarPer100g    != null && <InfoRow label="Đường"    value={`${food.sugarPer100g}g`} />}
                {food.sodiumMgPer100g != null && <InfoRow label="Sodium"   value={`${food.sodiumMgPer100g}mg`} />}
              </CardContent>
            </Card>
          )}

          {/* Dietary tags */}
          {food.dietaryTags.length > 0 && (
            <Card className="shadow-none">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-semibold">Dietary Tags</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {food.dietaryTags.map(t => (
                    <span key={t} className="px-2.5 py-1 rounded-full bg-primary/10 text-primary text-xs font-medium">
                      {DIETARY_TAG_LABELS[t as keyof typeof DIETARY_TAG_LABELS] ?? t}
                    </span>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Marketplace link */}
          {food.marketplaceItemId && (
            <Card className="shadow-none border-blue-200 bg-blue-50/30">
              <CardContent className="pt-4 pb-3">
                <p className="text-sm text-blue-800">
                  Liên kết với Marketplace item:{" "}
                  <span className="font-mono text-xs break-all">{food.marketplaceItemId}</span>
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
