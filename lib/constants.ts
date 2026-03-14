import { RandomEvent } from "@/types/pet.types";

export const DECAY_RATES = {
  hunger: 1,
  happiness: 0.5,
  hygiene: 0.3,
} as const;

export const ACTION_EFFECTS = {
  feed: 35,
  play: 25,
  clean: 30,
} as const;

export const TICK_INTERVAL = 10_000;
export const STORAGE_KEY = "tamagotchi-pet-state";

export const DEFAULT_PET_STATE = {
  hunger: 80,
  happiness: 80,
  hygiene: 80,
  lastUpdated: Date.now(),
} as const;

// Energy
export const ENERGY_DECAY_RATE = 0.4;
export const ENERGY_RECOVERY_RATE = 3.5;
export const SLEEP_DECAY_MULTIPLIER = 0.3;
export const LOW_ENERGY_THRESHOLD = 20;
export const LOW_ENERGY_ACTION_MULTIPLIER = 0.5;

// Egg hatching
export const EGG_HATCH_BASE_MS = 60_000;    // 1 minute base hatch time
export const EGG_RUB_BONUS_MS = 3_000;      // each rub shaves 3s off
export const EGG_RUB_COOLDOWN_MS = 500;     // max 2 rubs/sec
export const EGG_MAX_RUB_BONUS_MS = 45_000; // cap: can't skip more than 45s

// Evolution
export const EVOLUTION_STAGES = ["egg", "baby", "child", "teen", "adult"] as const;

export const EVOLUTION_THRESHOLDS = {
  egg:   { minAge: 0,  minCare: 0 },
  baby:  { minAge: 2,  minCare: 0 },
  child: { minAge: 10, minCare: 40 },
  teen:  { minAge: 30, minCare: 50 },
  adult: { minAge: 60, minCare: 60 },
} as const;

export const STAGE_DECAY_MULTIPLIERS: Record<string, number> = {
  egg: 0,
  baby: 1.5,
  child: 1.2,
  teen: 1.0,
  adult: 0.8,
};

// Energy costs per action
export const ACTION_ENERGY_COSTS: Record<string, number> = {
  feed: 2,
  play: 6,
  clean: 0,
};

// Hygiene costs per action (eating is messy, playing gets dirty)
export const ACTION_HYGIENE_COSTS: Record<string, number> = {
  feed: 5,
  play: 10,
};

// Cooldowns (ms)
export const ACTION_COOLDOWNS: Record<string, number> = {
  feed: 5_000,
  play: 8_000,
  clean: 6_000,
  sleep: 3_000,
  wake: 3_000,
};

// Overfeeding
export const OVERFEED_THRESHOLD = 90;
export const OVERFEED_HAPPINESS_PENALTY = -10;

// Death
export const DEATH_ZERO_STAT_DURATION = 3 * 60 * 1000;

// Random events
export const RANDOM_EVENT_CHANCE = 0.05;
export const RANDOM_EVENTS: RandomEvent[] = [
  { id: "found_toy",      message: "Found a toy!",               effect: { happiness: 10 } },
  { id: "sneezed",        message: "Achoo! Sneezed!",            effect: { hygiene: -8 } },
  { id: "found_snack",    message: "Found a snack!",             effect: { hunger: 8 } },
  { id: "got_scared",     message: "Heard a loud noise!",        effect: { happiness: -5 } },
  { id: "nap_bonus",      message: "Had a power nap!",           effect: { energy: 5 } },
  { id: "mud_splash",     message: "Rolled in the mud!",         effect: { hygiene: -12, happiness: 8 } },
  { id: "made_friend",    message: "Made an imaginary friend!",  effect: { happiness: 15 } },
  { id: "tummy_ache",     message: "Tummy ache...",              effect: { hunger: -10 } },
  { id: "sunny_day",      message: "It's a beautiful day!",      effect: { happiness: 8 } },
  { id: "bad_dream",      message: "Had a bad dream!",           effect: { happiness: -8 } },
  { id: "found_treat",    message: "Found a hidden treat!",      effect: { hunger: 12, happiness: 5 } },
  { id: "stretch",        message: "Did some stretching!",       effect: { energy: 5 } },
  { id: "spilled_food",   message: "Spilled some food...",       effect: { hunger: -5, hygiene: -8 } },
  { id: "got_hiccups",    message: "Got the hiccups!",           effect: { happiness: -5 } },
  { id: "found_treasure", message: "Found something shiny!",     effect: { happiness: 5 } },
];

// Activity log
export const MAX_LOG_ENTRIES = 15;

// Care score
export const CARE_SNAPSHOT_INTERVAL = 60_000;
