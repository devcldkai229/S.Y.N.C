"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Eye, EyeOff, Loader2, Zap } from "lucide-react";
import Link from "next/link";
import { useUserAuthStore } from "@/stores/user-auth.store";
import GoogleSignInButton from "@/components/ui/GoogleSignInButton";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5057";

function getDeviceId(): string {
  const key = "sync_device_id";
  let id = localStorage.getItem(key);
  if (!id) { id = crypto.randomUUID(); localStorage.setItem(key, id); }
  return id;
}

function LoginForm() {
  const router       = useRouter();
  const searchParams = useSearchParams();
  const redirect     = searchParams?.get("redirect") ?? "/subscription";
  const { login, isAuthenticated, loadFromStorage } = useUserAuthStore();

  const [email,        setEmail]        = useState("");
  const [password,     setPassword]     = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading,      setLoading]      = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
  const [error,        setError]        = useState("");

  useEffect(() => {
    loadFromStorage();
  }, [loadFromStorage]);

  useEffect(() => {
    if (isAuthenticated) router.replace(redirect);
  }, [isAuthenticated, redirect, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, deviceId: getDeviceId(), platform: 2 }),
      });
      const json = await res.json();
      if (!json.success || !json.data) {
        setError(json.message ?? "Email hoặc mật khẩu không đúng.");
        return;
      }
      const { accessToken, userId, email: userEmail, fullName } = json.data;
      login(accessToken, { id: userId, email: userEmail, fullName });
      router.push(redirect);
    } catch {
      setError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async (idToken: string) => {
    setGoogleLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/auth/google`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken, deviceId: getDeviceId(), platform: 2 }),
      });
      const json = await res.json();
      if (!json.success || !json.data) {
        setError(json.message ?? "Đăng nhập Google thất bại.");
        return;
      }
      const { accessToken, userId, email: userEmail, fullName } = json.data;
      login(accessToken, { id: userId, email: userEmail, fullName });
      router.push(redirect);
    } catch {
      setError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setGoogleLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="flex items-center justify-center gap-2 mb-8">
          <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center">
            <Zap className="w-4 h-4 text-white fill-white" />
          </div>
          <span className="font-bold text-xl tracking-tight text-primary">SYNC</span>
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-8">
          <h1 className="text-2xl font-bold text-gray-900 mb-1">Đăng nhập</h1>
          <p className="text-gray-500 text-sm mb-6">
            Chưa có tài khoản?{" "}
            <Link href="/register" className="text-primary font-medium hover:underline">
              Đăng ký
            </Link>
          </p>

          <GoogleSignInButton onToken={handleGoogle} loading={googleLoading} label="Tiếp tục với Google" />

          <div className="flex items-center gap-3 my-4">
            <div className="flex-1 h-px bg-gray-100" />
            <span className="text-xs text-gray-400">hoặc</span>
            <div className="flex-1 h-px bg-gray-100" />
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
              <input
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@email.com"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Mật khẩu</label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full px-4 py-3 pr-11 rounded-xl border border-gray-200 bg-white text-gray-900 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
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
              className="w-full flex items-center justify-center gap-2 bg-primary text-white px-6 py-3.5 rounded-full font-medium hover:bg-primary/90 transition-colors disabled:opacity-60 disabled:cursor-not-allowed shadow-md shadow-primary/20"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              Đăng nhập
            </button>
          </form>
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
