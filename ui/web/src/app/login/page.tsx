"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Eye, EyeOff, Loader2, Zap, Check, ArrowLeft, Mail } from "lucide-react";
import ParticleCursor from "@/components/ui/ParticleCursor";
import GoogleSignInButton from "@/components/ui/GoogleSignInButton";
import { useUserAuthStore } from "@/stores/user-auth.store";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5057";

interface AuthResponse {
  userId: string;
  email: string;
  fullName: string;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string;
  data: T | null;
  errors: Record<string, string[]> | null;
}

function getDeviceId(): string {
  const key = "sync_device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

const highlights = [
  "AI Coach cá nhân hóa 24/7",
  "Kế hoạch tập thông minh",
  "Theo dõi tiến trình nâng cao",
  "Cộng đồng 50.000+ thành viên",
];

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirect = searchParams?.get("redirect") ?? "/subscription";
  const justVerified = searchParams?.get("verified") === "1";
  const { login, isAuthenticated, loadFromStorage } = useUserAuthStore();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [unverified, setUnverified] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);

  useEffect(() => {
    loadFromStorage();
  }, [loadFromStorage]);

  useEffect(() => {
    if (isAuthenticated) {
      router.replace(redirect);
    }
  }, [isAuthenticated, redirect, router]);

  const saveAndRedirect = (data: AuthResponse) => {
    login(data.accessToken, { id: data.userId, email: data.email, fullName: data.fullName });
    router.push(redirect);
  };

  const handleGoogleLogin = async (idToken: string) => {
    setGoogleLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/auth/google`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken, deviceId: getDeviceId(), platform: 2 }),
      });
      const json: ApiEnvelope<AuthResponse> = await res.json();
      if (!json.success || !json.data) {
        setError(json.message ?? "Đăng nhập Google thất bại. Vui lòng thử lại.");
        return;
      }
      saveAndRedirect(json.data);
    } catch {
      setError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setGoogleLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setUnverified(false);

    try {
      const res = await fetch(`${API_BASE}/api/v1/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          password,
          deviceId: getDeviceId(),
          platform: 2, // Web
        }),
      });

      const json: ApiEnvelope<AuthResponse> = await res.json();

      if (!json.success || !json.data) {
        if (res.status === 403 && json.message?.toLowerCase().includes("verif")) {
          setUnverified(true);
          setError("Email chưa được xác minh. Vui lòng kiểm tra hộp thư và xác nhận tài khoản.");
        } else {
          setError(json.message ?? "Email hoặc mật khẩu không đúng.");
        }
        return;
      }

      saveAndRedirect(json.data);
    } catch {
      setError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-white overflow-hidden">
      {/* ── Left panel — branding ── */}
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
          <Link href="/" className="inline-flex items-center gap-2">
            <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center">
              <Zap className="w-4 h-4 text-white fill-white" />
            </div>
            <span className="font-bold text-xl tracking-tight text-primary">SYNC</span>
          </Link>
        </div>

        {/* Middle */}
        <div className="relative z-10">
          <h2 className="text-4xl font-bold text-gray-900 tracking-tight leading-tight mb-4">
            Chào mừng trở lại,
            <br />
            <span className="text-primary">tiếp tục hành trình.</span>
          </h2>
          <p className="text-gray-500 text-base mb-8 leading-relaxed">
            Đăng nhập để tiếp tục với AI Coach và kế hoạch tập luyện cá nhân của bạn.
          </p>
          <ul className="space-y-3">
            {highlights.map((item) => (
              <li key={item} className="flex items-center gap-3">
                <span className="w-5 h-5 rounded-full bg-primary-50 flex items-center justify-center shrink-0">
                  <Check className="w-3 h-3 text-primary" strokeWidth={3} />
                </span>
                <span className="text-gray-600 text-sm">{item}</span>
              </li>
            ))}
          </ul>
        </div>

        <p className="relative z-10 text-xs text-gray-400">© 2026 SYNC. Tất cả quyền được bảo lưu.</p>
      </div>

      {/* ── Right panel — form ── */}
      <div className="w-full lg:w-1/2 flex flex-col bg-gray-50 min-h-screen">
        {/* Mobile logo */}
        <div className="flex items-center justify-between p-6 lg:hidden">
          <Link href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <Zap className="w-4 h-4 text-white fill-white" />
            </div>
            <span className="font-bold text-lg tracking-tight text-primary">SYNC</span>
          </Link>
          <Link href="/" className="flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 transition-colors">
            <ArrowLeft className="w-4 h-4" />
            Trang chủ
          </Link>
        </div>

        {/* Back link desktop */}
        <div className="hidden lg:flex justify-end p-6">
          <Link href="/" className="flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 transition-colors">
            <ArrowLeft className="w-4 h-4" />
            Trang chủ
          </Link>
        </div>

        {/* Form */}
        <div className="flex-1 flex items-center justify-center px-6 pb-12">
          <div className="w-full max-w-sm">
            <div className="mb-8">
              {justVerified && (
                <div className="flex items-start gap-2.5 bg-primary-50 border border-primary/20 text-primary px-4 py-3 rounded-xl mb-5 text-sm">
                  <Check className="w-4 h-4 mt-0.5 shrink-0" strokeWidth={3} />
                  <span>Email đã được xác nhận thành công! Hãy đăng nhập để bắt đầu.</span>
                </div>
              )}
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Đăng nhập</h1>
              <p className="text-gray-500 text-sm">
                Chưa có tài khoản?{" "}
                <Link href="/register" className="text-primary font-medium hover:underline">
                  Đăng ký miễn phí
                </Link>
              </p>
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
                  placeholder="ten@email.com"
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all"
                />
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                    Mật khẩu
                  </label>
                  <Link href="#" className="text-xs text-primary hover:underline">
                    Quên mật khẩu?
                  </Link>
                </div>
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
                <div className="text-sm text-red-600 bg-red-50 border border-red-100 px-3 py-2.5 rounded-xl space-y-1.5">
                  <p>{error}</p>
                  {unverified && (
                    <Link
                      href={`/register?resend=${encodeURIComponent(email)}`}
                      className="inline-flex items-center gap-1 text-primary font-medium hover:underline text-xs"
                    >
                      <Mail className="w-3.5 h-3.5" />
                      Gửi lại mã xác nhận
                    </Link>
                  )}
                </div>
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

            <div className="flex items-center gap-3 my-6">
              <div className="flex-1 h-px bg-gray-200" />
              <span className="text-xs text-gray-400">hoặc</span>
              <div className="flex-1 h-px bg-gray-200" />
            </div>

            {googleLoading ? (
              <div className="w-full flex items-center justify-center gap-2 bg-white border border-gray-200 text-gray-500 px-6 py-3 rounded-full text-sm">
                <Loader2 className="w-4 h-4 animate-spin" />
                Đang xử lý...
              </div>
            ) : (
              <GoogleSignInButton
                onSuccess={handleGoogleLogin}
                onError={() => setError("Đăng nhập Google thất bại. Vui lòng thử lại.")}
                text="continue_with"
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  );
}
