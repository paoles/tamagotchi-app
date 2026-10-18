// Delayed delivery through Upstash QStash: each forecast alert becomes
// a message that calls /api/push/fire at its time.
import { Client, Receiver } from "@upstash/qstash";
import { HttpError } from "./core.js";

let client: Client | null = null;

export function qstash(): Client {
  if (client) return client;
  const token = process.env.QSTASH_TOKEN;
  if (!token) throw new HttpError(503, "scheduler not configured");
  client = new Client({ token, baseUrl: process.env.QSTASH_URL || undefined });
  return client;
}

export async function verify(req: Request, raw: string): Promise<boolean> {
  const current = process.env.QSTASH_CURRENT_SIGNING_KEY;
  const next = process.env.QSTASH_NEXT_SIGNING_KEY;
  const signature = req.headers.get("upstash-signature");
  if (!current || !next || !signature) return false;
  try {
    return await new Receiver({ currentSigningKey: current, nextSigningKey: next }).verify({ signature, body: raw });
  } catch {
    return false;
  }
}
