import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export type PromotionType = "Percentage" | "FixedAmount" | "FreeShipping" | string;

export interface PromotionCampaignDto {
  id:                     string;
  name:                   string;
  promotionType:          PromotionType;
  value:                  number;
  couponCode?:            string;
  applicableProductTypes?: string[];
  minimumSpend:           number;
  usageLimit:             number;
  startsAt:               string;
  endsAt:                 string;
  isActive:               boolean;
  createdAt:              string;
  updatedAt?:             string;
}

export type CreatePromotionCampaignDto = Omit<PromotionCampaignDto, "id" | "createdAt" | "updatedAt">;
export type UpdatePromotionCampaignDto = CreatePromotionCampaignDto;

export function campaignStatus(c: PromotionCampaignDto): "upcoming" | "running" | "expired" {
  const now = Date.now();
  const s   = new Date(c.startsAt).getTime();
  const e   = new Date(c.endsAt).getTime();
  if (now < s) return "upcoming";
  if (now > e) return "expired";
  return "running";
}

export function usePromotionCampaigns() {
  return useQuery({
    queryKey: ["admin", "promotions"],
    queryFn:  () => api.get<PromotionCampaignDto[]>("/api/v1/payment/payments/promotion-campaigns"),
  });
}

export function usePromotionCampaign(id: string) {
  return useQuery({
    queryKey: ["admin", "promotions", id],
    queryFn:  () => api.get<PromotionCampaignDto>(`/api/v1/payment/payments/promotion-campaigns/${id}`),
    enabled:  !!id,
  });
}

export function useCreatePromotionCampaign() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreatePromotionCampaignDto) =>
      api.post<PromotionCampaignDto>("/api/v1/payment/payments/promotion-campaigns", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "promotions"] });
      toast.success("Tạo chiến dịch thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdatePromotionCampaign() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdatePromotionCampaignDto }) =>
      api.put<PromotionCampaignDto>(`/api/v1/payment/payments/promotion-campaigns/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "promotions"] });
      toast.success("Cập nhật chiến dịch thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeletePromotionCampaign() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      api.delete(`/api/v1/payment/payments/promotion-campaigns/${id}?softDelete=true`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "promotions"] });
      toast.success("Đã xóa chiến dịch");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
