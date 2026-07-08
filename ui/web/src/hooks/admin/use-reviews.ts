import { useQuery } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";

// ── Enums ────────────────────────────────────────────────────────────────────
export type ReviewTargetType = "Partner" | "FoodMenuItem" | "AffiliateProduct";

export const REVIEW_TARGET_LABELS: Record<ReviewTargetType, string> = {
  Partner:          "Đối tác",
  FoodMenuItem:     "Món ăn",
  AffiliateProduct: "Sản phẩm liên kết",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface ReviewAuthorSnapshotDto {
  fullName:  string;
  avatarUrl?: string | null;
}

export interface ReviewDto {
  id:                string;
  userId:            string;
  authorSnapshot:    ReviewAuthorSnapshotDto;
  targetType:        ReviewTargetType;
  targetId:          string;
  rating:            number;
  comment?:          string | null;
  imageUrls?:        string[] | null;
  orderId?:          string | null;
  isVerifiedPurchase: boolean;
  partnerReply?:     string | null;
  createdAt:         string;
}

export interface ReviewListRequest {
  targetType?: ReviewTargetType;
  targetId?:   string;
  pageNumber?: number;
  pageSize?:   number;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function useReviews(params: ReviewListRequest = {}) {
  const qs = new URLSearchParams();
  if (params.targetType) qs.set("targetType", params.targetType);
  if (params.targetId)   qs.set("targetId",   params.targetId);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 50));

  return useQuery({
    queryKey: ["admin", "reviews", params],
    queryFn:  (): Promise<Paged<ReviewDto>> =>
      api.getPaged<ReviewDto>(`/api/v1/marketplace/reviews?${qs}`),
  });
}
