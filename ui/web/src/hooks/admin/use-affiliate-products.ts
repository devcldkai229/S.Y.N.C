import { useQuery } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";

// ── Enums ────────────────────────────────────────────────────────────────────
export type AffiliateCategory   = "Supplement" | "Equipment" | "Apparel" | "Accessory" | "Wearable" | "Other";
export type AvailabilityStatus  = "Available" | "SoldOut" | "Hidden";

export const AFFILIATE_CATEGORY_LABELS: Record<AffiliateCategory, string> = {
  Supplement: "Thực phẩm bổ sung",
  Equipment:  "Thiết bị tập",
  Apparel:    "Quần áo",
  Accessory:  "Phụ kiện",
  Wearable:   "Thiết bị đeo",
  Other:      "Khác",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface NutritionSnapshotDto {
  calories:            number;
  proteinGram:         number;
  carbGram:            number;
  fatGram:             number;
  servingDescription?: string | null;
}

export interface AffiliateProductDto {
  id:                  string;
  partnerId?:          string | null;
  brandName:           string;
  nameVi:              string;
  nameEn:              string;
  slug:                string;
  description:         string;
  imageUrls:           string[];
  category:            AffiliateCategory;
  price:               number;
  currency:            string;
  affiliateUrl:        string;
  externalProductId?:  string | null;
  commissionRate:      number;
  nutrition?:          NutritionSnapshotDto | null;
  dietaryTags?:        string[] | null;
  availability:        AvailabilityStatus;
  ratingAverage:       number;
  ratingCount:         number;
  createdAt:           string;
}

export interface AffiliateProductSearchRequest {
  query?:      string;
  category?:   string;
  partnerId?:  string;
  pageNumber?: number;
  pageSize?:   number;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function useAffiliateProducts(params: AffiliateProductSearchRequest = {}) {
  const qs = new URLSearchParams();
  if (params.query)    qs.set("query",    params.query);
  if (params.category) qs.set("category", params.category);
  if (params.partnerId) qs.set("partnerId", params.partnerId);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 100));

  return useQuery({
    queryKey: ["admin", "affiliate-products", params],
    queryFn:  (): Promise<Paged<AffiliateProductDto>> =>
      api.getPaged<AffiliateProductDto>(`/api/v1/marketplace/affiliate-products?${qs}`),
  });
}

export function useAffiliateProduct(id: string) {
  return useQuery({
    queryKey: ["admin", "affiliate-products", id],
    queryFn:  () => api.get<AffiliateProductDto>(`/api/v1/marketplace/affiliate-products/${id}`),
    enabled:  !!id,
  });
}
