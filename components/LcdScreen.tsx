"use client";

import React from "react";

interface LcdScreenProps {
  children: React.ReactNode;
  className?: string;
  shake?: boolean;
}

export default function LcdScreen({ children, className = "", shake = false }: LcdScreenProps) {
  return (
    <div className={`lcd-screen ${shake ? "animate-shake" : ""} ${className}`}>
      {children}
      <div className="lcd-grid" aria-hidden="true" />
      <div className="lcd-inner-shadow" aria-hidden="true" />
    </div>
  );
}
