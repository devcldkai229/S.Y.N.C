import { useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export type AssetType = "Unity3D" | "Video" | "Image";
export const ASSET_TYPES: AssetType[] = ["Unity3D", "Video", "Image"];

export interface CreateMotionAssetDto {
  exerciseId:               string;
  assetType:                AssetType;
  resourceUrl:              string;
  thumbnailUrl?:            string | null;
  unityPrefabId?:           string | null;
  unityAnimationClip?:      string | null;
  animationDurationSeconds: number;
}

export function useCreateMotionAsset(exerciseId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateMotionAssetDto) =>
      api.post(`/api/v1/exercise/exercises/${exerciseId}/motion-assets`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "exercises", exerciseId] });
      toast.success("Đã thêm tài nguyên động tác");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export interface UploadMotionAssetArgs {
  assetType:                AssetType;
  file:                     File;
  thumbnail?:               File | null;
  animationDurationSeconds: number;
}

export function useUploadMotionAsset(exerciseId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (args: UploadMotionAssetArgs) => {
      const fd = new FormData();
      fd.append("AssetType", args.assetType);
      fd.append("File", args.file);
      if (args.thumbnail) fd.append("ThumbnailFile", args.thumbnail);
      fd.append("AnimationDurationSeconds", String(args.animationDurationSeconds));
      return api.upload(`/api/v1/exercise/exercises/${exerciseId}/motion-assets/upload`, fd);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "exercises", exerciseId] });
      toast.success("Tải lên asset thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteMotionAsset(exerciseId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (assetId: string) => api.delete(`/api/v1/exercise/motion-assets/${assetId}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "exercises", exerciseId] });
      toast.success("Đã xóa tài nguyên động tác");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
