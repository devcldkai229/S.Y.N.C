"use client";

import { useEffect, useRef } from "react";

type Shape = "circle" | "square" | "triangle";

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  rotation: number;
  rotSpeed: number;
  depth: number;   // 0.3 – 1.0 → controls size, opacity, speed
  size: number;
  shape: Shape;
  alpha: number;
}

/* ── tunables ── */
const COUNT            = 85;
const INTERACTION_R    = 140;   // px — cursor repulsion radius
const PUSH             = 5;     // repulsion force multiplier
const FRICTION         = 0.955; // velocity decay per frame
const FLOAT_SPEED      = -0.012; // upward drift (negative = up)
const SHAPES: Shape[]  = ["circle", "square", "triangle"];

function drawShape(
  ctx: CanvasRenderingContext2D,
  shape: Shape,
  x: number,
  y: number,
  size: number,
  rot: number,
) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(rot);
  ctx.beginPath();
  switch (shape) {
    case "circle":
      ctx.arc(0, 0, size, 0, Math.PI * 2);
      break;
    case "square":
      ctx.rect(-size, -size, size * 2, size * 2);
      break;
    case "triangle":
      ctx.moveTo(0, -size * 1.3);
      ctx.lineTo(size * 1.1, size * 0.9);
      ctx.lineTo(-size * 1.1, size * 0.9);
      ctx.closePath();
      break;
  }
  ctx.fill();
  ctx.restore();
}

export default function ParticleCursor() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const pts       = useRef<Particle[]>([]);
  const mouse     = useRef({ x: -9999, y: -9999 });
  const raf       = useRef<number>(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    /* ── build particle grid ── */
    const init = () => {
      const w = canvas.offsetWidth;
      const h = canvas.offsetHeight;
      pts.current = Array.from({ length: COUNT }, () => {
        const depth = 0.25 + Math.random() * 0.75;
        return {
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.6,
          vy: (Math.random() - 0.5) * 0.6 - 0.15,
          rotation: Math.random() * Math.PI * 2,
          rotSpeed: (Math.random() - 0.5) * 0.025,
          depth,
          size: (2.5 + Math.random() * 5) * depth,
          shape: SHAPES[Math.floor(Math.random() * 3)],
          alpha: 0.18 + depth * 0.32,
        };
      });
    };

    /* ── size canvas ── */
    const resize = () => {
      canvas.width  = canvas.offsetWidth;
      canvas.height = canvas.offsetHeight;
      init();
    };
    resize();
    window.addEventListener("resize", resize);

    /* ── mouse tracking ── */
    const onMove = (e: MouseEvent) => {
      const r = canvas.getBoundingClientRect();
      mouse.current.x = e.clientX - r.left;
      mouse.current.y = e.clientY - r.top;
    };
    const onLeave = () => { mouse.current.x = -9999; mouse.current.y = -9999; };
    window.addEventListener("mousemove", onMove);
    canvas.parentElement?.addEventListener("mouseleave", onLeave);

    /* ── animation loop ── */
    const tick = () => {
      const w = canvas.offsetWidth;
      const h = canvas.offsetHeight;
      ctx.clearRect(0, 0, w, h);

      for (const p of pts.current) {
        /* cursor repulsion */
        const dx   = p.x - mouse.current.x;
        const dy   = p.y - mouse.current.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < INTERACTION_R && dist > 0) {
          const t     = 1 - dist / INTERACTION_R;
          const force = t * t * PUSH * p.depth;
          p.vx += (dx / dist) * force;
          p.vy += (dy / dist) * force;
        }

        /* float upward */
        p.vy += FLOAT_SPEED * p.depth;

        /* friction */
        p.vx *= FRICTION;
        p.vy *= FRICTION;

        p.x        += p.vx;
        p.y        += p.vy;
        p.rotation += p.rotSpeed;

        /* wrap around edges */
        if (p.x < -20)    p.x = w + 20;
        if (p.x > w + 20) p.x = -20;
        if (p.y < -20)    p.y = h + 20;
        if (p.y > h + 20) p.y = -20;

        /* depth-based shadow for 3-D feel */
        ctx.shadowColor = `rgba(26,131,68,${p.depth * 0.12})`;
        ctx.shadowBlur  = p.depth * 7;

        /* shade: displaced particles brighten toward primary green */
        const disp = Math.sqrt(
          (p.x - mouse.current.x) ** 2 + (p.y - mouse.current.y) ** 2,
        );
        const bright = dist < INTERACTION_R
          ? Math.min(1, (INTERACTION_R - dist) / 60)
          : 0;

        ctx.fillStyle = `rgba(26,131,68,${Math.min(1, p.alpha + bright * 0.45)})`;
        drawShape(ctx, p.shape, p.x, p.y, p.size + bright * 1.5, p.rotation);
      }

      /* reset shadow */
      ctx.shadowColor = "transparent";
      ctx.shadowBlur  = 0;

      raf.current = requestAnimationFrame(tick);
    };

    tick();

    return () => {
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", onMove);
      canvas.parentElement?.removeEventListener("mouseleave", onLeave);
      cancelAnimationFrame(raf.current);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden
      className="absolute inset-0 w-full h-full pointer-events-none z-[5]"
    />
  );
}
