import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { FadeUp } from "@/components/ui/motion";

export default function CTASection() {
  return (
    <section className="py-32 px-4 bg-white">
      <FadeUp className="max-w-4xl mx-auto text-center">
        <h2 className="text-5xl md:text-7xl font-bold text-gray-900 tracking-tight leading-[0.95] mb-8">
          Bắt đầu hành trình
          <br />
          của bạn{" "}
          <span className="text-primary">ngay hôm nay.</span>
        </h2>
        <p className="text-xl text-gray-400 mb-10 leading-relaxed">
          Tham gia cùng 50.000+ người đang tập luyện thông minh hơn với AI.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            href="/register"
            className="group flex items-center gap-2 bg-primary text-white px-9 py-4 rounded-full text-lg font-medium hover:bg-primary-dark transition-all hover:scale-[1.02] shadow-lg shadow-primary/25"
          >
            Bắt đầu miễn phí
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </Link>
        </div>
        <p className="text-gray-400 text-sm mt-5">Không cần thẻ tín dụng · Dùng thử miễn phí 14 ngày</p>
      </FadeUp>
    </section>
  );
}
