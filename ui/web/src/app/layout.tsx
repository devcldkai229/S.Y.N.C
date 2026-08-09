import type { Metadata } from "next";
import { Sora, DM_Sans } from "next/font/google";
import { Providers } from "@/lib/providers";
import "./globals.css";

const sora = Sora({
  variable: "--font-heading",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
});

const dmSans = DM_Sans({
  variable: "--font-sans",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "SYNC — Nền tảng fitness AI",
  description:
    "SYNC giúp bạn tập luyện thông minh hơn với AI coach, kế hoạch dinh dưỡng và cộng đồng đồng hành.",
  icons: {
    icon: [
      { url: "/images/favicon-32.png?v=3", sizes: "32x32", type: "image/png" },
      { url: "/images/favicon-48.png?v=3", sizes: "48x48", type: "image/png" },
      { url: "/favicon.ico?v=3", sizes: "16x16" },
      { url: "/favicon.svg?v=3", type: "image/svg+xml" },
    ],
    apple: [{ url: "/apple-icon.png?v=3", sizes: "180x180", type: "image/png" }],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="vi"
      className={`${sora.variable} ${dmSans.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-white font-sans">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
