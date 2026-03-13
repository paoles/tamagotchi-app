import {
  PetState, PetMood, EvolutionStage, ActionType,
  LogEntry, RandomEvent,
} from "@/types/pet.types";
import {
  DECAY_RATES, STAGE_DECAY_MULTIPLIERS, SLEEP_DECAY_MULTIPLIER,
  ENERGY_DECAY_RATE, ENERGY_RECOVERY_RATE, LOW_ENERGY_THRESHOLD,
  LOW_ENERGY_ACTION_MULTIPLIER, OVERFEED_THRESHOLD, OVERFEED_HAPPINESS_PENALTY,
  EVOLUTION_STAGES, EVOLUTION_THRESHOLDS, DEATH_ZERO_STAT_DURATION,
  ACTION_COOLDOWNS, MAX_LOG_ENTRIES, RANDOM_EVENT_CHANCE, RANDOM_EVENTS,
  EGG_HATCH_BASE_MS, EGG_RUB_BONUS_MS, EGG_RUB_COOLDOWN_MS, EGG_MAX_RUB_BONUS_MS,
} from "./constants";

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function calculateDecay(
  currentValue: number,
  decayRate: number,
  elapsedMinutes: number
): number {
  return clamp(currentValue - decayRate * elapsedMinutes, 0, 100);
}

export function migrateState(state: PetState): PetState {
  return {
    ...state,
    energy: state.energy ?? 100,
    bornAt: state.bornAt ?? state.lastUpdated,
    stage: state.stage ?? "baby",
    isSleeping: state.isSleeping ?? false,
    isDead: state.isDead ?? false,
    log: state.log ?? [],
    cooldowns: state.cooldowns ?? {},
    careScore: state.careScore ?? 50,
    careSnapshots: state.careSnapshots ?? 0,
  };
}

export function applyTimeBasedDecay(
  state: PetState,
  currentTime: number
): PetState {
  if (state.isDead) return { ...state, lastUpdated: currentTime };
  if (state.stage === "egg") return { ...state, lastUpdated: currentTime };

  const elapsedMs = currentTime - state.lastUpdated;
  if (elapsedMs <= 0) return { ...state, lastUpdated: currentTime };
  const elapsedMinutes = elapsedMs / (1000 * 60);

  const stageMult = STAGE_DECAY_MULTIPLIERS[state.stage ?? "baby"] ?? 1;
  const sleepMult = state.isSleeping ? SLEEP_DECAY_MULTIPLIER : 1;
  const totalMult = stageMult * sleepMult;

  const newHunger = calculateDecay(state.hunger, DECAY_RATES.hunger * totalMult, elapsedMinutes);
  const newHappiness = calculateDecay(state.happiness, DECAY_RATES.happiness * totalMult, elapsedMinutes);
  const newHygiene = calculateDecay(state.hygiene, DECAY_RATES.hygiene * totalMult, elapsedMinutes);

  const energyRate = state.isSleeping ? -ENERGY_RECOVERY_RATE : ENERGY_DECAY_RATE;
  const newEnergy = clamp((state.energy ?? 100) - energyRate * elapsedMinutes, 0, 100);

  const autoWake = state.isSleeping && newEnergy >= 100;

  let result: PetState = {
    ...state,
    hunger: newHunger,
    happiness: newHappiness,
    hygiene: newHygiene,
    energy: newEnergy,
    isSleeping: autoWake ? false : state.isSleeping,
    lastUpdated: currentTime,
  };

  if (autoWake) {
    result = addLogEntry(result, "Woke up fully rested!", "event");
  }

  result = checkDeathCondition(result, currentTime);
  return result;
}

export function getPetMood(state: PetState): PetMood {
  if (state.isDead) return "dead";
  if (state.isSleeping) return "sleeping";
  if (state.stage === "egg") return "neutral";

  const energy = state.energy ?? 100;
  const minStat = Math.min(state.hunger, state.happiness, state.hygiene, energy);

  if (minStat < 10) return "critical";
  if (state.hunger < 30) return "hungry";
  if (state.happiness < 30) return "sad";
  if (state.hygiene < 30) return "dirty";
  if (minStat >= 70) return "happy";
  return "neutral";
}

export function applyStat(
  state: PetState,
  stat: "hunger" | "happiness" | "hygiene",
  amount: number,
  energyCost = 0,
  hygieneCost = 0
): PetState {
  if (state.isDead || state.isSleeping) return state;

  const energy = state.energy ?? 100;
  const effectiveMult = energy < LOW_ENERGY_THRESHOLD ? LOW_ENERGY_ACTION_MULTIPLIER : 1;
  const effectiveAmount = Math.round(amount * effectiveMult);

  let newState: PetState = {
    ...state,
    [stat]: clamp((state[stat] as number) + effectiveAmount, 0, 100),
    energy: clamp(energy - energyCost, 0, 100),
    hygiene: stat === "hygiene"
      ? clamp((state.hygiene) + effectiveAmount, 0, 100)
      : clamp(state.hygiene - hygieneCost, 0, 100),
    lastUpdated: Date.now(),
  };

  if (stat === "hunger" && state.hunger > OVERFEED_THRESHOLD) {
    newState = {
      ...newState,
      happiness: clamp(newState.happiness + OVERFEED_HAPPINESS_PENALTY, 0, 100),
    };
    newState = addLogEntry(newState, "Overfed! Feeling sluggish...", "warning");
  }

  return newState;
}


export function getEggHatchTimeRemaining(state: PetState, currentTime: number): number {
  if (state.stage !== "egg") return 0;
  const bornAt = state.bornAt ?? currentTime;
  const rubBonus = Math.min(state.eggRubBonus ?? 0, EGG_MAX_RUB_BONUS_MS);
  const hatchAt = bornAt + EGG_HATCH_BASE_MS - rubBonus;
  return Math.max(0, hatchAt - currentTime);
}

export function rubEgg(state: PetState, currentTime: number): PetState {
  if (state.stage !== "egg") return state;
  const lastRub = state.lastEggRub ?? 0;
  if (currentTime - lastRub < EGG_RUB_COOLDOWN_MS) return state;
  const current = state.eggRubBonus ?? 0;
  const newBonus = Math.min(current + EGG_RUB_BONUS_MS, EGG_MAX_RUB_BONUS_MS);
  return { ...state, eggRubBonus: newBonus, lastEggRub: currentTime };
}

export function checkEvolution(state: PetState, currentTime: number): EvolutionStage {
  // Egg hatches based on real elapsed time minus rub bonus
  if (state.stage === "egg") {
    return getEggHatchTimeRemaining(state, currentTime) <= 0 ? "baby" : "egg";
  }

  const ageMinutes = (currentTime - (state.bornAt ?? currentTime)) / 60000;
  const care = state.careScore ?? 50;
  const currentIdx = EVOLUTION_STAGES.indexOf(state.stage ?? "egg");

  for (let i = EVOLUTION_STAGES.length - 1; i > currentIdx; i--) {
    const threshold = EVOLUTION_THRESHOLDS[EVOLUTION_STAGES[i]];
    if (ageMinutes >= threshold.minAge && care >= threshold.minCare) {
      return EVOLUTION_STAGES[i];
    }
  }
  return state.stage ?? "egg";
}

export function checkDeathCondition(state: PetState, currentTime: number): PetState {
  if (state.isDead || state.stage === "egg") return state;

  const hasZeroStat = state.hunger <= 0 || state.happiness <= 0 ||
    state.hygiene <= 0 || (state.energy ?? 100) <= 0;

  if (hasZeroStat) {
    if (!state.zeroStatSince) {
      return { ...state, zeroStatSince: currentTime };
    }
    if (currentTime - state.zeroStatSince >= DEATH_ZERO_STAT_DURATION) {
      let dead: PetState = { ...state, isDead: true, deathTime: currentTime, zeroStatSince: undefined };
      dead = addLogEntry(dead, "Your pet has passed away...", "death");
      return dead;
    }
    return state;
  }

  if (state.zeroStatSince) {
    return { ...state, zeroStatSince: undefined };
  }
  return state;
}

export function updateCareScore(state: PetState): PetState {
  const currentAvg = (state.hunger + state.happiness + state.hygiene + (state.energy ?? 100)) / 4;
  const prevScore = state.careScore ?? 50;
  const prevSnapshots = state.careSnapshots ?? 0;
  const newSnapshots = prevSnapshots + 1;
  const newScore = (prevScore * prevSnapshots + currentAvg) / newSnapshots;
  return { ...state, careScore: newScore, careSnapshots: newSnapshots };
}

export function isOnCooldown(state: PetState, action: ActionType, currentTime: number): boolean {
  const lastUsed = state.cooldowns?.[action] ?? 0;
  const cooldownMs = ACTION_COOLDOWNS[action] ?? 0;
  return (currentTime - lastUsed) < cooldownMs;
}

export function getCooldownRemaining(state: PetState, action: ActionType, currentTime: number): number {
  const lastUsed = state.cooldowns?.[action] ?? 0;
  const cooldownMs = ACTION_COOLDOWNS[action] ?? 0;
  return Math.max(0, cooldownMs - (currentTime - lastUsed));
}

export function setCooldown(state: PetState, action: ActionType, currentTime: number): PetState {
  return {
    ...state,
    cooldowns: { ...(state.cooldowns ?? {}), [action]: currentTime },
  };
}

export function addLogEntry(state: PetState, message: string, type: LogEntry["type"]): PetState {
  const entry: LogEntry = { timestamp: Date.now(), message, type };
  const log = [...(state.log ?? []), entry].slice(-MAX_LOG_ENTRIES);
  return { ...state, log };
}

export function rollRandomEvent(): RandomEvent | null {
  if (Math.random() > RANDOM_EVENT_CHANCE) return null;
  return RANDOM_EVENTS[Math.floor(Math.random() * RANDOM_EVENTS.length)];
}

export function applyRandomEvent(state: PetState, event: RandomEvent): PetState {
  let result = { ...state };
  for (const [key, value] of Object.entries(event.effect)) {
    const statKey = key as "hunger" | "happiness" | "hygiene" | "energy";
    const current = statKey === "energy" ? (result.energy ?? 100) : (result[statKey] as number);
    result = { ...result, [statKey]: clamp(current + value, 0, 100) };
  }
  return addLogEntry(result, event.message, "event");
}

export function getPetAge(bornAt: number | undefined, currentTime: number): string {
  if (!bornAt) return "";
  const diffMs = currentTime - bornAt;
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  if (days > 0) return `${days}d ${hours % 24}h old`;
  if (hours > 0) return `${hours}h ${minutes % 60}m old`;
  return `${minutes}m old`;
}

export function getSpritePath(stage: EvolutionStage, mood: PetMood): string {
  if (stage === "egg") return "/sprites/egg.svg";
  if (mood === "dead") return `/sprites/${stage}/dead.svg`;
  if (mood === "sleeping") return `/sprites/${stage}/sleeping.svg`;
  return `/sprites/${stage}/${mood}.svg`;
}
