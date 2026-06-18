import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export interface SubscriptionPlanDto {
  id:                       string;
  name:                     string;
  description?:             string;
  monthlyPrice:             number;
  yearlyPrice:              number;
  currency:                 string;
  features?:                string[];
  aiUsageLimitPerMonth:     number;
  premiumWorkoutAccess:     boolean;
  premiumMarketplaceAccess: boolean;
  priorityAiResponses:      boolean;
  maxAiAutoOrdersPerMonth:  number;
  isActive:                 boolean;
  googlePlayProductId?:     string;
  createdAt:                string;
  updatedAt?:               string;
}

export type CreateSubscriptionPlanDto = Omit<SubscriptionPlanDto, "id" | "createdAt" | "updatedAt">;
export type UpdateSubscriptionPlanDto = CreateSubscriptionPlanDto;

export function useSubscriptionPlans() {
  return useQuery({
    queryKey: ["admin", "subscription-plans"],
    queryFn:  () => api.get<SubscriptionPlanDto[]>("/api/v1/payment/payments/subscription-plans/admin"),
  });
}

export function useSubscriptionPlan(id: string) {
  return useQuery({
    queryKey: ["admin", "subscription-plans", id],
    queryFn:  () => api.get<SubscriptionPlanDto>(`/api/v1/payment/payments/subscription-plans/${id}`),
    enabled:  !!id,
  });
}

export function useCreateSubscriptionPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateSubscriptionPlanDto) =>
      api.post<SubscriptionPlanDto>("/api/v1/payment/payments/subscription-plans", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "subscription-plans"] });
      toast.success("Tạo gói dịch vụ thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateSubscriptionPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateSubscriptionPlanDto }) =>
      api.put<SubscriptionPlanDto>(`/api/v1/payment/payments/subscription-plans/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "subscription-plans"] });
      toast.success("Cập nhật gói dịch vụ thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteSubscriptionPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      api.delete(`/api/v1/payment/payments/subscription-plans/${id}?softDelete=true`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "subscription-plans"] });
      toast.success("Đã xóa gói dịch vụ");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
