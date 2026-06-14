import { useMutation } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";
import type { NotificationChannel } from "./use-notification-templates";

export type NotificationType =
  | "WorkoutReminder" | "MealAutoOrder" | "AiIntervention"
  | "Motivational" | "SystemAlert" | "RewardMinted" | "Promotion";
export type NotificationPriority = "Low" | "Normal" | "High" | "Urgent";

export const NOTIFICATION_TYPES: NotificationType[] = [
  "WorkoutReminder", "MealAutoOrder", "AiIntervention",
  "Motivational", "SystemAlert", "RewardMinted", "Promotion",
];
export const NOTIFICATION_PRIORITIES: NotificationPriority[] = ["Low", "Normal", "High", "Urgent"];

export interface SendNotificationDto {
  userId:    string;
  type:      NotificationType;
  channel:   NotificationChannel;
  priority:  NotificationPriority;
  title:     string;
  body:      string;
  imageUrl?: string | null;
  deepLink?: string | null;
  scheduledFor?: string | null;
}

export interface SendTemplatedNotificationDto {
  userId:       string;
  templateCode: string;
  variables:    Record<string, string>;
  priority:     NotificationPriority;
  deepLink?:    string | null;
  scheduledFor?: string | null;
}

export function useSendNotification() {
  return useMutation({
    mutationFn: (dto: SendNotificationDto) => api.post("/api/v1/notification/notifications/send", dto),
    onSuccess: () => toast.success("Đã đưa thông báo vào hàng đợi"),
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useSendTemplatedNotification() {
  return useMutation({
    mutationFn: (dto: SendTemplatedNotificationDto) => api.post("/api/v1/notification/notifications/send-templated", dto),
    onSuccess: () => toast.success("Đã đưa thông báo theo mẫu vào hàng đợi"),
    onError: (e: Error) => toast.error(e.message),
  });
}
