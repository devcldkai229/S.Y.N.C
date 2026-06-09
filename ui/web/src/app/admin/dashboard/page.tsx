"use client";

import { Users, CreditCard, Dumbbell, Megaphone } from "lucide-react";
import { StatsCard } from "@/components/admin/StatsCard";
import { useExercises } from "@/hooks/admin/use-exercises";
import { useSubscriptionPlans } from "@/hooks/admin/use-subscription-plans";
import { usePromotionCampaigns, campaignStatus } from "@/hooks/admin/use-promotions";
import { useUsers } from "@/hooks/admin/use-users";
import { Skeleton } from "@/components/ui/skeleton";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from "recharts";

const WEEKLY_DATA = [
  { week: "W1", users: 12 },
  { week: "W2", users: 19 },
  { week: "W3", users: 8 },
  { week: "W4", users: 27 },
  { week: "W5", users: 21 },
  { week: "W6", users: 34 },
];

const PIE_COLORS = ["#1A8344", "#3b82f6", "#f59e0b", "#8b5cf6"];

export default function DashboardPage() {
  const { data: exercisesPage, isLoading: loadingEx }   = useExercises({ pageSize: 1 });
  const { data: plans, isLoading: loadingPlans }         = useSubscriptionPlans();
  const { data: campaigns, isLoading: loadingCampaigns } = usePromotionCampaigns();
  const { data: users, isLoading: loadingUsers }         = useUsers();

  const totalUsers          = users?.length ?? 0;
  const totalExercises      = exercisesPage?.totalCount ?? 0;
  const activeCampaigns     = campaigns?.filter((c) => campaignStatus(c) === "running").length ?? 0;
  const activeSubscriptions = plans?.filter((p) => p.isActive).length ?? 0;

  const tierCounts = (plans ?? []).reduce<Record<string, number>>((acc, p) => {
    acc[p.name] = (acc[p.name] ?? 0) + 1;
    return acc;
  }, {});
  const pieData = Object.entries(tierCounts).map(([name, value]) => ({ name, value }));

  const isLoading = loadingEx || loadingPlans || loadingCampaigns || loadingUsers;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-xl font-bold text-gray-900">Tổng quan hệ thống</h2>
        <p className="text-sm text-gray-400 mt-0.5">Theo dõi hoạt động và các số liệu quan trọng</p>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {isLoading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-32 rounded-2xl" />
          ))
        ) : (
          <>
            <StatsCard title="Total Users"      value={totalUsers}          icon={Users}      color="green"  description="Registered accounts" />
            <StatsCard title="Active Plans"     value={activeSubscriptions} icon={CreditCard} color="blue"   description="Subscription plans active" />
            <StatsCard title="Exercise Catalog" value={totalExercises}      icon={Dumbbell}   color="orange" description="Total exercises in catalog" />
            <StatsCard title="Live Campaigns"   value={activeCampaigns}     icon={Megaphone}  color="purple" description="Promotion campaigns running" />
          </>
        )}
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">New Users (Weekly)</h3>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={WEEKLY_DATA} barSize={28}>
              <XAxis
                dataKey="week"
                tick={{ fontSize: 12, fill: "#9ca3af" }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 12, fill: "#9ca3af" }}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip
                cursor={{ fill: "#f9fafb" }}
                contentStyle={{ borderRadius: "12px", border: "1px solid #f3f4f6", fontSize: "12px", boxShadow: "0 4px 6px -1px rgba(0,0,0,0.05)" }}
              />
              <Bar dataKey="users" fill="#1A8344" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Subscription Plans Distribution</h3>
          <div className="flex items-center justify-center">
            {pieData.length > 0 ? (
              <ResponsiveContainer width="100%" height={220}>
                <PieChart>
                  <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                    {pieData.map((_, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Legend wrapperStyle={{ fontSize: "12px" }} />
                  <Tooltip
                    contentStyle={{ borderRadius: "12px", border: "1px solid #f3f4f6", fontSize: "12px", boxShadow: "0 4px 6px -1px rgba(0,0,0,0.05)" }}
                  />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <p className="text-gray-400 text-sm py-12">No plan data available</p>
            )}
          </div>
        </div>
      </div>

      {/* Recent users */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <h3 className="text-sm font-semibold text-gray-900 mb-4">Recent Users</h3>
        <div className="space-y-1">
          {(users ?? []).slice(0, 5).map((u) => {
            const avatarInitials = u.fullName
              ?.trim().split(" ").map((w: string) => w[0]).slice(0, 2).join("").toUpperCase() ?? "U";
            return (
              <div
                key={u.id}
                className="flex items-center justify-between py-3 px-3 rounded-xl hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary text-xs font-bold shrink-0">
                    {avatarInitials}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{u.fullName}</p>
                    <p className="text-xs text-gray-400">{u.email}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs font-medium bg-primary/10 text-primary px-2 py-0.5 rounded-full">
                    {u.subscriptionTier}
                  </span>
                  <p className="text-xs text-gray-400 mt-1">{u.role}</p>
                </div>
              </div>
            );
          })}
          {(!users || users.length === 0) && !isLoading && (
            <p className="text-gray-400 text-sm text-center py-8">No users found</p>
          )}
        </div>
      </div>
    </div>
  );
}
