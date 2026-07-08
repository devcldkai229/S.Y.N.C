"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import {
  UserPlus,
  Crown,
  DollarSign,
  ShoppingCart,
  Bot,
  Percent,
  RefreshCw,
  Activity,
} from "lucide-react";
import { StatsCard } from "@/components/admin/StatsCard";
import { ChartCard } from "@/components/admin/ChartCard";
import { DashboardDateRange } from "@/components/admin/DashboardDateRange";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useAiDashboard,
  useIamDashboard,
  useOrderDashboard,
  usePaymentDashboard,
  useRefreshDashboard,
  type DashboardDays,
} from "@/hooks/admin/use-dashboard";
import { formatDelta, formatNumber, formatPercent, formatVnd } from "@/lib/dashboard-format";
import {
  Area,
  AreaChart,
  Bar,
  CartesianGrid,
  Cell,
  ComposedChart,
  Legend,
  Line,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const PIE_COLORS = ["#6b7280", "#3b82f6", "#1A8344", "#f59e0b", "#8b5cf6", "#ec4899"];

function shortDate(date: string) {
  const [, m, d] = date.split("-");
  return `${d}/${m}`;
}

export default function DashboardPage() {
  const [days, setDays] = useState<DashboardDays>(30);
  const refresh = useRefreshDashboard();

  const iam = useIamDashboard(days);
  const payment = usePaymentDashboard(days);
  const order = useOrderDashboard(days);
  const ai = useAiDashboard(days);

  const lastUpdated = useMemo(() => {
    const times = [iam.data?.generatedAt, payment.data?.generatedAt, order.data?.generatedAt, ai.data?.generated_at]
      .filter(Boolean)
      .map((t) => new Date(t as string).getTime());
    if (times.length === 0) return null;
    return new Date(Math.max(...times));
  }, [iam.data, payment.data, order.data, ai.data]);

  const kpiLoading = iam.isLoading || payment.isLoading || order.isLoading;

  const growthChartData = useMemo(() => {
    const daily = iam.data?.userGrowthDaily ?? [];
    const cumulative = iam.data?.userGrowthCumulative ?? [];
    return daily.map((d, i) => ({
      date: shortDate(d.date),
      newUsers: d.value,
      cumulative: cumulative[i]?.value ?? 0,
    }));
  }, [iam.data]);

  const revenueChartData = useMemo(
    () =>
      (payment.data?.revenueDaily ?? []).map((r) => ({
        date: shortDate(r.date),
        subscription: r.subscription,
        other: r.other,
      })),
    [payment.data]
  );

  const orderComboData = useMemo(
    () =>
      (order.data?.ordersDaily ?? []).map((o, i) => ({
        date: shortDate(o.date),
        orders: o.value,
        gmv: order.data?.gmvDaily[i]?.value ?? 0,
      })),
    [order.data]
  );

  const handleRefresh = () => refresh(days);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Tổng quan</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {lastUpdated
              ? `Cập nhật: ${lastUpdated.toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })}`
              : "Đang tải dữ liệu…"}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <DashboardDateRange value={days} onChange={setDays} />
          <Button variant="outline" size="icon" onClick={handleRefresh} title="Làm mới">
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Row 1 — KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {kpiLoading ? (
          Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-2xl" />)
        ) : (
          <>
            <StatsCard
              title="DAU"
              value={formatNumber(iam.data?.dau.value ?? 0)}
              icon={Activity}
              color="green"
              trend={formatDelta(iam.data?.dau.deltaPercent)}
              sparkline={iam.data?.dau.sparkline}
              href="/admin/users"
            />
            <StatsCard
              title="Người dùng mới"
              value={formatNumber(iam.data?.newUsers.value ?? 0)}
              icon={UserPlus}
              color="blue"
              trend={formatDelta(iam.data?.newUsers.deltaPercent)}
              sparkline={iam.data?.newUsers.sparkline}
              href="/admin/users"
            />
            <StatsCard
              title="Premium"
              value={formatNumber(iam.data?.premiumUsers.value ?? 0)}
              icon={Crown}
              color="purple"
              trend={formatDelta(iam.data?.premiumUsers.deltaPercent)}
              description={`${payment.data?.activeSubscriptions.value ?? 0} gói đang active`}
              href="/admin/subscriptions"
            />
            <StatsCard
              title="Doanh thu subscription"
              value={formatVnd(payment.data?.subscriptionRevenue.value ?? 0)}
              icon={DollarSign}
              color="green"
              trend={formatDelta(payment.data?.subscriptionRevenue.deltaPercent)}
              sparkline={payment.data?.subscriptionRevenue.sparkline}
              href="/admin/transactions"
            />
            <StatsCard
              title="GMV"
              value={formatVnd(order.data?.gmv.value ?? 0)}
              icon={ShoppingCart}
              color="orange"
              trend={formatDelta(order.data?.gmv.deltaPercent)}
              sparkline={order.data?.gmv.sparkline}
              href="/admin/orders"
            />
            <StatsCard
              title="Số đơn hàng"
              value={formatNumber(order.data?.orderCount.value ?? 0)}
              icon={ShoppingCart}
              color="blue"
              trend={formatDelta(order.data?.orderCount.deltaPercent)}
              href="/admin/orders"
            />
            <StatsCard
              title="Lượt AI"
              value={formatNumber(ai.data?.total_turns.value ?? 0)}
              icon={Bot}
              color="purple"
              trend={formatDelta(ai.data?.total_turns.delta_percent)}
              sparkline={ai.data?.total_turns.sparkline}
            />
            <StatsCard
              title="Churn rate"
              value={formatPercent(iam.data?.churnRate.value ?? 0)}
              icon={Percent}
              color="orange"
              trend={formatDelta(iam.data?.churnRate.deltaPercent)}
              description="Người dùng rời hoạt động trong kỳ"
            />
          </>
        )}
      </div>

      {/* Row 2 — Growth + Revenue */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard
          title="Tăng trưởng người dùng"
          isLoading={iam.isLoading}
          isError={iam.isError}
          isEmpty={!iam.data?.userGrowthDaily.length}
          onRetry={() => iam.refetch()}
        >
          <ResponsiveContainer width="100%" height={240}>
            <ComposedChart data={growthChartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis yAxisId="left" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip />
              <Legend />
              <Bar yAxisId="left" dataKey="newUsers" name="Mới/ngày" fill="oklch(0.52 0.165 149)" radius={[4, 4, 0, 0]} barSize={20} />
              <Line yAxisId="right" type="monotone" dataKey="cumulative" name="Luỹ kế" stroke="#3b82f6" strokeWidth={2} dot={false} />
            </ComposedChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Doanh thu theo nguồn"
          isLoading={payment.isLoading}
          isError={payment.isError}
          isEmpty={!revenueChartData.length}
          onRetry={() => payment.refetch()}
        >
          <ResponsiveContainer width="100%" height={240}>
            <AreaChart data={revenueChartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
              <Tooltip formatter={(v) => formatVnd(Number(v ?? 0))} />
              <Legend />
              <Area type="monotone" dataKey="subscription" name="Subscription" stackId="1" fill="#1A8344" stroke="#1A8344" />
              <Area type="monotone" dataKey="other" name="Khác" stackId="1" fill="#93c5fd" stroke="#3b82f6" />
            </AreaChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      {/* Row 3 — Donuts */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ChartCard
          title="Free vs Premium"
          isLoading={iam.isLoading}
          isError={iam.isError}
          isEmpty={!iam.data?.tierDistribution.length}
          onRetry={() => iam.refetch()}
        >
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie data={iam.data?.tierDistribution ?? []} dataKey="count" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={80} label>
                {(iam.data?.tierDistribution ?? []).map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Trạng thái đơn hàng"
          isLoading={order.isLoading}
          isError={order.isError}
          isEmpty={!order.data?.orderStatusDistribution.length}
          onRetry={() => order.refetch()}
        >
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie data={order.data?.orderStatusDistribution ?? []} dataKey="count" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={80}>
                {(order.data?.orderStatusDistribution ?? []).map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Nền tảng thiết bị"
          isLoading={iam.isLoading}
          isError={iam.isError}
          isEmpty={!iam.data?.platformDistribution.length}
          onRetry={() => iam.refetch()}
        >
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie data={iam.data?.platformDistribution ?? []} dataKey="count" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={80}>
                {(iam.data?.platformDistribution ?? []).map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      {/* Row 4 — AI + Orders combo + Recent users */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartCard
          title="Hội thoại AI / ngày"
          isLoading={ai.isLoading}
          isError={ai.isError}
          isEmpty={!ai.data?.ai_turns_daily.length}
          onRetry={() => ai.refetch()}
        >
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={(ai.data?.ai_turns_daily ?? []).map((d) => ({ ...d, date: shortDate(d.date) }))}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} allowDecimals={false} />
              <Tooltip />
              <Area type="monotone" dataKey="value" name="Lượt" stroke="#8b5cf6" fill="#8b5cf633" />
            </AreaChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Phân bố intent AI"
          isLoading={ai.isLoading}
          isError={ai.isError}
          isEmpty={!ai.data?.intent_distribution.length}
          onRetry={() => ai.refetch()}
        >
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie data={ai.data?.intent_distribution ?? []} dataKey="count" nameKey="name" cx="50%" cy="50%" innerRadius={45} outerRadius={75}>
                {(ai.data?.intent_distribution ?? []).map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      <ChartCard
        title="Đơn hàng & GMV"
        isLoading={order.isLoading}
        isError={order.isError}
        isEmpty={!orderComboData.length}
        onRetry={() => order.refetch()}
      >
        <ResponsiveContainer width="100%" height={240}>
          <ComposedChart data={orderComboData}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis yAxisId="left" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} allowDecimals={false} />
            <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
            <Tooltip formatter={(v, name) => (name === "GMV" ? formatVnd(Number(v ?? 0)) : formatNumber(Number(v ?? 0)))} />
            <Legend />
            <Bar yAxisId="left" dataKey="orders" name="Số đơn" fill="#3b82f6" barSize={22} radius={[4, 4, 0, 0]} />
            <Line yAxisId="right" type="monotone" dataKey="gmv" name="GMV" stroke="#f59e0b" strokeWidth={2} dot={false} />
          </ComposedChart>
        </ResponsiveContainer>
      </ChartCard>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-sm font-semibold">Người dùng gần đây</CardTitle>
          <Link href="/admin/users" className="text-xs text-primary hover:underline">
            Xem tất cả
          </Link>
        </CardHeader>
        <CardContent>
          {iam.isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-10 w-full" />
              ))}
            </div>
          ) : (
            <div className="divide-y divide-border">
              {(iam.data?.recentUsers ?? []).map((u) => (
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
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-center text-sm text-muted-foreground">
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">WAU</p>
          <p className="text-lg font-bold text-gray-900">{formatNumber(iam.data?.wau.value ?? 0)}</p>
        </div>
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">MAU</p>
          <p className="text-lg font-bold text-gray-900">{formatNumber(iam.data?.mau.value ?? 0)}</p>
        </div>
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">Commission kỳ</p>
          <p className="text-lg font-bold text-gray-900">{formatVnd(order.data?.commissionRevenue.value ?? 0)}</p>
        </div>
      </div>
    </div>
  );
}
