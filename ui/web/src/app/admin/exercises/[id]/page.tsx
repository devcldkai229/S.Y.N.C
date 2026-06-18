"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ArrowLeft, Plus, Trash2, Loader2, Upload } from "lucide-react";
import { ExerciseForm } from "../_components/ExerciseForm";
import { useExercise, useUpdateExercise } from "@/hooks/admin/use-exercises";
import {
  useCreateMotionAsset,
  useUploadMotionAsset,
  useDeleteMotionAsset,
  ASSET_TYPES,
  type AssetType,
} from "@/hooks/admin/use-motion-assets";
import { ExerciseFormValues } from "@/lib/validations/exercise";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function EditExercisePage() {
  const params   = useParams<{ id: string }>();
  const id       = params?.id ?? "";
  const router   = useRouter();
  const { data, isLoading } = useExercise(id);
  const updateMutation = useUpdateExercise();
  const createAsset = useCreateMotionAsset(id);
  const uploadAsset = useUploadMotionAsset(id);
  const deleteAsset = useDeleteMotionAsset(id);

  // Form thêm theo URL
  const [asset, setAsset] = useState({ assetType: "Video" as AssetType, resourceUrl: "", thumbnailUrl: "", animationDurationSeconds: 0 });
  // Form upload file
  const [up, setUp] = useState({ assetType: "Video" as AssetType, animationDurationSeconds: 0 });
  const [file, setFile] = useState<File | null>(null);
  const [thumb, setThumb] = useState<File | null>(null);

  const addAsset = (e: React.FormEvent) => {
    e.preventDefault();
    createAsset.mutate(
      {
        exerciseId:               id,
        assetType:                asset.assetType,
        resourceUrl:              asset.resourceUrl,
        thumbnailUrl:             asset.thumbnailUrl || null,
        animationDurationSeconds: asset.animationDurationSeconds,
      },
      { onSuccess: () => setAsset({ assetType: "Video", resourceUrl: "", thumbnailUrl: "", animationDurationSeconds: 0 }) },
    );
  };

  const uploadFile = (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;
    uploadAsset.mutate(
      { assetType: up.assetType, file, thumbnail: thumb, animationDurationSeconds: up.animationDurationSeconds },
      { onSuccess: () => { setUp({ assetType: "Video", animationDurationSeconds: 0 }); setFile(null); setThumb(null); } },
    );
  };

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

  if (!data) return <p className="text-muted-foreground">Không tìm thấy bài tập.</p>;

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
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>

      <Tabs defaultValue="details">
        <TabsList>
          <TabsTrigger value="details">Chi tiết</TabsTrigger>
          <TabsTrigger value="assets">Tài nguyên động tác ({data.motionAssets?.length ?? 0})</TabsTrigger>
        </TabsList>

        <TabsContent value="details" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                {data.nameVi || data.nameEn}
                <Badge variant="outline" className="text-xs">{data.exerciseCode}</Badge>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ExerciseForm
                defaultValues={defaultValues}
                onSubmit={handleSubmit}
                loading={updateMutation.isPending}
                submitLabel="Cập nhật bài tập"
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="assets" className="mt-4 space-y-4">
          <Card>
            <CardHeader><CardTitle>Thêm tài nguyên động tác</CardTitle></CardHeader>
            <CardContent>
              <div className="space-y-5">
                {/* Vùng tải file nổi bật */}
                <form onSubmit={uploadFile} className="space-y-4">
                  <label
                    htmlFor="asset-file"
                    onDragOver={(e) => e.preventDefault()}
                    onDrop={(e) => { e.preventDefault(); const dropped = e.dataTransfer.files?.[0]; if (dropped) setFile(dropped); }}
                    className="flex flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-primary/40 bg-primary/5 hover:bg-primary/10 transition-colors cursor-pointer py-10 px-4 text-center"
                  >
                    <div className="w-12 h-12 rounded-full bg-primary/15 flex items-center justify-center">
                      <Upload className="w-6 h-6 text-primary" />
                    </div>
                    {file ? (
                      <>
                        <p className="text-sm font-semibold text-foreground">{file.name}</p>
                        <p className="text-xs text-muted-foreground">{(file.size / 1024 / 1024).toFixed(2)} MB · nhấn để chọn file khác</p>
                      </>
                    ) : (
                      <>
                        <p className="text-sm font-semibold text-foreground">Nhấn để chọn file hoặc kéo thả vào đây</p>
                        <p className="text-xs text-muted-foreground">Video, ảnh hoặc Unity asset (.glb, .fbx, .unity3d)</p>
                      </>
                    )}
                    <input
                      id="asset-file"
                      type="file"
                      className="hidden"
                      accept="video/*,image/*,.glb,.fbx,.unity3d"
                      onChange={(e) => setFile(e.target.files?.[0] ?? null)}
                    />
                  </label>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="space-y-1">
                      <Label>Loại</Label>
                      <Select value={up.assetType} onValueChange={(v) => setUp((p) => ({ ...p, assetType: v as AssetType }))}>
                        <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                        <SelectContent>{ASSET_TYPES.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}</SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-1">
                      <Label>Thời lượng (giây)</Label>
                      <Input type="number" value={up.animationDurationSeconds} onChange={(e) => setUp((p) => ({ ...p, animationDurationSeconds: Number(e.target.value) }))} />
                    </div>
                    <div className="space-y-1">
                      <Label>Ảnh thumbnail (tùy chọn)</Label>
                      <Input type="file" accept="image/*" onChange={(e) => setThumb(e.target.files?.[0] ?? null)} />
                    </div>
                  </div>

                  <Button type="submit" className="w-full" disabled={uploadAsset.isPending || !file}>
                    {uploadAsset.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Upload className="w-4 h-4 mr-2" />}
                    Tải lên tài nguyên
                  </Button>
                </form>

                {/* Phân cách */}
                <div className="flex items-center gap-3">
                  <div className="flex-1 h-px bg-border" />
                  <span className="text-xs text-muted-foreground">hoặc thêm theo URL có sẵn</span>
                  <div className="flex-1 h-px bg-border" />
                </div>

                {/* Thêm theo URL */}
                <form onSubmit={addAsset} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <Label>Loại</Label>
                    <Select value={asset.assetType} onValueChange={(v) => setAsset((p) => ({ ...p, assetType: v as AssetType }))}>
                      <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                      <SelectContent>{ASSET_TYPES.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}</SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-1">
                    <Label>Thời lượng (giây)</Label>
                    <Input type="number" value={asset.animationDurationSeconds} onChange={(e) => setAsset((p) => ({ ...p, animationDurationSeconds: Number(e.target.value) }))} />
                  </div>
                  <div className="space-y-1 md:col-span-2">
                    <Label>URL tài nguyên *</Label>
                    <Input value={asset.resourceUrl} onChange={(e) => setAsset((p) => ({ ...p, resourceUrl: e.target.value }))} placeholder="https://cdn.sync.local/..." required />
                  </div>
                  <div className="space-y-1 md:col-span-2">
                    <Label>URL thumbnail</Label>
                    <Input value={asset.thumbnailUrl} onChange={(e) => setAsset((p) => ({ ...p, thumbnailUrl: e.target.value }))} />
                  </div>
                  <div className="md:col-span-2 flex justify-end">
                    <Button type="submit" variant="outline" size="sm" disabled={createAsset.isPending}>
                      {createAsset.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Plus className="w-4 h-4 mr-2" />}
                      Thêm theo URL
                    </Button>
                  </div>
                </form>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><CardTitle>Danh sách tài nguyên ({data.motionAssets?.length ?? 0})</CardTitle></CardHeader>
            <CardContent>
              {data.motionAssets?.length === 0 ? (
                <p className="text-muted-foreground text-sm text-center py-8">Chưa có tài nguyên nào.</p>
              ) : (
                <div className="divide-y divide-border">
                  {data.motionAssets?.map((a) => (
                    <div key={a.id} className="flex items-center justify-between py-3">
                      <div className="min-w-0">
                        <p className="text-sm font-medium">{a.assetType}</p>
                        <p className="text-xs text-muted-foreground truncate max-w-sm">{a.resourceUrl}</p>
                        {a.animationDurationSeconds > 0 && (
                          <p className="text-xs text-muted-foreground">{a.animationDurationSeconds}s</p>
                        )}
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-destructive hover:text-destructive"
                        disabled={deleteAsset.isPending}
                        onClick={() => deleteAsset.mutate(a.id)}
                      >
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
