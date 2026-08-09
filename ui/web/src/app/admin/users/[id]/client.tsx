"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { ArrowLeft, Ban, CheckCircle2 } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useUser, useUpdateUserStatus } from "@/hooks/admin/use-users";
import { StatusBadge } from "@/components/admin/StatusBadge";
import { Skeleton } from "@/components/ui/skeleton";
import { format } from "date-fns";

const ROLE_COLORS: Record<string, string> = {
  SystemAdmin: "bg-purple-100 text-purple-700 border-purple-200",
  Partner:     "bg-blue-100 text-blue-700 border-blue-200",
  User:        "bg-gray-100 text-gray-600 border-gray-200",
};

const ROLE_LABELS: Record<string, string> = {
  SystemAdmin: "Quản trị viên",
  Partner:     "Đối tác",
  User:        "Người dùng",
};

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between py-2 border-b border-border last:border-0">
      <span className="text-sm text-muted-foreground">{label}</span>
      <span className="text-sm font-medium">{value}</span>
    </div>
  );
}

export default function UserDetailPage() {
  const params   = useParams<{ id: string }>();
  const id       = params?.id ?? "";
  const router   = useRouter();
  const { data, isLoading } = useUser(id);
  const updateStatus = useUpdateUserStatus();

  if (isLoading) {
    return (
      <div className="max-w-2xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-64 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">Không tìm thấy người dùng.</p>;

  const initials = (data.fullName || "?").split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase();
  const isSuspended = data.status === "Suspended";

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <div className="flex items-center justify-between">
        <Button variant="ghost" size="sm" onClick={() => router.back()}>
          <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
        </Button>
        {isSuspended ? (
          <Button size="sm" variant="outline" onClick={() => updateStatus.mutate({ id, status: "Active" })} disabled={updateStatus.isPending}>
            <CheckCircle2 className="w-4 h-4 mr-2" /> Kích hoạt
          </Button>
        ) : (
          <Button size="sm" variant="destructive" onClick={() => updateStatus.mutate({ id, status: "Suspended" })} disabled={updateStatus.isPending}>
            <Ban className="w-4 h-4 mr-2" /> Tạm khóa
          </Button>
        )}
      </div>

      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <Avatar className="w-14 h-14">
              <AvatarFallback className="text-lg bg-primary/10 text-primary font-semibold">{initials}</AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold">{data.fullName}</h2>
                <Badge variant="outline" className={`text-xs ${ROLE_COLORS[data.role] ?? ""}`}>{ROLE_LABELS[data.role] ?? data.role}</Badge>
                <StatusBadge status={data.status} />
              </div>
              <p className="text-sm text-muted-foreground">{data.email}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Tabs defaultValue="profile">
        <TabsList>
          <TabsTrigger value="profile">Hồ sơ</TabsTrigger>
          <TabsTrigger value="account">Tài khoản</TabsTrigger>
        </TabsList>

        <TabsContent value="profile" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-sm font-semibold">Thông tin hồ sơ</CardTitle></CardHeader>
            <CardContent>
              <InfoRow label="Họ tên"          value={data.fullName} />
              <InfoRow label="Email"           value={data.email} />
              <InfoRow label="Đã xác minh email" value={data.emailVerified ? "Có" : "Không"} />
              <InfoRow label="Vai trò"         value={ROLE_LABELS[data.role] ?? data.role} />
              <InfoRow label="Trạng thái"      value={<StatusBadge status={data.status} />} />
              <InfoRow label="Ngày tham gia"   value={format(new Date(data.createdAt), "dd/MM/yyyy")} />
              <InfoRow label="Hoạt động cuối"  value={data.lastActiveAt ? format(new Date(data.lastActiveAt), "dd/MM/yyyy HH:mm") : "—"} />
              <InfoRow label="Đăng nhập cuối"  value={data.lastLoginAt ? format(new Date(data.lastLoginAt), "dd/MM/yyyy HH:mm") : "—"} />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="account" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-sm font-semibold">Tài khoản & gói đăng ký</CardTitle></CardHeader>
            <CardContent>
              <InfoRow label="Gói hiện tại" value={data.subscriptionTier} />
              <InfoRow label="Mã người dùng" value={<span className="font-mono text-xs">{data.id}</span>} />
              <div className="mt-4 p-3 bg-muted/50 rounded-lg text-xs text-muted-foreground">
                Quản lý gói đăng ký chi tiết tại mục <span className="font-medium">Gói đăng ký</span>.
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
