"use client";

import { useForm, Controller, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { promotionSchema, PromotionFormValues } from "@/lib/validations/promotion";
import { FormSection } from "@/components/admin/FormSection";
import { TagInput } from "@/components/admin/TagInput";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2 } from "lucide-react";

const PROMOTION_TYPES = ["Percentage", "FixedAmount", "FreeShipping", "BuyOneGetOne"];

interface PromotionFormProps {
  defaultValues?: Partial<PromotionFormValues>;
  onSubmit:       (values: PromotionFormValues) => void;
  loading?:       boolean;
  submitLabel?:   string;
}

function FieldError({ msg }: { msg?: string }) {
  if (!msg) return null;
  return <p className="text-xs text-destructive mt-1">{msg}</p>;
}

function toDatetimeLocal(iso?: string) {
  if (!iso) return "";
  return iso.replace("Z", "").slice(0, 16);
}

export function PromotionForm({ defaultValues, onSubmit, loading, submitLabel = "Save" }: PromotionFormProps) {
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<PromotionFormValues>({
    resolver: zodResolver(promotionSchema) as unknown as Resolver<PromotionFormValues>,
    defaultValues: {
      isActive:               true,
      minimumSpend:           0,
      usageLimit:             0,
      applicableProductTypes: [],
      ...defaultValues,
      startsAt: defaultValues?.startsAt ? toDatetimeLocal(defaultValues.startsAt) : "",
      endsAt:   defaultValues?.endsAt   ? toDatetimeLocal(defaultValues.endsAt)   : "",
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      <FormSection title="Basic Info">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1 md:col-span-2">
            <Label>Campaign Name *</Label>
            <Input {...register("name")} placeholder="Summer Sale 2024" />
            <FieldError msg={errors.name?.message} />
          </div>

          <div className="space-y-1">
            <Label>Promotion Type *</Label>
            <Controller
              control={control}
              name="promotionType"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue placeholder="Select type..." /></SelectTrigger>
                  <SelectContent>
                    {PROMOTION_TYPES.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError msg={errors.promotionType?.message} />
          </div>

          <div className="space-y-1">
            <Label>Value</Label>
            <Input type="number" step="0.01" {...register("value")} placeholder="20 (% or fixed amount)" />
            <FieldError msg={errors.value?.message} />
          </div>

          <div className="space-y-1">
            <Label>Coupon Code</Label>
            <Input {...register("couponCode")} placeholder="SUMMER20" className="uppercase" />
          </div>

          <div className="space-y-1">
            <Label>Minimum Spend (VND)</Label>
            <Input type="number" {...register("minimumSpend")} placeholder="0" />
          </div>

          <div className="space-y-1">
            <Label>Usage Limit (0 = unlimited)</Label>
            <Input type="number" {...register("usageLimit")} placeholder="0" />
          </div>
        </div>
      </FormSection>

      <FormSection title="Schedule">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label>Starts At *</Label>
            <Input type="datetime-local" {...register("startsAt")} />
            <FieldError msg={errors.startsAt?.message} />
          </div>
          <div className="space-y-1">
            <Label>Ends At *</Label>
            <Input type="datetime-local" {...register("endsAt")} />
            <FieldError msg={errors.endsAt?.message} />
          </div>
        </div>
      </FormSection>

      <FormSection title="Applicable Products">
        <Controller
          control={control}
          name="applicableProductTypes"
          render={({ field }) => (
            <TagInput
              value={field.value ?? []}
              onChange={field.onChange}
              placeholder="e.g. SubscriptionPlan, WorkoutTemplate — press Enter"
            />
          )}
        />
      </FormSection>

      <FormSection title="Settings">
        <Controller control={control} name="isActive" render={({ field }) => (
          <div className="flex items-center gap-2">
            <Switch checked={field.value} onCheckedChange={field.onChange} id="isActive" />
            <Label htmlFor="isActive">Active</Label>
          </div>
        )} />
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
