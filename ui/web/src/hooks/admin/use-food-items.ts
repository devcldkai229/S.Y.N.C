import { useQuery } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";

// ── Enums ────────────────────────────────────────────────────────────────────
export type FoodCategory  = "Grains" | "Protein" | "Vegetable" | "Fruit" | "Dairy" | "Fat" | "Beverage" | "Snack" | "PreparedMeal" | "Supplement" | "FastFood";
export type DietaryTag    = "Vegetarian" | "Vegan" | "Keto" | "LowCarb" | "HighProtein" | "LowFat" | "GlutenFree" | "Halal" | "DairyFree";
export type FoodDataSource = "System" | "UserSubmitted" | "Marketplace" | "External";

export const FOOD_CATEGORY_LABELS: Record<string, string> = {
  Grains: "Ngũ cốc", Protein: "Đạm", Vegetable: "Rau củ", Fruit: "Trái cây",
  Dairy: "Sữa", Fat: "Chất béo", Beverage: "Đồ uống", Snack: "Ăn vặt",
  PreparedMeal: "Món chế biến", Supplement: "Thực phẩm bổ sung", FastFood: "Đồ ăn nhanh",
};

export const DIETARY_TAG_LABELS: Record<DietaryTag, string> = {
  Vegetarian: "Chay", Vegan: "Thuần chay", Keto: "Keto", LowCarb: "Low Carb",
  HighProtein: "High Protein", LowFat: "Low Fat", GlutenFree: "Gluten Free",
  Halal: "Halal", DairyFree: "Không sữa",
};

export const FOOD_SOURCE_LABELS: Record<FoodDataSource, string> = {
  System: "Hệ thống", UserSubmitted: "Người dùng", Marketplace: "Marketplace", External: "Bên ngoài",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface FoodItemDto {
  id:                  string;
  nameVi:              string;
  nameEn:              string;
  slug:                string;
  category:            FoodCategory;
  brand?:              string | null;
  barcode?:            string | null;
  servingSizeGram:     number;
  servingDescription?: string | null;
  caloriesPer100g:     number;
  proteinPer100g:      number;
  carbPer100g:         number;
  fatPer100g:          number;
  fiberPer100g?:       number | null;
  sugarPer100g?:       number | null;
  sodiumMgPer100g?:    number | null;
  dietaryTags:         DietaryTag[];
  imageUrl?:           string | null;
  source:              FoodDataSource;
  marketplaceItemId?:  string | null;
  isVerified:          boolean;
  isActive:            boolean;
  createdAt?:          string;
}

export interface FoodSearchRequest {
  query?:       string;
  category?:    string;
  dietaryTags?: string[];
  pageNumber?:  number;
  pageSize?:    number;
}

export interface ImportSystemFoodItemDto {
  nameVi:              string;
  nameEn:              string;
  slug:                string;
  category:            FoodCategory;
  brand?:              string | null;
  barcode?:            string | null;
  servingSizeGram:     number;
  servingDescription?: string | null;
  caloriesPer100g:     number;
  proteinPer100g:      number;
  carbPer100g:         number;
  fatPer100g:          number;
  dietaryTags?:        DietaryTag[];
  imageUrl?:           string | null;
  isVerified:          boolean;
}

export interface ImportSystemFoodItemsRequest {
  items: ImportSystemFoodItemDto[];
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function useFoodItems(params: FoodSearchRequest = {}) {
  const qs = new URLSearchParams();
  if (params.query)    qs.set("query",    params.query);
  if (params.category) qs.set("category", params.category);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 100));

  return useQuery({
    queryKey: ["admin", "food-items", params],
    queryFn:  (): Promise<Paged<FoodItemDto>> =>
      api.getPaged<FoodItemDto>(`/api/v1/nutrition/foods?${qs}`),
  });
}

export function useFoodItem(id: string) {
  return useQuery({
    queryKey: ["admin", "food-items", id],
    queryFn:  () => api.get<FoodItemDto>(`/api/v1/nutrition/foods/${id}`),
    enabled:  !!id,
  });
}
