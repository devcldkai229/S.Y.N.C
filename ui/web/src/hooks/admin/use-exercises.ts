import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";
import { toast } from "sonner";

export interface ExerciseCatalogDto {
  id:                          string;
  exerciseCode:                string;
  nameEn:                      string;
  nameVi:                      string;
  slug:                        string;
  category:                    string;
  difficulty:                  string;
  movementPattern:             string;
  primaryMuscles:              string[];
  secondaryMuscles:            string[];
  equipmentRequired:           string[];
  isCompound:                  boolean;
  bodyRegion:                  string;
  estimatedCaloriesPerMinute:  number;
  metValue:                    number;
  recommendedRestSeconds:      number;
  contraindications:           string[];
  recommendedGoals:            string[];
  movementTags:                string[];
  aiCoachingCues:              string[];
  commonMistakes:              string[];
  requiresSpotter:             boolean;
  isActive:                    boolean;
}

export interface ExerciseMotionAssetDto {
  id:                       string;
  exerciseId:               string;
  assetType:                string;
  resourceUrl:              string;
  thumbnailUrl?:            string | null;
  unityPrefabId?:           string | null;
  unityAnimationClip?:      string | null;
  animationDurationSeconds: number;
}

export interface ExerciseCatalogDetailDto extends ExerciseCatalogDto {
  motionAssets: ExerciseMotionAssetDto[];
}

interface ExerciseListParams {
  query?:           string;
  category?:        string;
  difficulty?:      string;
  bodyRegion?:      string;
  pageNumber?:      number;
  pageSize?:        number;
}

export type CreateExerciseDto = Omit<ExerciseCatalogDto, "id">;
export type UpdateExerciseDto = ExerciseCatalogDto;

export function useExercises(params: ExerciseListParams = {}) {
  const qs = new URLSearchParams();
  if (params.query)      qs.set("query",      params.query);
  if (params.category)   qs.set("category",   params.category);
  if (params.difficulty) qs.set("difficulty", params.difficulty);
  if (params.bodyRegion) qs.set("bodyRegion", params.bodyRegion);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 100));

  return useQuery({
    queryKey: ["admin", "exercises", params],
    queryFn:  (): Promise<Paged<ExerciseCatalogDto>> => api.getPaged<ExerciseCatalogDto>(`/api/v1/exercise/exercises?${qs}`),
  });
}

export function useExercise(id: string) {
  return useQuery({
    queryKey: ["admin", "exercises", id],
    queryFn:  () => api.get<ExerciseCatalogDetailDto>(`/api/v1/exercise/exercises/${id}/detail`),
    enabled:  !!id,
  });
}

export function useCreateExercise() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateExerciseDto) => api.post<ExerciseCatalogDto>("/api/v1/exercise/exercises", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "exercises"] });
      toast.success("Tạo bài tập thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateExercise() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateExerciseDto }) =>
      api.put<ExerciseCatalogDto>(`/api/v1/exercise/exercises/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "exercises"] });
      toast.success("Cập nhật bài tập thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteExercise() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/exercise/exercises/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "exercises"] });
      toast.success("Đã xóa bài tập");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
