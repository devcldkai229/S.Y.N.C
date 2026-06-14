"use client";

import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { TemplateForm } from "../_components/TemplateForm";
import { useCreateNotificationTemplate, NotificationChannel } from "@/hooks/admin/use-notification-templates";
import { NotificationTemplateFormValues } from "@/lib/validations/notification-template";

export default function NewTemplatePage() {
  const router = useRouter();
  const createMutation = useCreateNotificationTemplate();

  const handleSubmit = (v: NotificationTemplateFormValues) => {
    createMutation.mutate(
      {
        templateCode:  v.templateCode,
        name:          v.name,
        defaultTitle:  v.defaultTitle,
        defaultBody:   v.defaultBody,
        variablesJson: v.variablesJson || null,
        channel:       v.channel as NotificationChannel,
        isActive:      v.isActive,
      },
      { onSuccess: () => router.push("/admin/notification-templates") },
    );
  };

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Tạo mẫu thông báo</CardTitle></CardHeader>
        <CardContent>
          <TemplateForm mode="create" onSubmit={handleSubmit} loading={createMutation.isPending} submitLabel="Tạo mẫu" />
        </CardContent>
      </Card>
    </div>
  );
}
