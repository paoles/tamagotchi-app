// Web Push sending (VAPID) and the stored subscriptions.
import webpush from "web-push";
import { HttpError, redis } from "./core.js";

export type Subscription = {
  endpoint: string;
  expirationTime?: number | null;
  keys: { p256dh: string; auth: string };
};

let configured = false;

function setup(): void {
  if (configured) return;
  const pub = process.env.VAPID_PUBLIC_KEY;
  const priv = process.env.VAPID_PRIVATE_KEY;
  const subject = process.env.VAPID_SUBJECT ?? "mailto:pixelpet@example.com";
  if (!pub || !priv) throw new HttpError(503, "push not configured");
  webpush.setVapidDetails(subject, pub, priv);
  configured = true;
}

export function publicKey(): string {
  const key = process.env.VAPID_PUBLIC_KEY;
  if (!key) throw new HttpError(503, "push not configured");
  return key;
}

const SUB_TTL = 60 * 60 * 24 * 45;

export function validSubscription(s: unknown): s is Subscription {
  if (!s || typeof s !== "object") return false;
  const sub = s as Subscription;
  return (
    typeof sub.endpoint === "string" &&
    sub.endpoint.startsWith("https://") &&
    sub.endpoint.length < 1000 &&
    typeof sub.keys?.p256dh === "string" &&
    typeof sub.keys?.auth === "string"
  );
}

export async function saveSubscription(deviceId: string, sub: Subscription): Promise<void> {
  await redis().set(`sub:${deviceId}`, JSON.stringify(sub), { ex: SUB_TTL });
}

export async function dropSubscription(deviceId: string): Promise<void> {
  await redis().del(`sub:${deviceId}`);
}

export async function getSubscription(deviceId: string): Promise<Subscription | null> {
  const raw = await redis().get<string | Subscription>(`sub:${deviceId}`);
  if (!raw) return null;
  return typeof raw === "string" ? (JSON.parse(raw) as Subscription) : raw;
}

// Sends one notification. A gone subscription (404/410) is deleted.
export async function send(
  deviceId: string,
  payload: { title: string; body: string; tag?: string },
): Promise<"sent" | "gone" | "none"> {
  setup();
  const sub = await getSubscription(deviceId);
  if (!sub) return "none";
  try {
    await webpush.sendNotification(sub, JSON.stringify(payload), { TTL: 60 * 60 * 6, urgency: "normal" });
    return "sent";
  } catch (err) {
    const code = (err as { statusCode?: number }).statusCode;
    if (code === 404 || code === 410) {
      await dropSubscription(deviceId);
      return "gone";
    }
    throw err;
  }
}
