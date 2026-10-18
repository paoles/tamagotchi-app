// Shared plumbing for the Pixel Pet API: storage, device auth,
// rate limiting and JSON responses.
//
// Devices are anonymous: the game makes a random id + secret on first
// launch. The first request from an id stores a hash of its secret
// (trust on first use); every later request must present the same
// secret. Nothing here identifies a person.
import { Redis } from "@upstash/redis";
import { createHash, timingSafeEqual } from "node:crypto";

let redisClient: Redis | null = null;

export function redis(): Redis {
  if (redisClient) return redisClient;
  const url = process.env.UPSTASH_REDIS_REST_URL ?? process.env.KV_REST_API_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.KV_REST_API_TOKEN;
  if (!url || !token) throw new HttpError(503, "storage not configured");
  redisClient = new Redis({ url, token });
  return redisClient;
}

export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

// Wraps a handler so thrown HttpErrors become JSON error responses.
export function route(fn: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    try {
      return await fn(req);
    } catch (err) {
      if (err instanceof HttpError) return json({ error: err.message }, err.status);
      console.error(err);
      return json({ error: "internal error" }, 500);
    }
  };
}

export async function body<T = Record<string, unknown>>(req: Request, maxBytes = 96_000): Promise<T> {
  const text = await req.text();
  if (text.length > maxBytes) throw new HttpError(413, "too large");
  try {
    return JSON.parse(text) as T;
  } catch {
    throw new HttpError(400, "bad json");
  }
}

const ID_RE = /^[0-9a-f]{32}$/;

function sha256(s: string): string {
  return createHash("sha256").update(s).digest("hex");
}

// Checks (or, the first time, registers) a device's secret.
export async function auth(input: { deviceId?: unknown; secret?: unknown }): Promise<string> {
  const id = String(input.deviceId ?? "");
  const secret = String(input.secret ?? "");
  if (!ID_RE.test(id) || !ID_RE.test(secret)) throw new HttpError(400, "bad device");
  const key = `dev:${id}`;
  const hash = sha256(secret);
  const created = await redis().set(key, hash, { nx: true });
  if (created !== "OK") {
    const stored = await redis().get<string>(key);
    if (!stored || !timingSafeEqual(Buffer.from(stored), Buffer.from(hash))) {
      throw new HttpError(403, "wrong secret");
    }
  }
  await limit(`rl:${id}`, 40, 60);
  return id;
}

// Fixed-window limiter: at most `max` calls per `windowSec` per key.
export async function limit(key: string, max: number, windowSec: number): Promise<void> {
  const bucket = `${key}:${Math.floor(Date.now() / 1000 / windowSec)}`;
  const n = await redis().incr(bucket);
  if (n === 1) await redis().expire(bucket, windowSec + 5);
  if (n > max) throw new HttpError(429, "slow down");
}

export function clientIp(req: Request): string {
  return (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";
}

export function origin(req: Request): string {
  const host = req.headers.get("x-forwarded-host") ?? req.headers.get("host") ?? "";
  const proto = req.headers.get("x-forwarded-proto") ?? "https";
  return `${proto}://${host}`;
}
