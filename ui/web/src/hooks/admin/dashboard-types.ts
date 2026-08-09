export interface DailyPoint {
  date: string;
  value: number;
}

export interface KpiMetric {
  value: number;
  previousValue?: number | null;
  deltaPercent?: number | null;
  sparkline?: DailyPoint[];
}

export interface NamedCount {
  name: string;
  count: number;
}

export interface NamedAmount {
  name: string;
  amount: number;
}

export interface PartnerRevenue {
  partnerId: string;
  amount: number;
}

export interface StackedDailyPoint {
  date: string;
  subscription: number;
  other: number;
}

export interface IamDashboardOverview {
  generatedAt: string;
  days: number;
  dau: KpiMetric;
  wau: KpiMetric;
  mau: KpiMetric;
  newUsers: KpiMetric;
  premiumUsers: KpiMetric;
  churnRate: KpiMetric;
  userGrowthDaily: DailyPoint[];
  userGrowthCumulative: DailyPoint[];
  activeUsersDaily: DailyPoint[];
  tierDistribution: NamedCount[];
  platformDistribution: NamedCount[];
  recentUsers: Array<{
    id: string;
    email: string;
    fullName: string;
    subscriptionTier: string;
    role: string;
    createdAt: string;
  }>;
}

export interface PaymentDashboardOverview {
  generatedAt: string;
  days: number;
  subscriptionRevenue: KpiMetric;
  activeSubscriptions: KpiMetric;
  newSubscriptions: KpiMetric;
  cancelledSubscriptions: KpiMetric;
  revenueDaily: StackedDailyPoint[];
  paymentMethodDistribution: NamedCount[];
  promotionUsage: NamedCount[];
}

export interface OrderDashboardOverview {
  generatedAt: string;
  days: number;
  gmv: KpiMetric;
  orderCount: KpiMetric;
  commissionRevenue: KpiMetric;
  ordersDaily: DailyPoint[];
  gmvDaily: DailyPoint[];
  commissionDaily: DailyPoint[];
  orderStatusDistribution: NamedCount[];
  topPartners: PartnerRevenue[];
}

export interface AiKpiMetric {
  value: number;
  previous_value?: number | null;
  delta_percent?: number | null;
  sparkline?: DailyPoint[];
}

export interface AiDashboardOverview {
  generated_at: string;
  days: number;
  total_turns: AiKpiMetric;
  estimated_cost_usd: AiKpiMetric;
  ai_turns_daily: DailyPoint[];
  intent_distribution: NamedCount[];
  model_tier_distribution: NamedCount[];
  avg_cost_daily: DailyPoint[];
}
