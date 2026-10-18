# Pixel Pet — TODO

## One-time setup (owner)

- [ ] Create the Vercel project `pixel-pet` (framework: Other, output: `dist`) and link this repo
- [ ] Add GitHub repo secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
- [ ] Vercel Marketplace: add Upstash Redis and Upstash QStash to the project
- [ ] Generate VAPID keys (`npx web-push generate-vapid-keys`) and add `VAPID_PUBLIC_KEY`,
      `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (`mailto:you@…`) to the project's env vars
- [ ] Rename the GitHub repo to `pixel-pet`, then `git remote set-url origin …/pixel-pet.git`
- [ ] Retire the old `tamagotchi-app` Vercel project

## Verify on the preview URL

- [ ] Game loads on phone and desktop; saves survive a reload; works offline after one visit
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
