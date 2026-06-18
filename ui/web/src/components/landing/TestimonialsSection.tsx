import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";

const testimonials = [
  {
    name: "Minh Tuấn",
    role: "Lập trình viên",
    text: "Giảm 12kg trong 3 tháng. Kế hoạch dinh dưỡng AI rất thông minh — nó biết sở thích ăn uống của tôi và điều chỉnh khi tôi bận.",
    avatar: "MT",
  },
  {
    name: "Thanh Hương",
    role: "Bà mẹ 2 con",
    text: "Là mẹ bỉm sữa, tôi không có thời gian lãng phí. SYNC xây dựng bài tập xung quanh lịch trình bận rộn của tôi. Tôi chưa bao giờ kiên trì được như vậy.",
    avatar: "TH",
  },
  {
    name: "Quốc Bảo",
    role: "Runner nghiệp dư",
    text: "Phân tích tiến trình giúp tôi nhận ra luyện tập quá sức. Thành tích chạy của tôi cải thiện 8 phút sau khi làm theo khuyến nghị phục hồi.",
    avatar: "QB",
  },
];

export default function TestimonialsSection() {
  return (
    <section id="testimonials" className="py-24 px-4 bg-gray-50">
      <div className="max-w-7xl mx-auto">
        <FadeUp className="text-center mb-16">
          <p className="text-primary font-medium text-sm mb-3 uppercase tracking-wide">Đánh giá</p>
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 tracking-tight">
            Kết quả thực, con người thực
          </h2>
        </FadeUp>

        <StaggerContainer className="grid grid-cols-1 md:grid-cols-3 gap-6" stagger={0.12}>
          {testimonials.map((t) => (
            <StaggerItem key={t.name}>
              <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm hover:shadow-md transition-shadow h-full flex flex-col">
                <div className="flex items-center gap-1 mb-4">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <svg key={i} className="w-4 h-4 text-yellow-400 fill-current" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  ))}
                </div>
                <p className="text-gray-600 mb-6 leading-relaxed text-sm flex-1">"{t.text}"</p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary-50 text-primary font-bold flex items-center justify-center text-sm border border-primary-100">
                    {t.avatar}
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900 text-sm">{t.name}</p>
                    <p className="text-gray-400 text-xs">{t.role}</p>
                  </div>
                </div>
              </div>
            </StaggerItem>
          ))}
        </StaggerContainer>
      </div>
    </section>
  );
}
