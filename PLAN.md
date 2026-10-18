# Pixel Pet v2 — design

Rebuilt from scratch in Godot 4.7 (the Next.js v1 is at the `v1` tag). Decisions came from a
round of questions; this is what was built.

## The game

- **Real time.** One generation lives ~14–16 days on casual care (3–4 check-ins a day) and keeps
  living while the app is closed. Offline time is simulated on return and summarized.
- **Care:** hunger, happiness, energy (naps + nightly sleep), poop, discipline (scold fake
  attention calls), weight (snacks vs. games and a slow metabolism).
- **Sleep:** the player sets bedtime/wake (7–11 h) at the first hatch. Lights must go off within
  30 min of bedtime; switching them off up to 90 min early sends the pet to bed early.
- **Mistakes** (poop left 6 h, a need call ignored 60 min, lights left on) steer evolution and
  lifespan. A day of total neglect (hunger or happiness at 0 for 24 h) is fatal.
- **Evolution:** 16 forms. egg → mochi → puffle/smudge → bloom/zippy/pudding/grumble →
  lumina, sprout, comet, rascal, dumpling, grumpus, plus secrets starlight (flawless and fully
  disciplined teen) and chonk (overweight teen).
- **Generations:** old age leaves an egg that inherits one of the parent's two traits; neglect
  death leaves a grave and starts a new family line. Coins, items and the room carry over.
- **Economy:** coins from mini-games, perfect days, evolutions, legacy and badges; a 50-item shop
  (treats, toys, outfits, furniture, wallpapers, floors).
- **Extras:** Left/Right, Catch the Food, Jump Runner; 21 badges; collection book; family tree;
  memorial; daycare (4 free hours a day, then coins); real-clock sky with seasonal weather; icon
  speech bubbles; chiptune day/night music.
- **Online:** push notifications planned from a no-input forecast (categories in settings,
  quiet hours = the pet's sleep), anonymous cloud backup, one-time transfer codes.

## Milestones

| | Milestone | Status |
|---|---|---|
| M0 | Branch, scaffold, CI | ✅ |
| M1 | Core loop, art system, UI, saves, SFX | ✅ |
| M2 | Bubbles, idle chatter, music, sky/weather, daycare | ✅ |
| M3 | Shop, wardrobe, decorating, carry-over | ✅ |
| M4 | Mini-games, badges, book, family tree | ✅ |
| M5 | PWA, push + backup API, settings | ✅ code — needs Vercel/Upstash setup to go live |
| Launch | Merge v2 → main, rename to pixel-pet | ⏳ |

## Verification

- `-- sim`: perfect care (Starlight, old age at ~16 d), total neglect (death 24–36 h), casual
  care survives, all 8 adults reachable, catch-up == stepping, save round-trip + migration,
  forecast rules, daycare.
- `-- snap`: 47 screenshots across every screen and state.
- Web build + push: on the Vercel preview (see TODO.md for the one-time setup).
