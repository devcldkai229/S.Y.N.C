import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

const GREEN  = "bg-green-100 text-green-700 border-green-200";
const GRAY   = "bg-gray-100 text-gray-600 border-gray-200";
const GRAYD  = "bg-gray-100 text-gray-500 border-gray-200";
const RED    = "bg-red-100 text-red-700 border-red-200";
const ORANGE = "bg-orange-100 text-orange-700 border-orange-200";
const BLUE   = "bg-blue-100 text-blue-700 border-blue-200";

// key (lowercase) -> nhãn tiếng Việt + màu
const STATUS_MAP: Record<string, { label: string; className: string }> = {
  // chung
  active:    { label: "Đang hoạt động", className: GREEN },
  inactive:  { label: "Tạm tắt",        className: GRAY },
  true:      { label: "Đang hoạt động", className: GREEN },
  false:     { label: "Tạm tắt",        className: GRAYD },

  // người dùng (UserStatus)
  onboarding:          { label: "Đang thiết lập",  className: BLUE },
  suspended:           { label: "Tạm khóa",        className: ORANGE },
  pendingverification: { label: "Chờ xác minh",    className: BLUE },
  deleted:             { label: "Đã xóa",          className: RED },
  banned:              { label: "Bị cấm",          className: RED },

  // gói đăng ký (SubscriptionStatus)
  trial:     { label: "Dùng thử",   className: BLUE },
  pastdue:   { label: "Quá hạn",    className: ORANGE },
  cancelled: { label: "Đã hủy",     className: RED },
  expired:   { label: "Hết hạn",    className: GRAYD },
  paused:    { label: "Tạm dừng",   className: GRAY },

  // chiến dịch khuyến mãi (campaignStatus)
  running:   { label: "Đang chạy",  className: GREEN },
  upcoming:  { label: "Sắp diễn ra", className: BLUE },

  // challenge (ChallengeStatus)
  completed: { label: "Đã kết thúc", className: GRAYD },
};

interface StatusBadgeProps {
  status: string | boolean;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const key   = String(status).toLowerCase();
  const entry = STATUS_MAP[key] ?? { label: String(status), className: GRAY };

  return (
    <Badge variant="outline" className={cn("text-xs font-medium", entry.className, className)}>
      {entry.label}
    </Badge>
  );
}
