"use client";

import { useForm, Controller, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { notificationTemplateSchema, NotificationTemplateFormValues } from "@/lib/validations/notification-template";
import { FormSection } from "@/components/admin/FormSection";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2 } from "lucide-react";
import { NOTIFICATION_CHANNELS } from "@/hooks/admin/use-notification-templates";

interface TemplateFormProps {
  mode:           "create" | "edit";
  defaultValues?: Partial<NotificationTemplateFormValues>;
  onSubmit:       (values: NotificationTemplateFormValues) => void;
  loading?:       boolean;
  submitLabel?:   string;
}

function FieldError({ msg }: { msg?: string }) {
  if (!msg) return null;
  return <p className="text-xs text-destructive mt-1">{msg}</p>;
}

export function TemplateForm({ mode, defaultValues, onSubmit, loading, submitLabel = "Save" }: TemplateFormProps) {
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<NotificationTemplateFormValues>({
    resolver: zodResolver(notificationTemplateSchema) as unknown as Resolver<NotificationTemplateFormValues>,
    defaultValues: {
      channel:  "Push",
      isActive: true,
      ...defaultValues,
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      <FormSection title="Định danh">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label>Mã mẫu *</Label>
            <Input {...register("templateCode")} placeholder="WORKOUT_REMINDER" disabled={mode === "edit"} className="font-mono" />
            <FieldError msg={errors.templateCode?.message} />
          </div>
          <div className="space-y-1">
            <Label>Tên *</Label>
            <Input {...register("name")} placeholder="Nhắc giờ tập" />
            <FieldError msg={errors.name?.message} />
          </div>
          <div className="space-y-1">
            <Label>Kênh *</Label>
            <Controller control={control} name="channel" render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger className="w-full"><SelectValue placeholder="Kênh..." /></SelectTrigger>
                <SelectContent>
                  {NOTIFICATION_CHANNELS.map((c) => <SelectItem key={c} value={c}>{c}</SelectItem>)}
                </SelectContent>
              </Select>
            )} />
            <FieldError msg={errors.channel?.message} />
          </div>
          <div className="flex items-center gap-2 pt-6">
            <Controller control={control} name="isActive" render={({ field }) => (
              <Switch checked={!!field.value} onCheckedChange={field.onChange} id="isActive" />
            )} />
            <Label htmlFor="isActive">Hoạt động</Label>
          </div>
        </div>
      </FormSection>

      <FormSection title="Nội dung" description="Dùng {{biến}} làm placeholder, khai báo trong Variables JSON.">
        <div className="space-y-4">
          <div className="space-y-1">
            <Label>Tiêu đề mặc định *</Label>
            <Input {...register("defaultTitle")} placeholder="Đến giờ tập rồi {{name}}!" />
            <FieldError msg={errors.defaultTitle?.message} />
          </div>
          <div className="space-y-1">
            <Label>Nội dung mặc định *</Label>
            <Textarea {...register("defaultBody")} rows={4} placeholder="Buổi tập {{workoutName}} đang chờ bạn." />
            <FieldError msg={errors.defaultBody?.message} />
          </div>
          <div className="space-y-1">
            <Label>Variables JSON</Label>
            <Textarea {...register("variablesJson")} rows={3} className="font-mono text-xs" placeholder='{"name":"string","workoutName":"string"}' />
          </div>
        </div>
      </FormSection>

      <div className="flex justify-end gap-2 pt-2 border-t border-border">
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
          {submitLabel}
        </Button>
      </div>
    </form>
  );
}
