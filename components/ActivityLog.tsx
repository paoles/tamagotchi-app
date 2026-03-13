"use client";

import { LogEntry } from "@/types/pet.types";

interface ActivityLogProps {
  entries: LogEntry[];
  bare?: boolean;
}

const TYPE_COLORS: Record<string, string> = {
  action: "text-blue-400",
  evolution: "text-yellow-400",
  event: "text-purple-400",
  warning: "text-orange-400",
  death: "text-red-400",
};

export default function ActivityLog({ entries, bare }: ActivityLogProps) {
  const sorted = [...entries].reverse();

  const list = (
    <div className="overflow-y-auto scrollbar-thin flex-1">
      {sorted.map((entry, i) => (
        <div key={i} className="flex items-start gap-2 text-xs font-mono py-0.5">
          <span className="text-gray-600 shrink-0">
            {new Date(entry.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </span>
          <span className={TYPE_COLORS[entry.type] ?? "text-gray-400"}>
            {entry.message}
          </span>
        </div>
      ))}
    </div>
  );

  if (bare) return list;

  return (
    <div className="mt-4 border-t border-gray-700 pt-3">
      <h3 className="text-xs font-mono text-gray-500 mb-2">Activity Log</h3>
      <div className="max-h-32 overflow-y-auto scrollbar-thin">
        {sorted.map((entry, i) => (
          <div key={i} className="flex items-start gap-2 text-xs font-mono py-0.5">
            <span className="text-gray-600 shrink-0">
              {new Date(entry.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
            </span>
            <span className={TYPE_COLORS[entry.type] ?? "text-gray-400"}>
              {entry.message}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
