// POST /api/push/fire — called by QStash at an alert's time.
// Only requests carrying a valid QStash signature are accepted.
import { HttpError, json, route } from "../_lib/core.js";
import { send } from "../_lib/push.js";
import { verify } from "../_lib/qstash.js";

export const POST = route(async (req) => {
  const raw = await req.text();
  if (!(await verify(req, raw))) throw new HttpError(401, "bad signature");
  let msg: { deviceId?: string; title?: string; body?: string; tag?: string };
  try {
    msg = JSON.parse(raw);
  } catch {
    throw new HttpError(400, "bad json");
  }
  if (!msg.deviceId || !/^[0-9a-f]{32}$/.test(msg.deviceId)) throw new HttpError(400, "bad device");
  const result = await send(msg.deviceId, {
    title: msg.title ?? "Pixel Pet",
    body: msg.body ?? "",
    tag: msg.tag ?? "pixelpet",
  });
  return json({ ok: true, result });
});
