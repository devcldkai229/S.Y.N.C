import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";
import { toast } from "sonner";

// ── Enums ────────────────────────────────────────────────────────────────────
export type PartnerType   = "CloudKitchen" | "Restaurant" | "AffiliateBrand";
export type PartnerStatus = "PendingApproval" | "Active" | "Suspended" | "Closed";

export const PARTNER_TYPE_LABELS: Record<PartnerType, string> = {
  CloudKitchen:   "Cloud Kitchen",
  Restaurant:     "Nhà hàng",
  AffiliateBrand: "Thương hiệu liên kết",
};

export const PARTNER_STATUS_LABELS: Record<PartnerStatus, string> = {
  PendingApproval: "Chờ duyệt",
  Active:          "Hoạt động",
  Suspended:       "Tạm dừng",
  Closed:          "Đã đóng",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface OperatingHourDto {
  dayOfWeek: number;
  openTime:  string;
  closeTime: string;
  isClosed:  boolean;
}

export interface LocationDto {
  latitude:  number;
  longitude: number;
}

export interface PartnerDto {
  id:                string;
  ownerUserId:       string;
  name:              string;
  slug:              string;
  type:              PartnerType;
  description?:      string | null;
  logoUrl?:          string | null;
  coverImageUrl?:    string | null;
  email:             string;
  phoneNumber?:      string | null;
  address?:          string | null;
  location?:         LocationDto | null;
  serviceRadiusKm?:  number | null;
  operatingHours:    OperatingHourDto[];
  commissionRate:    number;
  status:            PartnerStatus;
  ratingAverage:     number;
  ratingCount:       number;
  isAiRecommendable: boolean;
  distanceKm?:       number | null;
  createdAt:         string;
}

export interface FoodMenuItemDto {
  id:              string;
  partnerId:       string;
  nameVi:          string;
  nameEn:          string;
  slug:            string;
  description:     string;
  imageUrls:       string[];
  category:        string;
  price:           number;
  currency:        string;
  prepTimeMinutes: number;
  availability:    string;
  isAiRecommended: boolean;
  ratingAverage:   number;
  ratingCount:     number;
}

export interface PartnerDetailDto extends PartnerDto {
  menu: FoodMenuItemDto[];
}

export interface PartnerSearchRequest {
  query?:      string;
  type?:       string;
  pageNumber?: number;
  pageSize?:   number;
}

export interface UpdatePartnerStatusDto {
  status: PartnerStatus;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function usePartners(params: PartnerSearchRequest = {}) {
  const qs = new URLSearchParams();
  if (params.query) qs.set("query", params.query);
  if (params.type)  qs.set("type",  params.type);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 100));

  return useQuery({
    queryKey: ["admin", "partners", params],
    queryFn:  (): Promise<Paged<PartnerDto>> =>
      api.getPaged<PartnerDto>(`/api/v1/marketplace/partners?${qs}`),
  });
}

export function usePartner(id: string) {
  return useQuery({
    queryKey: ["admin", "partners", id],
    queryFn:  () => api.get<PartnerDetailDto>(`/api/v1/marketplace/partners/${id}`),
    enabled:  !!id,
  });
}

export function useUpdatePartnerStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: PartnerStatus }) =>
      api.patch<PartnerDto>(`/api/v1/marketplace/admin/partners/${id}/status`, { status }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "partners"] });
      toast.success("Cập nhật trạng thái đối tác thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
