import { useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import type {
  AiDashboardOverview,
  IamDashboardOverview,
  OrderDashboardOverview,
  PaymentDashboardOverview,
} from "./dashboard-types";

export type DashboardDays = 7 | 30 | 90;

const STALE_MS = 60_000;

export function useIamDashboard(days: DashboardDays) {
  return useQuery({
    queryKey: ["admin", "dashboard", "iam", days],
    queryFn: () => api.get<IamDashboardOverview>(`/api/v1/iam/admin/dashboard/overview?days=${days}`),
    staleTime: STALE_MS,
  });
}

export function usePaymentDashboard(days: DashboardDays) {
  return useQuery({
    queryKey: ["admin", "dashboard", "payment", days],
    queryFn: () => api.get<PaymentDashboardOverview>(`/api/v1/payment/admin/dashboard/overview?days=${days}`),
    staleTime: STALE_MS,
  });
}

export function useOrderDashboard(days: DashboardDays) {
  return useQuery({
    queryKey: ["admin", "dashboard", "order", days],
    queryFn: () => api.get<OrderDashboardOverview>(`/api/v1/order/admin/dashboard/overview?days=${days}`),
    staleTime: STALE_MS,
  });
}

export function useAiDashboard(days: DashboardDays) {
  return useQuery({
    queryKey: ["admin", "dashboard", "ai", days],
    queryFn: () => api.get<AiDashboardOverview>(`/api/v1/ai/admin/dashboard/overview?days=${days}`),
    staleTime: STALE_MS,
    retry: 1,
  });
}

export function useRefreshDashboard() {
  const qc = useQueryClient();
  return (days: DashboardDays) =>
    qc.invalidateQueries({ queryKey: ["admin", "dashboard"], refetchType: "active" });
}
