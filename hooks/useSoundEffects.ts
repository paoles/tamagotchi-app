"use client";

import { useCallback, useRef, useState } from "react";

type SoundId = "feed" | "play" | "clean" | "sleep" | "wake" | "evolve" | "critical" | "death" | "event" | "rub";

export function useSoundEffects() {
  const [muted, setMuted] = useState(false);
  const audioCtxRef = useRef<AudioContext | null>(null);

  const getContext = useCallback(() => {
    if (!audioCtxRef.current) {
      audioCtxRef.current = new AudioContext();
    }
    return audioCtxRef.current;
  }, []);

  const playTone = useCallback((
    frequency: number,
    duration: number,
    type: OscillatorType = "square",
    volume: number = 0.1
  ) => {
    if (muted) return;
    try {
      const ctx = getContext();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = type;
      osc.frequency.value = frequency;
      gain.gain.value = volume;
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
      osc.connect(gain).connect(ctx.destination);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + duration);
    } catch { /* ignore audio errors */ }
  }, [muted, getContext]);

  const playSound = useCallback((id: SoundId) => {
    if (muted) return;
    switch (id) {
      case "feed":
        playTone(440, 0.1); setTimeout(() => playTone(554, 0.1), 100);
        break;
      case "play":
        playTone(523, 0.08); setTimeout(() => playTone(659, 0.08), 80); setTimeout(() => playTone(784, 0.15), 160);
        break;
      case "clean":
        playTone(330, 0.15, "sine");
        break;
      case "sleep":
        playTone(262, 0.3, "sine", 0.05);
        break;
      case "wake":
        playTone(523, 0.1); setTimeout(() => playTone(659, 0.15), 120);
        break;
      case "evolve":
        [0, 100, 200, 300].forEach((d, i) => setTimeout(() => playTone(440 + i * 110, 0.15), d));
        break;
      case "critical":
        playTone(200, 0.3, "sawtooth", 0.08);
        break;
      case "death":
        playTone(200, 0.5, "sawtooth", 0.05); setTimeout(() => playTone(150, 0.8, "sawtooth", 0.03), 500);
        break;
      case "event":
        playTone(600, 0.08); setTimeout(() => playTone(500, 0.08), 100);
        break;
      case "rub":
        playTone(320, 0.06, "sine", 0.06);
        break;
    }
  }, [muted, playTone]);

  return { playSound, muted, toggleMute: () => setMuted((m) => !m) };
}
