import Navbar from "@/components/landing/Navbar";
import PricingSection from "@/components/landing/PricingSection";
import MySubscriptionStatus from "@/components/landing/MySubscriptionStatus";
import CTASection from "@/components/landing/CTASection";
import DisplayTextSection from "@/components/landing/DisplayTextSection";
import ParticleCursor from "@/components/ui/ParticleCursor";
import { Check, Shield, RefreshCcw, HeadphonesIcon } from "lucide-react";
import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";

const guarantees = [
  {
    icon: Shield,
    title: "Bảo mật thanh toán",
    description: "Mọi giao dịch được mã hóa SSL 256-bit. Thông tin của bạn luôn an toàn.",
  },
  {
    icon: RefreshCcw,
    title: "Hủy bất cứ lúc nào",
    description: "Không ràng buộc hợp đồng. Hủy gói Pro trong 1 click, không mất phí.",
  },
  {
    icon: HeadphonesIcon,
    title: "Hỗ trợ tận tâm",
    description: "Đội ngũ hỗ trợ sẵn sàng giải đáp mọi thắc mắc của bạn 7 ngày/tuần.",
  },
];

const faqs = [
  {
    q: "Gói Free có bị giới hạn thời gian không?",
    a: "Không. Gói Free là miễn phí mãi mãi, bạn có thể dùng vô thời hạn mà không cần nhập thẻ tín dụng.",
  },
  {
    q: "Tôi có thể nâng cấp từ Free lên Pro bất cứ lúc nào không?",
    a: "Có, bạn có thể nâng cấp ngay lập tức. Gói Pro sẽ kích hoạt tức thì sau khi thanh toán thành công.",
  },
  {
    q: "Phương thức thanh toán nào được hỗ trợ?",
    a: "SYNC hỗ trợ thanh toán qua VNPay, Momo, và các thẻ nội địa/quốc tế phổ biến.",
  },
  {
    q: "Nếu tôi hủy Pro, dữ liệu của tôi có bị mất không?",
    a: "Không. Toàn bộ lịch sử tập luyện và dữ liệu của bạn được giữ nguyên khi chuyển về gói Free.",
  },
];

export default function SubscriptionPage() {
  return (
    <>
      <Navbar />
      <main className="pt-16">
        {/* Hero — same background treatment as HeroSection */}
        <section className="relative py-28 px-4 bg-white text-center overflow-hidden">
          {/* Particle field */}
          <ParticleCursor />

          {/* Soft radial fade so centre stays readable */}
          <div
            className="absolute inset-0 pointer-events-none z-[6]"
            style={{
              background:
                "radial-gradient(ellipse 70% 60% at 50% 40%, white 20%, rgba(255,255,255,0.55) 55%, transparent 80%)",
            }}
          />

          {/* Animated gradient blobs */}
          <div
            className="absolute -top-32 -left-32 w-[550px] h-[550px] rounded-full pointer-events-none z-[3]"
            style={{
              background: "radial-gradient(circle, rgba(26,131,68,0.10) 0%, transparent 70%)",
              animation: "blob-drift 16s ease-in-out infinite",
            }}
          />
          <div
            className="absolute -bottom-20 -right-32 w-[480px] h-[480px] rounded-full pointer-events-none z-[3]"
            style={{
              background: "radial-gradient(circle, rgba(26,131,68,0.07) 0%, transparent 70%)",
              animation: "blob-drift 22s ease-in-out infinite reverse",
            }}
          />

          {/* Content */}
          <FadeUp className="relative z-10 max-w-3xl mx-auto">
            <span className="inline-flex items-center gap-1.5 bg-primary-50 text-primary text-xs font-semibold px-3 py-1.5 rounded-full border border-primary/20 mb-6">
              <Check className="w-3.5 h-3.5" />
              Đơn giản · Minh bạch · Không ẩn phí
            </span>
            <h1 className="text-5xl md:text-6xl font-bold text-gray-900 tracking-tight leading-[1.05] mb-6">
              Đầu tư cho sức khỏe
              <br />
              <span className="text-primary">không cần tốn nhiều.</span>
            </h1>
            <p className="text-xl text-gray-400 leading-relaxed max-w-xl mx-auto">
              Bắt đầu với gói Free, nâng cấp khi bạn sẵn sàng chinh phục những mục tiêu lớn hơn.
            </p>
          </FadeUp>
        </section>

        {/* Gói hiện tại của user (chỉ hiện khi đã login) */}
        <MySubscriptionStatus />

        {/* Pricing cards */}
        <PricingSection />

        {/* Guarantees */}
        <section className="py-20 px-4 bg-gray-50">
          <div className="max-w-4xl mx-auto">
            <FadeUp className="text-center mb-12">
              <h2 className="text-2xl md:text-3xl font-bold text-gray-900 tracking-tight">
                Cam kết từ SYNC
              </h2>
            </FadeUp>
            <StaggerContainer className="grid grid-cols-1 md:grid-cols-3 gap-6" stagger={0.1}>
              {guarantees.map((g) => (
                <StaggerItem key={g.title}>
                  <div className="bg-white rounded-2xl p-6 border border-gray-100 hover:shadow-md transition-all duration-300 h-full">
                    <div className="w-10 h-10 rounded-xl bg-primary-50 flex items-center justify-center mb-4">
                      <g.icon className="w-5 h-5 text-primary" />
                    </div>
                    <h3 className="font-semibold text-gray-900 mb-2">{g.title}</h3>
                    <p className="text-gray-400 text-sm leading-relaxed">{g.description}</p>
                  </div>
                </StaggerItem>
              ))}
            </StaggerContainer>
          </div>
        </section>

        {/* FAQ */}
        <section className="py-20 px-4 bg-white">
          <div className="max-w-2xl mx-auto">
            <FadeUp className="text-center mb-12">
              <p className="text-primary font-medium text-sm mb-3 uppercase tracking-wide">FAQ</p>
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 tracking-tight">
                Câu hỏi thường gặp
              </h2>
            </FadeUp>
            <StaggerContainer className="space-y-4" stagger={0.08}>
              {faqs.map((faq) => (
                <StaggerItem key={faq.q}>
                  <div className="bg-gray-50 rounded-2xl p-6 border border-gray-100 hover:border-gray-200 transition-colors">
                    <p className="font-semibold text-gray-900 mb-2">{faq.q}</p>
                    <p className="text-gray-500 text-sm leading-relaxed">{faq.a}</p>
                  </div>
                </StaggerItem>
              ))}
            </StaggerContainer>
          </div>
        </section>

        <CTASection />
      </main>
      <DisplayTextSection />
    </>
  );
}
