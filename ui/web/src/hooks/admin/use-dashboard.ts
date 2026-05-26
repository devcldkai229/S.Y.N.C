import { useQuery } from "@tanstack/react-query";
import { api } from "@/services/api";

export interface DashboardStats {
  totalUsers: number;
  activeSubscriptions: number;
  totalExercises: number;
  activeCampaigns: number;
}

export function useDashboardStats() {
  return useQuery({
    queryKey: ["admin", "dashboard-stats"],
    queryFn:  () => api.get<DashboardStats>("/api/v1/admin/dashboard/stats"),
    staleTime: 60_000,
  });
}
