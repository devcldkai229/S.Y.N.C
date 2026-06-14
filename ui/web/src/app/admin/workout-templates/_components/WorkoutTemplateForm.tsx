"use client";

import { useForm, Controller, useFieldArray, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { workoutTemplateSchema, WorkoutTemplateFormValues } from "@/lib/validations/workout-template";
import { FormSection } from "@/components/admin/FormSection";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Plus, Trash2 } from "lucide-react";
import { DIFFICULTIES } from "@/hooks/admin/use-workout-templates";
import { useExercises } from "@/hooks/admin/use-exercises";

interface WorkoutTemplateFormProps {
  defaultValues?: Partial<WorkoutTemplateFormValues>;
  onSubmit:       (values: WorkoutTemplateFormValues) => void;
  loading?:       boolean;
  submitLabel?:   string;
}

function FieldError({ msg }: { msg?: string }) {
  if (!msg) return null;
  return <p className="text-xs text-destructive mt-1">{msg}</p>;
}

export function WorkoutTemplateForm({ defaultValues, onSubmit, loading, submitLabel = "Save" }: WorkoutTemplateFormProps) {
  const { data: exercises } = useExercises({ pageSize: 200 });
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<WorkoutTemplateFormValues>({
    resolver: zodResolver(workoutTemplateSchema) as unknown as Resolver<WorkoutTemplateFormValues>,
    defaultValues: {
      difficulty:               "Beginner",
      isSystemTemplate:         true,
      createdBy:                "system",
      estimatedDurationMinutes: 45,
      estimatedCaloriesBurn:    300,
      aiRecoveryScore:          50,
      sessions:                 [],
      ...defaultValues,
    },
  });

  const { fields, append, remove } = useFieldArray({ control, name: "sessions" });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      <FormSection title="Thông tin cơ bản">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label>Tên mẫu *</Label>
            <Input {...register("name")} placeholder="Toàn thân cho người mới" />
            <FieldError msg={errors.name?.message} />
          </div>
          <div className="space-y-1">
            <Label>Mục tiêu *</Label>
            <Input {...register("goal")} placeholder="Tăng cơ / Sức mạnh..." />
            <FieldError msg={errors.goal?.message} />
          </div>
          <div className="space-y-1">
            <Label>Độ khó *</Label>
            <Controller control={control} name="difficulty" render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>{DIFFICULTIES.map((d) => <SelectItem key={d} value={d}>{d}</SelectItem>)}</SelectContent>
              </Select>
            )} />
          </div>
          <div className="space-y-1">
            <Label>Người tạo</Label>
            <Input {...register("createdBy")} placeholder="system" />
          </div>
          <div className="space-y-1">
            <Label>Thời lượng (phút)</Label>
            <Input type="number" {...register("estimatedDurationMinutes")} />
          </div>
          <div className="space-y-1">
            <Label>Calo ước tính</Label>
            <Input type="number" {...register("estimatedCaloriesBurn")} />
          </div>
          <div className="space-y-1">
            <Label>Điểm phục hồi AI (0-100)</Label>
            <Input type="number" {...register("aiRecoveryScore")} />
          </div>
          <div className="flex items-center gap-2 pt-6">
            <Controller control={control} name="isSystemTemplate" render={({ field }) => (
              <Switch checked={!!field.value} onCheckedChange={field.onChange} id="isSystemTemplate" />
            )} />
            <Label htmlFor="isSystemTemplate">Mẫu hệ thống</Label>
          </div>
        </div>
      </FormSection>

      <FormSection title="Các block bài tập">
        <div className="space-y-3">
          {fields.map((f, i) => (
            <div key={f.id} className="rounded-lg border border-border p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-muted-foreground">Block #{i + 1}</span>
                <Button type="button" variant="ghost" size="icon" className="w-7 h-7 text-destructive" onClick={() => remove(i)}>
                  <Trash2 className="w-4 h-4" />
                </Button>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                <div className="col-span-2 md:col-span-4 space-y-1">
                  <Label className="text-xs">Bài tập *</Label>
                  <Controller control={control} name={`sessions.${i}.exerciseId`} render={({ field }) => (
                    <Select value={field.value} onValueChange={field.onChange}>
                      <SelectTrigger className="w-full"><SelectValue placeholder="Chọn bài tập..." /></SelectTrigger>
                      <SelectContent>
                        {(exercises?.items ?? []).map((e) => <SelectItem key={e.id} value={e.id}>{e.nameVi || e.nameEn}</SelectItem>)}
                      </SelectContent>
                    </Select>
                  )} />
                </div>
                <div className="space-y-1"><Label className="text-xs">Thứ tự</Label><Input type="number" {...register(`sessions.${i}.order`)} /></div>
                <div className="space-y-1"><Label className="text-xs">Số hiệp</Label><Input type="number" {...register(`sessions.${i}.sets`)} /></div>
                <div className="space-y-1"><Label className="text-xs">Reps tối thiểu</Label><Input type="number" {...register(`sessions.${i}.minReps`)} /></div>
                <div className="space-y-1"><Label className="text-xs">Reps tối đa</Label><Input type="number" {...register(`sessions.${i}.maxReps`)} /></div>
                <div className="space-y-1"><Label className="text-xs">Nghỉ (giây)</Label><Input type="number" {...register(`sessions.${i}.restSeconds`)} /></div>
                <div className="space-y-1"><Label className="text-xs">RIR</Label><Input type="number" {...register(`sessions.${i}.rir`)} /></div>
                <div className="space-y-1"><Label className="text-xs">Nhịp (tempo)</Label><Input {...register(`sessions.${i}.tempo`)} placeholder="3-1-1" /></div>
                <div className="col-span-2 space-y-1"><Label className="text-xs">Ghi chú</Label><Input {...register(`sessions.${i}.notes`)} /></div>
              </div>
            </div>
          ))}
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => append({ order: fields.length, exerciseId: "", sets: 3, minReps: 8, maxReps: 12, restSeconds: 60, tempo: "", rir: 2, notes: "" })}
          >
            <Plus className="w-4 h-4 mr-2" /> Thêm block
          </Button>
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
