"use client";

import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { ExerciseForm } from "../_components/ExerciseForm";
import { useCreateExercise } from "@/hooks/admin/use-exercises";
import { ExerciseFormValues } from "@/lib/validations/exercise";

export default function NewExercisePage() {
  const router  = useRouter();
  const createMutation = useCreateExercise();

  const handleSubmit = (values: ExerciseFormValues) => {
    createMutation.mutate(values, {
      onSuccess: () => router.push("/admin/exercises"),
    });
  };

  return (
    <div className="max-w-3xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Back
      </Button>
      <Card>
        <CardHeader>
          <CardTitle>New Exercise</CardTitle>
        </CardHeader>
        <CardContent>
          <ExerciseForm onSubmit={handleSubmit} loading={createMutation.isPending} submitLabel="Create Exercise" />
        </CardContent>
      </Card>
    </div>
  );
}
