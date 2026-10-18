// POST /api/transfer/redeem {code} → {save}
// One use only. Limited per IP so codes can't be guessed.
import { HttpError, body, clientIp, json, limit, redis, route } from "../_lib/core.js";

export const POST = route(async (req) => {
  const b = await body<{ code?: string }>(req, 500);
  await limit(`xfer-redeem:${clientIp(req)}`, 10, 3600);
  const code = String(b.code ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
  if (code.length !== 6) throw new HttpError(400, "bad code");
  const id = await redis().getdel<string>(`xfer:${code}`);
  if (!id) throw new HttpError(404, "unknown or expired code");
  const stored = await redis().get<{ save: string; savedAt: number }>(`save:${id}`);
  if (!stored) throw new HttpError(404, "no backup");
  return json({ ok: true, save: stored.save, savedAt: stored.savedAt });
});
