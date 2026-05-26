"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { ArrowLeft } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useUser } from "@/hooks/admin/use-users";
import { StatusBadge } from "@/components/admin/StatusBadge";
import { Skeleton } from "@/components/ui/skeleton";
import { format } from "date-fns";

const ROLE_COLORS: Record<string, string> = {
  Admin:  "bg-purple-100 text-purple-700 border-purple-200",
  Staff:  "bg-blue-100 text-blue-700 border-blue-200",
  Member: "bg-gray-100 text-gray-600 border-gray-200",
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

  if (isLoading) {
    return (
      <div className="max-w-2xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-64 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">User not found.</p>;

  const initials = data.fullName.split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase();

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Back
      </Button>

      {/* Profile header */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <Avatar className="w-14 h-14">
              <AvatarFallback className="text-lg bg-primary/10 text-primary font-semibold">{initials}</AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold">{data.fullName}</h2>
                <Badge variant="outline" className={`text-xs ${ROLE_COLORS[data.role] ?? ""}`}>{data.role}</Badge>
                <StatusBadge status={data.status} />
              </div>
              <p className="text-sm text-muted-foreground">{data.email}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Tabs defaultValue="profile">
        <TabsList>
          <TabsTrigger value="profile">Profile</TabsTrigger>
          <TabsTrigger value="subscription">Subscription</TabsTrigger>
        </TabsList>

        <TabsContent value="profile" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-sm font-semibold">Profile Details</CardTitle></CardHeader>
            <CardContent>
              <InfoRow label="Full Name"          value={data.fullName} />
              <InfoRow label="Email"              value={data.email} />
              <InfoRow label="Role"               value={data.role} />
              <InfoRow label="Status"             value={<StatusBadge status={data.status} />} />
              <InfoRow label="Member Since"       value={format(new Date(data.createdAt), "dd/MM/yyyy")} />
              <InfoRow label="Last Active"        value={format(new Date(data.lastActive), "dd/MM/yyyy")} />
              <div className="mt-4 p-3 bg-muted/50 rounded-lg text-xs text-muted-foreground">
                Note: Full biometric & device data requires admin backend endpoints (pending implementation).
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="subscription" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-sm font-semibold">Subscription</CardTitle></CardHeader>
            <CardContent>
              <InfoRow label="Current Plan" value={data.subscriptionTier} />
              <InfoRow label="Status"       value={<StatusBadge status="active" />} />
              <div className="mt-4 p-3 bg-muted/50 rounded-lg text-xs text-muted-foreground">
                Note: Detailed billing info requires admin user subscription endpoints (pending implementation).
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
