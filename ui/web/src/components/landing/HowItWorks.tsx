import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";

const steps = [
  {
    step: "01",
    title: "Kể về bản thân",
    description: "Chia sẻ mục tiêu fitness, trình độ hiện tại, thời gian rảnh và bất kỳ giới hạn nào. AI sẽ xây dựng hồ sơ cá nhân của bạn.",
  },
  {
    step: "02",
    title: "Nhận kế hoạch riêng",
    description: "Nhận chương trình tập luyện và kế hoạch dinh dưỡng hoàn toàn cá nhân hóa, được tạo ra đặc biệt cho cơ thể và mục tiêu của bạn.",
  },
  {
    step: "03",
    title: "Tập luyện & theo dõi",
    description: "Thực hiện kế hoạch, ghi nhật ký tập luyện và theo dõi dinh dưỡng. AI coach sẽ điều chỉnh mọi thứ khi bạn tiến bộ.",
  },
];

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="py-24 px-4 bg-white">
      <div className="max-w-7xl mx-auto">
        <FadeUp className="text-center mb-16">
          <p className="text-primary font-medium text-sm mb-3 uppercase tracking-wide">Cách hoạt động</p>
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 tracking-tight">
            Bắt đầu trong
            <br />3 bước đơn giản
          </h2>
        </FadeUp>

        <StaggerContainer className="grid grid-cols-1 md:grid-cols-3 gap-12" stagger={0.15}>
          {steps.map((step) => (
            <StaggerItem key={step.step}>
              <div className="flex flex-col items-start md:items-center text-left md:text-center">
                <div className="flex items-center justify-center w-16 h-16 rounded-2xl bg-primary-50 border border-primary-100 mb-6">
                  <span className="text-2xl font-bold text-primary">{step.step}</span>
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">{step.title}</h3>
                <p className="text-gray-400 leading-relaxed text-sm max-w-xs">{step.description}</p>
              </div>
            </StaggerItem>
          ))}
        </StaggerContainer>
      </div>
    </section>
  );
}
