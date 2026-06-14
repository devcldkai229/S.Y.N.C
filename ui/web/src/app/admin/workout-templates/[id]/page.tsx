"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { WorkoutTemplateForm } from "../_components/WorkoutTemplateForm";
import { useWorkoutTemplate, useUpdateWorkoutTemplate, Difficulty } from "@/hooks/admin/use-workout-templates";
import { WorkoutTemplateFormValues } from "@/lib/validations/workout-template";
import { Skeleton } from "@/components/ui/skeleton";

export default function EditWorkoutTemplatePage() {
  const params = useParams<{ id: string }>();
  const id     = params?.id ?? "";
  const router = useRouter();
  const { data, isLoading } = useWorkoutTemplate(id);
  const updateMutation = useUpdateWorkoutTemplate();

  const handleSubmit = (v: WorkoutTemplateFormValues) => {
    updateMutation.mutate(
      {
        id,
        dto: {
          name:                     v.name,
          goal:                     v.goal,
          difficulty:               v.difficulty as Difficulty,
          estimatedDurationMinutes: v.estimatedDurationMinutes,
          estimatedCaloriesBurn:    v.estimatedCaloriesBurn,
          aiRecoveryScore:          v.aiRecoveryScore,
          isSystemTemplate:         v.isSystemTemplate,
          createdBy:                v.createdBy,
          sessions:                 v.sessions.map((s) => ({ ...s, notes: s.notes || null })),
        },
      },
      { onSuccess: () => router.push("/admin/workout-templates") },
    );
  };

  if (isLoading) {
    return (
      <div className="max-w-3xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-96 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">Không tìm thấy mẫu buổi tập.</p>;

  return (
    <div className="max-w-3xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Sửa mẫu buổi tập — {data.name}</CardTitle></CardHeader>
        <CardContent>
          <WorkoutTemplateForm
            defaultValues={{
              name:                     data.name,
              goal:                     data.goal,
              difficulty:               data.difficulty,
              estimatedDurationMinutes: data.estimatedDurationMinutes,
              estimatedCaloriesBurn:    data.estimatedCaloriesBurn,
              aiRecoveryScore:          data.aiRecoveryScore,
              isSystemTemplate:         data.isSystemTemplate,
              createdBy:                data.createdBy,
              sessions:                 data.sessions.map((s) => ({ ...s, notes: s.notes ?? "" })),
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
