"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowRight, Sparkles, Send, Activity } from "lucide-react";
import { HeroEntrance, SlideIn } from "@/components/ui/motion";

export default function HeroSection() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    setIsLoggedIn(!!localStorage.getItem("sync_token"));
  }, []);

  return (
    <section className="relative min-h-[100svh] flex items-center pt-20 pb-16 md:pb-20 overflow-hidden">
      {/* Atmosphere — light wash only on copy side so trail stays vivid on the right */}
      <div
        className="absolute inset-0 pointer-events-none z-[1]"
        style={{
          background:
            "radial-gradient(ellipse 55% 70% at 18% 45%, rgba(255,255,255,0.88) 0%, rgba(255,255,255,0.35) 42%, transparent 70%), radial-gradient(ellipse 40% 50% at 85% 20%, rgba(26,131,68,0.06) 0%, transparent 60%)",
        }}
      />

      <div className="relative z-10 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-10 items-center">
          {/* Copy — left */}
          <div className="lg:col-span-6 xl:col-span-5 text-left">
            <HeroEntrance delay={0.05}>
              <p className="text-primary font-semibold text-xs uppercase tracking-[0.18em] mb-5">
                SYNC · Fitness AI
              </p>
            </HeroEntrance>

            <HeroEntrance delay={0.14}>
              <h1 className="font-heading text-[2.75rem] sm:text-5xl md:text-6xl xl:text-[4.25rem] font-bold tracking-tight text-gray-950 mb-5 leading-[1.02]">
                Tập luyện
                <br />
                thông minh,
                <br />
                <span className="text-primary">sống khỏe hơn.</span>
              </h1>
            </HeroEntrance>

            <HeroEntrance delay={0.26}>
              <p className="text-base md:text-lg text-gray-500 max-w-md mb-8 leading-relaxed">
                AI tạo kế hoạch tập và dinh dưỡng riêng cho bạn — thích nghi theo
                cơ thể, mục tiêu và lối sống mỗi tuần.
              </p>
            </HeroEntrance>

            <HeroEntrance delay={0.36}>
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
                <Link
                  href={isLoggedIn ? "/subscription" : "/register"}
                  className="group inline-flex items-center justify-center gap-2 bg-primary text-white px-7 py-3.5 rounded-full text-sm font-semibold hover:bg-primary-dark transition-all hover:scale-[1.02] shadow-lg shadow-primary/25"
                >
                  {isLoggedIn ? "Bắt đầu ngay" : "Bắt đầu miễn phí"}
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                </Link>
                <Link
                  href="#how-it-works"
                  className="group inline-flex items-center justify-center gap-2 text-gray-700 px-6 py-3.5 rounded-full text-sm font-medium border border-gray-200 bg-white/70 backdrop-blur-sm hover:border-gray-300 hover:bg-white transition-colors"
                >
                  Cách hoạt động
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                </Link>
              </div>
            </HeroEntrance>

            <HeroEntrance delay={0.46}>
              <div className="mt-10 flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-gray-400">
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                  50K+ người dùng
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                  Miễn phí bắt đầu
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                  Hủy bất cứ lúc nào
                </span>
              </div>
            </HeroEntrance>
          </div>

          {/* Product visual — right */}
          <div className="lg:col-span-6 xl:col-span-7 relative">
            <SlideIn from="right" delay={0.2}>
              <div className="relative mx-auto max-w-lg lg:max-w-none lg:ml-auto">
                {/* Soft green glow behind card so trail + product both read */}
                <div
                  className="absolute -inset-8 rounded-[2rem] pointer-events-none opacity-70"
                  style={{
                    background:
                      "radial-gradient(ellipse at 60% 40%, rgba(26,131,68,0.14) 0%, transparent 65%)",
                  }}
                />

                <div className="relative bg-white/95 backdrop-blur-md rounded-3xl border border-gray-200/90 shadow-2xl shadow-gray-900/8 overflow-hidden">
                  {/* Top bar */}
                  <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 bg-gradient-to-r from-primary-50/80 to-white">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-primary rounded-2xl flex items-center justify-center shadow-md shadow-primary/30">
                        <Sparkles className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-gray-900">SYNC AI Coach</p>
                        <p className="text-xs text-primary font-medium flex items-center gap-1">
                          <span className="inline-block w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
                          Đang trực tuyến
                        </p>
                      </div>
                    </div>
                    <div className="hidden sm:flex items-center gap-1.5 text-xs text-gray-400 bg-white border border-gray-100 rounded-full px-3 py-1">
                      <Activity className="w-3.5 h-3.5 text-primary" />
                      Kế hoạch tuần
                    </div>
                  </div>

                  <div className="p-5 space-y-4">
                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                        <Sparkles className="w-3.5 h-3.5 text-white" />
                      </div>
                      <div className="bg-gray-50 rounded-2xl rounded-tl-md px-4 py-3 text-sm text-gray-700 border border-gray-100 max-w-[90%]">
                        Xin chào! Mục tiêu tuần này của bạn là gì?
                      </div>
                    </div>

                    <div className="flex justify-end">
                      <div className="bg-primary text-white rounded-2xl rounded-tr-md px-4 py-3 text-sm max-w-[85%] shadow-md shadow-primary/20">
                        Giảm mỡ, tăng cơ — 45 phút, 4 buổi/tuần.
                      </div>
                    </div>

                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                        <Sparkles className="w-3.5 h-3.5 text-white" />
                      </div>
                      <div className="space-y-3 max-w-[92%]">
                        <div className="bg-gray-50 rounded-2xl rounded-tl-md px-4 py-3 text-sm text-gray-700 border border-gray-100">
                          Đã dựng chương trình{" "}
                          <span className="text-primary font-semibold">HIIT + Sức mạnh 4 ngày</span>{" "}
                          và macro dinh dưỡng phù hợp.
                        </div>
                        <div className="grid grid-cols-3 gap-2">
                          {[
                            { v: "4×", l: "Buổi/tuần" },
                            { v: "45p", l: "Mỗi buổi" },
                            { v: "2.1k", l: "Cal/ngày" },
                          ].map((s) => (
                            <div
                              key={s.l}
                              className="rounded-xl bg-primary-50 border border-primary-100 px-2 py-2.5 text-center"
                            >
                              <p className="text-lg font-bold text-primary leading-none">{s.v}</p>
                              <p className="text-[10px] text-gray-500 mt-1">{s.l}</p>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 bg-white rounded-full border border-gray-200 px-4 py-2.5 shadow-sm">
                      <input
                        type="text"
                        placeholder="Hỏi AI coach…"
                        className="flex-1 text-sm text-gray-500 outline-none bg-transparent"
                        readOnly
                      />
                      <button
                        type="button"
                        className="w-9 h-9 bg-primary rounded-full flex items-center justify-center flex-shrink-0 shadow-md shadow-primary/25"
                        aria-label="Gửi"
                      >
                        <Send className="w-3.5 h-3.5 text-white" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </SlideIn>
          </div>
        </div>
      </div>
    </section>
  );
}
