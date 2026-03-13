"use client";

import { useState } from "react";
import { usePetState } from "@/hooks/usePetState";
import { useSoundEffects } from "@/hooks/useSoundEffects";
import { getPetMood, getPetAge } from "@/lib/petLogic";
import { ACTION_COOLDOWNS } from "@/lib/constants";
import Pet from "./Pet";
import StatBar from "./StatBar";
import ActionButton from "./ActionButton";
import ActivityLog from "./ActivityLog";
import ActionEffects from "./ActionEffects";
import MuteButton from "./MuteButton";
import LcdScreen from "./LcdScreen";

export default function GameContainer() {
  const {
    petState, feed, play, clean, sleep, wake,
    resetPet, namePet, showNamingDialog,
    activeEffect, getCooldown, rubEgg, eggHatchTimeRemaining,
    actionAnimation, petTap,
  } = usePetState();

  const [nameInput, setNameInput] = useState("");
  const [showLog, setShowLog] = useState(false);
  const { playSound, muted, toggleMute } = useSoundEffects();

  const mood = getPetMood(petState);
  const isEgg = petState.stage === "egg";
  const isSleeping = petState.isSleeping;

  const handleRubEgg = () => { rubEgg(); playSound("rub"); };
  const handlePetTap = () => { if (petTap()) playSound("play"); };
  const handleFeed = () => { feed(); playSound("feed"); };
  const handlePlay = () => { play(); playSound("play"); };
  const handleClean = () => { clean(); playSound("clean"); };
  const handleSleep = () => { sleep(); playSound("sleep"); };
  const handleWake = () => { wake(); playSound("wake"); };
  const handleNamePet = (name: string) => { namePet(name); setNameInput(""); };

  return (
    <div className="flex flex-col items-center w-full h-full">
      <div className="w-full p-4 relative overflow-hidden flex flex-col flex-1">

        {/* Death overlay — covers card without resizing it */}
        {petState.isDead && (
          <div className="absolute inset-0 bg-gray-900 rounded-3xl z-20 flex flex-col items-center justify-center text-center p-8">
            <div className="text-6xl mb-4 opacity-50">&#x1F480;</div>
            <h2 className="text-xl font-mono text-red-400 mb-2">Rest in Peace</h2>
            {petState.name && (
              <p className="text-lg font-mono text-white mb-1">{petState.name}</p>
            )}
            <p className="text-sm font-mono text-gray-500 mb-6">
              Lived for {getPetAge(petState.bornAt, petState.deathTime ?? Date.now())}
            </p>
            <div className="border-t border-gray-700 pt-4 mt-4 w-full">
              <p className="text-xs font-mono text-gray-500 mb-2">
                Care Score: {Math.round(petState.careScore ?? 0)}%
              </p>
              <p className="text-xs font-mono text-gray-500 mb-4">
                Final Stage: {petState.stage}
              </p>
            </div>
            <button
              onClick={resetPet}
              className="px-8 py-3 bg-gray-800 hover:bg-gray-700 border-2 border-gray-600 hover:border-gray-400 rounded-xl font-mono text-white transition-all cursor-pointer"
            >
              Start New Egg
            </button>
          </div>
        )}

        {/* Naming overlay — covers card without resizing it */}
        {showNamingDialog && (
          <div className="absolute inset-0 bg-gray-900 rounded-3xl z-20 flex flex-col items-center justify-center text-center p-8">
            <div className="text-4xl mb-4 animate-bounce-slow">&#x1F423;</div>
            <h2 className="text-xl font-mono text-white mb-2">Your egg hatched!</h2>
            <p className="text-sm font-mono text-gray-400 mb-6">Give your new pet a name:</p>
            <input
              type="text"
              value={nameInput}
              onChange={(e) => setNameInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && nameInput.trim() && handleNamePet(nameInput)}
              maxLength={16}
              placeholder="Enter name..."
              autoFocus
              className="w-full bg-gray-800 border-2 border-gray-600 rounded-lg px-4 py-2 font-mono text-white text-center focus:border-green-500 focus:outline-none mb-4"
            />
            <button
              onClick={() => nameInput.trim() && handleNamePet(nameInput)}
              disabled={!nameInput.trim()}
              className="px-8 py-2 bg-green-700 hover:bg-green-600 disabled:bg-gray-700 disabled:text-gray-500 border-2 border-green-500 disabled:border-gray-600 rounded-xl font-mono text-white transition-all cursor-pointer"
            >
              Confirm
            </button>
          </div>
        )}

        {/* Name + age header — always rendered to reserve space */}
        <div className={`text-center mb-3 font-mono ${!petState.name ? "invisible" : ""}`}>
          <span className="text-lg text-white">{petState.name || "\u00A0"}</span>
          <span className="text-xs text-gray-500 ml-2">
            {petState.name ? getPetAge(petState.bornAt, Date.now()) : ""}
          </span>
        </div>

        {/* Mute button */}
        <MuteButton muted={muted} onToggle={toggleMute} />

        {/* Screen bezel */}
        <LcdScreen shake={mood === "critical"} className="rounded-2xl p-4 mb-3 flex-1 flex flex-col items-center justify-center">
          <Pet state={petState} onEggClick={handleRubEgg} eggHatchTimeRemaining={eggHatchTimeRemaining} actionAnimation={actionAnimation} onPetClick={handlePetTap} />
          {activeEffect && <ActionEffects effectId={activeEffect} />}
        </LcdScreen>

        {/* Stats — always rendered; invisible during egg to preserve height */}
        <div className={`flex flex-row justify-around items-center mb-3 ${isEgg ? "invisible" : ""}`}>
          <StatBar label="Hunger" value={petState.hunger} icon="&#x1F356;" flashWarning={petState.hunger < 15} />
          <StatBar label="Happiness" value={petState.happiness} icon="&#x2B50;" flashWarning={petState.happiness < 15} />
          <StatBar label="Hygiene" value={petState.hygiene} icon="&#x1FAE7;" flashWarning={petState.hygiene < 15} />
          <StatBar label="Energy" value={petState.energy ?? 100} icon="&#x26A1;" flashWarning={(petState.energy ?? 100) < 15} />
        </div>

        {/* Action buttons — min-height reserves space across all states */}
        <div className="flex justify-center gap-2 flex-wrap items-center">
          {!isEgg && !isSleeping && (
            <>
              <ActionButton label="Feed" onClick={handleFeed} icon="&#x1F354;"
                disabled={getCooldown("feed") > 0} cooldownRemaining={getCooldown("feed")} cooldownMax={ACTION_COOLDOWNS.feed} />
              <ActionButton label="Play" onClick={handlePlay} icon="&#x1F3AE;"
                disabled={getCooldown("play") > 0} cooldownRemaining={getCooldown("play")} cooldownMax={ACTION_COOLDOWNS.play} />
              <ActionButton label="Clean" onClick={handleClean} icon="&#x1F6C1;"
                disabled={getCooldown("clean") > 0} cooldownRemaining={getCooldown("clean")} cooldownMax={ACTION_COOLDOWNS.clean} />
              <ActionButton label="Sleep" onClick={handleSleep} icon="&#x1F4A4;"
                disabled={getCooldown("sleep") > 0} cooldownRemaining={getCooldown("sleep")} cooldownMax={ACTION_COOLDOWNS.sleep} />
            </>
          )}
          {isSleeping && (
            <ActionButton label="Wake" onClick={handleWake} icon="&#x2600;&#xFE0F;"
              disabled={getCooldown("wake") > 0} cooldownRemaining={getCooldown("wake")} cooldownMax={ACTION_COOLDOWNS.wake} />
          )}
        </div>

        {/* Log overlay popup */}
        {showLog && (
          <div className="absolute inset-0 bg-gray-900 rounded-3xl z-10 flex flex-col p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-mono text-white">Activity Log</h3>
              <button onClick={() => setShowLog(false)} className="text-gray-500 hover:text-white font-mono text-xs cursor-pointer px-2 py-1">&#x2715; Close</button>
            </div>
            <ActivityLog entries={petState.log ?? []} bare />
          </div>
        )}

        {/* Log toggle button — fixed height keeps card size consistent */}
        <div className="mt-2 border-t border-gray-700 pt-2 flex items-center gap-2">
          <button
            onClick={() => setShowLog(true)}
            disabled={(petState.log?.length ?? 0) === 0}
            className="flex-1 text-left text-xs font-mono text-gray-500 hover:text-gray-300 disabled:cursor-default flex justify-between items-center cursor-pointer"
          >
            <span>Activity Log</span>
            <span className="text-gray-600">{petState.log?.length ?? 0} entries ›</span>
          </button>
          <button
            onClick={resetPet}
            className="text-xs text-gray-600 hover:text-gray-400 font-mono transition-colors cursor-pointer whitespace-nowrap"
          >
            New Egg
          </button>
        </div>
      </div>

    </div>
  );
}
