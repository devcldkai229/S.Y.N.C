"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, Trophy, Loader2, Save, AlertCircle } from "lucide-react";
import { useAchievement, useUpdateAchievement } from "@/hooks/admin/use-achievements";

export default function EditAchievementPage() {
  const params = useParams<{ id: string }>();
  const id = params?.id as string;
  const router = useRouter();

  const { data: achievement, isLoading, isError } = useAchievement(id);
  const update = useUpdateAchievement();

  const [form, setForm] = useState({
    name:            "",
    description:     "",
    xpReward:        100,
    coinReward:      10,
    iconUrl:         "",
    requirementJson: "",
  });

  // Populate form when data loads
  useEffect(() => {
    if (achievement) {
      setForm({
        name:            achievement.name,
        description:     achievement.description,
        xpReward:        achievement.xpReward,
        coinReward:      achievement.coinReward,
        iconUrl:         achievement.iconUrl,
        requirementJson: achievement.requirementJson ?? "",
      });
    }
  }, [achievement]);

  const set = <K extends keyof typeof form>(k: K, v: (typeof form)[K]) =>
    setForm(p => ({ ...p, [k]: v }));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (form.requirementJson.trim()) {
      try { JSON.parse(form.requirementJson); }
      catch { alert("Requirement JSON không hợp lệ"); return; }
    }
    update.mutate(
      {
        id,
        dto: {
          name:            form.name,
          description:     form.description,
          xpReward:        form.xpReward,
          coinReward:      form.coinReward,
          iconUrl:         form.iconUrl,
          requirementJson: form.requirementJson.trim() || null,
        },
      },
      { onSuccess: () => router.push("/admin/achievements") }
    );
  };

  if (isLoading) {
    return (
      <div className="space-y-4 max-w-2xl">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-64 rounded-xl" />
        <Skeleton className="h-32 rounded-xl" />
      </div>
    );
  }

  if (isError || !achievement) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-3 text-muted-foreground">
        <AlertCircle className="w-10 h-10" />
        <p>Không tìm thấy thành tựu.</p>
        <Button variant="outline" size="sm" onClick={() => router.back()}>Quay lại</Button>
      </div>
    );
  }

  return (
    <div className="space-y-4 max-w-2xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => router.back()}>
          <ArrowLeft className="w-4 h-4" />
        </Button>
        <div className="flex items-center gap-2">
          {form.iconUrl ? (
            <img src={form.iconUrl} alt={form.name} className="w-8 h-8 rounded-lg object-contain" onError={e => (e.currentTarget.style.display = "none")} />
          ) : (
            <div className="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Trophy className="w-4 h-4 text-yellow-600" />
            </div>
          )}
          <div>
            <h1 className="text-lg font-bold">Chỉnh sửa thành tựu</h1>
            <p className="text-xs text-muted-foreground font-mono">{achievement.code}</p>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Card className="shadow-none">
          <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Thông tin cơ bản</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <Label>URL Icon *</Label>
              <Input value={form.iconUrl} onChange={e => set("iconUrl", e.target.value)} placeholder="https://..." required />
            </div>
            <div className="space-y-1.5">
              <Label>Tên thành tựu *</Label>
              <Input value={form.name} onChange={e => set("name", e.target.value)} required />
            </div>
            <div className="space-y-1.5">
              <Label>Mô tả *</Label>
              <Textarea rows={3} value={form.description} onChange={e => set("description", e.target.value)} required />
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-none">
          <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Phần thưởng</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label>XP Reward</Label>
              <Input type="number" min={0} value={form.xpReward} onChange={e => set("xpReward", Number(e.target.value))} />
            </div>
            <div className="space-y-1.5">
              <Label>Coin Reward</Label>
              <Input type="number" min={0} value={form.coinReward} onChange={e => set("coinReward", Number(e.target.value))} />
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-none">
          <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Điều kiện mở khóa</CardTitle></CardHeader>
          <CardContent>
            <Textarea
              rows={5}
              className="font-mono text-xs"
              value={form.requirementJson}
              onChange={e => set("requirementJson", e.target.value)}
              placeholder={`{\n  "streak": 7\n}`}
            />
          </CardContent>
        </Card>

        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={() => router.back()}>Hủy</Button>
          <Button type="submit" disabled={update.isPending}>
            {update.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Save className="w-4 h-4 mr-2" />}
            Lưu thay đổi
          </Button>
        </div>
      </form>
    </div>
  );
}
