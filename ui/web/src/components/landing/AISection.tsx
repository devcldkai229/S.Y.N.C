import { Sparkles, CheckCircle2 } from "lucide-react";
import { SlideIn, FadeUp } from "@/components/ui/motion";

const benefits = [
  "Phân tích chỉ số cơ thể và lịch sử tập luyện của bạn",
  "Tạo kế hoạch dựa trên lịch trình và thiết bị hiện có",
  "Điều chỉnh hàng tuần theo tiến trình và phản hồi",
  "Hỗ trợ huấn luyện và động lực 24/7",
  "Kết hợp dinh dưỡng và tập luyện cho kết quả tối ưu",
];

const exercises = ["Squat 4×12", "Bench Press 4×10", "Romanian Deadlift 3×12", "Pull-ups 3×max"];

export default function AISection() {
  return (
    <section className="py-24 px-4 bg-gray-50">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          {/* Left */}
          <SlideIn from="left">
            <div className="inline-flex items-center gap-2 bg-primary-50 border border-primary-100 text-primary rounded-full px-4 py-1.5 text-sm font-medium mb-6">
              <Sparkles className="w-3.5 h-3.5" />
              Được hỗ trợ bởi AI
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6 tracking-tight leading-tight">
              Trợ lý fitness AI
              <br />
              cá nhân của bạn
            </h2>
            <p className="text-gray-400 text-lg mb-8 leading-relaxed">
              Không giống các app fitness thông thường, AI của SYNC hiểu cơ thể, mục tiêu và giới hạn riêng của bạn. Nó không chỉ đưa ra kế hoạch — mà còn huấn luyện bạn từng bước một.
            </p>
            <ul className="space-y-3.5">
              {benefits.map((b) => (
                <li key={b} className="flex items-start gap-3 text-gray-600">
                  <CheckCircle2 className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
                  <span className="text-sm leading-relaxed">{b}</span>
                </li>
              ))}
            </ul>
          </SlideIn>

          {/* Right */}
          <SlideIn from="right" delay={0.1}>
            <div className="relative">
              <div className="bg-white rounded-3xl border border-gray-100 p-6 shadow-xl shadow-gray-100">
                <div className="mb-5">
                  <p className="text-xs text-gray-400 mb-1 uppercase tracking-wide">Kế hoạch cá nhân hóa của bạn</p>
                  <h3 className="font-bold text-gray-900 text-xl">Chương trình Lean Muscle 4 tuần</h3>
                </div>

                <div className="grid grid-cols-3 gap-3 mb-6">
                  {[
                    { value: "4x", label: "Buổi/tuần" },
                    { value: "45m", label: "Mỗi buổi" },
                    { value: "2,100", label: "Cal/ngày" },
                  ].map((s) => (
                    <div key={s.label} className="bg-primary-50 rounded-xl p-3 text-center">
                      <p className="text-2xl font-bold text-primary leading-none mb-1">{s.value}</p>
                      <p className="text-xs text-gray-400">{s.label}</p>
                    </div>
                  ))}
                </div>

                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-xs text-gray-400 mb-3 uppercase tracking-wide font-medium">Bài tập hôm nay</p>
                  <div className="space-y-2.5">
                    {exercises.map((ex, i) => (
                      <div key={ex} className="flex items-center gap-3">
                        <div className={`w-4 h-4 rounded-full border-2 flex-shrink-0 ${i < 2 ? "border-primary bg-primary" : "border-gray-300"}`} />
                        <span className={`text-sm ${i < 2 ? "text-gray-400 line-through" : "text-gray-700"}`}>{ex}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="mt-5">
                  <div className="flex justify-between text-xs text-gray-400 mb-1.5">
                    <span>Tiến trình tuần 2</span>
                    <span className="text-primary font-medium">60%</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-2 bg-primary rounded-full" style={{ width: "60%" }} />
                  </div>
                </div>
              </div>

              {/* Floating card */}
              <div className="absolute -bottom-5 -left-5 bg-white rounded-2xl border border-gray-100 shadow-xl px-4 py-3">
                <p className="text-xs text-gray-400 mb-0.5">AI Insight</p>
                <p className="text-sm font-semibold text-gray-800">💪 Bạn mạnh hơn 23% so với tháng trước!</p>
              </div>
            </div>
          </SlideIn>
        </div>
      </div>
    </section>
  );
}
