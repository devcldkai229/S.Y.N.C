"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import {
  UserPlus,
  Crown,
  DollarSign,
  ShoppingCart,
  Percent,
  RefreshCw,
  Activity,
  Handshake,
  Wallet,
  Coins,
  HandCoins,
  Receipt,
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
import { usePartners } from "@/hooks/admin/use-partners";
import { useCommissionRevenueSummary } from "@/hooks/admin/use-commissions";
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

function deltaPercent(current: number, previous: number): number {
  if (previous === 0) return current > 0 ? 100 : 0;
  return Math.round(((current - previous) / previous) * 1000) / 10;
}

function KpiSectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
      {children}
    </h2>
  );
}

export default function DashboardPage() {
  const [days, setDays] = useState<DashboardDays>(30);
  const refresh = useRefreshDashboard();

  const iam = useIamDashboard(days);
  const payment = usePaymentDashboard(days);
  const order = useOrderDashboard(days);
  const ai = useAiDashboard(days);
  const partners = usePartners({ pageSize: 200 });
  const commissionPending = useCommissionRevenueSummary({ status: "Pending" });
  const commissionConfirmed = useCommissionRevenueSummary({ status: "Confirmed" });

  const lastUpdated = useMemo(() => {
    const times = [iam.data?.generatedAt, payment.data?.generatedAt, order.data?.generatedAt, ai.data?.generated_at]
      .filter(Boolean)
      .map((t) => new Date(t as string).getTime());
    if (times.length === 0) return null;
    return new Date(Math.max(...times));
  }, [iam.data, payment.data, order.data, ai.data]);

  const kpiLoading =
    iam.isLoading ||
    payment.isLoading ||
    order.isLoading ||
    partners.isLoading ||
    commissionPending.isLoading ||
    commissionConfirmed.isLoading;

  const totalPartners = partners.data?.pagination.totalRecords ?? 0;
  const activePartners = (partners.data?.items ?? []).filter((p) => p.status === "Active").length;
  const pendingPartners = (partners.data?.items ?? []).filter((p) => p.status === "PendingApproval").length;
  const partnersError = partners.isError;

  const revenueError = payment.isError || order.isError;
  const totalRevenueCurrent = (payment.data?.subscriptionRevenue.value ?? 0) + (order.data?.commissionRevenue.value ?? 0);
  const totalRevenuePrevious =
    (payment.data?.subscriptionRevenue.previousValue ?? 0) + (order.data?.commissionRevenue.previousValue ?? 0);

  const unpaidCommission =
    (commissionPending.data?.totalCommission ?? 0) + (commissionConfirmed.data?.totalCommission ?? 0);
  const unpaidCommissionError = commissionPending.isError || commissionConfirmed.isError;

  const orderCountValue = order.data?.orderCount.value ?? 0;
  const orderCountPrevious = order.data?.orderCount.previousValue ?? 0;
  const gmvValue = order.data?.gmv.value ?? 0;
  const gmvPrevious = order.data?.gmv.previousValue ?? 0;
  const aovCurrent = orderCountValue > 0 ? gmvValue / orderCountValue : 0;
  const aovPrevious = orderCountPrevious > 0 ? gmvPrevious / orderCountPrevious : 0;

  const partnerNameById = useMemo(() => {
    const map = new Map<string, string>();
    (partners.data?.items ?? []).forEach((p) => map.set(p.id, p.name));
    return map;
  }, [partners.data]);

  const growthChartData = useMemo(() => {
    const daily = iam.data?.userGrowthDaily ?? [];
    const cumulative = iam.data?.userGrowthCumulative ?? [];
    return daily.map((d, i) => ({
      date: shortDate(d.date),
      newUsers: d.value,
      cumulative: cumulative[i]?.value ?? 0,
    }));
  }, [iam.data]);

  const revenueChartData = useMemo(() => {
    const commissionByDate = new Map((order.data?.commissionDaily ?? []).map((c) => [c.date, c.value]));
    return (payment.data?.revenueDaily ?? []).map((r) => ({
      date: shortDate(r.date),
      subscription: r.subscription,
      commission: commissionByDate.get(r.date) ?? 0,
      other: r.other,
    }));
  }, [payment.data, order.data]);

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

      {/* KPI — Doanh thu & hoa hồng */}
      <section className="space-y-3">
        <KpiSectionTitle>Doanh thu &amp; hoa hồng</KpiSectionTitle>
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {kpiLoading ? (
            Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-2xl" />)
          ) : (
            <>
              <StatsCard
                title="Tổng doanh thu"
                value={formatVnd(totalRevenueCurrent)}
                icon={Wallet}
                color="green"
                error={revenueError}
                trend={formatDelta(deltaPercent(totalRevenueCurrent, totalRevenuePrevious))}
                description="Subscription + hoa hồng"
                href="/admin/transactions"
              />
              <StatsCard
                title="Doanh thu subscription"
                value={formatVnd(payment.data?.subscriptionRevenue.value ?? 0)}
                icon={DollarSign}
                color="green"
                error={payment.isError}
                trend={formatDelta(payment.data?.subscriptionRevenue.deltaPercent)}
                sparkline={payment.data?.subscriptionRevenue.sparkline}
                href="/admin/transactions"
              />
              <StatsCard
                title="Hoa hồng"
                value={formatVnd(order.data?.commissionRevenue.value ?? 0)}
                icon={Coins}
                color="orange"
                error={order.isError}
                trend={formatDelta(order.data?.commissionRevenue.deltaPercent)}
                sparkline={order.data?.commissionRevenue.sparkline}
                href="/admin/commissions"
              />
              <StatsCard
                title="Hoa hồng chờ trả"
                value={formatVnd(unpaidCommission)}
                icon={HandCoins}
                color="orange"
                error={unpaidCommissionError}
                description="Chờ xử lý + đã xác nhận, chưa thanh toán"
                href="/admin/commissions"
              />
            </>
          )}
        </div>
      </section>

      {/* KPI — Đơn hàng & đối tác */}
      <section className="space-y-3">
        <KpiSectionTitle>Đơn hàng &amp; đối tác</KpiSectionTitle>
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {kpiLoading ? (
            Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-2xl" />)
          ) : (
            <>
              <StatsCard
                title="GMV"
                value={formatVnd(order.data?.gmv.value ?? 0)}
                icon={ShoppingCart}
                color="blue"
                error={order.isError}
                trend={formatDelta(order.data?.gmv.deltaPercent)}
                sparkline={order.data?.gmv.sparkline}
                description="Tổng giá trị đơn hàng"
                href="/admin/orders"
              />
              <StatsCard
                title="Số đơn hàng"
                value={formatNumber(order.data?.orderCount.value ?? 0)}
                icon={ShoppingCart}
                color="blue"
                error={order.isError}
                trend={formatDelta(order.data?.orderCount.deltaPercent)}
                href="/admin/orders"
              />
              <StatsCard
                title="AOV"
                value={formatVnd(aovCurrent)}
                icon={Receipt}
                color="blue"
                error={order.isError}
                trend={formatDelta(deltaPercent(aovCurrent, aovPrevious))}
                description="Giá trị đơn trung bình"
                href="/admin/orders"
              />
              <StatsCard
                title="Đối tác hoạt động"
                value={formatNumber(activePartners)}
                icon={Handshake}
                color="purple"
                error={partnersError}
                description={`${pendingPartners} chờ duyệt · ${totalPartners} tổng đối tác`}
                href="/admin/marketplace"
              />
            </>
          )}
        </div>
      </section>

      {/* KPI — Người dùng */}
      <section className="space-y-3">
        <KpiSectionTitle>Người dùng</KpiSectionTitle>
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {kpiLoading ? (
            Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-2xl" />)
          ) : (
            <>
              <StatsCard
                title="Người dùng mới"
                value={formatNumber(iam.data?.newUsers.value ?? 0)}
                icon={UserPlus}
                color="blue"
                error={iam.isError}
                trend={formatDelta(iam.data?.newUsers.deltaPercent)}
                sparkline={iam.data?.newUsers.sparkline}
                href="/admin/users"
              />
              <StatsCard
                title="DAU"
                value={formatNumber(iam.data?.dau.value ?? 0)}
                icon={Activity}
                color="green"
                error={iam.isError}
                trend={formatDelta(iam.data?.dau.deltaPercent)}
                sparkline={iam.data?.dau.sparkline}
                href="/admin/users"
              />
              <StatsCard
                title="Premium"
                value={formatNumber(iam.data?.premiumUsers.value ?? 0)}
                icon={Crown}
                color="purple"
                error={iam.isError}
                trend={formatDelta(iam.data?.premiumUsers.deltaPercent)}
                description={`${payment.data?.activeSubscriptions.value ?? 0} gói đang active`}
                href="/admin/subscriptions"
              />
              <StatsCard
                title="Churn rate"
                value={formatPercent(iam.data?.churnRate.value ?? 0)}
                icon={Percent}
                color="orange"
                error={iam.isError}
                trend={formatDelta(iam.data?.churnRate.deltaPercent)}
                description="Người dùng rời hoạt động trong kỳ"
              />
            </>
          )}
        </div>
      </section>

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
          isLoading={payment.isLoading || order.isLoading}
          isError={payment.isError}
          isEmpty={!revenueChartData.length}
          onRetry={() => {
            payment.refetch();
            order.refetch();
          }}
        >
          <ResponsiveContainer width="100%" height={240}>
            <AreaChart data={revenueChartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
              <Tooltip formatter={(v) => formatVnd(Number(v ?? 0))} />
              <Legend />
              <Area type="monotone" dataKey="subscription" name="Subscription" stackId="1" fill="#1A8344" stroke="#1A8344" />
              <Area type="monotone" dataKey="commission" name="Hoa hồng" stackId="1" fill="#fcd34d" stroke="#f59e0b" />
              <Area type="monotone" dataKey="other" name="Khác" stackId="1" fill="#93c5fd" stroke="#3b82f6" />
            </AreaChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      {/* Row 3 — Orders & GMV */}
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

      {/* Row 4 — Donuts */}
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

      {/* Row 5 — Recent users + Top partners */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
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
            ) : iam.isError ? (
              <div className="flex flex-col items-center justify-center py-8 gap-2 text-sm text-muted-foreground">
                <p>Không tải được dữ liệu</p>
                <button type="button" onClick={() => iam.refetch()} className="text-primary hover:underline text-xs">
                  Thử lại
                </button>
              </div>
            ) : (iam.data?.recentUsers ?? []).length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-8">Chưa có người dùng nào.</p>
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

        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-sm font-semibold">Top đối tác theo doanh thu</CardTitle>
            <Link href="/admin/marketplace" className="text-xs text-primary hover:underline">
              Xem tất cả
            </Link>
          </CardHeader>
          <CardContent>
            {order.isLoading || partners.isLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Skeleton key={i} className="h-10 w-full" />
                ))}
              </div>
            ) : order.isError ? (
              <div className="flex flex-col items-center justify-center py-8 gap-2 text-sm text-muted-foreground">
                <p>Không tải được dữ liệu</p>
                <button type="button" onClick={() => order.refetch()} className="text-primary hover:underline text-xs">
                  Thử lại
                </button>
              </div>
            ) : (order.data?.topPartners ?? []).length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-8">Chưa có đơn hàng nào trong kỳ này.</p>
            ) : (
              <div className="divide-y divide-border">
                {(order.data?.topPartners ?? []).map((p, i) => (
                  <div key={p.partnerId} className="flex items-center justify-between py-3">
                    <div className="flex items-center gap-3">
                      <span className="text-xs font-mono text-muted-foreground w-4">{i + 1}</span>
                      <p className="text-sm font-medium">
                        {partnerNameById.get(p.partnerId) ?? `${p.partnerId.slice(0, 8)}…`}
                      </p>
                    </div>
                    <p className="text-sm font-semibold text-gray-900">{formatVnd(p.amount)}</p>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Row 6 — AI activity */}
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

      {/* Row 7 — Secondary metrics */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 text-center text-sm text-muted-foreground">
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">WAU</p>
          <p className="text-lg font-bold text-gray-900">
            {iam.isError ? "—" : formatNumber(iam.data?.wau.value ?? 0)}
          </p>
        </div>
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">MAU</p>
          <p className="text-lg font-bold text-gray-900">
            {iam.isError ? "—" : formatNumber(iam.data?.mau.value ?? 0)}
          </p>
        </div>
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">Gói đăng ký mới</p>
          <p className="text-lg font-bold text-gray-900">
            {payment.isError ? "—" : formatNumber(payment.data?.newSubscriptions.value ?? 0)}
          </p>
        </div>
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">Gói hủy</p>
          <p className="text-lg font-bold text-gray-900">
            {payment.isError ? "—" : formatNumber(payment.data?.cancelledSubscriptions.value ?? 0)}
          </p>
        </div>
        <div className="rounded-lg border bg-white p-3">
          <p className="font-medium text-gray-700">Lượt AI</p>
          <p className="text-lg font-bold text-gray-900">
            {ai.isError ? "—" : formatNumber(ai.data?.total_turns.value ?? 0)}
          </p>
        </div>
      </div>
    </div>
  );
}
