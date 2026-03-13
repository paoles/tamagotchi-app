"use client";

interface MuteButtonProps {
  muted: boolean;
  onToggle: () => void;
}

export default function MuteButton({ muted, onToggle }: MuteButtonProps) {
  return (
    <button
      onClick={onToggle}
      className="absolute top-4 right-4 text-lg opacity-50 hover:opacity-100 transition-opacity cursor-pointer z-10"
      title={muted ? "Unmute" : "Mute"}
    >
      {muted ? "\uD83D\uDD07" : "\uD83D\uDD0A"}
    </button>
  );
}
