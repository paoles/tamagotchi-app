"use client";

import { PetState } from "@/types/pet.types";
import { getPetMood } from "@/lib/petLogic";
import PetSprite from "./PetSprite";

interface PetProps {
  state: PetState;
  onEggClick?: () => void;
  eggHatchTimeRemaining?: number;
  actionAnimation?: string | null;
  onPetClick?: () => void;
}

export default function Pet({ state, onEggClick, eggHatchTimeRemaining, actionAnimation, onPetClick }: PetProps) {
  const mood = getPetMood(state);

  return (
    <div className="flex items-center justify-center p-2">
      <PetSprite
        mood={mood}
        stage={state.stage ?? "baby"}
        onEggClick={onEggClick}
        eggHatchTimeRemaining={eggHatchTimeRemaining}
        actionAnimation={actionAnimation}
        onPetClick={onPetClick}
      />
    </div>
  );
}
