"use client";

import { useState, useEffect, useRef } from "react";
import { PetMood, EvolutionStage } from "@/types/pet.types";
import { getSpritePath } from "@/lib/petLogic";

const MOOD_LABELS: Record<PetMood, string> = {
  happy: "Your pet is thriving!",
  neutral: "Your pet is doing okay.",
  hungry: "Your pet is hungry!",
  sad: "Your pet is sad...",
  dirty: "Your pet needs a bath!",
  critical: "Your pet needs urgent care!",
  sleeping: "Zzz... sleeping peacefully.",
  dead: "Your pet has passed away...",
};

const STAGE_LABELS: Record<EvolutionStage, string> = {
  egg: "Egg",
  baby: "Baby",
  child: "Child",
  teen: "Teen",
  adult: "Adult",
};

const IDLE_ANIMATIONS = ["animate-blink", "animate-yawn", "animate-fidget"] as const;
const IDLE_DURATIONS: Record<string, number> = {
  "animate-blink": 250,
  "animate-yawn": 1500,
  "animate-fidget": 400,
};

interface PetSpriteProps {
  mood: PetMood;
  stage: EvolutionStage;
  onEggClick?: () => void;
  eggHatchTimeRemaining?: number;
  actionAnimation?: string | null;
  onPetClick?: () => void;
}

export default function PetSprite({ mood, stage, onEggClick, eggHatchTimeRemaining = 0, actionAnimation, onPetClick }: PetSpriteProps) {
  const [wiggling, setWiggling] = useState(false);
  const [idleAnim, setIdleAnim] = useState("");
  const idleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const idleClearRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const canIdle = stage !== "egg" && mood !== "dead" && mood !== "sleeping" && mood !== "critical";

  useEffect(() => {
    if (!canIdle) {
      setIdleAnim("");
      return;
    }

    const scheduleNext = () => {
      const delay = 4000 + Math.random() * 6000;
      idleTimerRef.current = setTimeout(() => {
        const anim = IDLE_ANIMATIONS[Math.floor(Math.random() * IDLE_ANIMATIONS.length)];
        setIdleAnim(anim);
        idleClearRef.current = setTimeout(() => {
          setIdleAnim("");
          scheduleNext();
        }, IDLE_DURATIONS[anim] + 50);
      }, delay);
    };

    scheduleNext();

    return () => {
      if (idleTimerRef.current) clearTimeout(idleTimerRef.current);
      if (idleClearRef.current) clearTimeout(idleClearRef.current);
    };
  }, [canIdle]);

  if (stage === "egg") {
    const seconds = Math.ceil(eggHatchTimeRemaining / 1000);
    const pct = Math.max(0, Math.min(100, (1 - eggHatchTimeRemaining / 60000) * 100));

    const handleClick = () => {
      onEggClick?.();
      setWiggling(true);
      setTimeout(() => setWiggling(false), 300);
    };

    return (
      <div className="flex flex-col items-center gap-2">
        <div className="text-xs font-mono text-[#3a7a50]">Egg</div>
        <button
          onClick={handleClick}
          className="cursor-pointer select-none active:scale-95 transition-transform focus:outline-none"
          title="Rub the egg!"
        >
          <img
            src="/sprites/egg.svg"
            alt="Tamagotchi egg"
            width={160}
            height={160}
            className={"pixelated drop-shadow-[0_2px_8px_rgba(0,80,40,0.3)] " + (wiggling ? "animate-wiggle" : "animate-bounce-slow")}
          />
        </button>
        {/* Progress bar */}
        <div className="w-32 h-1.5 bg-[#a8d8b8] rounded-full overflow-hidden">
          <div
            className="h-full bg-[#2a8a4a] rounded-full transition-all duration-500"
            style={{ width: pct + "%" }}
          />
        </div>
        <p className="text-sm font-mono text-[#1a4a2a] font-bold">
          {seconds > 0 ? "Hatching in " + seconds + "s..." : "Hatching!"}
        </p>
        <p className="text-xs font-mono text-[#3a7a50]">Rub the egg to speed it up!</p>
      </div>
    );
  }

  const spritePath = getSpritePath(stage, mood);

  // Animation priority: dead > sleeping > action > critical > mood-specific > idle > default
  let animClass: string;
  if (mood === "dead") {
    animClass = "opacity-50 grayscale";
  } else if (mood === "sleeping") {
    animClass = "animate-sleep-bob";
  } else if (actionAnimation) {
    animClass = actionAnimation;
  } else if (mood === "critical") {
    animClass = "animate-tremble";
  } else if (mood === "sad") {
    animClass = "animate-droop";
  } else if (mood === "hungry") {
    animClass = "animate-head-shake";
  } else if (idleAnim) {
    animClass = idleAnim;
  } else {
    animClass = "animate-bounce-slow";
  }

  const canClick = mood !== "dead" && mood !== "sleeping";

  return (
    <div className="flex flex-col items-center gap-3">
      <div className="text-xs font-mono text-[#3a7a50]">{STAGE_LABELS[stage]}</div>
      <div className="relative">
        <button
          onClick={canClick ? onPetClick : undefined}
          disabled={!canClick || !onPetClick}
          className="cursor-pointer select-none focus:outline-none disabled:cursor-default"
          title={canClick ? "Pet your pet!" : undefined}
        >
          <img
            src={spritePath}
            alt={"Tamagotchi pet - " + stage + " - " + mood}
            width={160}
            height={160}
            className={"pixelated drop-shadow-[0_2px_8px_rgba(0,80,40,0.3)] " + animClass}
          />
        </button>
      </div>
      <p className="text-sm font-mono text-[#3a7a50] animate-pulse">
        {MOOD_LABELS[mood]}
      </p>
    </div>
  );
}
