"use client";

interface ActionEffectsProps {
  effectId: string;
}

const EFFECT_PARTICLES: Record<string, { emoji: string; count: number }> = {
  hearts:  { emoji: "\u2764\uFE0F", count: 5 },
  stars:   { emoji: "\u2B50", count: 6 },
  bubbles: { emoji: "\uD83E\uDEE7", count: 4 },
};

export default function ActionEffects({ effectId }: ActionEffectsProps) {
  const config = EFFECT_PARTICLES[effectId];
  if (!config) return null;

  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      {Array.from({ length: config.count }).map((_, i) => (
        <span
          key={i}
          className="absolute animate-float-up text-xl"
          style={{
            left: `${20 + Math.random() * 60}%`,
            bottom: "20%",
            animationDelay: `${i * 0.12}s`,
            animationDuration: `${0.6 + Math.random() * 0.4}s`,
          }}
        >
          {config.emoji ?? FOOD_EMOJIS[i % FOOD_EMOJIS.length]}
        </span>
      ))}
    </div>
  );
}
