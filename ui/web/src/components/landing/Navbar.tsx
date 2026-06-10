"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Menu, X, Zap, User, LogOut, ChevronDown } from "lucide-react";

interface SyncUser {
  id: string;
  email: string;
  fullName: string;
}

const navLinks = [
  { label: "Features",     href: "/#features" },
  { label: "How it works", href: "/#how-it-works" },
  { label: "Testimonials", href: "/#testimonials" },
  { label: "Pricing",      href: "/subscription" },
];

export default function Navbar() {
  const router = useRouter();
  const [isOpen, setIsOpen]       = useState(false);
  const [user, setUser]           = useState<SyncUser | null>(null);
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Read auth state from localStorage after mount (client-only)
  useEffect(() => {
    const raw = localStorage.getItem("sync_user");
    if (raw) {
      try { setUser(JSON.parse(raw) as SyncUser); } catch { /* ignore */ }
    }

    // Close dropdown on outside click
    const handler = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("sync_token");
    localStorage.removeItem("sync_refresh_token");
    localStorage.removeItem("sync_user");
    setUser(null);
    setDropdownOpen(false);
    router.push("/");
  };

  // Initials avatar from fullName
  const initials = user?.fullName
    ? user.fullName.trim().split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase()
    : "U";

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/90 backdrop-blur-md border-b border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">

          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <Zap className="w-4 h-4 text-white fill-white" />
            </div>
            <span className="font-bold text-xl tracking-tight text-primary">SYNC</span>
          </Link>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((item) => (
              <Link
                key={item.label}
                href={item.href}
                className="text-sm text-gray-500 hover:text-gray-900 transition-colors"
              >
                {item.label}
              </Link>
            ))}
          </div>

          {/* Desktop CTA / User menu */}
          <div className="hidden md:flex items-center gap-4">
            {user ? (
              <div className="relative" ref={dropdownRef}>
                <button
                  onClick={() => setDropdownOpen(!dropdownOpen)}
                  className="flex items-center gap-2 pl-1 pr-3 py-1 rounded-full hover:bg-gray-100 transition-colors"
                >
                  {/* Avatar */}
                  <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white text-xs font-bold shrink-0">
                    {initials}
                  </div>
                  <span className="text-sm font-medium text-gray-700 max-w-[120px] truncate">
                    {user.fullName}
                  </span>
                  <ChevronDown className={`w-3.5 h-3.5 text-gray-400 transition-transform ${dropdownOpen ? "rotate-180" : ""}`} />
                </button>

                {/* Dropdown */}
                {dropdownOpen && (
                  <div className="absolute right-0 top-full mt-2 w-56 bg-white rounded-2xl shadow-lg border border-gray-100 py-1.5 overflow-hidden">
                    {/* User info */}
                    <div className="px-4 py-3 border-b border-gray-50">
                      <p className="text-sm font-semibold text-gray-900 truncate">{user.fullName}</p>
                      <p className="text-xs text-gray-400 truncate mt-0.5">{user.email}</p>
                    </div>

                    <div className="py-1">
                      <Link
                        href="/profile"
                        onClick={() => setDropdownOpen(false)}
                        className="flex items-center gap-2.5 px-4 py-2.5 text-sm text-gray-600 hover:bg-gray-50 hover:text-gray-900 transition-colors"
                      >
                        <User className="w-4 h-4" />
                        Hồ sơ của tôi
                      </Link>
                      <Link
                        href="/subscription"
                        onClick={() => setDropdownOpen(false)}
                        className="flex items-center gap-2.5 px-4 py-2.5 text-sm text-gray-600 hover:bg-gray-50 hover:text-gray-900 transition-colors"
                      >
                        <Zap className="w-4 h-4" />
                        Nâng cấp gói
                      </Link>
                    </div>

                    <div className="border-t border-gray-50 pt-1">
                      <button
                        onClick={handleLogout}
                        className="flex items-center gap-2.5 w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-50 transition-colors"
                      >
                        <LogOut className="w-4 h-4" />
                        Đăng xuất
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <>
                <Link href="/login" className="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                  Sign in
                </Link>
                <Link
                  href="/register"
                  className="text-sm bg-primary text-white px-5 py-2 rounded-full hover:bg-primary-dark transition-colors font-medium"
                >
                  Get started
                </Link>
              </>
            )}
          </div>

          {/* Mobile menu button */}
          <button onClick={() => setIsOpen(!isOpen)} className="md:hidden p-2 text-gray-600">
            {isOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {isOpen && (
        <div className="md:hidden bg-white border-t border-gray-100 px-4 py-4 space-y-3">
          {navLinks.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              className="block text-gray-600 py-1"
              onClick={() => setIsOpen(false)}
            >
              {item.label}
            </Link>
          ))}

          {user ? (
            <div className="pt-2 border-t border-gray-100 space-y-2">
              {/* Mobile user info */}
              <div className="flex items-center gap-3 py-2">
                <div className="w-9 h-9 rounded-full bg-primary flex items-center justify-center text-white text-xs font-bold shrink-0">
                  {initials}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-semibold text-gray-900 truncate">{user.fullName}</p>
                  <p className="text-xs text-gray-400 truncate">{user.email}</p>
                </div>
              </div>
              <Link
                href="/profile"
                className="flex items-center gap-2 text-gray-600 py-1.5 text-sm"
                onClick={() => setIsOpen(false)}
              >
                <User className="w-4 h-4" /> Hồ sơ của tôi
              </Link>
              <button
                onClick={() => { handleLogout(); setIsOpen(false); }}
                className="flex items-center gap-2 text-red-500 py-1.5 text-sm w-full"
              >
                <LogOut className="w-4 h-4" /> Đăng xuất
              </button>
            </div>
          ) : (
            <Link
              href="/register"
              className="block w-full text-center bg-primary text-white px-4 py-2.5 rounded-full font-medium mt-2"
              onClick={() => setIsOpen(false)}
            >
              Get started
            </Link>
          )}
        </div>
      )}
    </nav>
  );
}
