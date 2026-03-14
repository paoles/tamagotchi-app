# Tamagotchi App

## Stack

- **Next.js 15** (App Router), **React 19**, **TypeScript 5.7**, **Tailwind CSS 4**
- No external dependencies beyond core Next.js/React/Tailwind
- Procedural audio via Web Audio API (no audio files)
- SVG pixel art sprites (no image assets besides SVGs)
- localStorage for persistence (no database)

## Dev Server

Node.js is not in the default bash PATH on this machine. Always prefix commands:

```bash
export PATH="/c/Program Files/nodejs:$PATH" && npm run dev
```

Or use the launch.json config which runs `node node_modules/next/dist/bin/next dev` directly on port 3000.


## Deployment

- **GitHub**: https://github.com/paoles/tamagotchi-app
- **Vercel**: Auto-deploys from main branch on every push
- To deploy changes: On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
- Build command:  (must pass TypeScript checks)

## Architecture

```
app/
  layout.tsx          # Root layout, h-dvh viewport-locked, imports globals.css
  page.tsx            # Renders DeviceShell > GameContainer
  globals.css         # Tailwind import + custom keyframe animations

types/
  pet.types.ts        # All type definitions (PetState, PetMood, EvolutionStage, etc.)

lib/
  constants.ts        # All game balance numbers, rates, thresholds, events
  petLogic.ts         # Pure functions: state in, state out (no React, no side effects)

hooks/
  useLocalStorage.ts  # Generic localStorage hook with SSR hydration guard
  useStatDecay.ts     # Interval-based decay tick (accepts optional custom decay fn)
  usePetState.ts      # Main game state orchestrator (actions, evolution, events, naming)
  useSoundEffects.ts  # Web Audio API procedural 8-bit sound synthesis + mute toggle

components/
  DeviceShell.tsx    # Plastic tamagotchi shell wrapper, viewport zoom scaling
  GameContainer.tsx   # Top-level smart component, all screens as overlays inside one card
  Pet.tsx             # Passes state to PetSprite, displays mood text
  PetSprite.tsx       # Stage-aware sprite rendering with animation classes
  StatBar.tsx         # Circular SVG progress ring per stat: icon in center, % below, color-coded
  ActionButton.tsx    # Button with emoji icon, rAF-animated cooldown drain bar, disabled state
  NamingDialog.tsx    # (legacy, unused) — naming now inlined in GameContainer overlay
  DeathScreen.tsx     # (legacy, unused) — death now inlined in GameContainer overlay
  ActionEffects.tsx   # Floating emoji particles on action (hearts/stars/bubbles)
  ActivityLog.tsx     # Scrollable color-coded event log (bare prop for popup mode)
  MuteButton.tsx      # Sound on/off toggle

public/sprites/
  egg.svg             # Egg stage (single sprite)
  baby/*.svg          # Baby stage: happy, neutral, hungry, sad, dirty, critical, sleeping, dead
  child/*.svg         # Child stage (purple theme): same 8 moods
  teen/*.svg          # Teen stage (orange/spiky theme): same 8 moods
  adult/*.svg         # Adult stage (blue/crown theme): same 8 moods
  *.svg (root)        # Legacy sprites from v1 (baby copies), kept for backward compat
```

## Key Design Patterns

### State Management
- All game state lives in a single `PetState` object persisted to localStorage under key `"tamagotchi-pet-state"`
- `useLocalStorage` handles SSR hydration (returns initialValue until client-side mount)
- `usePetState` is the single source of truth - no other component reads/writes localStorage directly
- State updates use functional `setPetState(prev => ...)` to avoid race conditions

### Pure Game Logic (petLogic.ts)
All game mechanics are pure functions in `petLogic.ts`. This is intentional - keeps logic testable and separates concerns from React.

Key functions:
- `migrateState()` - Fills defaults for optional fields (backward compat with old saves)
- `applyTimeBasedDecay()` - Decays stats based on real elapsed time, handles sleep mode, energy, auto-wake, death check
- `getPetMood()` - Derives visual mood from current stats (priority: dead > sleeping > egg > critical > hungry > sad > dirty > happy > neutral)
- `applyStat()` - Applies action with energy effectiveness multiplier, energy/hygiene costs per action, and overfeeding penalty
- `checkEvolution()` - Returns target stage based on age (minutes) + careScore
- `checkDeathCondition()` - Tracks `zeroStatSince`, kills pet after 3min at zero
- `getSpritePath()` - Returns `/sprites/{stage}/{mood}.svg`

### Decay System
- `useStatDecay` runs a tick every `TICK_INTERVAL` (10s)
- `usePetState` provides an extended decay function that also checks evolution, random events, and care score
- Decay rates are modified by: stage multiplier (babies decay faster, adults slower), sleep multiplier (30% rate while sleeping)
- Time-based: calculates decay from `lastUpdated` timestamp, not from tick count

### Evolution
Stages: `egg -> baby -> child -> teen -> adult`
- Based on age (minutes since `bornAt`) AND `careScore` (rolling average of all stats)
- Egg has no stat decay; hatches into Baby at 2 min
- Each stage has a decay multiplier: egg=0, baby=1.5, child=1.2, teen=1.0, adult=0.8

### Backward Compatibility
- All post-v1 `PetState` fields are optional (`?`)
- `migrateState()` fills defaults on mount
- Old localStorage data loads without breaking

## Layout Constraints

- The entire device must fit within the viewport at all times — no page-level scrolling
- DeviceShell applies CSS zoom scaling (via useEffect) when the device exceeds viewport height
- All game states (egg, alive, sleeping, dead, naming) render inside one fixed-size card
- Death screen and naming dialog are absolute overlays (z-20) inside the card, not early returns
- Stats section is always rendered (invisible during egg) to prevent height changes
- Button area uses min-h-[176px] to stay consistent between awake (4 buttons) and sleeping (1 button)
- Activity log is a popup overlay toggled by a button, not always-visible inline content

## Game Balance Constants (constants.ts)

| Constant | Value | Notes |
|----------|-------|-------|
| Tick interval | 10s | How often decay runs |
| Hunger decay | 1.0/min | Base rate before multipliers |
| Happiness decay | 0.5/min | |
| Hygiene decay | 0.3/min | |
| Energy decay | 0.4/min | While awake |
| Energy recovery | 3.5/min | While sleeping |
| Sleep decay mult | 0.3 | Stats decay at 30% while asleep |
| Feed amount | +35 | Hunger; -2 energy, -5 hygiene |
| Play amount | +25 | Happiness; -8 energy, -10 hygiene |
| Clean amount | +30 | Hygiene; no energy cost |
| Overfeed threshold | 90 | Feeding above this = -10 happiness |
| Death timer | 3 min | Any stat at 0 for this long = death |
| Random event chance | 5% | Per tick |
| Cooldowns | feed:5s, play:8s, clean:6s, sleep/wake:3s | |

## CSS Animations (globals.css)

- `bounce-slow` - Default pet idle (2s cycle, -8px)
- `float-up` - Action effect particles (0.8s, fade + rise)
- `shake` - Screen shake on critical mood (0.6s)
- `tremble` - Pet tremble on critical (0.3s)
- `sleep-bob` - Gentle sleeping sway (3s, +2px, -2deg)
- `pulse-red` - Warning flash on stat bars <15% (1s)

## Screen

- Background: pastel mint `#d4f0e0` with `#7ab890` border — light, playful, no LCD styling
- No pixel grid overlay (`.lcd-grid` is `display: none`)
- Text in screen uses `#3a7a50` (stage/mood labels) and `#1a4a2a` (emphasis text)
- Sprite drop shadow: `rgba(0,80,40,0.3)`
- `.lcd-screen` CSS class name kept for structural reasons; no longer green/LCD styled

## Stat Bars (StatBar.tsx)

- Circular SVG progress rings, 64×64px each
- Icon emoji centered inside the ring; colored `%` value below
- RADIUS=26, CIRCUMFERENCE=2πR, `strokeDashoffset` drives fill
- Colors: green `#22c55e` (≥60%), yellow `#eab308` (≥30%), red `#ef4444` (<30%)
- Track ring at 18% opacity; `strokeLinecap="round"`; SVG rotated −90°
- All 4 sit in one `flex-row justify-around` row below the LCD screen
- `label` prop is optional (passed but unused; kept for backward compat)

## Device Shell

- `.device-shell-outer`: `max-width: 360px`, `max-height: 780px` — caps desktop to mobile aspect ratio
- Lanyard loop visible on both desktop and mobile
- `.device-body` keeps `border-radius: 2.5rem` on mobile (not overridden to 0)
- "New Egg" button always inline with Activity Log row (no responsive split)

## Action Buttons (ActionButton.tsx)

- 3D raised plastic look: warm cream gradient, multi-layer box-shadow (4px bottom edge `#9c9080`)
- `:active`: translateY(3px) + inverted inset shadows
- Cooldown: absolute-positioned 3px amber bar (`.device-button-cd-bar`) at bottom, drains via `requestAnimationFrame`
- Button has `position: relative; overflow: hidden` so bar clips at rounded corners without affecting layout
- `cooldownMax` prop drives bar width percentage; no CSS transition needed (rAF handles smoothness)

## Sprites

All sprites are 16x16 pixel art SVGs using `<rect>` elements with `shape-rendering="crispEdges"`. Rendered at 160x160 with CSS `image-rendering: pixelated`.

Color themes per stage:
- **Baby**: Green (#44cc44)
- **Child**: Purple (#aa55cc)
- **Teen**: Orange (#dd8833) with spiky hair
- **Adult**: Blue (#4488cc) with crown

Each stage has 8 mood variants: happy, neutral, hungry, sad, dirty, critical, sleeping, dead.
