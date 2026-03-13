"use client";

import { useEffect, useCallback, useRef, useState } from "react";
import { PetState, ActionType } from "@/types/pet.types";
import { useLocalStorage } from "./useLocalStorage";
import { useStatDecay } from "./useStatDecay";
import {
  applyTimeBasedDecay, applyStat, migrateState, checkEvolution,
  isOnCooldown, setCooldown, addLogEntry, rollRandomEvent,
  applyRandomEvent, updateCareScore, getCooldownRemaining,
  rubEgg as rubEggFn, getEggHatchTimeRemaining,
} from "@/lib/petLogic";
import {
  STORAGE_KEY, DEFAULT_PET_STATE, ACTION_EFFECTS, ACTION_ENERGY_COSTS, ACTION_HYGIENE_COSTS,
  CARE_SNAPSHOT_INTERVAL,
} from "@/lib/constants";

export function usePetState() {
  const [petState, setPetState] = useLocalStorage<PetState>(
    STORAGE_KEY,
    { ...DEFAULT_PET_STATE, lastUpdated: Date.now(), stage: "egg" as const, energy: 100, bornAt: Date.now() }
  );

  const [showNamingDialog, setShowNamingDialog] = useState(false);
  const [activeEffect, setActiveEffect] = useState<string | null>(null);
  const [actionAnimation, setActionAnimation] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now());

  const petTapCooldownRef = useRef(0);

  const mountedRef = useRef(false);
  const lastCareSnapshot = useRef(Date.now());

  useEffect(() => {
    if (mountedRef.current) return;
    mountedRef.current = true;
    setPetState((prev) => {
      const migrated = migrateState(prev);
      return applyTimeBasedDecay(migrated, Date.now());
    });
  }, [setPetState]);

  useEffect(() => {
    const interval = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(interval);
  }, []);

  const extendedDecay = useCallback((prev: PetState): PetState => {
    if (prev.isDead) return prev;

    let state = applyTimeBasedDecay(prev, Date.now());

    if (Date.now() - lastCareSnapshot.current > CARE_SNAPSHOT_INTERVAL) {
      state = updateCareScore(state);
      lastCareSnapshot.current = Date.now();
    }

    const newStage = checkEvolution(state, Date.now());
    if (newStage !== state.stage) {
      state = { ...state, stage: newStage };
      state = addLogEntry(state, `Evolved to ${newStage}!`, "evolution");
    }

    if (!state.isSleeping && !state.isDead && state.stage !== "egg") {
      const event = rollRandomEvent();
      if (event) {
        state = applyRandomEvent(state, event);
      }
    }

    return state;
  }, []);

  useStatDecay(setPetState, extendedDecay);

  useEffect(() => {
    if (petState.stage !== "egg" && petState.stage !== undefined && !petState.name && !petState.isDead) {
      setShowNamingDialog(true);
    }
  }, [petState.stage, petState.name, petState.isDead]);

  const triggerActionAnimation = useCallback((animClass: string, durationMs: number) => {
    setActionAnimation(animClass);
    setTimeout(() => setActionAnimation(null), durationMs);
  }, []);

  const performAction = useCallback((
    action: ActionType,
    stat: "hunger" | "happiness" | "hygiene",
    amount: number,
    logMessage: string,
    effectId: string
  ) => {
    const currentTime = Date.now();
    setPetState((prev) => {
      if (prev.isDead || prev.isSleeping) return prev;
      if (isOnCooldown(prev, action, currentTime)) return prev;
      let state = applyStat(prev, stat, amount, ACTION_ENERGY_COSTS[action] ?? 0, ACTION_HYGIENE_COSTS[action] ?? 0);
      state = setCooldown(state, action, currentTime);
      state = addLogEntry(state, logMessage, "action");
      return state;
    });
    setActiveEffect(effectId);
    setTimeout(() => setActiveEffect(null), 800);
    if (action === "feed") triggerActionAnimation("animate-chew", 500);
    else if (action === "play") triggerActionAnimation("animate-jump", 400);
    else if (action === "clean") triggerActionAnimation("animate-spin-clean", 500);
  }, [setPetState, triggerActionAnimation]);

  const petTap = useCallback((): boolean => {
    if (Date.now() < petTapCooldownRef.current) return false;
    setPetState((prev) => {
      if (prev.isDead || prev.isSleeping || prev.stage === "egg") return prev;
      let state = { ...prev, happiness: Math.min(100, (prev.happiness ?? 0) + 5) };
      state = addLogEntry(state, "Got some pets! \u2764\uFE0F", "action");
      return state;
    });
    setActiveEffect("hearts");
    setTimeout(() => setActiveEffect(null), 800);
    triggerActionAnimation("animate-pet-tap", 500);
    petTapCooldownRef.current = Date.now() + 30_000;
    return true;
  }, [setPetState, triggerActionAnimation]);

  const feed = useCallback(() => {
    performAction("feed", "hunger", ACTION_EFFECTS.feed, "Fed the pet", "food");
  }, [performAction]);

  const play = useCallback(() => {
    performAction("play", "happiness", ACTION_EFFECTS.play, "Played with the pet", "stars");
  }, [performAction]);

  const clean = useCallback(() => {
    performAction("clean", "hygiene", ACTION_EFFECTS.clean, "Cleaned the pet", "bubbles");
  }, [performAction]);

  const sleep = useCallback(() => {
    setPetState((prev) => {
      if (prev.isDead || prev.isSleeping || prev.stage === "egg") return prev;
      if (isOnCooldown(prev, "sleep", Date.now())) return prev;
      let state: PetState = { ...prev, isSleeping: true };
      state = setCooldown(state, "sleep", Date.now());
      state = addLogEntry(state, "Pet went to sleep", "action");
      return state;
    });
  }, [setPetState]);

  const wake = useCallback(() => {
    setPetState((prev) => {
      if (!prev.isSleeping) return prev;
      if (isOnCooldown(prev, "wake", Date.now())) return prev;
      let state: PetState = { ...prev, isSleeping: false };
      state = setCooldown(state, "wake", Date.now());
      state = addLogEntry(state, "Pet woke up", "action");
      return state;
    });
  }, [setPetState]);

  const namePet = useCallback((name: string) => {
    setPetState((prev) => {
      let state = { ...prev, name: name.trim() };
      state = addLogEntry(state, `Named "${name.trim()}"`, "event");
      return state;
    });
    setShowNamingDialog(false);
  }, [setPetState]);


  const rubEggAction = useCallback(() => {
    const currentTime = Date.now();
    setPetState((prev) => {
      if (prev.stage !== "egg") return prev;
      return rubEggFn(prev, currentTime);
    });
  }, [setPetState]);

    const resetPet = useCallback(() => {
    const t = Date.now();
    setPetState({
      ...DEFAULT_PET_STATE, lastUpdated: t, bornAt: t, stage: "egg",
      energy: 100, isSleeping: false, isDead: false, log: [],
      cooldowns: {}, careScore: 50, careSnapshots: 0,
    } as PetState);
    setShowNamingDialog(false);
  }, [setPetState]);

  const eggHatchTimeRemaining = petState.stage === "egg"
    ? getEggHatchTimeRemaining(petState, now)
    : 0;

  const getCooldown = useCallback((action: ActionType) => {
    return getCooldownRemaining(petState, action, now);
  }, [petState, now]);

  return {
    petState, feed, play, clean, sleep, wake,
    resetPet, namePet, showNamingDialog, activeEffect, getCooldown,
    rubEgg: rubEggAction, eggHatchTimeRemaining,
    actionAnimation, petTap,
  };
}
