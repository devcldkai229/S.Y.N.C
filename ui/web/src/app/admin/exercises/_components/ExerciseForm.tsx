"use client";

import { useForm, Controller, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { exerciseSchema, ExerciseFormValues } from "@/lib/validations/exercise";
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

const CATEGORIES       = ["Strength", "Cardio", "Flexibility", "Balance", "Plyometric", "Functional", "Sport"];
const DIFFICULTIES     = ["Beginner", "Intermediate", "Advanced", "Elite"];
const MOVEMENT_PATTERNS = ["Push", "Pull", "Squat", "Hinge", "Carry", "Rotate", "Gait", "Jump", "Crawl"];
const BODY_REGIONS     = ["UpperBody", "LowerBody", "Core", "FullBody", "Arms", "Back", "Chest", "Shoulders", "Legs", "Glutes"];

interface ExerciseFormProps {
  defaultValues?: Partial<ExerciseFormValues>;
  onSubmit:       (values: ExerciseFormValues) => void;
  loading?:       boolean;
  submitLabel?:   string;
}

function FieldError({ msg }: { msg?: string }) {
  if (!msg) return null;
  return <p className="text-xs text-destructive mt-1">{msg}</p>;
}

export function ExerciseForm({ defaultValues, onSubmit, loading, submitLabel = "Save" }: ExerciseFormProps) {
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<ExerciseFormValues>({
    resolver: zodResolver(exerciseSchema) as unknown as Resolver<ExerciseFormValues>,
    defaultValues: {
      isActive:        true,
      isCompound:      false,
      requiresSpotter: false,
      primaryMuscles:  [],
      secondaryMuscles: [],
      equipmentRequired: [],
      contraindications: [],
      recommendedGoals: [],
      movementTags:    [],
      aiCoachingCues:  [],
      commonMistakes:  [],
      ...defaultValues,
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      {/* Basic Info */}
      <FormSection title="Basic Info">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label>Exercise Code *</Label>
            <Input {...register("exerciseCode")} placeholder="EX001" />
            <FieldError msg={errors.exerciseCode?.message} />
          </div>
          <div className="space-y-1">
            <Label>Slug *</Label>
            <Input {...register("slug")} placeholder="barbell-squat" />
            <FieldError msg={errors.slug?.message} />
          </div>
          <div className="space-y-1">
            <Label>Name (Vietnamese) *</Label>
            <Input {...register("nameVi")} placeholder="Squat tạ đòn" />
            <FieldError msg={errors.nameVi?.message} />
          </div>
          <div className="space-y-1">
            <Label>Name (English) *</Label>
            <Input {...register("nameEn")} placeholder="Barbell Squat" />
            <FieldError msg={errors.nameEn?.message} />
          </div>
        </div>
      </FormSection>

      {/* Classification */}
      <FormSection title="Classification">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(
            [
              { label: "Category *",         name: "category",        items: CATEGORIES },
              { label: "Difficulty *",        name: "difficulty",      items: DIFFICULTIES },
              { label: "Movement Pattern *",  name: "movementPattern", items: MOVEMENT_PATTERNS },
              { label: "Body Region *",       name: "bodyRegion",      items: BODY_REGIONS },
            ] as const
          ).map(({ label, name, items }) => (
            <div key={name} className="space-y-1">
              <Label>{label}</Label>
              <Controller
                control={control}
                name={name}
                render={({ field }) => (
                  <Select value={field.value} onValueChange={field.onChange}>
                    <SelectTrigger><SelectValue placeholder="Select..." /></SelectTrigger>
                    <SelectContent>
                      {items.map((i) => <SelectItem key={i} value={i}>{i}</SelectItem>)}
                    </SelectContent>
                  </Select>
                )}
              />
              <FieldError msg={errors[name]?.message} />
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
          <div className="space-y-1">
            <Label>Calories/Min</Label>
            <Input type="number" {...register("estimatedCaloriesPerMinute")} placeholder="8" />
          </div>
          <div className="space-y-1">
            <Label>MET Value</Label>
            <Input type="number" step="0.1" {...register("metValue")} placeholder="5.0" />
          </div>
          <div className="space-y-1">
            <Label>Rest (seconds)</Label>
            <Input type="number" {...register("recommendedRestSeconds")} placeholder="60" />
          </div>
        </div>

        <div className="flex gap-8 mt-4">
          <Controller control={control} name="isCompound" render={({ field }) => (
            <div className="flex items-center gap-2">
              <Switch checked={field.value} onCheckedChange={field.onChange} id="isCompound" />
              <Label htmlFor="isCompound">Compound movement</Label>
            </div>
          )} />
          <Controller control={control} name="requiresSpotter" render={({ field }) => (
            <div className="flex items-center gap-2">
              <Switch checked={field.value} onCheckedChange={field.onChange} id="requiresSpotter" />
              <Label htmlFor="requiresSpotter">Requires spotter</Label>
            </div>
          )} />
          <Controller control={control} name="isActive" render={({ field }) => (
            <div className="flex items-center gap-2">
              <Switch checked={field.value} onCheckedChange={field.onChange} id="isActive" />
              <Label htmlFor="isActive">Active</Label>
            </div>
          )} />
        </div>
      </FormSection>

      {/* Muscles & Equipment */}
      <FormSection title="Muscles & Equipment">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(
            [
              { label: "Primary Muscles",   name: "primaryMuscles" },
              { label: "Secondary Muscles", name: "secondaryMuscles" },
              { label: "Equipment",         name: "equipmentRequired" },
              { label: "Contraindications", name: "contraindications" },
            ] as const
          ).map(({ label, name }) => (
            <div key={name} className="space-y-1">
              <Label>{label}</Label>
              <Controller
                control={control}
                name={name}
                render={({ field }) => (
                  <TagInput value={field.value} onChange={field.onChange} placeholder={`Add ${label.toLowerCase()} and press Enter`} />
                )}
              />
            </div>
          ))}
        </div>
      </FormSection>

      {/* AI & Coaching */}
      <FormSection title="AI & Coaching">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(
            [
              { label: "Recommended Goals", name: "recommendedGoals" },
              { label: "Movement Tags",     name: "movementTags" },
              { label: "AI Coaching Cues",  name: "aiCoachingCues" },
              { label: "Common Mistakes",   name: "commonMistakes" },
            ] as const
          ).map(({ label, name }) => (
            <div key={name} className="space-y-1">
              <Label>{label}</Label>
              <Controller
                control={control}
                name={name}
                render={({ field }) => (
                  <TagInput value={field.value} onChange={field.onChange} placeholder={`Add ${label.toLowerCase()} and press Enter`} />
                )}
              />
            </div>
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
