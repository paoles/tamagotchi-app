// Pixel Pet browser glue. GDScript reaches these through
// JavaScriptBridge.get_interface("PixelPet"). Async work reports back
// through a callback taking one JSON string, which keeps the Godot side
// simple (no Promise plumbing). Everything is optional: the game works
// without it (e.g. in the editor or an old browser).
(function () {
  "use strict";

  let installPrompt = null;
  const hiddenCallbacks = [];

  window.addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault();
    installPrompt = e;
  });

  function fireHidden() {
    for (const cb of hiddenCallbacks) {
      try {
        cb();
      } catch (_) {
        /* ignore */
      }
    }
  }
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "hidden") fireHidden();
  });
  window.addEventListener("pagehide", fireHidden);

  if ("serviceWorker" in navigator && location.protocol !== "file:") {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("sw.js").catch((err) => console.warn("sw:", err));
    });
  }

  function reply(cb, value) {
    try {
      cb(JSON.stringify(value));
    } catch (err) {
      console.warn("PixelPet callback failed", err);
    }
  }

  function b64ToBytes(b64) {
    const pad = "=".repeat((4 - (b64.length % 4)) % 4);
    const raw = atob((b64 + pad).replace(/-/g, "+").replace(/_/g, "/"));
    const out = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
  }

  const PixelPet = {
    version: 2,

    vibrate(ms) {
      try {
        if (navigator.vibrate) navigator.vibrate(ms);
      } catch (_) {
        /* ignore */
      }
    },

    isStandalone() {
      return (
        window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
      );
    },

    isIOS() {
      return (
        /iphone|ipad|ipod/i.test(navigator.userAgent) ||
        (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
      );
    },

    pushSupported() {
      return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window;
    },

    pushPermission() {
      return "Notification" in window ? Notification.permission : "unsupported";
    },

    // Called from GDScript inside a tap handler, so the browser still
    // counts it as a user gesture.
    enablePush(vapidKey, cb) {
      if (!PixelPet.pushSupported()) return reply(cb, { ok: false, why: "unsupported" });
      Notification.requestPermission()
        .then((perm) => {
          if (perm !== "granted") throw new Error("denied");
          return navigator.serviceWorker.ready;
        })
        .then((reg) =>
          reg.pushManager.getSubscription().then(
            (sub) =>
              sub ||
              reg.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: b64ToBytes(vapidKey),
              }),
          ),
        )
        .then((sub) => reply(cb, { ok: true, subscription: sub.toJSON() }))
        .catch((err) => reply(cb, { ok: false, why: String(err && err.message ? err.message : err) }));
    },

    disablePush(cb) {
      if (!PixelPet.pushSupported()) return reply(cb, { ok: true });
      navigator.serviceWorker.ready
        .then((reg) => reg.pushManager.getSubscription())
        .then((sub) => (sub ? sub.unsubscribe() : true))
        .then(() => reply(cb, { ok: true }))
        .catch((err) => reply(cb, { ok: false, why: String(err) }));
    },

    // POST JSON to our own API; replies {ok, status, data}.
    api(path, bodyJson, cb, keepalive) {
      fetch(path, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: bodyJson,
        keepalive: !!keepalive,
      })
        .then((res) =>
          res
            .json()
            .catch(() => ({}))
            .then((data) => reply(cb, { ok: res.ok, status: res.status, data })),
        )
        .catch((err) => reply(cb, { ok: false, status: 0, data: { error: String(err) } }));
    },

    // Fire-and-forget POST that survives the page closing.
    beacon(path, bodyJson) {
      try {
        if (navigator.sendBeacon) {
          return navigator.sendBeacon(path, new Blob([bodyJson], { type: "application/json" }));
        }
      } catch (_) {
        /* fall through */
      }
      fetch(path, { method: "POST", headers: { "Content-Type": "application/json" }, body: bodyJson, keepalive: true }).catch(
        () => {},
      );
      return true;
    },

    onHidden(cb) {
      hiddenCallbacks.push(cb);
    },

    canInstall() {
      return installPrompt !== null;
    },

    promptInstall(cb) {
      if (!installPrompt) return reply(cb, { ok: false });
      installPrompt.prompt();
      installPrompt.userChoice
        .then((choice) => {
          installPrompt = null;
          reply(cb, { ok: choice.outcome === "accepted" });
        })
        .catch(() => reply(cb, { ok: false }));
    },

    promptText(message, fallback) {
      const v = window.prompt(message, fallback || "");
      return v === null ? "" : v;
    },
  };

  window.PixelPet = PixelPet;
})();
