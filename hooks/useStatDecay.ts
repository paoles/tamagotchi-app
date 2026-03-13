"use client";

import { useEffect } from "react";
import { PetState } from "@/types/pet.types";
import { applyTimeBasedDecay } from "@/lib/petLogic";
import { TICK_INTERVAL } from "@/lib/constants";

export function useStatDecay(
  setPetState: (updater: (prev: PetState) => PetState) => void,
  customDecayFn?: (prev: PetState) => PetState
) {
  useEffect(() => {
    const decayFn = customDecayFn ?? ((prev: PetState) => applyTimeBasedDecay(prev, Date.now()));
    const interval = setInterval(() => {
      setPetState(decayFn);
    }, TICK_INTERVAL);

    return () => clearInterval(interval);
  }, [setPetState, customDecayFn]);
}
