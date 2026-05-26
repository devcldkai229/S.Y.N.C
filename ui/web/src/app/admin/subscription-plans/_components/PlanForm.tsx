"use client";

import { useForm, Controller, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { subscriptionPlanSchema, SubscriptionPlanFormValues } from "@/lib/validations/subscription-plan";
import { FormSection } from "@/components/admin/FormSection";
import { TagInput } from "@/components/admin/TagInput";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Loader2 } from "lucide-react";

interface PlanFormProps {
  defaultValues?: Partial<SubscriptionPlanFormValues>;
  onSubmit:       (values: SubscriptionPlanFormValues) => void;
  loading?:       boolean;
  submitLabel?:   string;
}

function FieldError({ msg }: { msg?: string }) {
  if (!msg) return null;
  return <p className="text-xs text-destructive mt-1">{msg}</p>;
}

export function PlanForm({ defaultValues, onSubmit, loading, submitLabel = "Save" }: PlanFormProps) {
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<SubscriptionPlanFormValues>({
    resolver: zodResolver(subscriptionPlanSchema) as unknown as Resolver<SubscriptionPlanFormValues>,
    defaultValues: {
      currency:                 "VND",
      features:                 [],
      premiumWorkoutAccess:     false,
      premiumMarketplaceAccess: false,
      priorityAiResponses:      false,
      isActive:                 true,
      aiUsageLimitPerMonth:     0,
      maxAiAutoOrdersPerMonth:  0,
      monthlyPrice:             0,
      yearlyPrice:              0,
      ...defaultValues,
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      <FormSection title="Basic Info">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1 md:col-span-2">
            <Label>Plan Name *</Label>
            <Input {...register("name")} placeholder="Pro Plan" />
            <FieldError msg={errors.name?.message} />
          </div>
          <div className="space-y-1 md:col-span-2">
            <Label>Description</Label>
            <Textarea {...register("description")} placeholder="Plan description..." rows={2} />
          </div>
        </div>
      </FormSection>

      <FormSection title="Pricing">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="space-y-1">
            <Label>Monthly Price (VND)</Label>
            <Input type="number" {...register("monthlyPrice")} placeholder="99000" />
            <FieldError msg={errors.monthlyPrice?.message} />
          </div>
          <div className="space-y-1">
            <Label>Yearly Price (VND)</Label>
            <Input type="number" {...register("yearlyPrice")} placeholder="990000" />
            <FieldError msg={errors.yearlyPrice?.message} />
          </div>
          <div className="space-y-1">
            <Label>Currency</Label>
            <Input {...register("currency")} placeholder="VND" />
          </div>
        </div>
      </FormSection>

      <FormSection title="Features & Limits">
        <div className="space-y-1">
          <Label>Features</Label>
          <Controller
            control={control}
            name="features"
            render={({ field }) => (
              <TagInput value={field.value ?? []} onChange={field.onChange} placeholder="Add feature and press Enter" />
            )}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
          <div className="space-y-1">
            <Label>AI Usage Limit / Month</Label>
            <Input type="number" {...register("aiUsageLimitPerMonth")} />
          </div>
          <div className="space-y-1">
            <Label>Max AI Auto Orders / Month</Label>
            <Input type="number" {...register("maxAiAutoOrdersPerMonth")} />
          </div>
          <div className="space-y-1">
            <Label>Google Play Product ID</Label>
            <Input {...register("googlePlayProductId")} placeholder="sync.plan.pro.monthly" />
          </div>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
          {(
            [
              { name: "premiumWorkoutAccess",     label: "Premium Workouts" },
              { name: "premiumMarketplaceAccess", label: "Premium Marketplace" },
              { name: "priorityAiResponses",      label: "Priority AI" },
              { name: "isActive",                 label: "Active" },
            ] as const
          ).map(({ name, label }) => (
            <Controller key={name} control={control} name={name} render={({ field }) => (
              <div className="flex items-center gap-2">
                <Switch checked={!!field.value} onCheckedChange={field.onChange} id={name} />
                <Label htmlFor={name} className="text-sm">{label}</Label>
              </div>
            )} />
          ))}
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
