import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";
import { toast } from "sonner";

export type Difficulty = "Beginner" | "Intermediate" | "Advanced";
export const DIFFICULTIES: Difficulty[] = ["Beginner", "Intermediate", "Advanced"];

export interface TemplateSessionBlockDto {
  order:       number;
  exerciseId:  string;
  sets:        number;
  minReps:     number;
  maxReps:     number;
  restSeconds: number;
  tempo:       string;
  rir:         number;
  notes?:      string | null;
}

export interface WorkoutTemplateDto {
  id:                       string;
  name:                     string;
  goal:                     string;
  difficulty:               Difficulty;
  estimatedDurationMinutes: number;
  targetMuscleGroups:       string[];
  requiredEquipment:        string[];
  estimatedCaloriesBurn:    number;
  aiRecoveryScore:          number;
  isSystemTemplate:         boolean;
  createdBy:                string;
  sessions:                 TemplateSessionBlockDto[];
}

export interface CreateWorkoutTemplateDto {
  name:                     string;
  goal:                     string;
  difficulty:               Difficulty;
  estimatedDurationMinutes: number;
  estimatedCaloriesBurn:    number;
  aiRecoveryScore:          number;
  isSystemTemplate:         boolean;
  createdBy:                string;
  sessions:                 TemplateSessionBlockDto[];
}

export type UpdateWorkoutTemplateDto = CreateWorkoutTemplateDto;

export function useWorkoutTemplates(pageSize = 100) {
  return useQuery({
    queryKey: ["admin", "workout-templates", pageSize],
    queryFn:  (): Promise<Paged<WorkoutTemplateDto>> =>
      api.getPaged<WorkoutTemplateDto>(`/api/v1/exercise/workout-templates?pageNumber=1&pageSize=${pageSize}`),
  });
}

export function useWorkoutTemplate(id: string) {
  return useQuery({
    queryKey: ["admin", "workout-templates", id],
    queryFn:  () => api.get<WorkoutTemplateDto>(`/api/v1/exercise/workout-templates/${id}`),
    enabled:  !!id,
  });
}

export function useCreateWorkoutTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateWorkoutTemplateDto) =>
      api.post<WorkoutTemplateDto>("/api/v1/exercise/workout-templates", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "workout-templates"] });
      toast.success("Tạo mẫu buổi tập thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateWorkoutTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateWorkoutTemplateDto }) =>
      api.put(`/api/v1/exercise/workout-templates/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "workout-templates"] });
      toast.success("Cập nhật mẫu buổi tập thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteWorkoutTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/exercise/workout-templates/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "workout-templates"] });
      toast.success("Đã xóa mẫu buổi tập");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
