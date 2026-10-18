// POST /api/push/subscribe {deviceId, secret, subscription}
// POST /api/push/subscribe {deviceId, secret, unsubscribe: true}
import { HttpError, auth, body, json, route } from "../_lib/core.js";
import { dropSubscription, saveSubscription, validSubscription } from "../_lib/push.js";

export const POST = route(async (req) => {
  const b = await body<{ deviceId?: string; secret?: string; subscription?: unknown; unsubscribe?: boolean }>(req, 4000);
  const id = await auth(b);
  if (b.unsubscribe) {
    await dropSubscription(id);
    return json({ ok: true });
  }
  if (!validSubscription(b.subscription)) throw new HttpError(400, "bad subscription");
  await saveSubscription(id, b.subscription);
  return json({ ok: true });
});
