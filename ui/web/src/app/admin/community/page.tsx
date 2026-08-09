"use client";

import { useState } from "react";
import { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/admin/DataTable";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { ConfirmDialog } from "@/components/admin/ConfirmDialog";
import { Heart, MessageCircle, Share2, Trash2, Loader2, Plus, Users, LayoutList, Trophy, CheckCircle, PauseCircle, XCircle } from "lucide-react";
import { format } from "date-fns";
import {
  useFeed,
  useDeletePost,
  useAllChallenges,
  useCreateChallenge,
  useUpdateChallengeStatus,
  useDeleteChallenge,
  CHALLENGE_GOAL_TYPES,
  type ChallengeGoalType,
  type ChallengeLocationValue,
  type PostDto,
  type CommunityChallengeDto,
} from "@/hooks/admin/use-social";
import { ChallengeLocationPicker } from "@/components/admin/ChallengeLocationPicker";
import {
  useBlogs,
  useUpdateBlogStatus,
  useDeleteBlog,
  BLOG_STATUS_LABELS,
  BLOG_STATUS_COLORS,
  type BlogDto,
  type BlogStatus,
} from "@/hooks/admin/use-blogs";
// ── Posts Tab ────────────────────────────────────────────────────────────────
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
        const initials = (p.authorSnapshot.fullName || "?").slice(0, 2).toUpperCase();
        return (
          <Card key={p.id}>
            <CardContent className="pt-6">
              <div className="flex items-start gap-3">
                <Avatar className="w-9 h-9">
                  {p.authorSnapshot.avatarUrl && <AvatarImage src={p.authorSnapshot.avatarUrl} />}
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
                <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive shrink-0" onClick={() => setTarget(p)}>
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

// ── Challenges Tab ───────────────────────────────────────────────────────────
function ChallengesTab() {
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const { data, isLoading } = useAllChallenges({
    status: statusFilter !== "all" ? statusFilter : undefined,
    pageSize: 100,
  });
  
  const createChallenge = useCreateChallenge();
  const updateStatus    = useUpdateChallengeStatus();
  const deleteChallenge = useDeleteChallenge();

  const [delTarget, setDelTarget] = useState<CommunityChallengeDto | null>(null);
  const [location, setLocation] = useState<ChallengeLocationValue | null>(null);
  const [f, setF] = useState({
    title: "", description: "", startDate: "", endDate: "",
    goalType: "TotalWorkouts" as ChallengeGoalType, targetValue: 0,
    pointRewards: 0, gifts: "",
  });

  const challenges = data?.items ?? [];
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((p) => ({ ...p, [k]: v }));

  const resetForm = () => {
    setF({ title: "", description: "", startDate: "", endDate: "", goalType: "TotalWorkouts", targetValue: 0, pointRewards: 0, gifts: "" });
    setLocation(null);
  };

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!location) return;

    const start = new Date(f.startDate);
    const registrationDeadline = new Date(start.getTime() - 60 * 60 * 1000);

    createChallenge.mutate(
      {
        title: f.title,
        description: f.description,
        registrationDeadline: registrationDeadline.toISOString(),
        startDate: start.toISOString(),
        endDate: new Date(f.endDate).toISOString(),
        goalType: f.goalType,
        targetValue: f.targetValue,
        pointRewards: f.pointRewards > 0 ? f.pointRewards : undefined,
        gifts: f.gifts.split(",").map((g) => g.trim()).filter(Boolean),
        address: location.address,
        latitude: location.latitude,
        longitude: location.longitude,
      },
      { onSuccess: resetForm },
    );
  };

  const columns: ColumnDef<CommunityChallengeDto>[] = [
    {
      accessorKey: "title",
      header: "Thử thách",
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-sm">{row.original.title}</p>
          <p className="text-xs text-muted-foreground truncate max-w-[200px]">{row.original.description}</p>
        </div>
      ),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => {
        const s = row.original.status;
        const cls = s === "Active" ? "bg-green-100 text-green-800" :
                    s === "InProgress" ? "bg-amber-100 text-amber-800" :
                    s === "Completed" ? "bg-gray-100 text-gray-800" :
                    s === "Upcoming" ? "bg-blue-100 text-blue-800" : "bg-muted text-muted-foreground";
        return <Badge className={`text-[10px] ${cls} hover:${cls}`}>{s}</Badge>;
      }
    },
    {
      accessorKey: "address",
      header: "Địa điểm",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground truncate max-w-[160px] block">
          {row.original.address ?? "—"}
        </span>
      ),
    },
    {
      accessorKey: "goalType",
      header: "Mục tiêu",
      cell: ({ row }) => (
        <div className="text-xs">
          <span className="font-medium">{row.original.goalType}</span>
          <span className="text-muted-foreground"> ({row.original.targetValue})</span>
        </div>
      ),
    },
    {
      accessorKey: "participantCount",
      header: "Người tham gia",
      cell: ({ row }) => <span className="text-sm font-medium">{row.original.participantCount}</span>,
    },
    {
      id: "period",
      header: "Thời gian",
      cell: ({ row }) => (
        <span className="text-xs text-muted-foreground">
          {format(new Date(row.original.startDate), "dd/MM")} - {format(new Date(row.original.endDate), "dd/MM/yy")}
        </span>
      ),
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const c = row.original;
        return (
          <div className="flex items-center gap-1">
            {c.status === "Upcoming" && (
              <Button size="icon" variant="ghost" className="h-7 w-7 text-green-600 hover:text-green-700 hover:bg-green-50"
                      onClick={() => updateStatus.mutate({ id: c.id, action: "activate" })}>
                <CheckCircle className="w-3.5 h-3.5" />
              </Button>
            )}
            {c.status === "Active" && (
              <Button size="icon" variant="ghost" className="h-7 w-7 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                      onClick={() => updateStatus.mutate({ id: c.id, action: "complete" })}>
                <Trophy className="w-3.5 h-3.5" />
              </Button>
            )}
            <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive hover:text-destructive"
                    onClick={() => setDelTarget(c)}>
              <Trash2 className="w-3.5 h-3.5" />
            </Button>
          </div>
        );
      }
    }
  ];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <div className="lg:col-span-1 space-y-4">
        <Card className="shadow-none">
          <CardHeader className="pb-2"><CardTitle className="text-sm font-semibold">Tạo thử thách</CardTitle></CardHeader>
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
                  <Label>Mục tiêu</Label>
                  <Select value={f.goalType} onValueChange={(v) => set("goalType", v as ChallengeGoalType)}>
                    <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                    <SelectContent>{CHALLENGE_GOAL_TYPES.map((g) => <SelectItem key={g} value={g}>{g}</SelectItem>)}</SelectContent>
                  </Select>
                </div>
                <div className="space-y-1">
                  <Label>Giá trị</Label>
                  <Input type="number" step="0.01" value={f.targetValue} onChange={(e) => set("targetValue", Number(e.target.value))} />
                </div>
                <div className="space-y-1">
                  <Label>Điểm thưởng</Label>
                  <Input type="number" step="1" min="0" value={f.pointRewards} onChange={(e) => set("pointRewards", Number(e.target.value))} />
                </div>
                <div className="space-y-1">
                  <Label>Quà tặng</Label>
                  <Input placeholder="Áo thun, Bình nước..." value={f.gifts} onChange={(e) => set("gifts", e.target.value)} />
                </div>
              </div>
              <ChallengeLocationPicker value={location} onChange={setLocation} />
              <div className="flex justify-end pt-2">
                <Button type="submit" size="sm" disabled={!location || createChallenge.isPending}>
                  {createChallenge.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Plus className="w-4 h-4 mr-2" />}
                  Tạo
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>

      <div className="lg:col-span-2 space-y-4">
        <div className="flex items-center justify-between">
          <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v || "")}>
            <SelectTrigger className="w-40 h-8 text-sm"><SelectValue placeholder="Trạng thái" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tất cả</SelectItem>
              <SelectItem value="Active">Mở đăng ký (Active)</SelectItem>
              <SelectItem value="Upcoming">Sắp diễn ra (Upcoming)</SelectItem>
              <SelectItem value="InProgress">Đang diễn ra (InProgress)</SelectItem>
              <SelectItem value="Completed">Đã kết thúc (Completed)</SelectItem>
            </SelectContent>
          </Select>
          <span className="text-xs text-muted-foreground">{challenges.length} thử thách</span>
        </div>

        {isLoading ? (
          <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
        ) : (
          <DataTable columns={columns} data={challenges} searchPlaceholder="Tìm tên..." />
        )}

        <ConfirmDialog
          open={!!delTarget}
          onOpenChange={o => !o && setDelTarget(null)}
          title="Xóa thử thách"
          description={`Xóa "${delTarget?.title}" khỏi hệ thống?`}
          confirmLabel="Xóa"
          loading={deleteChallenge.isPending}
          onConfirm={() => {
            if (!delTarget) return;
            deleteChallenge.mutate(delTarget.id, { onSuccess: () => setDelTarget(null) });
          }}
        />
      </div>
    </div>
  );
}

// ── Blogs Tab ────────────────────────────────────────────────────────────────
function BlogsTab() {
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const { data, isLoading } = useBlogs({
    status: statusFilter !== "all" ? statusFilter as BlogStatus : undefined,
    pageSize: 100,
  });

  const updateStatus = useUpdateBlogStatus();
  const deleteBlog   = useDeleteBlog();
  const [delTarget, setDelTarget] = useState<BlogDto | null>(null);

  const blogs = data?.items ?? [];

  const columns: ColumnDef<BlogDto>[] = [
    {
      accessorKey: "title",
      header: "Tiêu đề",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <img src={row.original.coverImageUrl} alt="" className="w-10 h-10 rounded-lg object-cover" />
          <span className="font-medium text-sm max-w-[200px] truncate block" title={row.original.title}>
            {row.original.title}
          </span>
        </div>
      ),
    },
    {
      accessorKey: "authorSnapshot",
      header: "Tác giả",
      cell: ({ row }) => <span className="text-sm">{row.original.authorSnapshot.fullName}</span>,
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => {
        const s = row.original.status;
        const cls = BLOG_STATUS_COLORS[s] ?? "bg-gray-100 text-gray-600";
        return <Badge className={`text-[10px] ${cls} hover:${cls}`}>{BLOG_STATUS_LABELS[s]}</Badge>;
      }
    },
    {
      id: "stats",
      header: "Tương tác",
      cell: ({ row }) => (
        <div className="flex items-center gap-3 text-xs text-muted-foreground">
          <span className="flex items-center gap-1"><Heart className="w-3 h-3" /> {row.original.likeCount}</span>
          <span className="flex items-center gap-1"><Share2 className="w-3 h-3" /> {row.original.shareCount}</span>
        </div>
      )
    },
    {
      accessorKey: "createdAt",
      header: "Ngày tạo",
      cell: ({ row }) => <span className="text-xs text-muted-foreground">{format(new Date(row.original.createdAt), "dd/MM/yyyy")}</span>,
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const b = row.original;
        return (
          <div className="flex items-center gap-1">
            {b.status === "Draft" && (
              <Button size="icon" variant="ghost" className="h-7 w-7 text-green-600 hover:text-green-700 hover:bg-green-50"
                      onClick={() => updateStatus.mutate({ id: b.id, status: "Published" })} title="Xuất bản">
                <CheckCircle className="w-3.5 h-3.5" />
              </Button>
            )}
            {b.status === "Published" && (
              <Button size="icon" variant="ghost" className="h-7 w-7 text-orange-600 hover:text-orange-700 hover:bg-orange-50"
                      onClick={() => updateStatus.mutate({ id: b.id, status: "Archived" })} title="Lưu trữ">
                <PauseCircle className="w-3.5 h-3.5" />
              </Button>
            )}
            {b.status === "Archived" && (
              <Button size="icon" variant="ghost" className="h-7 w-7 text-green-600 hover:text-green-700 hover:bg-green-50"
                      onClick={() => updateStatus.mutate({ id: b.id, status: "Published" })} title="Xuất bản lại">
                <CheckCircle className="w-3.5 h-3.5" />
              </Button>
            )}
            <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive hover:text-destructive"
                    onClick={() => setDelTarget(b)}>
              <Trash2 className="w-3.5 h-3.5" />
            </Button>
          </div>
        );
      }
    }
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v || "")}>
          <SelectTrigger className="w-40 h-8 text-sm"><SelectValue placeholder="Trạng thái" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả</SelectItem>
            {Object.entries(BLOG_STATUS_LABELS).map(([k, v]) => <SelectItem key={k} value={k}>{v}</SelectItem>)}
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{blogs.length} blogs</span>
      </div>

      {isLoading ? (
        <div className="space-y-2">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 rounded-lg" />)}</div>
      ) : (
        <DataTable columns={columns} data={blogs} searchPlaceholder="Tìm tiêu đề..." />
      )}

      <ConfirmDialog
        open={!!delTarget}
        onOpenChange={o => !o && setDelTarget(null)}
        title="Xóa Blog"
        description={`Xóa vĩnh viễn blog "${delTarget?.title}"?`}
        confirmLabel="Xóa"
        loading={deleteBlog.isPending}
        onConfirm={() => {
          if (!delTarget) return;
          deleteBlog.mutate(delTarget.id, { onSuccess: () => setDelTarget(null) });
        }}
      />
    </div>
  );
}

// ── Page ─────────────────────────────────────────────────────────────────────
export default function CommunityPage() {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
          <Users className="w-4 h-4 text-primary" />
        </div>
        <div>
          <h1 className="text-lg font-bold">Cộng đồng</h1>
          <p className="text-xs text-muted-foreground">Quản lý bài viết, thử thách và nội dung blog</p>
        </div>
      </div>

      <Tabs defaultValue="posts">
        <TabsList>
          <TabsTrigger value="posts" className="gap-1.5"><LayoutList className="w-3.5 h-3.5" /> Bài viết (Feed)</TabsTrigger>
          <TabsTrigger value="challenges" className="gap-1.5"><Trophy className="w-3.5 h-3.5" /> Thử thách</TabsTrigger>
          <TabsTrigger value="blogs" className="gap-1.5"><LayoutList className="w-3.5 h-3.5" /> Blogs</TabsTrigger>
        </TabsList>
        <TabsContent value="posts" className="mt-4"><PostsTab /></TabsContent>
        <TabsContent value="challenges" className="mt-4"><ChallengesTab /></TabsContent>
        <TabsContent value="blogs" className="mt-4"><BlogsTab /></TabsContent>
      </Tabs>
    </div>
  );
}
