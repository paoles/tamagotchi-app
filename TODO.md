# Pixel Pet — TODO

## One-time setup (owner)

- [ ] Create the Vercel project `pixel-pet` (framework: Other, output: `dist`) and link this repo
- [ ] Add GitHub repo secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
- [ ] Vercel Marketplace: add Upstash Redis and Upstash QStash to the project
- [ ] Generate VAPID keys (`npx web-push generate-vapid-keys`) and add `VAPID_PUBLIC_KEY`,
      `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (`mailto:you@…`) to the project's env vars
- [ ] Rename the GitHub repo to `pixel-pet`, then `git remote set-url origin …/pixel-pet.git`
- [ ] Retire the old `tamagotchi-app` Vercel project

## Verified locally (web export served from dist/, built-in browser)

- [x] Game loads; layout fills phone and desktop sizes; JS ↔ GDScript bridge works
- [x] Saves survive a reload (localStorage + IndexedDB); page-hide re-saves
- [x] Service worker installs; game loads offline with the server stopped
- [x] Hatch → name → bedtime flow, feeding, Jump Runner, recap after a long gap, live forecast

## Verify on the preview URL
- [ ] Add to Home Screen; turn on notifications; Debug → Test push arrives
- [ ] A scheduled alert arrives with the app closed (Debug → +time won't do — wait for a real one)
- [ ] Backup → transfer code → redeem on a second device

## Launch

- [ ] Merge `v2` into `main` (production deploy)

## Ideas for later

- More mini-games (memory match), more forms per stage, seasonal shop items
- Haptics on actions (`WebBridge.vibrate`), large-UI setting
- Translations (strings are already in `strings.gd`)
- Free furniture placement instead of fixed slots
