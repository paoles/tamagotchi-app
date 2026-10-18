// POST /api/push/schedule {deviceId, secret, alerts: [{at, title, body, tag}]}
//
// Replaces the device's planned notifications with a new forecast:
// previously queued QStash messages are cancelled and one delayed
// message is published per alert. An unchanged forecast is a no-op.
import { createHash } from "node:crypto";
import { HttpError, auth, body, json, origin, redis, route } from "../_lib/core.js";
import { qstash } from "../_lib/qstash.js";

type Alert = { at: number; title: string; body: string; tag: string };

const MAX_ALERTS = 6;
const HORIZON_S = 26 * 3600;

function clean(raw: unknown): Alert[] {
  if (!Array.isArray(raw)) throw new HttpError(400, "alerts must be a list");
  const now = Math.floor(Date.now() / 1000);
  const out: Alert[] = [];
  for (const a of raw.slice(0, MAX_ALERTS)) {
    const at = Math.floor(Number((a as Alert)?.at));
    if (!Number.isFinite(at) || at < now + 20 || at > now + HORIZON_S) continue;
    out.push({
      at,
      title: String((a as Alert).title ?? "Pixel Pet").slice(0, 60),
      body: String((a as Alert).body ?? "").slice(0, 160),
      tag: String((a as Alert).tag ?? "pixelpet").replace(/[^a-z0-9_-]/gi, "").slice(0, 32),
    });
  }
  return out;
}

export const POST = route(async (req) => {
  const b = await body<{ deviceId?: string; secret?: string; alerts?: unknown }>(req, 8000);
  const id = await auth(b);
  const alerts = clean(b.alerts);
  const hash = createHash("sha256").update(JSON.stringify(alerts)).digest("hex").slice(0, 16);
  const key = `sched:${id}`;
  const prev = await redis().get<{ hash: string; ids: string[] }>(key);
  if (prev?.hash === hash) return json({ ok: true, scheduled: alerts.length, unchanged: true });

  const q = qstash();
  for (const mid of prev?.ids ?? []) {
    await q.messages.delete(mid).catch(() => undefined);
  }
  const target = `${origin(req)}/api/push/fire`;
  const ids: string[] = [];
  for (const a of alerts) {
    const res = await q.publishJSON({
      url: target,
      body: { deviceId: id, title: a.title, body: a.body, tag: a.tag },
      notBefore: a.at,
      retries: 2,
    });
    ids.push(res.messageId);
  }
  await redis().set(key, { hash, ids }, { ex: HORIZON_S + 3600 });
  return json({ ok: true, scheduled: ids.length });
});
