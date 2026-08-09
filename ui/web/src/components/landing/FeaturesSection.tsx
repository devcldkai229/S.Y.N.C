import { Brain, Utensils, BarChart3, Zap, HeartPulse, Users } from "lucide-react";
import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";

const features = [
  {
    icon: Brain,
    title: "Huấn luyện viên AI",
    description: "Chat với AI coach 24/7. Nhận ngay câu trả lời về bài tập, dinh dưỡng và phục hồi thể chất.",
    bg: "bg-primary-50",
    color: "text-primary",
  },
  {
    icon: Zap,
    title: "Kế hoạch tập thông minh",
    description: "Chương trình tập luyện thích nghi với tiến trình của bạn, trình độ thể lực và thiết bị hiện có.",
    bg: "bg-blue-50",
    color: "text-blue-600",
  },
  {
    icon: Utensils,
    title: "Kế hoạch dinh dưỡng",
    description: "Kế hoạch bữa ăn cá nhân hóa kèm theo dõi macro, công thức nấu ăn và danh sách mua sắm.",
    bg: "bg-orange-50",
    color: "text-orange-600",
  },
  {
    icon: BarChart3,
    title: "Phân tích tiến trình",
    description: "Thông tin chuyên sâu về xu hướng hiệu suất, thay đổi cơ thể và các mốc mục tiêu của bạn.",
    bg: "bg-purple-50",
    color: "text-purple-600",
  },
  {
    icon: HeartPulse,
    title: "Theo dõi sức khỏe",
    description: "Đồng bộ với thiết bị đeo để theo dõi nhịp tim, chất lượng giấc ngủ và điểm phục hồi.",
    bg: "bg-red-50",
    color: "text-red-500",
  },
  {
    icon: Users,
    title: "Thử thách cộng đồng",
    description: "Tham gia thử thách nhóm, cạnh tranh với bạn bè và duy trì động lực cùng cộng đồng.",
    bg: "bg-yellow-50",
    color: "text-yellow-600",
  },
];

export default function FeaturesSection() {
  return (
    <section id="features" className="relative z-[2] py-28 px-4 bg-white/80 backdrop-blur-[2px]">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <FadeUp className="text-center mb-16">
          <p className="text-primary font-medium text-sm mb-3 uppercase tracking-wide">Tính năng</p>
          <h2 className="font-heading text-4xl md:text-5xl font-bold text-gray-900 mb-5 tracking-tight">
            Mọi thứ bạn cần để
            <br />
            đạt đỉnh cao thể lực
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
            Từ kế hoạch do AI tạo ra đến huấn luyện thời gian thực, SYNC có đủ công cụ để biến đổi hành trình của bạn.
          </p>
        </FadeUp>

        {/* Stagger cards */}
        <StaggerContainer className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" stagger={0.08}>
          {features.map((feature) => (
            <StaggerItem key={feature.title}>
              <div className="group rounded-2xl p-7 border border-gray-100 bg-white hover:border-primary/20 hover:shadow-lg hover:shadow-primary/5 transition-all duration-300 cursor-default h-full">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center mb-5 ${feature.bg} ${feature.color}`}>
                  <feature.icon className="w-6 h-6" />
                </div>
                <h3 className="font-heading font-semibold text-gray-900 text-lg mb-2">{feature.title}</h3>
                <p className="text-gray-500 text-sm leading-relaxed">{feature.description}</p>
              </div>
            </StaggerItem>
          ))}
        </StaggerContainer>
      </div>
    </section>
  );
}
