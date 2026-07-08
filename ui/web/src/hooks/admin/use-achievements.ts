import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface AchievementDto {
  id:               string;
  code:             string;
  name:             string;
  description:      string;
  xpReward:         number;
  coinReward:       number;
  iconUrl:          string;
  requirementJson?: string | null;
  createdAt?:       string;
}

export interface CreateAchievementDto {
  code:             string;
  name:             string;
  description:      string;
  xpReward:         number;
  coinReward:       number;
  iconUrl:          string;
  requirementJson?: string | null;
}

export type UpdateAchievementDto = Partial<CreateAchievementDto>;

// ── Hooks ─────────────────────────────────────────────────────────────────────
/**
 * NOTE: InternalGamificationController is unauthenticated internal API.
 * A proper AdminAchievementsController (AuthPolicies.AdminOnly) should be added
 * to IAM service. Endpoint placeholder: /api/v1/iam/admin/achievements
 */
export function useAchievements() {
  return useQuery({
    queryKey: ["admin", "achievements"],
    queryFn:  () => api.get<AchievementDto[]>("/api/v1/iam/admin/achievements"),
  });
}

export function useAchievement(id: string) {
  return useQuery({
    queryKey: ["admin", "achievements", id],
    queryFn:  () => api.get<AchievementDto>(`/api/v1/iam/admin/achievements/${id}`),
    enabled:  !!id,
  });
}

export function useCreateAchievement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateAchievementDto) =>
      api.post<AchievementDto>("/api/v1/iam/admin/achievements", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "achievements"] });
      toast.success("Tạo thành tựu thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateAchievement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateAchievementDto }) =>
      api.put<AchievementDto>(`/api/v1/iam/admin/achievements/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "achievements"] });
      toast.success("Cập nhật thành tựu thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteAchievement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/iam/admin/achievements/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "achievements"] });
      toast.success("Đã xóa thành tựu");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
