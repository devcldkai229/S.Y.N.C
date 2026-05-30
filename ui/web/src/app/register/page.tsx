"use client";

import { useState, useRef, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Eye, EyeOff, Loader2, Zap, Crown, ArrowLeft,
  Check, Mail, RefreshCw, ArrowRight,
} from "lucide-react";
import ParticleCursor from "@/components/ui/ParticleCursor";
import GoogleSignInButton from "@/components/ui/GoogleSignInButton";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5057";

interface RegisterData { userId: string; email: string; message: string }
interface VerifyData   { userId: string; email: string; emailVerified: boolean }

interface AuthResponse { userId: string; email: string; fullName: string; accessToken: string; refreshToken: string; expiresIn: number; }

interface ApiEnvelope<T> {
  success: boolean;
  message: string;
  data: T | null;
  errors: Record<string, string[]> | null;
}

function getDeviceId(): string {
  const key = "sync_device_id";
  let id = localStorage.getItem(key);
  if (!id) { id = crypto.randomUUID(); localStorage.setItem(key, id); }
  return id;
}

// ── OTP input — 6 individual boxes ────────────────────────────────────────────
function OtpInput({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  const refs = useRef<(HTMLInputElement | null)[]>([]);

  const handleChange = (i: number, char: string) => {
    if (!/^\d*$/.test(char)) return;
    const arr = value.padEnd(6, " ").split("");
    arr[i] = char.slice(-1) || " ";
    const next = arr.join("").trimEnd();
    onChange(next);
    if (char && i < 5) refs.current[i + 1]?.focus();
  };

  const handleKeyDown = (i: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace") {
      if (!value[i] || value[i] === " ") {
        refs.current[i - 1]?.focus();
      }
      const arr = value.padEnd(6, " ").split("");
      arr[i] = " ";
      onChange(arr.join("").trimEnd());
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const text = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    onChange(text);
    refs.current[Math.min(text.length, 5)]?.focus();
  };

  return (
    <div className="flex gap-3 justify-center">
      {Array.from({ length: 6 }).map((_, i) => (
        <input
          key={i}
          ref={(el) => { refs.current[i] = el; }}
          type="text"
          inputMode="numeric"
          maxLength={1}
          value={value[i] ?? ""}
          onChange={(e) => handleChange(i, e.target.value)}
          onKeyDown={(e) => handleKeyDown(i, e)}
          onPaste={handlePaste}
          className="w-11 h-13 text-center text-xl font-bold text-gray-900 bg-white border-2 border-gray-200 rounded-xl outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all caret-transparent"
          style={{ height: "3.25rem" }}
        />
      ))}
    </div>
  );
}

// ── Main component (uses useSearchParams — needs Suspense wrapper) ─────────────
function RegisterForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const planParam = searchParams.get("plan") ?? "";
  const resendEmail = searchParams.get("resend") ?? "";

  const isPro = planParam === "pro";

  // Step 1 — register form state
  const [fullName, setFullName]             = useState("");
  const [email, setEmail]                   = useState(resendEmail);
  const [password, setPassword]             = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword]     = useState(false);
  const [showConfirm, setShowConfirm]       = useState(false);
  const [registerLoading, setRegisterLoading] = useState(false);
  const [registerError, setRegisterError]   = useState("");
  const [fieldErrors, setFieldErrors]       = useState<Record<string, string>>({});
  const [googleLoading, setGoogleLoading]   = useState(false);

  // Step 2 — OTP verification state
  const [step, setStep]         = useState<"register" | "verify">(resendEmail ? "verify" : "register");
  const [registeredEmail, setRegisteredEmail] = useState(resendEmail);
  const [otp, setOtp]           = useState("");
  const [verifyLoading, setVerifyLoading] = useState(false);
  const [verifyError, setVerifyError]     = useState("");
  const [resendLoading, setResendLoading] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);

  // Countdown timer for resend
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const t = setTimeout(() => setResendCooldown((c) => c - 1), 1000);
    return () => clearTimeout(t);
  }, [resendCooldown]);

  // ── Google Sign-Up/In ────────────────────────────────────────────────────
  const handleGoogleRegister = async (idToken: string) => {
    setGoogleLoading(true);
    setRegisterError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/auth/google`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken, deviceId: getDeviceId(), platform: 2 }),
      });
      const json: ApiEnvelope<AuthResponse> = await res.json();
      if (!json.success || !json.data) {
        setRegisterError(json.message ?? "Đăng nhập Google thất bại. Vui lòng thử lại.");
        return;
      }
      const { accessToken, refreshToken, userId, email: userEmail, fullName } = json.data;
      localStorage.setItem("sync_token", accessToken);
      localStorage.setItem("sync_refresh_token", refreshToken);
      localStorage.setItem("sync_user", JSON.stringify({ id: userId, email: userEmail, fullName }));
      router.push("/");
    } catch {
      setRegisterError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setGoogleLoading(false);
    }
  };

  // ── Step 1: Register ─────────────────────────────────────────────────────
  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setRegisterError("");
    setFieldErrors({});

    if (password !== confirmPassword) {
      setFieldErrors({ confirmPassword: "Mật khẩu xác nhận không khớp." });
      return;
    }

    setRegisterLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/v1/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fullName,
          email,
          password,
          deviceId: getDeviceId(),
          platform: 2,
        }),
      });

      const json: ApiEnvelope<RegisterData> = await res.json();

      if (!json.success) {
        if (json.errors) {
          // Map server field errors to Vietnamese
          const mapped: Record<string, string> = {};
          if (json.errors["Email"])    mapped.email    = json.errors["Email"][0];
          if (json.errors["Password"]) mapped.password = json.errors["Password"][0];
          if (json.errors["FullName"]) mapped.fullName = json.errors["FullName"][0];
          setFieldErrors(mapped);
        } else {
          if (res.status === 409) {
            setRegisterError("Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.");
          } else {
            setRegisterError(json.message ?? "Đã xảy ra lỗi. Vui lòng thử lại.");
          }
        }
        return;
      }

      // Success → move to OTP step
      setRegisteredEmail(email);
      setResendCooldown(60);
      setStep("verify");
    } catch {
      setRegisterError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setRegisterLoading(false);
    }
  };

  // ── Step 2: Verify OTP ───────────────────────────────────────────────────
  const handleVerify = async () => {
    if (otp.replace(/\s/g, "").length < 6) {
      setVerifyError("Vui lòng nhập đủ 6 chữ số.");
      return;
    }
    setVerifyLoading(true);
    setVerifyError("");
    try {
      const res = await fetch(
        `${API_BASE}/api/v1/auth/verify-email?token=${encodeURIComponent(otp.trim())}`,
        { method: "GET", headers: { Accept: "application/json" } },
      );

      const json: ApiEnvelope<VerifyData> = await res.json();

      if (!json.success) {
        if (res.status === 404) {
          setVerifyError("Mã xác nhận không đúng hoặc đã hết hạn. Vui lòng thử lại.");
        } else {
          setVerifyError(json.message ?? "Xác nhận thất bại. Vui lòng thử lại.");
        }
        return;
      }

      // Verified → redirect to login with success hint
      router.push("/login?verified=1");
    } catch {
      setVerifyError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setVerifyLoading(false);
    }
  };

  // ── Step 2: Resend code ──────────────────────────────────────────────────
  const handleResend = async () => {
    if (resendCooldown > 0) return;
    setResendLoading(true);
    setVerifyError("");
    try {
      await fetch(`${API_BASE}/api/v1/auth/resend-verification`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: registeredEmail }),
      });
      setOtp("");
      setResendCooldown(60);
    } catch {
      setVerifyError("Không thể gửi lại mã. Vui lòng thử lại sau.");
    } finally {
      setResendLoading(false);
    }
  };

  // ── Shared left panel ────────────────────────────────────────────────────
  const LeftPanel = (
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

      <div className="relative z-10">
        <Link href="/" className="inline-flex items-center gap-2">
          <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center">
            <Zap className="w-4 h-4 text-white fill-white" />
          </div>
          <span className="font-bold text-xl tracking-tight text-primary">SYNC</span>
        </Link>
      </div>

      <div className="relative z-10">
        {step === "verify" ? (
          <>
            <div className="w-16 h-16 bg-primary-50 rounded-2xl flex items-center justify-center mb-6">
              <Mail className="w-8 h-8 text-primary" />
            </div>
            <h2 className="text-4xl font-bold text-gray-900 tracking-tight leading-tight mb-4">
              Kiểm tra
              <br />
              <span className="text-primary">hộp thư của bạn.</span>
            </h2>
            <p className="text-gray-500 text-base leading-relaxed">
              Chúng tôi đã gửi mã xác nhận 6 chữ số đến{" "}
              <span className="font-semibold text-gray-700">{registeredEmail}</span>.
              <br /><br />
              Mã chỉ có hiệu lực một lần. Kiểm tra cả hộp thư rác nếu không thấy email.
            </p>
          </>
        ) : (
          <>
            <h2 className="text-4xl font-bold text-gray-900 tracking-tight leading-tight mb-4">
              Bắt đầu hành trình
              <br />
              <span className="text-primary">fitness thông minh.</span>
            </h2>
            <p className="text-gray-500 text-base mb-8 leading-relaxed">
              Tham gia cùng 50.000+ người đang tập luyện thông minh hơn mỗi ngày với AI Coach của SYNC.
            </p>
            {isPro ? (
              <div className="bg-primary-50 border border-primary/20 rounded-2xl p-5">
                <div className="flex items-center gap-2 mb-2">
                  <Crown className="w-4 h-4 text-primary" />
                  <span className="text-sm font-semibold text-primary">Gói Pro đã chọn</span>
                </div>
                <p className="text-gray-600 text-sm">
                  <span className="font-bold text-gray-900">99.000đ/tháng</span> · Hủy bất cứ lúc nào.
                  Hoàn thành đăng ký để kích hoạt.
                </p>
              </div>
            ) : (
              <div className="bg-gray-50 border border-gray-100 rounded-2xl p-5">
                <p className="text-sm font-semibold text-gray-700 mb-1">Gói Free — 0đ mãi mãi</p>
                <p className="text-gray-500 text-sm">Nâng cấp lên Pro bất cứ lúc nào để mở khóa toàn bộ tính năng AI.</p>
              </div>
            )}
          </>
        )}
      </div>

      <p className="relative z-10 text-xs text-gray-400">© 2026 SYNC. Tất cả quyền được bảo lưu.</p>
    </div>
  );

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen flex bg-white overflow-hidden">
      {LeftPanel}

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
          {step === "verify" ? (
            <button
              onClick={() => setStep("register")}
              className="flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Quay lại đăng ký
            </button>
          ) : (
            <Link href="/" className="flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 transition-colors">
              <ArrowLeft className="w-4 h-4" />
              Trang chủ
            </Link>
          )}
        </div>

        <div className="flex-1 flex items-center justify-center px-6 pb-12">
          <div className="w-full max-w-sm">
            {/* ══ Step 1: Register form ══════════════════════════════════════ */}
            {step === "register" && (
              <>
                <div className="mb-8">
                  <h1 className="text-2xl font-bold text-gray-900 mb-1">Tạo tài khoản</h1>
                  <p className="text-gray-500 text-sm">
                    Đã có tài khoản?{" "}
                    <Link href="/login" className="text-primary font-medium hover:underline">
                      Đăng nhập
                    </Link>
                  </p>
                </div>

                <form onSubmit={handleRegister} className="space-y-4">
                  {/* Full name */}
                  <div>
                    <label htmlFor="fullName" className="block text-sm font-medium text-gray-700 mb-1.5">
                      Họ và tên
                    </label>
                    <input
                      id="fullName"
                      type="text"
                      autoComplete="name"
                      autoFocus
                      required
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      placeholder="Nguyễn Văn A"
                      className={`w-full px-4 py-3 rounded-xl border bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all ${fieldErrors.fullName ? "border-red-300" : "border-gray-200"}`}
                    />
                    {fieldErrors.fullName && <p className="text-xs text-red-500 mt-1">{fieldErrors.fullName}</p>}
                  </div>

                  {/* Email */}
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1.5">
                      Email
                    </label>
                    <input
                      id="email"
                      type="email"
                      autoComplete="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="ten@email.com"
                      className={`w-full px-4 py-3 rounded-xl border bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all ${fieldErrors.email ? "border-red-300" : "border-gray-200"}`}
                    />
                    {fieldErrors.email && <p className="text-xs text-red-500 mt-1">{fieldErrors.email}</p>}
                  </div>

                  {/* Password */}
                  <div>
                    <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1.5">
                      Mật khẩu <span className="text-gray-400 font-normal">(tối thiểu 8 ký tự)</span>
                    </label>
                    <div className="relative">
                      <input
                        id="password"
                        type={showPassword ? "text" : "password"}
                        autoComplete="new-password"
                        required
                        minLength={8}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="••••••••"
                        className={`w-full px-4 py-3 pr-11 rounded-xl border bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all ${fieldErrors.password ? "border-red-300" : "border-gray-200"}`}
                      />
                      <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors" tabIndex={-1}>
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                    {fieldErrors.password && <p className="text-xs text-red-500 mt-1">{fieldErrors.password}</p>}
                  </div>

                  {/* Confirm password */}
                  <div>
                    <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-1.5">
                      Xác nhận mật khẩu
                    </label>
                    <div className="relative">
                      <input
                        id="confirmPassword"
                        type={showConfirm ? "text" : "password"}
                        autoComplete="new-password"
                        required
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Nhập lại mật khẩu"
                        className={`w-full px-4 py-3 pr-11 rounded-xl border bg-white text-gray-900 placeholder:text-gray-400 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/15 transition-all ${fieldErrors.confirmPassword ? "border-red-300" : "border-gray-200"}`}
                      />
                      <button type="button" onClick={() => setShowConfirm(!showConfirm)} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors" tabIndex={-1}>
                        {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                    {fieldErrors.confirmPassword && <p className="text-xs text-red-500 mt-1">{fieldErrors.confirmPassword}</p>}
                  </div>

                  {registerError && (
                    <p className="text-sm text-red-600 bg-red-50 border border-red-100 px-3 py-2.5 rounded-xl">
                      {registerError}
                    </p>
                  )}

                  <button
                    type="submit"
                    disabled={registerLoading}
                    className="w-full flex items-center justify-center gap-2 bg-primary text-white px-6 py-3.5 rounded-full font-medium hover:bg-primary-dark transition-colors disabled:opacity-60 disabled:cursor-not-allowed shadow-md shadow-primary/20 mt-2"
                  >
                    {registerLoading
                      ? <Loader2 className="w-4 h-4 animate-spin" />
                      : <ArrowRight className="w-4 h-4" />
                    }
                    {isPro ? "Đăng ký & kích hoạt gói Pro" : "Tạo tài khoản miễn phí"}
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
                    onSuccess={handleGoogleRegister}
                    onError={() => setRegisterError("Đăng nhập Google thất bại. Vui lòng thử lại.")}
                    text="signup_with"
                  />
                )}

                <p className="text-center text-xs text-gray-400 mt-6 leading-relaxed">
                  Bằng cách đăng ký, bạn đồng ý với{" "}
                  <Link href="#" className="underline hover:text-gray-600">Điều khoản dịch vụ</Link>{" "}
                  và{" "}
                  <Link href="#" className="underline hover:text-gray-600">Chính sách bảo mật</Link> của SYNC.
                </p>
              </>
            )}

            {/* ══ Step 2: OTP verification ═══════════════════════════════════ */}
            {step === "verify" && (
              <>
                <div className="mb-8">
                  <div className="w-12 h-12 bg-primary-50 rounded-2xl flex items-center justify-center mb-4">
                    <Mail className="w-6 h-6 text-primary" />
                  </div>
                  <h1 className="text-2xl font-bold text-gray-900 mb-2">Xác nhận email</h1>
                  <p className="text-gray-500 text-sm leading-relaxed">
                    Nhập mã 6 chữ số đã được gửi đến{" "}
                    <span className="font-semibold text-gray-700">{registeredEmail}</span>
                  </p>
                </div>

                <div className="space-y-6">
                  <OtpInput value={otp} onChange={setOtp} />

                  {verifyError && (
                    <p className="text-sm text-red-600 bg-red-50 border border-red-100 px-3 py-2.5 rounded-xl text-center">
                      {verifyError}
                    </p>
                  )}

                  <button
                    type="button"
                    onClick={handleVerify}
                    disabled={verifyLoading || otp.replace(/\s/g, "").length < 6}
                    className="w-full flex items-center justify-center gap-2 bg-primary text-white px-6 py-3.5 rounded-full font-medium hover:bg-primary-dark transition-colors disabled:opacity-60 disabled:cursor-not-allowed shadow-md shadow-primary/20"
                  >
                    {verifyLoading && <Loader2 className="w-4 h-4 animate-spin" />}
                    {verifyLoading ? "Đang xác nhận..." : "Xác nhận tài khoản"}
                  </button>

                  <div className="text-center">
                    <p className="text-sm text-gray-500 mb-2">Không nhận được mã?</p>
                    <button
                      type="button"
                      onClick={handleResend}
                      disabled={resendLoading || resendCooldown > 0}
                      className="inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline disabled:text-gray-400 disabled:no-underline transition-colors"
                    >
                      {resendLoading
                        ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
                        : <RefreshCw className="w-3.5 h-3.5" />
                      }
                      {resendCooldown > 0
                        ? `Gửi lại sau ${resendCooldown}s`
                        : "Gửi lại mã"
                      }
                    </button>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="flex-1 h-px bg-gray-200" />
                    <span className="text-xs text-gray-400">hoặc</span>
                    <div className="flex-1 h-px bg-gray-200" />
                  </div>

                  <button
                    type="button"
                    onClick={() => { setStep("register"); setOtp(""); setVerifyError(""); }}
                    className="w-full flex items-center justify-center gap-2 bg-white border border-gray-200 text-gray-600 px-6 py-3 rounded-full text-sm font-medium hover:bg-gray-50 transition-all"
                  >
                    <ArrowLeft className="w-4 h-4" />
                    Quay lại & chỉnh sửa email
                  </button>
                </div>

                {/* Step indicator */}
                <div className="flex items-center justify-center gap-2 mt-8">
                  <div className="flex items-center gap-1">
                    <span className="w-6 h-6 rounded-full bg-primary flex items-center justify-center">
                      <Check className="w-3.5 h-3.5 text-white" strokeWidth={3} />
                    </span>
                    <span className="text-xs text-gray-400">Tạo tài khoản</span>
                  </div>
                  <div className="w-6 h-px bg-gray-300" />
                  <div className="flex items-center gap-1">
                    <span className="w-6 h-6 rounded-full bg-primary/10 border-2 border-primary flex items-center justify-center">
                      <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    </span>
                    <span className="text-xs text-gray-700 font-medium">Xác nhận email</span>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function RegisterPage() {
  return (
    <Suspense>
      <RegisterForm />
    </Suspense>
  );
}
