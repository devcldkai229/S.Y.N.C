"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth.store";
import { api } from "@/services/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Zap, Loader2 } from "lucide-react";

interface LoginResponse {
  data: { token: string; user: { id: string; email: string; fullName: string; role: string } };
}

export default function AdminLoginPage() {
  const router = useRouter();
  const login  = useAuthStore((s) => s.login);

  const [email,    setEmail]    = useState("");
  const [password, setPassword] = useState("");
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      let deviceId = typeof window !== "undefined" ? localStorage.getItem("sync_device_id") : null;
      if (!deviceId && typeof window !== "undefined") {
        deviceId = Math.random().toString(36).substring(2) + Date.now().toString(36);
        localStorage.setItem("sync_device_id", deviceId);
      }
      deviceId = deviceId || "web-admin-default";

      const res = await api.post<LoginResponse>("/api/v1/auth/login", { 
        email, 
        password,
        deviceId,
        platform: "Web"
      });
      login(res.data.token, res.data.user);
      router.push("/admin/dashboard");
    } catch (err: any) {
      const errMsg = err?.response?.data?.message || err?.response?.data?.Message || err?.message || "Email hoặc mật khẩu không đúng. Vui lòng thử lại.";
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-muted flex items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center space-y-1">
          <div className="flex justify-center mb-2">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
              <Zap className="w-5 h-5 text-primary-foreground fill-current" />
            </div>
          </div>
          <CardTitle className="text-2xl font-bold">SYNC Admin</CardTitle>
          <CardDescription>Đăng nhập vào trang quản trị</CardDescription>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="admin@sync.vn"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoFocus
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Mật khẩu</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>

            {error && (
              <p className="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-md">
                {error}
              </p>
            )}

            <Button type="submit" className="w-full" disabled={loading}>
              {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
              Đăng nhập
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
