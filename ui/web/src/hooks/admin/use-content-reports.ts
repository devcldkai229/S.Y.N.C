import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";
import { toast } from "sonner";

export type ReportStatus = "Pending" | "Reviewed" | "Actioned" | "Dismissed";

export interface AdminContentReportDto {
  id: string;
  reporterId: string;
  targetId: string;
  targetType: string;
  reason: string;
  details?: string | null;
  status: ReportStatus;
  createdAt: string;
}

export function useAdminContentReports(params: { status?: string; page?: number; pageSize?: number } = {}) {
  const qs = new URLSearchParams();
  if (params.status) qs.set("status", params.status);
  qs.set("page", String(params.page ?? 1));
  qs.set("pageSize", String(params.pageSize ?? 50));

  return useQuery({
    queryKey: ["admin", "content-reports", params],
    queryFn: (): Promise<Paged<AdminContentReportDto>> =>
      api.getPaged<AdminContentReportDto>(`/api/v1/social/admin/reports?${qs}`),
  });
}

export function useResolveContentReport() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      status,
      hidePost,
    }: {
      id: string;
      status: ReportStatus;
      hidePost?: boolean;
    }) => api.patch(`/api/v1/social/admin/reports/${id}`, { status, hidePost }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "content-reports"] });
      toast.success("Đã cập nhật báo cáo");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
