"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth.store";
import { api } from "@/services/api";
import { Eye, EyeOff, Loader2, Zap, ShieldCheck, Lock } from "lucide-react";
import ParticleCursor from "@/components/ui/ParticleCursor";

interface LoginResponse {
  data: { token: string; user: { id: string; email: string; fullName: string; role: string } };
}

const ADMIN_FEATURES = [
  "Quản lý người dùng toàn hệ thống",
  "Theo dõi doanh thu & thống kê",
  "Quản lý bài tập & nội dung",
  "Cấu hình gói đăng ký & khuyến mãi",
];

export default function AdminLoginPage() {
  const router = useRouter();
  const login  = useAuthStore((s) => s.login);

  const [email,        setEmail]        = useState("");
  const [password,     setPassword]     = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading,      setLoading]      = useState(false);
  const [error,        setError]        = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await api.post<LoginResponse>("/api/v1/auth/login", { email, password });
      login(res.data.token, res.data.user);
      router.push("/admin/dashboard");
    } catch {
      setError("Email hoặc mật khẩu không đúng. Vui lòng thử lại.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-white overflow-hidden">
      {/* Left branding panel */}
      <div className="hidden lg:flex lg:w-1/2 relative bg-white overflow-hidden flex-col justify-between p-12 min-h-screen">
        <ParticleCursor />
        <div
          className="absolute inset-0 pointer-events-none z-[6]"
          style={{
            background:
              "radial-gradient(ellipse 70% 60% at 40% 50%, rgba(255,255,255,0.88) 20%, rgba(255,255,255,0.45) 60%, transparent 85%)",
          }}
        />
        <div
          className="absolute -top-32 -left-32 w-[500px] h-[500px] rounded-full pointer-events-none z-[3]"
          style={{
            background: "radial-gradient(circle, rgba(26,131,68,0.12) 0%, transparent 70%)",
            animation: "blob-drift 16s ease-in-out infinite",
          }}
        />
        <div
          className="absolute -bottom-24 -right-24 w-[420px] h-[420px] rounded-full pointer-events-none z-[3]"
          style={{
            background: "radial-gradient(circle, rgba(26,131,68,0.08) 0%, transparent 70%)",
            animation: "blob-drift 22s ease-in-out infinite reverse",
          }}
        />

        {/* Logo */}
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2">
            <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center">
              <Zap className="w-4 h-4 text-white fill-white" />
            </div>
            <span className="font-bold text-xl tracking-tight text-primary">SYNC</span>
            <span className="text-xs font-semibold bg-primary/10 text-primary px-2 py-0.5 rounded-full ml-1">
              Admin
            </span>
          </div>
        </div>

        <div className="relative z-10">
          <div className="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center mb-6">
            <ShieldCheck className="w-7 h-7 text-primary" />
          </div>
          <h2 className="text-4xl font-bold text-gray-900 tracking-tight leading-tight mb-4">
            Trang quản trị
            <br />
            <span className="text-primary">SYNC Platform.</span>
          </h2>
          <p className="text-gray-500 text-base mb-8 leading-relaxed">
            Đăng nhập để quản lý người dùng, nội dung và theo dõi hoạt động của toàn hệ thống.
          </p>
          <ul className="space-y-3">
            {ADMIN_FEATURES.map((item) => (
              <li key={item} className="flex items-center gap-3">
                <span className="w-5 h-5 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                  <ShieldCheck className="w-3 h-3 text-primary" strokeWidth={3} />
                </span>
                <span className="text-gray-600 text-sm">{item}</span>
              </li>
            ))}
          </ul>
        </div>

        <p className="relative z-10 text-xs text-gray-400">© 2026 SYNC. Tất cả quyền được bảo lưu.</p>
      </div>

      {/* Right form panel */}
      <div className="w-full lg:w-1/2 flex flex-col bg-gray-50 min-h-screen">
        {/* Mobile logo */}
        <div className="flex items-center p-6 lg:hidden">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <Zap className="w-4 h-4 text-white fill-white" />
            </div>
            <span className="font-bold text-lg tracking-tight text-primary">SYNC Admin</span>
          </div>
        </div>

        {/* Restricted badge desktop */}
        <div className="hidden lg:flex justify-end p-6">
          <div className="flex items-center gap-1.5 text-xs font-medium text-primary bg-primary/8 px-3 py-1.5 rounded-full border border-primary/15">
            <Lock className="w-3 h-3" />
            Restricted Access
          </div>
        </div>

        {/* Form */}
        <div className="flex-1 flex items-center justify-center px-6 pb-12">
          <div className="w-full max-w-sm">
            <div className="mb-8">
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Đăng nhập Admin</h1>
              <p className="text-gray-500 text-sm">Chỉ dành cho quản trị viên hệ thống.</p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1.5">
                  Email
                </label>
                <input
                  id="email"
                  type="email"
                  autoComplete="email"
                  autoFocus
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@sync.vn"
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all"
                />
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1.5">
                  Mật khẩu
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    autoComplete="current-password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full px-4 py-3 pr-11 rounded-xl border border-gray-200 bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {error && (
                <p className="text-sm text-red-600 bg-red-50 border border-red-100 px-3 py-2.5 rounded-xl">
                  {error}
                </p>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 bg-primary text-white px-6 py-3.5 rounded-full font-medium hover:bg-primary-dark transition-colors disabled:opacity-60 disabled:cursor-not-allowed shadow-md shadow-primary/20 mt-2"
              >
                {loading && <Loader2 className="w-4 h-4 animate-spin" />}
                Đăng nhập
              </button>
            </form>

            <p className="text-center text-xs text-gray-400 mt-8 leading-relaxed">
              Không phải quản trị viên?{" "}
              <a href="/" className="underline hover:text-gray-600 transition-colors">
                Quay về trang chủ
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
