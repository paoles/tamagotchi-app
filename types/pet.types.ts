export type EvolutionStage = "egg" | "baby" | "child" | "teen" | "adult";

export type PetMood =
  | "happy"
  | "neutral"
  | "hungry"
  | "sad"
  | "dirty"
  | "critical"
  | "sleeping"
  | "dead";

export type ActionType = "feed" | "play" | "clean" | "sleep" | "wake";

export interface LogEntry {
  timestamp: number;
  message: string;
  type: "action" | "evolution" | "event" | "warning" | "death";
}

export interface RandomEvent {
  id: string;
  message: string;
  effect: Partial<Record<"hunger" | "happiness" | "hygiene" | "energy", number>>;
}

export interface PetState {
  hunger: number;
  happiness: number;
  hygiene: number;
  lastUpdated: number;
  energy?: number;
  name?: string;
  bornAt?: number;
  stage?: EvolutionStage;
  isSleeping?: boolean;
  isDead?: boolean;
  deathTime?: number;
  zeroStatSince?: number;
  cooldowns?: Record<string, number>;
  log?: LogEntry[];
  careScore?: number;
  careSnapshots?: number;
  eggRubBonus?: number;  // accumulated ms shaved off hatch time
  lastEggRub?: number;   // timestamp of last rub (for rate limiting)
}

export interface StatBarProps {
  label?: string;
  value: number;
  icon: string;
  flashWarning?: boolean;
}

export interface ActionButtonProps {
  label: string;
  onClick: () => void;
  icon: string;
  disabled?: boolean;
  cooldownRemaining?: number;
  cooldownMax?: number;
}
