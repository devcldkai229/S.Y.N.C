import { StaggerContainer, StaggerItem } from "@/components/ui/motion";

const stats = [
  { value: "50K+", label: "Người dùng hoạt động" },
  { value: "2M+", label: "Buổi tập hoàn thành" },
  { value: "98%", label: "Đạt được mục tiêu" },
  { value: "4.9★", label: "Đánh giá trên cửa hàng ứng dụng" },
];

export default function StatsSection() {
  return (
    <section className="relative z-[2] py-16 border-y border-gray-100/80 bg-white/80 backdrop-blur-[1px]">
      <div className="max-w-7xl mx-auto px-4">
        <StaggerContainer className="grid grid-cols-2 md:grid-cols-4 gap-8" stagger={0.12}>
          {stats.map((stat) => (
            <StaggerItem key={stat.label}>
              <div className="text-center">
                <div className="text-4xl md:text-5xl font-bold text-primary tracking-tight">
                  {stat.value}
                </div>
                <div className="text-gray-400 mt-1.5 text-sm">{stat.label}</div>
              </div>
            </StaggerItem>
          ))}
        </StaggerContainer>
      </div>
    </section>
  );
}
