"use client";

import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { WorkoutTemplateForm } from "../_components/WorkoutTemplateForm";
import { useCreateWorkoutTemplate, Difficulty } from "@/hooks/admin/use-workout-templates";
import { WorkoutTemplateFormValues } from "@/lib/validations/workout-template";

export default function NewWorkoutTemplatePage() {
  const router = useRouter();
  const createMutation = useCreateWorkoutTemplate();

  const handleSubmit = (v: WorkoutTemplateFormValues) => {
    createMutation.mutate(
      {
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
      { onSuccess: () => router.push("/admin/workout-templates") },
    );
  };

  return (
    <div className="max-w-3xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Tạo mẫu buổi tập</CardTitle></CardHeader>
        <CardContent>
          <WorkoutTemplateForm onSubmit={handleSubmit} loading={createMutation.isPending} submitLabel="Tạo mẫu" />
        </CardContent>
      </Card>
    </div>
  );
}
