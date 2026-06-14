import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export type SubscriptionStatus = "Trial" | "Active" | "PastDue" | "Cancelled" | "Expired" | "Paused";
export type PaymentProvider = "InternalWallet" | "GooglePlay" | "PayOS";

export const SUBSCRIPTION_STATUSES: SubscriptionStatus[] = [
  "Trial", "Active", "PastDue", "Cancelled", "Expired", "Paused",
];
export const PAYMENT_PROVIDERS: PaymentProvider[] = ["InternalWallet", "GooglePlay", "PayOS"];

export interface UserSubscriptionDto {
  id:                     string;
  userId:                 string;
  subscriptionPlanId:     string;
  subscriptionPlanName:   string;
  status:                 SubscriptionStatus;
  startedAt:              string;
  expiredAt?:             string | null;
  autoRenew:              boolean;
  lastBillingAt?:         string | null;
  nextBillingAt?:         string | null;
  cancellationReason?:    string | null;
  managedBy:              PaymentProvider;
  externalSubscriptionId?: string | null;
  createdAt:              string;
  updatedAt?:             string | null;
}

export interface CreateUserSubscriptionDto {
  userId:                  string;
  subscriptionPlanId:      string;
  status:                  SubscriptionStatus;
  startedAt:               string;
  expiredAt?:              string | null;
  autoRenew:               boolean;
  nextBillingAt?:          string | null;
  managedBy:               PaymentProvider;
  externalSubscriptionId?: string | null;
}

export interface UpdateUserSubscriptionDto {
  status:                  SubscriptionStatus;
  expiredAt?:              string | null;
  autoRenew:               boolean;
  nextBillingAt?:          string | null;
  cancellationReason?:     string | null;
  managedBy:               PaymentProvider;
  externalSubscriptionId?: string | null;
}

interface SubscriptionListParams {
  userId?: string;
  status?: SubscriptionStatus;
}

export function useUserSubscriptions(params: SubscriptionListParams = {}) {
  const qs = new URLSearchParams();
  if (params.userId) qs.set("userId", params.userId);
  if (params.status) qs.set("status", params.status);

  return useQuery({
    queryKey: ["admin", "user-subscriptions", params],
    queryFn:  () => api.get<UserSubscriptionDto[]>(`/api/v1/payment/payments/user-subscriptions?${qs}`),
  });
}

export function useUserSubscription(id: string) {
  return useQuery({
    queryKey: ["admin", "user-subscriptions", id],
    queryFn:  () => api.get<UserSubscriptionDto>(`/api/v1/payment/payments/user-subscriptions/${id}`),
    enabled:  !!id,
  });
}

export function useCreateUserSubscription() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateUserSubscriptionDto) =>
      api.post<UserSubscriptionDto>("/api/v1/payment/payments/user-subscriptions", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "user-subscriptions"] });
      toast.success("Tạo gói đăng ký thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateUserSubscription() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateUserSubscriptionDto }) =>
      api.put<UserSubscriptionDto>(`/api/v1/payment/payments/user-subscriptions/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "user-subscriptions"] });
      toast.success("Cập nhật gói đăng ký thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteUserSubscription() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      api.delete(`/api/v1/payment/payments/user-subscriptions/${id}?softDelete=true`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "user-subscriptions"] });
      toast.success("Đã xóa gói đăng ký");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
