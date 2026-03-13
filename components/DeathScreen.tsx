"use client";

import { PetState } from "@/types/pet.types";
import { getPetAge } from "@/lib/petLogic";

interface DeathScreenProps {
  petState: PetState;
  onReset: () => void;
}

export default function DeathScreen({ petState, onReset }: DeathScreenProps) {
  const age = getPetAge(petState.bornAt, petState.deathTime ?? Date.now());

  return (
    <div className="flex flex-col items-center gap-6 w-full max-w-sm mx-auto">
      <div className="w-full bg-gray-900 border-2 border-gray-700 rounded-3xl p-8 shadow-[0_0_30px_rgba(0,0,0,0.5)] text-center">
        <div className="text-6xl mb-4 opacity-50">&#x1F480;</div>
        <h2 className="text-xl font-mono text-red-400 mb-2">Rest in Peace</h2>
        {petState.name && (
          <p className="text-lg font-mono text-white mb-1">{petState.name}</p>
        )}
        <p className="text-sm font-mono text-gray-500 mb-6">Lived for {age}</p>
        <div className="border-t border-gray-700 pt-4 mt-4">
          <p className="text-xs font-mono text-gray-500 mb-2">
            Care Score: {Math.round(petState.careScore ?? 0)}%
          </p>
          <p className="text-xs font-mono text-gray-500 mb-4">
            Final Stage: {petState.stage}
          </p>
        </div>
        <button
          onClick={onReset}
          className="px-8 py-3 bg-gray-800 hover:bg-gray-700 border-2 border-gray-600 hover:border-gray-400 rounded-xl font-mono text-white transition-all cursor-pointer"
        >
          Start New Egg
        </button>
      </div>
    </div>
  );
}
