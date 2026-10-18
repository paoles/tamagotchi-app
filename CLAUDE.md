# Pixel Pet (v2)

A real-time virtual pet: a Godot 4.7 web export (portrait, installable PWA)
plus a few Vercel functions for push notifications and cloud backup.
v1 (Next.js) is retired — it lives at the `v1` git tag.

## Layout

```
game/                 Godot project (open game/project.godot)
  scripts/            all game code (class_name scripts, built in code — no scenes besides main)
  web/shell.html      custom HTML shell for the web export
  addons/godot_ai/    editor-only MCP plugin (runtime helper idles in release builds)
web-static/           copied into dist/ after export: sw.js, pixelpet.js, manifest, icons
api/                  Vercel Node functions (TypeScript, Web Request/Response handlers)
tools/serve.mjs       zero-dependency static server for a local dist/
.github/workflows/    CI: import → sim checks → web export → Vercel deploy
```

## Commands

Godot lives at `C:\Users\nicop\OneDrive\Documents\Godot_v4.7.1-stable_win64.exe\` (use the
`_console.exe` for terminal output). From the repo root, with `G` = that console exe:

```bash
"$G" --headless --path game --import        # rebuild the class cache (after adding class_name scripts)
"$G" --headless --path game -- sim          # life-sim checks; exit code = failures (runs in CI)
"$G" --headless --path game -- art <dir>    # contact sheets of all generated art (PNG)
"$G" --path game -- snap <dir>              # screenshots of every screen (needs a window)
"$G" --headless --path game -- icons web-static/icons   # regenerate PWA icons
```

Node is not on the default bash PATH: `export PATH="/c/Program Files/nodejs:$PATH"`.
`npm run typecheck` checks the API. Local web test: export (needs export templates) to `dist/`,
then run the `pixelpet-web` launch config (serves dist/ on :3000).

## Architecture

- **One save Dictionary** (`save_state.gd`) serialized to JSON. Ages, timers and countdowns are
  minute counters, so daycare freezes a pet by not stepping it. New fields get defaults in
  `SaveState.migrate()`; JSON floats are normalized back to ints.
- **Pure simulation** (`sim.gd`): `Sim.advance(save, t)` steps 1 minute at a time and returns
  events. The same code runs live play, offline catch-up, the push forecast and the harness.
  Randomness uses the RNG state stored in the save → deterministic.
- **Actions** (`care.gd`, `shop.gd`) return `{ok, why, anim, events}`; `Game.act()/apply()` catch
  the sim up first, emit events, check badges and save. UI never edits the save directly
  (settings toggles are the exception and call `ui.settings_changed()`).
- **All tuning** lives in `cfg.gd`; all player-facing text in `strings.gd` (`S.t(key, args)`).
- **Art is generated in code** — no image assets. Creatures are shape recipes (`art/forms.gd`)
  rasterized with outlines/shading by `art/pixel.gd`; faces are composed per expression;
  icons, goods and the 5×7 / 3×5 bitmap fonts are text grids. Everything is drawn at an integer
  scale (room pixels ×3) with nearest filtering.
- **Audio** is synthesized into AudioStreamWAV buffers (`audio/synth.gd`); music renders in
  slices across frames so the single-threaded web build never stalls.
- **UI** (`ui/`): `GameUI` holds a portrait column (pastel margins on wide screens) with the
  room (`pet/world.gd`), HUD, action bar, toasts and one `Sheet` at a time. Screens are builder
  functions in `ui/screens*.gd`; later modules register into `Screens.EXTRA`.
- **Online** (`online.gd`, `web_bridge.gd`, `web-static/pixelpet.js`): only active on the web.
  Alerts come from `Forecast.alerts()` (category filters, quiet while asleep except lights,
  ≤6, ≥60 min apart) and are sent on page hide (beacon) and every 10 minutes.

## Gotchas

- `:=` can't infer a type from a Dictionary value — write `var x: float = pet.hunger`.
- `class_name` must not collide with engine classes (e.g. `Sky` → we use `SkyCycle`).
- After adding a `class_name` script, run `--import` before headless runs.
- Godot's web build can't render system emoji: every symbol is a pixel icon in `art/icons.gd`.
- Labels with `clip_text` collapse to zero width inside HBoxes; footers don't clip.
- Sheets measure their height one frame after opening (wrapped text needs its width first).

## Deployment

- Branch `v2` → preview deploys; `main` → production (after the v2 merge).
- Vercel's git auto-deploy is off (`vercel.json`); GitHub Actions deploys with
  `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` secrets. Without them CI still runs the
  sim checks and the export, and skips the deploy.
- API env vars (Vercel): `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`, Upstash Redis
  (`UPSTASH_REDIS_REST_URL`/`_TOKEN` or `KV_REST_API_URL`/`_TOKEN`), QStash (`QSTASH_TOKEN`,
  `QSTASH_CURRENT_SIGNING_KEY`, `QSTASH_NEXT_SIGNING_KEY`, optional `QSTASH_URL`).
