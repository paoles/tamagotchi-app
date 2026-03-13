"use client";

import { useState } from "react";

interface NamingDialogProps {
  onSubmit: (name: string) => void;
}

export default function NamingDialog({ onSubmit }: NamingDialogProps) {
  const [name, setName] = useState("");

  return (
    <div className="flex flex-col items-center gap-6 w-full max-w-sm mx-auto">
      <div className="w-full bg-gray-900 border-2 border-gray-700 rounded-3xl p-8 shadow-[0_0_30px_rgba(0,0,0,0.5)] text-center">
        <div className="text-4xl mb-4 animate-bounce-slow">&#x1F423;</div>
        <h2 className="text-xl font-mono text-white mb-2">Your egg hatched!</h2>
        <p className="text-sm font-mono text-gray-400 mb-6">Give your new pet a name:</p>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && name.trim() && onSubmit(name)}
          maxLength={16}
          placeholder="Enter name..."
          autoFocus
          className="w-full bg-gray-800 border-2 border-gray-600 rounded-lg px-4 py-2 font-mono text-white text-center focus:border-green-500 focus:outline-none mb-4"
        />
        <button
          onClick={() => name.trim() && onSubmit(name)}
          disabled={!name.trim()}
          className="px-8 py-2 bg-green-700 hover:bg-green-600 disabled:bg-gray-700 disabled:text-gray-500 border-2 border-green-500 disabled:border-gray-600 rounded-xl font-mono text-white transition-all cursor-pointer"
        >
          Confirm
        </button>
      </div>
    </div>
  );
}
