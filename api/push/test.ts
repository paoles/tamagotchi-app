// POST /api/push/test {deviceId, secret} — sends a notification right
// away (debug panel), so the whole push path can be checked by hand.
import { HttpError, auth, body, json, limit, route } from "../_lib/core.js";
import { send } from "../_lib/push.js";

export const POST = route(async (req) => {
  const b = await body<{ deviceId?: string; secret?: string }>(req, 2000);
  const id = await auth(b);
  await limit(`test:${id}`, 5, 600);
  const result = await send(id, { title: "Pixel Pet", body: "Test notification. Hello from your pet!", tag: "test" });
  if (result === "none") throw new HttpError(404, "no subscription");
  return json({ ok: true, result });
});
