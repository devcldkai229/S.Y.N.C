"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Upload, Trash2 } from "lucide-react";
import { ExerciseForm } from "../_components/ExerciseForm";
import { useExercise, useUpdateExercise } from "@/hooks/admin/use-exercises";
import { ExerciseFormValues } from "@/lib/validations/exercise";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function EditExercisePage() {
  const params   = useParams<{ id: string }>();
  const id       = params?.id ?? "";
  const router   = useRouter();
  const { data, isLoading } = useExercise(id);
  const updateMutation = useUpdateExercise();

  const handleSubmit = (values: ExerciseFormValues) => {
    updateMutation.mutate({ id, dto: { id, ...values } }, {
      onSuccess: () => router.push("/admin/exercises"),
    });
  };

  if (isLoading) {
    return (
      <div className="max-w-3xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-96 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">Exercise not found.</p>;

  const defaultValues: Partial<ExerciseFormValues> = {
    exerciseCode:               data.exerciseCode,
    nameEn:                     data.nameEn,
    nameVi:                     data.nameVi,
    slug:                       data.slug,
    category:                   data.category,
    difficulty:                 data.difficulty,
    movementPattern:            data.movementPattern,
    bodyRegion:                 data.bodyRegion,
    estimatedCaloriesPerMinute: data.estimatedCaloriesPerMinute,
    metValue:                   data.metValue,
    recommendedRestSeconds:     data.recommendedRestSeconds,
    isCompound:                 data.isCompound,
    requiresSpotter:            data.requiresSpotter,
    isActive:                   data.isActive,
    primaryMuscles:             data.primaryMuscles,
    secondaryMuscles:           data.secondaryMuscles,
    equipmentRequired:          data.equipmentRequired,
    contraindications:          data.contraindications,
    recommendedGoals:           data.recommendedGoals,
    movementTags:               data.movementTags,
    aiCoachingCues:             data.aiCoachingCues,
    commonMistakes:             data.commonMistakes,
  };

  return (
    <div className="max-w-3xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Back
      </Button>

      <Tabs defaultValue="details">
        <TabsList>
          <TabsTrigger value="details">Details</TabsTrigger>
          <TabsTrigger value="assets">Motion Assets ({data.motionAssets?.length ?? 0})</TabsTrigger>
        </TabsList>

        <TabsContent value="details" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                {data.nameEn}
                <Badge variant="outline" className="text-xs">{data.exerciseCode}</Badge>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ExerciseForm
                defaultValues={defaultValues}
                onSubmit={handleSubmit}
                loading={updateMutation.isPending}
                submitLabel="Update Exercise"
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="assets" className="mt-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>Motion Assets</CardTitle>
              <Button size="sm" variant="outline">
                <Upload className="w-4 h-4 mr-2" /> Upload Asset
              </Button>
            </CardHeader>
            <CardContent>
              {data.motionAssets?.length === 0 ? (
                <p className="text-muted-foreground text-sm text-center py-8">No assets uploaded yet.</p>
              ) : (
                <div className="divide-y divide-border">
                  {data.motionAssets?.map((asset) => (
                    <div key={asset.id} className="flex items-center justify-between py-3">
                      <div>
                        <p className="text-sm font-medium">{asset.assetType}</p>
                        <p className="text-xs text-muted-foreground truncate max-w-sm">{asset.url}</p>
                        <p className="text-xs text-muted-foreground">{(asset.fileSize / 1024).toFixed(1)} KB</p>
                      </div>
                      <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive">
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
