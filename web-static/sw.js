// Pixel Pet service worker: offline play + push notifications.
//
// Caching is network-first for everything same-origin: online, the
// browser always gets the latest export (the .wasm and .pck must match,
// so stale-while-revalidate would be unsafe); offline, the last good
// copy is served. Push messages arrive as JSON {title, body, tag}.
"use strict";

const CACHE = "pixelpet-v1";
const SHELL = [
  "./",
  "index.html",
  "index.js",
  "index.wasm",
  "index.pck",
  "index.audio.worklet.js",
  "index.audio.position.worklet.js",
  "pixelpet.js",
  "manifest.webmanifest",
  "icons/icon-192.png",
  "icons/icon-512.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => Promise.allSettled(SHELL.map((url) => cache.add(url))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin || url.pathname.startsWith("/api/")) return;
  event.respondWith(
    fetch(req)
      .then((res) => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(req, copy));
        }
        return res;
      })
      .catch(() => caches.match(req).then((hit) => hit || caches.match("index.html"))),
  );
});

self.addEventListener("push", (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (_) {
    data = { body: event.data ? event.data.text() : "" };
  }
  const title = data.title || "Pixel Pet";
  event.waitUntil(
    self.registration.showNotification(title, {
      body: data.body || "Your pet misses you!",
      tag: data.tag || "pixelpet",
      renotify: true,
      icon: "icons/icon-192.png",
      badge: "icons/favicon-32.png",
      data: { url: data.url || "./" },
    }),
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || "./", self.location.href).href;
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((wins) => {
      for (const w of wins) {
        if (w.url.startsWith(self.location.origin) && "focus" in w) return w.focus();
      }
      return self.clients.openWindow(target);
    }),
  );
});
