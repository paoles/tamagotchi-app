// POST /api/backup {deviceId, secret, save, savedAt}           → store
// POST /api/backup {deviceId, secret, restore: true}            → fetch
//
// The save is an opaque JSON string (at most 64 KB). It is kept for
// 90 days after the last backup.
import { HttpError, auth, body, json, redis, route } from "./_lib/core.js";

const MAX_SAVE = 64_000;
const TTL = 60 * 60 * 24 * 90;

export const POST = route(async (req) => {
  const b = await body<{ deviceId?: string; secret?: string; save?: unknown; savedAt?: unknown; restore?: boolean }>(req, MAX_SAVE + 2000);
  const id = await auth(b);
  const key = `save:${id}`;
  if (b.restore) {
    const stored = await redis().get<{ save: string; savedAt: number }>(key);
    if (!stored) throw new HttpError(404, "no backup");
    return json({ ok: true, ...stored });
  }
  if (typeof b.save !== "string" || b.save.length > MAX_SAVE) throw new HttpError(400, "bad save");
  const savedAt = Math.floor(Number(b.savedAt) || Date.now() / 1000);
  await redis().set(key, { save: b.save, savedAt }, { ex: TTL });
  return json({ ok: true, savedAt });
});
