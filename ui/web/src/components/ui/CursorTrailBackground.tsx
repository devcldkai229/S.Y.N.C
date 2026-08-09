"use client";

import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { cn } from "@/lib/utils";

/**
 * Antigravity-style cursor magnet trail.
 * Transparent canvas — particles orbit the cursor in concentric rings.
 * Galaxy palette; fixed mode portals to document.body so nothing can cover it.
 */

/** Cosmic nebula / galaxy accents */
const COLORS_GALAXY = [
  "#C4B5FD", // soft violet
  "#A78BFA", // violet
  "#818CF8", // indigo
  "#60A5FA", // blue
  "#38BDF8", // sky
  "#22D3EE", // cyan
  "#E879F9", // fuchsia
  "#F0ABFC", // pink
  "#FDBA74", // warm star
  "#E0E7FF", // starlight
];

const COLORS_LIGHT = COLORS_GALAXY;
const COLORS_DARK = [
  "#DDD6FE",
  "#C4B5FD",
  "#A5B4FC",
  "#7DD3FC",
  "#67E8F9",
  "#F0ABFC",
  "#F9A8D4",
  "#FDE68A",
  "#F8FAFC",
];

const MIN_SPACING = 76;
const MAGNET_RADIUS = 420;
const RING_RADII = [70, 110, 155, 210];
const WAVE_SPEED = 0.45;
const WAVE_AMPLITUDE = 24;
const LERP_SPEED = 0.1;
const PULSE_SPEED = 2.8;
const PARTICLE_VARIANCE = 2.2;
/** Cap particles — 500+ blocks the main thread and makes pages look stuck loading. */
const MAX_PARTICLES = 200;

interface Particle {
  homeX: number;
  homeY: number;
  cx: number;
  cy: number;
  t: number;
  speed: number;
  randomRadiusOffset: number;
  ringLayer: number;
  baseSize: number;
  colorRGB: [number, number, number];
  isDash: boolean;
}

function hexToRGB(hex: string): [number, number, number] {
  return [
    parseInt(hex.slice(1, 3), 16),
    parseInt(hex.slice(3, 5), 16),
    parseInt(hex.slice(5, 7), 16),
  ];
}

function rgba(rgb: [number, number, number], a: number): string {
  return `rgba(${rgb[0]},${rgb[1]},${rgb[2]},${a})`;
}

function poissonDiskSample(
  w: number,
  h: number,
  minDist: number,
  maxCount: number,
): Array<[number, number]> {
  const cellSize = minDist / Math.SQRT2;
  const gridW = Math.ceil(w / cellSize);
  const gridH = Math.ceil(h / cellSize);
  const grid: (number | null)[] = new Array(gridW * gridH).fill(null);
  const points: Array<[number, number]> = [];
  const active: number[] = [];

  const gridIndex = (x: number, y: number) =>
    Math.floor(x / cellSize) + Math.floor(y / cellSize) * gridW;

  const addPoint = (x: number, y: number) => {
    const i = points.length;
    points.push([x, y]);
    active.push(i);
    grid[gridIndex(x, y)] = i;
  };

  addPoint(Math.random() * w, Math.random() * h);

  const k = 30;
  while (active.length > 0 && points.length < maxCount) {
    const idx = Math.floor(Math.random() * active.length);
    const [px, py] = points[active[idx]];
    let found = false;

    for (let attempt = 0; attempt < k; attempt++) {
      const angle = Math.random() * Math.PI * 2;
      const r = minDist + Math.random() * minDist;
      const nx = px + Math.cos(angle) * r;
      const ny = py + Math.sin(angle) * r;

      if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;

      const gi = Math.floor(nx / cellSize);
      const gj = Math.floor(ny / cellSize);
      let tooClose = false;

      for (let di = -2; di <= 2 && !tooClose; di++) {
        for (let dj = -2; dj <= 2 && !tooClose; dj++) {
          const ci = gi + di;
          const cj = gj + dj;
          if (ci < 0 || ci >= gridW || cj < 0 || cj >= gridH) continue;
          const neighbor = grid[ci + cj * gridW];
          if (neighbor !== null) {
            const [npx, npy] = points[neighbor];
            const dx = nx - npx;
            const dy = ny - npy;
            if (dx * dx + dy * dy < minDist * minDist) tooClose = true;
          }
        }
      }

      if (!tooClose) {
        addPoint(nx, ny);
        found = true;
        break;
      }
    }

    if (!found) active.splice(idx, 1);
  }

  return points;
}

function createParticles(
  w: number,
  h: number,
  colors: string[],
): Particle[] {
  const margin = MAGNET_RADIUS;
  const extW = w + margin * 2;
  const extH = h + margin * 2;
  const positions = poissonDiskSample(extW, extH, MIN_SPACING, MAX_PARTICLES);

  return positions.map(([px, py]) => {
    const x = px - margin;
    const y = py - margin;
    const color = colors[Math.floor(Math.random() * colors.length)];
    return {
      homeX: x,
      homeY: y,
      cx: x,
      cy: y,
      t: Math.random() * 100,
      speed: 0.01 + Math.random() / 200,
      randomRadiusOffset: (Math.random() - 0.5) * 2,
      ringLayer: Math.floor(Math.random() * RING_RADII.length),
      baseSize: 8 + Math.random() * 7,
      colorRGB: hexToRGB(color),
      isDash: Math.random() < 0.6,
    };
  });
}

type Props = {
  className?: string;
  /** light = faint ambient on white; dark = brighter ambient on dark surfaces */
  variant?: "light" | "dark";
  /** fixed full-viewport overlay (landing) vs absolute fill parent (auth panels) */
  mode?: "fixed" | "absolute";
};

export default function CursorTrailBackground({
  className,
  variant = "light",
  mode = "absolute",
}: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef(0);
  const particlesRef = useRef<Particle[]>([]);
  const mouseRef = useRef({ x: -9999, y: -9999 });
  const virtualMouseRef = useRef({ x: -9999, y: -9999 });
  const sizeRef = useRef({ w: 0, h: 0 });
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduceMotion) return;

    const ctx = canvas.getContext("2d", { alpha: true });
    if (!ctx) return;

    const colors = variant === "dark" ? COLORS_DARK : COLORS_LIGHT;
    const ambientAlpha = variant === "dark" ? 0.55 : 0.5;
    const ringAlphaMax = variant === "dark" ? 0.98 : 1;

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const parent = canvas.parentElement;
      const w =
        mode === "fixed"
          ? window.innerWidth
          : parent?.clientWidth || window.innerWidth;
      const h =
        mode === "fixed"
          ? window.innerHeight
          : parent?.clientHeight || window.innerHeight;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      sizeRef.current = { w, h };
      particlesRef.current = createParticles(w, h, colors);
    };

    const onMouseMove = (e: MouseEvent) => {
      if (mode === "fixed") {
        mouseRef.current = { x: e.clientX, y: e.clientY };
        return;
      }
      const r = canvas.getBoundingClientRect();
      mouseRef.current = { x: e.clientX - r.left, y: e.clientY - r.top };
    };
    const onMouseLeave = () => {
      mouseRef.current = { x: -9999, y: -9999 };
    };
    const onTouchMove = (e: TouchEvent) => {
      const t = e.touches[0];
      if (!t) return;
      if (mode === "fixed") {
        mouseRef.current = { x: t.clientX, y: t.clientY };
        return;
      }
      const r = canvas.getBoundingClientRect();
      mouseRef.current = { x: t.clientX - r.left, y: t.clientY - r.top };
    };
    const onTouchEnd = () => {
      mouseRef.current = { x: -9999, y: -9999 };
    };

    const tick = () => {
      rafRef.current = requestAnimationFrame(tick);
      if (document.visibilityState === "hidden") return;

      const { w, h } = sizeRef.current;
      const mouse = mouseRef.current;
      const vMouse = virtualMouseRef.current;
      const particles = particlesRef.current;

      const smoothFactor = 0.08;
      if (mouse.x > -1000) {
        vMouse.x += (mouse.x - vMouse.x) * smoothFactor;
        vMouse.y += (mouse.y - vMouse.y) * smoothFactor;
      } else {
        vMouse.x = -9999;
        vMouse.y = -9999;
      }

      const targetX = vMouse.x;
      const targetY = vMouse.y;
      const mouseActive = targetX > -1000;

      ctx.clearRect(0, 0, w, h);

      for (let i = 0; i < particles.length; i++) {
        const p = particles[i];
        p.t += p.speed / 2;

        const dx = p.homeX - targetX;
        const dy = p.homeY - targetY;
        const dist = Math.sqrt(dx * dx + dy * dy);

        let destX = p.homeX;
        let destY = p.homeY;
        const myRingRadius = RING_RADII[p.ringLayer];

        if (mouseActive && dist < MAGNET_RADIUS) {
          const angle = Math.atan2(dy, dx);
          const wave = Math.sin(p.t * WAVE_SPEED + angle) * WAVE_AMPLITUDE;
          const deviation = p.randomRadiusOffset * 10;
          const currentRingRadius = myRingRadius + wave + deviation;
          destX = targetX + currentRingRadius * Math.cos(angle);
          destY = targetY + currentRingRadius * Math.sin(angle);
        }

        p.cx += (destX - p.cx) * LERP_SPEED;
        p.cy += (destY - p.cy) * LERP_SPEED;

        const curDistX = p.cx - targetX;
        const curDistY = p.cy - targetY;
        const currentDist = Math.sqrt(curDistX * curDistX + curDistY * curDistY);
        const distFromRing = Math.abs(currentDist - myRingRadius);

        let scaleFactor: number;
        if (mouseActive && dist < MAGNET_RADIUS) {
          scaleFactor = 1 - distFromRing / (myRingRadius * 0.5);
          scaleFactor = Math.max(0.05, Math.min(1, scaleFactor));
        } else {
          scaleFactor = 0.46;
        }

        const pulse = 0.8 + Math.sin(p.t * PULSE_SPEED) * 0.2 * PARTICLE_VARIANCE;
        const finalScale = scaleFactor * pulse;
        const drawSize = p.baseSize * finalScale;

        let alpha: number;
        if (mouseActive && dist < MAGNET_RADIUS) {
          alpha = scaleFactor * ringAlphaMax;
        } else {
          alpha = ambientAlpha;
        }

        if (drawSize < 0.2 || alpha < 0.01) continue;

        const angleToCenter = Math.atan2(targetY - p.cy, targetX - p.cx);

        // Glow only for cursor-active particles so ambient stays cheap.
        const glow = mouseActive && dist < MAGNET_RADIUS ? drawSize * 1.6 : 0;

        if (p.isDash) {
          const dashLen = drawSize * 3.5;
          const dashW = drawSize * 0.6;
          const r = dashW * 0.45;
          ctx.save();
          ctx.translate(p.cx, p.cy);
          ctx.rotate(angleToCenter + Math.PI / 2);
          ctx.shadowColor = rgba(p.colorRGB, alpha);
          ctx.shadowBlur = glow;
          ctx.fillStyle = rgba(p.colorRGB, alpha);
          ctx.beginPath();
          ctx.roundRect(-dashW / 2, -dashLen / 2, dashW, dashLen, r);
          ctx.fill();
          ctx.restore();
        } else {
          ctx.shadowColor = rgba(p.colorRGB, alpha);
          ctx.shadowBlur = glow;
          ctx.beginPath();
          ctx.arc(p.cx, p.cy, drawSize * 0.45, 0, Math.PI * 2);
          ctx.fillStyle = rgba(p.colorRGB, alpha);
          ctx.fill();
          ctx.shadowBlur = 0;
        }
      }
    };

    window.addEventListener("resize", resize);
    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseleave", onMouseLeave);
    window.addEventListener("touchmove", onTouchMove, { passive: true });
    window.addEventListener("touchend", onTouchEnd);

    // Defer heavy poisson sampling so first paint / route transitions stay responsive.
    const boot = window.setTimeout(() => {
      resize();
      rafRef.current = requestAnimationFrame(tick);
    }, 0);

    return () => {
      window.clearTimeout(boot);
      cancelAnimationFrame(rafRef.current);
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseleave", onMouseLeave);
      window.removeEventListener("touchmove", onTouchMove);
      window.removeEventListener("touchend", onTouchEnd);
    };
  }, [variant, mode, mounted]);

  const canvas = (
    <canvas
      ref={canvasRef}
      aria-hidden
      className={cn(
        "pointer-events-none",
        mode === "fixed"
          ? "fixed inset-0"
          : "absolute inset-0 z-[1]",
        className,
      )}
      style={
        mode === "fixed"
          ? {
              // Above page content, below sticky navbar (z-50) + dialogs/toasts (z-50–9999+).
              zIndex: 45,
              position: "fixed",
              inset: 0,
              width: "100vw",
              height: "100vh",
              pointerEvents: "none",
            }
          : undefined
      }
    />
  );

  // Portal to <body> so stacking contexts / transforms in the page cannot cover the trail.
  if (mode === "fixed") {
    if (!mounted) return null;
    return createPortal(canvas, document.body);
  }

  return canvas;
}
