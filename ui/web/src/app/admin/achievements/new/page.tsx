"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ArrowLeft, Trophy, Loader2, Save } from "lucide-react";
import { useCreateAchievement } from "@/hooks/admin/use-achievements";

export default function NewAchievementPage() {
  const router = useRouter();
  const create = useCreateAchievement();

  const [form, setForm] = useState({
    code:            "",
    name:            "",
    description:     "",
    xpReward:        100,
    coinReward:      10,
    iconUrl:         "",
    requirementJson: "",
  });

  const set = <K extends keyof typeof form>(k: K, v: (typeof form)[K]) =>
    setForm(p => ({ ...p, [k]: v }));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validate JSON if provided
    if (form.requirementJson.trim()) {
      try { JSON.parse(form.requirementJson); }
      catch { alert("Requirement JSON không hợp lệ"); return; }
    }

    create.mutate(
      {
        code:            form.code,
        name:            form.name,
        description:     form.description,
        xpReward:        form.xpReward,
        coinReward:      form.coinReward,
        iconUrl:         form.iconUrl,
        requirementJson: form.requirementJson.trim() || null,
      },
      { onSuccess: () => router.push("/admin/achievements") }
    );
  };

  return (
    <div className="space-y-4 max-w-2xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => router.back()}>
          <ArrowLeft className="w-4 h-4" />
        </Button>
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
            <Trophy className="w-4 h-4 text-yellow-600" />
          </div>
          <div>
            <h1 className="text-lg font-bold">Tạo thành tựu mới</h1>
            <p className="text-xs text-muted-foreground">Thêm huy hiệu vào hệ thống gamification</p>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Card className="shadow-none">
          <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Thông tin cơ bản</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label>Code * <span className="text-xs text-muted-foreground">(unique, SCREAMING_SNAKE_CASE)</span></Label>
                <Input
                  value={form.code}
                  onChange={e => set("code", e.target.value.toUpperCase().replace(/[^A-Z0-9_]/g, "_"))}
                  placeholder="FIRST_WORKOUT"
                  required
                />
              </div>
              <div className="space-y-1.5">
                <Label>URL Icon *</Label>
                <Input value={form.iconUrl} onChange={e => set("iconUrl", e.target.value)} placeholder="https://..." required />
              </div>
            </div>

            <div className="space-y-1.5">
              <Label>Tên thành tựu *</Label>
              <Input value={form.name} onChange={e => set("name", e.target.value)} placeholder="Buổi tập đầu tiên" required />
            </div>

            <div className="space-y-1.5">
              <Label>Mô tả *</Label>
              <Textarea
                rows={3}
                value={form.description}
                onChange={e => set("description", e.target.value)}
                placeholder="Hoàn thành buổi tập luyện đầu tiên của bạn"
                required
              />
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-none">
          <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Phần thưởng</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label>XP Reward</Label>
              <Input
                type="number"
                min={0}
                value={form.xpReward}
                onChange={e => set("xpReward", Number(e.target.value))}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Coin Reward (SyncCoins)</Label>
              <Input
                type="number"
                min={0}
                value={form.coinReward}
                onChange={e => set("coinReward", Number(e.target.value))}
              />
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-none">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold">Điều kiện mở khóa</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <Textarea
              rows={5}
              className="font-mono text-xs"
              value={form.requirementJson}
              onChange={e => set("requirementJson", e.target.value)}
              placeholder={`{\n  "streak": 7,\n  "workoutsCompleted": 10\n}`}
            />
            <p className="text-xs text-muted-foreground">
              JSON tùy chọn mô tả điều kiện. AI engine sẽ parse field này để trigger unlock.
            </p>
          </CardContent>
        </Card>

        {/* Preview */}
        {(form.name || form.iconUrl) && (
          <Card className="shadow-none bg-muted/30">
            <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Xem trước</CardTitle></CardHeader>
            <CardContent>
              <div className="flex items-center gap-3 p-3 rounded-xl bg-background border border-border">
                {form.iconUrl ? (
                  <img src={form.iconUrl} alt={form.name} className="w-12 h-12 rounded-xl object-contain" onError={e => (e.currentTarget.style.display = "none")} />
                ) : (
                  <div className="w-12 h-12 rounded-xl bg-yellow-100 flex items-center justify-center">
                    <Trophy className="w-6 h-6 text-yellow-600" />
                  </div>
                )}
                <div>
                  <p className="font-semibold">{form.name || "Tên thành tựu"}</p>
                  <p className="text-sm text-muted-foreground">{form.description || "Mô tả"}</p>
                  <div className="flex items-center gap-3 mt-1 text-xs">
                    <span className="text-blue-600 font-medium">⚡ {form.xpReward} XP</span>
                    <span className="text-yellow-600 font-medium">🪙 {form.coinReward} Coins</span>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={() => router.back()}>Hủy</Button>
          <Button type="submit" disabled={create.isPending}>
            {create.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Save className="w-4 h-4 mr-2" />}
            Tạo thành tựu
          </Button>
        </div>
      </form>
    </div>
  );
}
