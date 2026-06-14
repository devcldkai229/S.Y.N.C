import { z } from "zod";

export const notificationTemplateSchema = z.object({
  templateCode: z.string().min(1, "Required").max(128),
  name:         z.string().min(1, "Required").max(256),
  defaultTitle: z.string().min(1, "Required").max(256),
  defaultBody:  z.string().min(1, "Required").max(2000),
  variablesJson: z.string().optional(),
  channel:      z.string().min(1, "Required"),
  isActive:     z.boolean().default(true),
});

export type NotificationTemplateFormValues = z.infer<typeof notificationTemplateSchema>;
