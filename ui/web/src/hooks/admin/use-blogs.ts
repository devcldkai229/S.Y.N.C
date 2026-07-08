import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";
import { toast } from "sonner";

// ── Enums ────────────────────────────────────────────────────────────────────
export type BlogStatus = "Draft" | "Published" | "Archived";

export const BLOG_STATUS_LABELS: Record<BlogStatus, string> = {
  Draft:     "Nháp",
  Published: "Đã xuất bản",
  Archived:  "Đã lưu trữ",
};

export const BLOG_STATUS_COLORS: Record<BlogStatus, string> = {
  Draft:     "bg-gray-100 text-gray-600",
  Published: "bg-green-100 text-green-800",
  Archived:  "bg-orange-100 text-orange-800",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface BlogAuthorSnapshotDto {
  fullName:   string;
  avatarUrl?: string | null;
}

export interface BlogDto {
  id:            string;
  authorId:      string;
  authorSnapshot: BlogAuthorSnapshotDto;
  title:         string;
  slug:          string;
  coverImageUrl: string;
  content:       string;
  tags:          string[];
  status:        BlogStatus;
  publishedAt?:  string | null;
  likeCount:     number;
  shareCount:    number;
  createdAt:     string;
}

export interface BlogListRequest {
  status?:     BlogStatus;
  pageNumber?: number;
  pageSize?:   number;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function useBlogs(params: BlogListRequest = {}) {
  const qs = new URLSearchParams();
  if (params.status) qs.set("status", params.status);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 50));

  return useQuery({
    queryKey: ["admin", "blogs", params],
    queryFn:  (): Promise<Paged<BlogDto>> =>
      api.getPaged<BlogDto>(`/api/v1/social/blogs?${qs}`),
  });
}

export function useUpdateBlogStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: BlogStatus }) =>
      api.patch(`/api/v1/social/blogs/${id}/status`, { status }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "blogs"] });
      toast.success("Đã cập nhật trạng thái blog");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteBlog() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/social/blogs/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "blogs"] });
      toast.success("Đã xóa blog");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
