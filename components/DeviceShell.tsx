"use client";

import React, { useRef, useEffect } from "react";

export default function DeviceShell({ children }: { children: React.ReactNode }) {
  const outerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = outerRef.current;
    if (!el) return;

    let rafId: number | null = null;

    const applyZoom = () => {
      if (!el) return;
      if (rafId !== null) cancelAnimationFrame(rafId);

      // Reset to natural size
      el.style.zoom = "1";

      // On mobile (≤480px), CSS handles fluid layout — skip zoom
      if (window.innerWidth <= 480) return;

      rafId = requestAnimationFrame(() => {
        rafId = null;
        const availH = window.innerHeight - 8;
        const availW = window.innerWidth - 8;

        // Pass 1: measure at zoom=1 and compute initial scale
        const naturalH = el.offsetHeight;
        const naturalW = el.offsetWidth;
        const scaleH = naturalH > availH ? availH / naturalH : 1;
        const scaleW = naturalW > availW ? availW / naturalW : 1;
        const scale1 = Math.min(scaleH, scaleW);

        if (scale1 >= 1) {
          el.style.zoom = "1";
          return;
        }

        el.style.zoom = String(scale1);

        // Pass 2: content may reflow at the new (narrower) zoomed width.
        // Read the actual rendered size and correct if still overflowing.
        rafId = requestAnimationFrame(() => {
          rafId = null;
          const r = el.getBoundingClientRect();
          const overH = r.height / availH;
          const overW = r.width / availW;
          const over = Math.max(overH, overW);
          if (over > 1) {
            el.style.zoom = String(scale1 / over);
          }
        });
      });
    };

    applyZoom();
    window.addEventListener("resize", applyZoom);
    return () => {
      window.removeEventListener("resize", applyZoom);
      if (rafId !== null) cancelAnimationFrame(rafId);
    };
  }, []);

  return (
    <div ref={outerRef} className="device-shell-outer">
      {/* Lanyard loop attachment point */}
      <div className="device-lanyard" />

      {/* Main plastic body */}
      <div className="device-body">
        {/* Corner Phillips screws */}
        <div className="device-screw device-screw-tl" />
        <div className="device-screw device-screw-tr" />
        <div className="device-screw device-screw-bl" />
        <div className="device-screw device-screw-br" />

        {/* Brand header */}
        <div className="device-header">
          <span className="device-logo">TAMAGOTCHI</span>
        </div>

        {/* Game content slot */}
        <div className="device-content">
          {children}
        </div>

        {/* Bottom padding zone */}
        <div className="device-footer" />
      </div>
    </div>
  );
}
