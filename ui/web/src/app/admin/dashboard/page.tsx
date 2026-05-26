"use client";

import { Users, CreditCard, Dumbbell, Megaphone } from "lucide-react";
import { StatsCard } from "@/components/admin/StatsCard";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { useExercises } from "@/hooks/admin/use-exercises";
import { useSubscriptionPlans } from "@/hooks/admin/use-subscription-plans";
import { usePromotionCampaigns, campaignStatus } from "@/hooks/admin/use-promotions";
import { useUsers } from "@/hooks/admin/use-users";
import { Skeleton } from "@/components/ui/skeleton";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";

const WEEKLY_DATA = [
  { week: "W1", users: 12 },
  { week: "W2", users: 19 },
  { week: "W3", users: 8 },
  { week: "W4", users: 27 },
  { week: "W5", users: 21 },
  { week: "W6", users: 34 },
];

const PIE_COLORS = ["#6b7280", "#3b82f6", "#1A8344", "#f59e0b"];

export default function DashboardPage() {
  const { data: exercisesPage, isLoading: loadingEx }   = useExercises({ pageSize: 1 });
  const { data: plans, isLoading: loadingPlans }         = useSubscriptionPlans();
  const { data: campaigns, isLoading: loadingCampaigns } = usePromotionCampaigns();
  const { data: users, isLoading: loadingUsers }         = useUsers();

  const totalUsers         = users?.length ?? 0;
  const totalExercises     = exercisesPage?.totalCount ?? 0;
  const activeCampaigns    = campaigns?.filter((c) => campaignStatus(c) === "running").length ?? 0;
  const activeSubscriptions = plans?.filter((p) => p.isActive).length ?? 0;

  const tierCounts = (plans ?? []).reduce<Record<string, number>>((acc, p) => {
    acc[p.name] = (acc[p.name] ?? 0) + 1;
    return acc;
  }, {});
  const pieData = Object.entries(tierCounts).map(([name, value]) => ({ name, value }));

  const isLoading = loadingEx || loadingPlans || loadingCampaigns || loadingUsers;

  return (
    <div className="space-y-6">
      {/* Stats row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {isLoading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))
        ) : (
          <>
            <StatsCard title="Total Users"          value={totalUsers}         icon={Users}      description="Mock data — backend pending" />
            <StatsCard title="Active Plans"         value={activeSubscriptions} icon={CreditCard}  description="Subscription plans active" />
            <StatsCard title="Exercise Catalog"     value={totalExercises}     icon={Dumbbell}   description="Total exercises in catalog" />
            <StatsCard title="Running Campaigns"    value={activeCampaigns}    icon={Megaphone}  description="Promotion campaigns live" />
          </>
        )}
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-semibold">New Users (Weekly)</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={WEEKLY_DATA} barSize={28}>
                <XAxis dataKey="week" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip cursor={{ fill: "oklch(0.97 0 0)" }} />
                <Bar dataKey="users" fill="oklch(0.52 0.165 149)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-semibold">Subscription Plans Distribution</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center justify-center">
            {pieData.length > 0 ? (
              <ResponsiveContainer width="100%" height={220}>
                <PieChart>
                  <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                    {pieData.map((_, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Legend />
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <p className="text-muted-foreground text-sm py-12">No plan data available</p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Recent users */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-semibold">Recent Users</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="divide-y divide-border">
            {(users ?? []).slice(0, 5).map((u) => (
              <div key={u.id} className="flex items-center justify-between py-3">
                <div>
                  <p className="text-sm font-medium">{u.fullName}</p>
                  <p className="text-xs text-muted-foreground">{u.email}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs font-medium">{u.subscriptionTier}</p>
                  <p className="text-xs text-muted-foreground">{u.role}</p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
