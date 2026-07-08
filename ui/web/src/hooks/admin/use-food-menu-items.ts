import { useQuery } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";

// ── Enums ────────────────────────────────────────────────────────────────────
export type FoodCategory      = "Grains" | "Protein" | "Vegetable" | "Fruit" | "Dairy" | "Fat" | "Beverage" | "Snack" | "PreparedMeal" | "Supplement" | "FastFood";
export type AvailabilityStatus = "Available" | "SoldOut" | "Hidden";
export type SpiceLevel         = "None" | "Mild" | "Medium" | "Hot";

export const FOOD_CATEGORY_LABELS: Record<string, string> = {
  Grains: "Ngũ cốc", Protein: "Đạm", Vegetable: "Rau củ", Fruit: "Trái cây",
  Dairy: "Sữa", Fat: "Chất béo", Beverage: "Đồ uống", Snack: "Ăn vặt",
  PreparedMeal: "Món chế biến", Supplement: "Thực phẩm bổ sung", FastFood: "Đồ ăn nhanh",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface NutritionSnapshotDto {
  calories:            number;
  proteinGram:         number;
  carbGram:            number;
  fatGram:             number;
  servingDescription?: string | null;
}

export interface FoodMenuItemDto {
  id:              string;
  partnerId:       string;
  nameVi:          string;
  nameEn:          string;
  slug:            string;
  description:     string;
  imageUrls:       string[];
  category:        FoodCategory;
  price:           number;
  currency:        string;
  prepTimeMinutes: number;
  nutrition:       NutritionSnapshotDto;
  dietaryTags:     string[];
  spiceLevel:      SpiceLevel;
  availability:    AvailabilityStatus;
  isAiRecommended: boolean;
  ratingAverage:   number;
  ratingCount:     number;
  createdAt:       string;
}

export interface FoodMenuItemSearchRequest {
  query?:      string;
  partnerId?:  string;
  category?:   string;
  pageNumber?: number;
  pageSize?:   number;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function useFoodMenuItems(params: FoodMenuItemSearchRequest = {}) {
  const qs = new URLSearchParams();
  if (params.query)     qs.set("query",     params.query);
  if (params.partnerId) qs.set("partnerId", params.partnerId);
  if (params.category)  qs.set("category",  params.category);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 100));

  return useQuery({
    queryKey: ["admin", "food-menu-items", params],
    queryFn:  (): Promise<Paged<FoodMenuItemDto>> =>
      api.getPaged<FoodMenuItemDto>(`/api/v1/marketplace/food-menu-items?${qs}`),
  });
}

export function useFoodMenuItem(id: string) {
  return useQuery({
    queryKey: ["admin", "food-menu-items", id],
    queryFn:  () => api.get<FoodMenuItemDto>(`/api/v1/marketplace/food-menu-items/${id}`),
    enabled:  !!id,
  });
}
