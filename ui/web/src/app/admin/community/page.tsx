"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Heart, MessageCircle, Share2, Trash2, Loader2, Plus } from "lucide-react";
import { format } from "date-fns";
import {
  useFeed,
  useDeletePost,
  useActiveChallenges,
  useCreateChallenge,
  CHALLENGE_GOAL_TYPES,
  type ChallengeGoalType,
  type PostDto,
} from "@/hooks/admin/use-social";
import { useAuthStore } from "@/stores/auth.store";

function PostsTab() {
  const { data, isLoading } = useFeed();
  const deletePost = useDeletePost();
  const [target, setTarget] = useState<PostDto | null>(null);

  if (isLoading) {
    return <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-24 rounded-lg" />)}</div>;
  }

  return (
    <div className="space-y-3">
      {(data ?? []).length === 0 && <p className="text-muted-foreground text-sm py-8 text-center">Chưa có bài viết nào.</p>}
      {(data ?? []).map((p) => {
        const initials = (p.authorSnapshot.fullName || "?").split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase();
        return (
          <Card key={p.id}>
            <CardContent className="pt-6">
              <div className="flex items-start gap-3">
                <Avatar className="w-9 h-9">
                  <AvatarFallback className="text-xs bg-primary/10 text-primary">{initials}</AvatarFallback>
                </Avatar>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="text-sm font-medium">{p.authorSnapshot.fullName || "Ẩn danh"}</p>
                    <Badge variant="outline" className="text-xs">{p.postType}</Badge>
                    {!p.isPublic && <Badge variant="outline" className="text-xs">Riêng tư</Badge>}
                    <span className="text-xs text-muted-foreground">{format(new Date(p.createdAt), "dd/MM/yyyy HH:mm")}</span>
                  </div>
                  <p className="text-sm mt-1 whitespace-pre-wrap break-words">{p.content}</p>
                  {p.mediaUrls.length > 0 && (
                    <p className="text-xs text-muted-foreground mt-1">{p.mediaUrls.length} tệp đính kèm</p>
                  )}
                  <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1"><Heart className="w-3 h-3" /> {p.metrics.likeCount}</span>
                    <span className="flex items-center gap-1"><MessageCircle className="w-3 h-3" /> {p.metrics.commentCount}</span>
                    <span className="flex items-center gap-1"><Share2 className="w-3 h-3" /> {p.metrics.shareCount}</span>
                  </div>
                </div>
                <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive" onClick={() => setTarget(p)}>
                  <Trash2 className="w-4 h-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        );
      })}

      <ConfirmDialog
        open={!!target}
        onOpenChange={(o) => !o && setTarget(null)}
        title="Gỡ bài viết"
        description="Gỡ bài viết này khỏi cộng đồng? Hành động không thể hoàn tác."
        confirmLabel="Gỡ bài"
        loading={deletePost.isPending}
        onConfirm={() => {
          if (!target) return;
          deletePost.mutate(target.id, { onSuccess: () => setTarget(null) });
        }}
      />
    </div>
  );
}

function ChallengesTab() {
  const { data, isLoading } = useActiveChallenges();
  const create = useCreateChallenge();
  const adminUser = useAuthStore((s) => s.user);
  const [f, setF] = useState({
    title: "", description: "", startDate: "", endDate: "",
    goalType: "TotalWorkouts" as ChallengeGoalType, targetValue: 0, feedAnnouncement: "",
  });
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((p) => ({ ...p, [k]: v }));

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    create.mutate(
      {
        title: f.title, description: f.description, startDate: f.startDate, endDate: f.endDate,
        goalType: f.goalType, targetValue: f.targetValue,
        authorSnapshot: { fullName: adminUser?.fullName ?? "SYNC Admin" },
        feedAnnouncement: f.feedAnnouncement || null,
      },
      { onSuccess: () => setF({ title: "", description: "", startDate: "", endDate: "", goalType: "TotalWorkouts", targetValue: 0, feedAnnouncement: "" }) },
    );
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <Card>
        <CardHeader><CardTitle className="text-sm font-semibold">Tạo thử thách</CardTitle></CardHeader>
        <CardContent>
          <form onSubmit={submit} className="space-y-3">
            <div className="space-y-1">
              <Label>Tiêu đề *</Label>
              <Input value={f.title} onChange={(e) => set("title", e.target.value)} required />
            </div>
            <div className="space-y-1">
              <Label>Mô tả *</Label>
              <Textarea value={f.description} onChange={(e) => set("description", e.target.value)} rows={2} required />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label>Bắt đầu *</Label>
                <Input type="datetime-local" value={f.startDate} onChange={(e) => set("startDate", e.target.value)} required />
              </div>
              <div className="space-y-1">
                <Label>Kết thúc *</Label>
                <Input type="datetime-local" value={f.endDate} onChange={(e) => set("endDate", e.target.value)} required />
              </div>
              <div className="space-y-1">
                <Label>Loại mục tiêu</Label>
                <Select value={f.goalType} onValueChange={(v) => set("goalType", v as ChallengeGoalType)}>
                  <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                  <SelectContent>{CHALLENGE_GOAL_TYPES.map((g) => <SelectItem key={g} value={g}>{g}</SelectItem>)}</SelectContent>
                </Select>
              </div>
              <div className="space-y-1">
                <Label>Giá trị mục tiêu</Label>
                <Input type="number" step="0.01" value={f.targetValue} onChange={(e) => set("targetValue", Number(e.target.value))} />
              </div>
            </div>
            <div className="space-y-1">
              <Label>Thông báo lên feed</Label>
              <Input value={f.feedAnnouncement} onChange={(e) => set("feedAnnouncement", e.target.value)} placeholder="Tùy chọn — tự sinh từ tiêu đề nếu trống" />
            </div>
            <div className="flex justify-end">
              <Button type="submit" size="sm" disabled={create.isPending}>
                {create.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Plus className="w-4 h-4 mr-2" />}
                Tạo
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-sm font-semibold">Thử thách đang diễn ra</CardTitle></CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">{Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-lg" />)}</div>
          ) : (data ?? []).length === 0 ? (
            <p className="text-muted-foreground text-sm py-8 text-center">Chưa có thử thách nào.</p>
          ) : (
            <div className="divide-y divide-border">
              {(data ?? []).map((c) => (
                <div key={c.id} className="py-3">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">{c.title}</p>
                    <Badge variant="outline" className="text-xs">{c.status}</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">{c.goalType} · mục tiêu {c.targetValue} · {c.participantCount} người tham gia</p>
                  <p className="text-xs text-muted-foreground">
                    {format(new Date(c.startDate), "dd/MM")} – {format(new Date(c.endDate), "dd/MM/yyyy")}
                  </p>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

export default function CommunityPage() {
  return (
    <Tabs defaultValue="posts">
      <TabsList>
        <TabsTrigger value="posts">Bài viết</TabsTrigger>
        <TabsTrigger value="challenges">Thử thách</TabsTrigger>
      </TabsList>
      <TabsContent value="posts" className="mt-4"><PostsTab /></TabsContent>
      <TabsContent value="challenges" className="mt-4"><ChallengesTab /></TabsContent>
    </Tabs>
  );
}
