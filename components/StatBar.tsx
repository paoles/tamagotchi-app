"use client";

import { StatBarProps } from "@/types/pet.types";

const RADIUS = 26;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

function getColor(value: number): string {
  if (value >= 60) return "#22c55e";
  if (value >= 30) return "#eab308";
  return "#ef4444";
}

function getTrackColor(value: number): string {
  if (value >= 60) return "rgba(34,197,94,0.18)";
  if (value >= 30) return "rgba(234,179,8,0.18)";
  return "rgba(239,68,68,0.18)";
}

export default function StatBar({ value, icon, flashWarning }: StatBarProps) {
  const rounded = Math.round(value);
  const dashOffset = CIRCUMFERENCE * (1 - rounded / 100);
  const color = getColor(rounded);
  const trackColor = getTrackColor(rounded);

  return (
    <div className={`flex flex-col items-center gap-1 ${flashWarning ? "animate-pulse-red" : ""}`}>
      <div className="relative" style={{ width: 64, height: 64 }}>
        <svg
          width="64"
          height="64"
          viewBox="0 0 64 64"
          style={{ transform: "rotate(-90deg)", display: "block" }}
        >
          <circle
            cx="32"
            cy="32"
            r={RADIUS}
            fill="none"
            stroke={trackColor}
            strokeWidth="5"
          />
          <circle
            cx="32"
            cy="32"
            r={RADIUS}
            fill="none"
            stroke={color}
            strokeWidth="5"
            strokeDasharray={CIRCUMFERENCE}
            strokeDashoffset={dashOffset}
            strokeLinecap="round"
            style={{ transition: "stroke-dashoffset 0.5s ease-out, stroke 0.3s" }}
          />
        </svg>
        <div
          className="absolute inset-0 flex items-center justify-center"
          style={{ fontSize: "1.35rem", lineHeight: 1 }}
        >
          {icon}
        </div>
      </div>
      <span className="font-mono" style={{ color, fontSize: "0.6rem" }}>
        {rounded}%
      </span>
    </div>
  );
}
