import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export type NotificationChannel = "Push" | "InApp" | "Email" | "Sms";
export const NOTIFICATION_CHANNELS: NotificationChannel[] = ["Push", "InApp", "Email", "Sms"];

export interface NotificationTemplateDto {
  id:            string;
  templateCode:  string;
  name:          string;
  defaultTitle:  string;
  defaultBody:   string;
  variablesJson?: string | null;
  channel:       NotificationChannel;
  isActive:      boolean;
  createdAt:     string;
  updatedAt?:    string | null;
}

export interface CreateNotificationTemplateDto {
  templateCode:  string;
  name:          string;
  defaultTitle:  string;
  defaultBody:   string;
  variablesJson?: string | null;
  channel:       NotificationChannel;
  isActive:      boolean;
}

export type UpdateNotificationTemplateDto = Omit<CreateNotificationTemplateDto, "templateCode">;

export function useNotificationTemplates() {
  return useQuery({
    queryKey: ["admin", "notification-templates"],
    queryFn:  () => api.get<NotificationTemplateDto[]>("/api/v1/notification/templates"),
  });
}

export function useNotificationTemplate(id: string) {
  return useQuery({
    queryKey: ["admin", "notification-templates", id],
    queryFn:  () => api.get<NotificationTemplateDto>(`/api/v1/notification/templates/${id}`),
    enabled:  !!id,
  });
}

export function useCreateNotificationTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateNotificationTemplateDto) =>
      api.post<NotificationTemplateDto>("/api/v1/notification/templates", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("Tạo mẫu thông báo thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateNotificationTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateNotificationTemplateDto }) =>
      api.put(`/api/v1/notification/templates/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("Cập nhật mẫu thông báo thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteNotificationTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/notification/templates/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("Đã xóa mẫu thông báo");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useToggleTemplateStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.patch(`/api/v1/notification/templates/${id}/toggle-status`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "notification-templates"] });
      toast.success("Đã cập nhật trạng thái mẫu");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
