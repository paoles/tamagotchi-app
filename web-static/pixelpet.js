// Pixel Pet browser glue. GDScript reaches these through
// JavaScriptBridge.get_interface("PixelPet"). Everything here is
// optional: the game works without it (e.g. in the editor).
(function () {
  "use strict";

  const PixelPet = {
    version: 1,

    // Short haptic tap where supported (Android browsers).
    vibrate(ms) {
      try {
        if (navigator.vibrate) navigator.vibrate(ms);
      } catch (_) {
        /* ignore */
      }
    },

    isStandalone() {
      return (
        window.matchMedia("(display-mode: standalone)").matches ||
        window.navigator.standalone === true
      );
    },

    isIOS() {
      return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
        (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
    },
  };

  window.PixelPet = PixelPet;
})();
