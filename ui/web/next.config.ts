import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Hide the floating Next.js "N" badge in `next dev` (never shown in production).
  devIndicators: false,
  // Static export → S3 + CloudFront (ui/web deploy-web job).
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
};

export default nextConfig;
