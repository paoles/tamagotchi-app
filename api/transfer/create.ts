// POST /api/transfer/create {deviceId, secret} → {code}
// A six-character code, valid for 24 hours, that lets another device
// download this device's latest cloud backup.
import { randomInt } from "node:crypto";
import { HttpError, auth, body, json, limit, redis, route } from "../_lib/core.js";

const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export const POST = route(async (req) => {
  const b = await body<{ deviceId?: string; secret?: string }>(req, 2000);
  const id = await auth(b);
  await limit(`xfer-create:${id}`, 5, 3600);
  if (!(await redis().exists(`save:${id}`))) throw new HttpError(409, "back up first");
  for (let attempt = 0; attempt < 5; attempt++) {
    let code = "";
    for (let i = 0; i < 6; i++) code += ALPHABET[randomInt(ALPHABET.length)];
    const ok = await redis().set(`xfer:${code}`, id, { nx: true, ex: 86400 });
    if (ok === "OK") return json({ ok: true, code, expiresIn: 86400 });
  }
  throw new HttpError(503, "try again");
});
