"use client";

import { useEffect, useRef, useState } from "react";
import { ActionButtonProps } from "@/types/pet.types";

export default function ActionButton({ label, onClick, icon, disabled, cooldownRemaining, cooldownMax }: ActionButtonProps) {
  const [barPct, setBarPct] = useState(0);
  const rafRef = useRef<number>(0);
  const endTimeRef = useRef<number>(0);

  useEffect(() => {
    if (cooldownRemaining && cooldownRemaining > 0 && cooldownMax) {
      endTimeRef.current = Date.now() + cooldownRemaining;
      const tick = () => {
        const remaining = endTimeRef.current - Date.now();
        if (remaining <= 0) {
          setBarPct(0);
          return;
        }
        setBarPct((remaining / cooldownMax) * 100);
        rafRef.current = requestAnimationFrame(tick);
      };
      cancelAnimationFrame(rafRef.current);
      rafRef.current = requestAnimationFrame(tick);
    } else {
      setBarPct(0);
      cancelAnimationFrame(rafRef.current);
    }
    return () => cancelAnimationFrame(rafRef.current);
  }, [cooldownRemaining, cooldownMax]);

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`device-button${disabled ? " device-button-disabled" : ""}`}
    >
      <span className="text-xl leading-none">{icon}</span>
      <span className="device-button-label">{label}</span>
      <div className="device-button-cd-bar" style={{ width: `${barPct}%` }} />
    </button>
  );
}
