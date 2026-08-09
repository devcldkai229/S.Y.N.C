import Image from "next/image";
import { cn } from "@/lib/utils";

type SyncLogoProps = {
  className?: string;
  /** Pixel height for next/image sizing. Default 32. */
  height?: number;
  priority?: boolean;
};

/** Brand wordmark from `public/images/sync_logo.png` (includes SYNC text + mark). */
export function SyncLogo({ className, height = 32, priority = false }: SyncLogoProps) {
  const width = Math.round(height * 3.4);
  return (
    <Image
      src="/images/sync_logo.png"
      alt="SYNC"
      width={width}
      height={height}
      priority={priority}
      // CSS may override height (h-8, h-9…); keep aspect ratio for next/image.
      style={{ width: "auto" }}
      className={cn("h-8 w-auto max-w-none object-contain", className)}
    />
  );
}
