import Navbar from "@/components/landing/Navbar";
import PricingSection from "@/components/landing/PricingSection";
import MySubscriptionStatus from "@/components/landing/MySubscriptionStatus";
import CTASection from "@/components/landing/CTASection";
import DisplayTextSection from "@/components/landing/DisplayTextSection";
import Footer from "@/components/landing/Footer";
import CursorTrailBackground from "@/components/ui/CursorTrailBackground";
import { Check, Shield, RefreshCcw, HeadphonesIcon } from "lucide-react";
import { FadeUp, StaggerContainer, StaggerItem } from "@/components/ui/motion";

const guarantees = [
  {
    icon: Shield,
    title: "Thanh toán an toàn",
    description: "Web qua PayOS / VietQR; Android qua Google Play Billing. Mã hóa SSL, không lưu thẻ trên SYNC.",
  },
  {
    icon: RefreshCcw,
    title: "Hủy giữ quyền tới hết hạn",
    description: "Hủy 1 click — bạn vẫn dùng Premium đến ngày hết hạn, rồi mới về Free. Không mất dữ liệu.",
  },
  {
    icon: HeadphonesIcon,
    title: "Giá trị thấy được ngay",
    description: "CYN không giới hạn, Adaptive theo cân, Insight & SmartPush AI — không chỉ “gói ẩn”.",
  },
];

const faqs = [
  {
    q: "Gói Free có bị giới hạn thời gian không?",
    a: "Không. Free miễn phí mãi mãi: lộ trình Foundation, nhật ký tập/ăn, cộng đồng và CYN AI 30 lượt/tháng — không cần thẻ.",
  },
  {
    q: "Premium mở khóa những gì khác Free?",
    a: "CYN không giới hạn; Adaptive Coaching điều chỉnh calo/macro theo cân thật; Insight (biểu đồ & dự đoán); SmartPush AI cá nhân hóa; giáo án/video HD; ưu đãi Marketplace và đặt đơn hỗ trợ AI (tối đa 10 lần/tháng).",
  },
  {
    q: "Tôi có thể nâng cấp từ Free lên Premium bất cứ lúc nào không?",
    a: "Có. Thanh toán thành công là Premium kích hoạt ngay. Trên web dùng PayOS / VietQR; trên Android dùng Google Play Billing.",
  },
  {
    q: "Nếu tôi hủy Premium, dữ liệu có mất không?",
    a: "Không. Lịch sử tập, dinh dưỡng và hồ sơ giữ nguyên. Bạn giữ quyền Premium tới hết hạn, sau đó về Free với hạn mức AI Free.",
  },
  {
    q: "Có tự gia hạn không?",
    a: "Đợt này thanh toán theo tháng, gia hạn thủ công (web). Trên Android theo chính sách Google Play Billing của gói đăng ký.",
  },
];

export default function SubscriptionPage() {
  return (
    <div className="relative min-h-screen bg-[#FAFCFA]">
      <Navbar />
      <main className="pt-16">
        <section className="relative py-28 px-4 text-center overflow-hidden">
          <FadeUp className="relative z-10 max-w-3xl mx-auto">
            <span className="inline-flex items-center gap-1.5 bg-primary-50/90 text-primary text-xs font-semibold px-3 py-1.5 rounded-full border border-primary/20 mb-6 backdrop-blur-sm">
              <Check className="w-3.5 h-3.5" />
              99.000đ/tháng · Hủy giữ quyền tới hết hạn
            </span>
            <h1 className="font-heading text-5xl md:text-6xl font-bold text-gray-900 tracking-tight leading-[1.05] mb-6">
              Premium cho người
              <br />
              <span className="text-primary">muốn tiến thật.</span>
            </h1>
            <p className="text-xl text-gray-500 leading-relaxed max-w-xl mx-auto">
              Free đủ để bắt đầu. Premium mở CYN không giới hạn, Adaptive theo cân thật,
              Insight sâu và SmartPush AI — coach đồng hành mỗi ngày.
            </p>
          </FadeUp>
        </section>

        <MySubscriptionStatus />
        <PricingSection />

        <section className="py-20 px-4 bg-gray-50/80">
          <div className="max-w-4xl mx-auto">
            <FadeUp className="text-center mb-12">
              <h2 className="font-heading text-2xl md:text-3xl font-bold text-gray-900 tracking-tight">
                Cam kết từ SYNC
              </h2>
            </FadeUp>
            <StaggerContainer className="grid grid-cols-1 md:grid-cols-3 gap-6" stagger={0.1}>
              {guarantees.map((g) => (
                <StaggerItem key={g.title}>
                  <div className="bg-white rounded-2xl p-6 border border-gray-100 hover:shadow-md hover:border-primary/15 transition-all duration-300 h-full">
                    <div className="w-10 h-10 rounded-xl bg-primary-50 flex items-center justify-center mb-4">
                      <g.icon className="w-5 h-5 text-primary" />
                    </div>
                    <h3 className="font-semibold text-gray-900 mb-2">{g.title}</h3>
                    <p className="text-gray-500 text-sm leading-relaxed">{g.description}</p>
                  </div>
                </StaggerItem>
              ))}
            </StaggerContainer>
          </div>
        </section>

        <section className="py-20 px-4 bg-white/80">
          <div className="max-w-2xl mx-auto">
            <FadeUp className="text-center mb-12">
              <p className="text-primary font-medium text-sm mb-3 uppercase tracking-wide">
                Câu hỏi thường gặp
              </p>
              <h2 className="font-heading text-3xl md:text-4xl font-bold text-gray-900 tracking-tight">
                Giải đáp nhanh
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
      <Footer />
      <CursorTrailBackground mode="fixed" variant="light" />
    </div>
  );
}
