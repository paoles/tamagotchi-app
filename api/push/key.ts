// GET|POST /api/push/key: the VAPID public key the browser subscribes with.
import { json, route } from "../_lib/core.js";
import { publicKey } from "../_lib/push.js";

const handler = route(async () => json({ ok: true, key: publicKey() }));
export const GET = handler;
export const POST = handler;
