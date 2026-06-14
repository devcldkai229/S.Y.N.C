"use client";

import Link from "next/link";
import { ArrowRight, Sparkles, Send } from "lucide-react";
import { HeroEntrance } from "@/components/ui/motion";
import ParticleCursor from "@/components/ui/ParticleCursor";

export default function HeroSection() {
  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center pt-16 px-4 bg-white overflow-hidden">
      {/* Interactive particle field — z-[5], below content z-[10] */}
      <ParticleCursor />

      {/* Soft radial fade so center stays readable */}
      <div
        className="absolute inset-0 pointer-events-none z-[6]"
        style={{
          background:
            "radial-gradient(ellipse 65% 55% at 50% 42%, white 15%, rgba(255,255,255,0.6) 50%, transparent 80%)",
        }}
      />

      {/* Animated gradient blobs — z-[3] below particle canvas */}
      <div className="blob-primary absolute -top-40 -left-40 w-[600px] h-[600px] rounded-full pointer-events-none z-[3]"
        style={{ background: "radial-gradient(circle, rgba(26,131,68,0.10) 0%, transparent 70%)" }} />
      <div className="blob-secondary absolute -bottom-20 -right-40 w-[500px] h-[500px] rounded-full pointer-events-none z-[3]"
        style={{ background: "radial-gradient(circle, rgba(26,131,68,0.07) 0%, transparent 70%)" }} />

      {/* Content */}
      <div className="relative z-10 max-w-5xl mx-auto w-full text-center">
        <HeroEntrance delay={0.1}>
          <div className="inline-flex items-center gap-2 bg-primary-50 border border-primary-100 text-primary rounded-full px-4 py-1.5 text-sm font-medium mb-8">
            <Sparkles className="w-3.5 h-3.5" />
            AI-Powered Fitness Platform
          </div>
        </HeroEntrance>

        <HeroEntrance delay={0.22}>
          <h1 className="text-6xl md:text-8xl font-bold tracking-tight text-gray-900 mb-6 leading-[0.95]">
            Train smarter,
            <br />
            <span className="text-primary">live better.</span>
          </h1>
        </HeroEntrance>

        <HeroEntrance delay={0.36}>
          <p className="text-xl text-gray-400 max-w-2xl mx-auto mb-10 leading-relaxed">
            Your AI fitness companion creates personalized workout and nutrition plans that
            adapt to your body, goals, and lifestyle — updated weekly.
          </p>
        </HeroEntrance>

        <HeroEntrance delay={0.48}>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-20">
            <Link
              href="/admin/login"
              className="group flex items-center gap-2 bg-primary text-white px-8 py-4 rounded-full text-base font-medium hover:bg-primary-dark transition-all hover:scale-[1.03] shadow-lg shadow-primary/25"
            >
              Bắt đầu miễn phí
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </Link>
            <Link
              href="#how-it-works"
              className="group flex items-center gap-2 text-gray-500 px-8 py-4 rounded-full text-base hover:text-gray-900 transition-colors"
            >
              Xem cách hoạt động
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </Link>
          </div>
        </HeroEntrance>

        {/* AI chat mockup */}
        <HeroEntrance delay={0.62}>
          <div className="relative max-w-2xl mx-auto">
            {/* Bottom fade */}
            <div className="absolute bottom-0 left-0 right-0 h-28 bg-gradient-to-t from-white to-transparent z-10 pointer-events-none rounded-b-2xl" />

            <div className="bg-gray-50 rounded-2xl border border-gray-200 p-6 shadow-2xl shadow-gray-100 text-left">
              {/* Header */}
              <div className="flex items-center gap-3 mb-5 pb-4 border-b border-gray-100">
                <div className="w-9 h-9 bg-primary rounded-full flex items-center justify-center">
                  <Sparkles className="w-4 h-4 text-white" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-900">SYNC AI Coach</p>
                  <p className="text-xs text-primary">● Online</p>
                </div>
              </div>

              {/* Messages */}
              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <div className="w-7 h-7 bg-primary rounded-full flex items-center justify-center flex-shrink-0">
                    <Sparkles className="w-3.5 h-3.5 text-white" />
                  </div>
                  <div className="bg-white rounded-2xl rounded-tl-none px-4 py-3 text-sm text-gray-700 shadow-sm border border-gray-100 max-w-xs">
                    Xin chào! Tôi là AI coach của bạn. Bạn đang hướng đến mục tiêu gì?
                  </div>
                </div>
                <div className="flex justify-end">
                  <div className="bg-primary text-white rounded-2xl rounded-tr-none px-4 py-3 text-sm max-w-xs">
                    Tôi muốn giảm mỡ và tăng cơ, chỉ có 45 phút 4 buổi/tuần.
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-7 h-7 bg-primary rounded-full flex items-center justify-center flex-shrink-0">
                    <Sparkles className="w-3.5 h-3.5 text-white" />
                  </div>
                  <div className="bg-white rounded-2xl rounded-tl-none px-4 py-3 text-sm text-gray-700 shadow-sm border border-gray-100 max-w-sm">
                    Tuyệt! Tôi đã tạo chương trình{" "}
                    <span className="text-primary font-semibold">4-day HIIT + Strength</span> và
                    kế hoạch dinh dưỡng cắt giảm calorie phù hợp riêng cho bạn. 🎯
                  </div>
                </div>
              </div>

              {/* Input */}
              <div className="mt-5 flex items-center gap-2 bg-white rounded-full border border-gray-200 px-4 py-2.5">
                <input
                  type="text"
                  placeholder="Hỏi AI coach bất cứ điều gì..."
                  className="flex-1 text-sm text-gray-500 outline-none bg-transparent"
                  readOnly
                />
                <button className="w-8 h-8 bg-primary rounded-full flex items-center justify-center flex-shrink-0">
                  <Send className="w-3.5 h-3.5 text-white" />
                </button>
              </div>
            </div>
          </div>
        </HeroEntrance>
      </div>
    </section>
  );
}
