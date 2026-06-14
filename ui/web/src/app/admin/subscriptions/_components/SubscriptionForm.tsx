"use client";

import { useForm, Controller, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { userSubscriptionSchema, UserSubscriptionFormValues } from "@/lib/validations/user-subscription";
import { FormSection } from "@/components/admin/FormSection";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2 } from "lucide-react";
import { SUBSCRIPTION_STATUSES, PAYMENT_PROVIDERS } from "@/hooks/admin/use-user-subscriptions";
import { useSubscriptionPlans } from "@/hooks/admin/use-subscription-plans";

interface SubscriptionFormProps {
  mode:          "create" | "edit";
  defaultValues?: Partial<UserSubscriptionFormValues>;
  onSubmit:       (values: UserSubscriptionFormValues) => void;
  loading?:       boolean;
  submitLabel?:   string;
}

function FieldError({ msg }: { msg?: string }) {
  if (!msg) return null;
  return <p className="text-xs text-destructive mt-1">{msg}</p>;
}

function toDatetimeLocal(iso?: string | null) {
  if (!iso) return "";
  return iso.replace("Z", "").slice(0, 16);
}

export function SubscriptionForm({ mode, defaultValues, onSubmit, loading, submitLabel = "Save" }: SubscriptionFormProps) {
  const { data: plans } = useSubscriptionPlans();
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<UserSubscriptionFormValues>({
    resolver: zodResolver(userSubscriptionSchema) as unknown as Resolver<UserSubscriptionFormValues>,
    defaultValues: {
      status:    "Active",
      managedBy: "InternalWallet",
      autoRenew: false,
      userId:    "",
      subscriptionPlanId: "",
      ...defaultValues,
      startedAt:     toDatetimeLocal(defaultValues?.startedAt) || toDatetimeLocal(new Date().toISOString()),
      expiredAt:     toDatetimeLocal(defaultValues?.expiredAt),
      nextBillingAt: toDatetimeLocal(defaultValues?.nextBillingAt),
    },
  });

  const isEdit = mode === "edit";

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      <FormSection title="Gán gói">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label>Mã người dùng *</Label>
            <Input {...register("userId")} placeholder="GUID người dùng" disabled={isEdit} />
            <FieldError msg={errors.userId?.message} />
          </div>
          <div className="space-y-1">
            <Label>Gói dịch vụ *</Label>
            <Controller
              control={control}
              name="subscriptionPlanId"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange} disabled={isEdit}>
                  <SelectTrigger className="w-full"><SelectValue placeholder="Chọn gói..." /></SelectTrigger>
                  <SelectContent>
                    {(plans ?? []).map((p) => <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError msg={errors.subscriptionPlanId?.message} />
          </div>
        </div>
      </FormSection>

      <FormSection title="Trạng thái & thanh toán">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label>Trạng thái *</Label>
            <Controller control={control} name="status" render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger className="w-full"><SelectValue placeholder="Trạng thái..." /></SelectTrigger>
                <SelectContent>
                  {SUBSCRIPTION_STATUSES.map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}
                </SelectContent>
              </Select>
            )} />
            <FieldError msg={errors.status?.message} />
          </div>
          <div className="space-y-1">
            <Label>Nguồn quản lý *</Label>
            <Controller control={control} name="managedBy" render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger className="w-full"><SelectValue placeholder="Nguồn..." /></SelectTrigger>
                <SelectContent>
                  {PAYMENT_PROVIDERS.map((p) => <SelectItem key={p} value={p}>{p}</SelectItem>)}
                </SelectContent>
              </Select>
            )} />
            <FieldError msg={errors.managedBy?.message} />
          </div>
          <div className="space-y-1">
            <Label>Ngày bắt đầu *</Label>
            <Input type="datetime-local" {...register("startedAt")} />
            <FieldError msg={errors.startedAt?.message} />
          </div>
          <div className="space-y-1">
            <Label>Ngày hết hạn</Label>
            <Input type="datetime-local" {...register("expiredAt")} />
          </div>
          <div className="space-y-1">
            <Label>Lần thu phí kế tiếp</Label>
            <Input type="datetime-local" {...register("nextBillingAt")} />
          </div>
          <div className="space-y-1">
            <Label>Mã đăng ký bên ngoài</Label>
            <Input {...register("externalSubscriptionId")} placeholder="mã tham chiếu nhà cung cấp" />
          </div>
        </div>

        <div className="flex items-center gap-2 mt-4">
          <Controller control={control} name="autoRenew" render={({ field }) => (
            <Switch checked={!!field.value} onCheckedChange={field.onChange} id="autoRenew" />
          )} />
          <Label htmlFor="autoRenew">Tự động gia hạn</Label>
        </div>

        {isEdit && (
          <div className="space-y-1 mt-4">
            <Label>Lý do hủy</Label>
            <Textarea {...register("cancellationReason")} rows={2} placeholder="Lý do hủy (nếu có)..." />
          </div>
        )}
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
