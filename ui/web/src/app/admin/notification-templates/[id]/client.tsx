"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { TemplateForm } from "../_components/TemplateForm";
import {
  useNotificationTemplate,
  useUpdateNotificationTemplate,
  NotificationChannel,
} from "@/hooks/admin/use-notification-templates";
import { NotificationTemplateFormValues } from "@/lib/validations/notification-template";
import { Skeleton } from "@/components/ui/skeleton";

export default function EditTemplatePage() {
  const params = useParams<{ id: string }>();
  const id     = params?.id ?? "";
  const router = useRouter();
  const { data, isLoading } = useNotificationTemplate(id);
  const updateMutation = useUpdateNotificationTemplate();

  const handleSubmit = (v: NotificationTemplateFormValues) => {
    updateMutation.mutate(
      {
        id,
        dto: {
          name:          v.name,
          defaultTitle:  v.defaultTitle,
          defaultBody:   v.defaultBody,
          variablesJson: v.variablesJson || null,
          channel:       v.channel as NotificationChannel,
          isActive:      v.isActive,
        },
      },
      { onSuccess: () => router.push("/admin/notification-templates") },
    );
  };

  if (isLoading) {
    return (
      <div className="max-w-2xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-96 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">Không tìm thấy mẫu thông báo.</p>;

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Sửa mẫu thông báo — {data.name}</CardTitle></CardHeader>
        <CardContent>
          <TemplateForm
            mode="edit"
            defaultValues={{
              templateCode:  data.templateCode,
              name:          data.name,
              defaultTitle:  data.defaultTitle,
              defaultBody:   data.defaultBody,
              variablesJson: data.variablesJson ?? undefined,
              channel:       data.channel,
              isActive:      data.isActive,
            }}
            onSubmit={handleSubmit}
            loading={updateMutation.isPending}
            submitLabel="Cập nhật mẫu"
          />
        </CardContent>
      </Card>
    </div>
  );
}
