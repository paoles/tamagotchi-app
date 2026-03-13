# Tamagotchi App - Development Plan

## Vision

Transform the current functional Tamagotchi prototype into a polished **retro handheld device** experience with deeper gameplay through mini-games and an item shop economy.

## Phase Overview

| Phase | Name | Focus | Depends On |
|-------|------|-------|------------|
| 1 | Device Shell | Retro handheld hardware UI wrap | - |
| 2 | LCD Screen Overhaul | Green-tint LCD aesthetic for pet viewport | Phase 1 |
| 3 | Physical Buttons | Replace flat buttons with tactile 3D buttons | Phase 1 |
| 4 | Stat Display Rework | Segmented pixel-style stat bars | Phase 1 |
| 5 | Pet Interactivity & Animation | Idle behaviors, action animations, tap interaction | Phase 4 |
| 6 | Coin Economy | Earn coins from care actions | - |
| 7 | Item Shop | Shop screen to buy food, toys, accessories | Phase 6 |
| 8 | Inventory and Usage | Inventory UI, equip accessories, use items | Phase 7 |
| 9 | Mini-Game: Memory Match | Puzzle game - flip cards to find pairs | Phase 6 |
| 10 | Mini-Game: Catch Game | Reflex game - catch falling items | Phase 6 |
| 11 | Screen Transitions | Animated transitions between screens | Phase 1 |
| 12 | 8-Bit Background & Day/Night Cycle | Pixel art grass field with real-time sun/moon | Phase 1 |
| 13 | Polish Pass | Sound, animation tweaks, edge cases | All |

---

## Phase 1 - Device Shell

Wrap the entire app in a **retro Tamagotchi/Game Boy-style device frame**. Foundation for all visual work.

### Design
- Rounded rectangular device body with visible bezel/border
- Color: matte plastic look (off-white/cream, CSS gradients + shadows)
- Decorative elements: screw dots in corners, brand text, lanyard loop
- Screen is an inset rectangle within the device body
- Below screen: physical button area. Above screen: logo area

### Technical Approach
- New DeviceShell.tsx wrapping GameContainer
- Pure CSS/Tailwind for the device body (no images)
- CSS box-shadow layers for depth, border-radius for rounded shape
- Responsive: scales to fit viewport while maintaining aspect ratio
- page.tsx renders DeviceShell instead of bare GameContainer

### Files to Change
- components/DeviceShell.tsx (new)
- app/page.tsx (swap GameContainer for DeviceShell)
- app/globals.css (device-specific styles)

---

## Phase 2 - Screen Overhaul ✅

Replace current dark screen with a **pastel mint game screen** — light, playful, retro without the monochrome LCD look.

### Design (as implemented)
- Pastel mint background (#d4f0e0) with #7ab890 border
- No pixel grid overlay (removed — was too LCD-specific)
- Subtle inset shadow for screen depth
- Sprites render with soft green drop-shadow against mint background
- Text in screen uses dark green tones (#3a7a50, #1a4a2a) for readability

### Technical Approach
- Reusable LcdScreen wrapper kept for structure (class name unchanged)
- CSS drives all visual changes — no canvas, no filters
- PetSprite.tsx text/shadow colors updated for light background

### Files Changed
- components/LcdScreen.tsx (new)
- components/GameContainer.tsx (use LcdScreen)
- components/PetSprite.tsx (text + shadow colors for light bg)
- app/globals.css (mint bg, removed grid, updated shadows)

---

## Phase 3 - Physical Buttons

Replace flat ActionButton with **3D tactile plastic buttons**.

### Design
- Circular or rounded-square with raised/pressed states
- CSS 3D: highlight on top edge, shadow on bottom (convex)
- Active/pressed: invert shadows, translate down 2px
- Engraved text labels below each button
- Row of 3-4 buttons on device shell body below screen

### Technical Approach
- Rework ActionButton.tsx styling completely
- Multi-layer box-shadow for raised plastic look
- :active pseudo-class for press animation
- Cooldown indicator: 3px amber drain bar (absolute-positioned, rAF-animated, no layout shift)

### Action Side Effects (implemented)
- Feed: -3 energy, -5 hygiene (eating is messy)
- Play: -8 energy, -10 hygiene (playing gets dirty)
- Clean: -5 energy

### Files to Change
- components/ActionButton.tsx (restyle)
- app/globals.css (button press keyframes)

---

## Phase 4 - Stat Display Rework ✅

Replace tall stacked bars with **circular SVG progress rings** in one row.

### Design (as implemented)
- 4 circular rings in a single row below the screen
- Icon emoji centered inside each ring
- Colored arc fill (green/yellow/red) + faint track ring
- Percentage label below each circle
- Freed vertical space makes the LCD screen taller

### Technical Approach
- StatBar.tsx rewritten: SVG circles with strokeDasharray/strokeDashoffset
- RADIUS=26, strokeLinecap="round", SVG rotated −90° for top-start
- GameContainer stats section: flex-row justify-around
- label prop made optional (no longer rendered)

### Files Changed
- components/StatBar.tsx (full rewrite)
- components/GameContainer.tsx (flex-row layout)
- types/pet.types.ts (label?: optional)


---

## Phase 5 - Pet Interactivity & Animation ✅

Add **life and personality** to the pet through animated behaviors and direct interaction.

### Features (implemented)
- **Idle animations**: Pet randomly blinks, yawns, or fidgets every 4–10s while awake
- **Action animations**: Feed → chew bob, Play → big jump, Clean → spin
- **Mood animations**: Sad → droop sway (looping), Hungry → head-shake (looping)
- **Click/tap**: Click pet for +5 happiness + hearts effect (30s cooldown)
- **Feed particles**: Food emoji particles (🍖🍗🥩🍔🦆) on feed, instead of hearts
- **More random events**: Expanded from 6 to 15 event types

### Technical Approach
- 9 new CSS keyframes in globals.css (blink, yawn, fidget, chew, jump, spin-clean, pet-tap, droop, head-shake)
- Idle system in PetSprite.tsx via useEffect + random setTimeout cycling
- Animation priority: dead > sleeping > action > critical > mood > idle > default
- `actionAnimation` state in usePetState.ts, auto-cleared after each anim duration
- `petTap` callback in usePetState.ts with 30s cooldown ref

### Files Changed
- app/globals.css
- components/PetSprite.tsx
- components/Pet.tsx
- hooks/usePetState.ts
- components/GameContainer.tsx
- lib/constants.ts

---

## Phase 6 - Coin Economy

Add **coin currency** earned through care, spent in shop.

### Game Design
- Earn coins: feeding (+1), playing (+2), cleaning (+1), daily survival (+10)
- Bonus coins for high care score
- Display in device header/status area

### Technical Approach
- Add coins?: number to PetState
- Pure coin reward functions in petLogic.ts
- migrateState() adds coins: 0 default

### Files to Change
- types/pet.types.ts (add coins)
- lib/constants.ts (coin amounts)
- lib/petLogic.ts (coin functions)
- hooks/usePetState.ts (coin rewards in actions)
- components/GameContainer.tsx (coin display)

---

## Phase 6 - Item Shop

**Shop screen** to spend coins on food, toys, accessories.

### Game Design
- Food: apple (+10 hunger/3 coins), steak (+30/8), cake (+15 hunger -5 hygiene/5)
- Toys: ball (+15 happiness/5), puzzle (+20 happiness -5 energy/7)
- Accessories: hat, bow, glasses (cosmetic, 15-25 coins)

### Technical Approach
- New types/item.types.ts (ShopItem, ItemCategory, InventoryEntry)
- New lib/shopData.ts (static item catalog)
- New components/ShopScreen.tsx (item grid with buy buttons)
- New hooks/useNavigation.ts (screen switching)
- PetState gets inventory?: InventoryEntry[]

### Files to Change
- types/item.types.ts (new)
- lib/shopData.ts (new)
- components/ShopScreen.tsx (new)
- hooks/useNavigation.ts (new)
- types/pet.types.ts (add inventory)
- lib/petLogic.ts (item usage)
- components/GameContainer.tsx (navigation)

---

## Phase 7 - Inventory and Usage

Use items and equip accessories on the pet.

### Game Design
- Inventory screen with use/equip buttons
- Food/toys: apply effect, remove from inventory
- Accessories: overlay on pet sprite, max 1 equipped

### Technical Approach
- New components/InventoryScreen.tsx
- Accessory overlay: positioned img on pet sprite in PetSprite.tsx
- SVGs in public/sprites/accessories/
- PetState.equippedAccessory?: string

### Files to Change
- components/InventoryScreen.tsx (new)
- components/PetSprite.tsx (accessory overlay)
- public/sprites/accessories/*.svg (new)
- types/pet.types.ts (equippedAccessory)


---

## Phase 8 - Mini-Game: Memory Match

**Card-flip memory puzzle** in the device screen.

### Game Design
- 4x3 grid (6 pairs), emoji icons
- Fewer moves = more coins (5-15 reward)
- Costs 2 energy to play

### Technical Approach
- Self-contained components/games/MemoryMatch.tsx
- Local state for cards, flips, matches
- CSS flip animation, completion callback

### Files to Change
- components/games/MemoryMatch.tsx (new)
- app/globals.css (card flip animation)
- hooks/usePetState.ts (addCoins, energy cost)
- components/GameContainer.tsx (navigation)

---

## Phase 9 - Mini-Game: Catch Game

**Falling-item reflex game** in the device screen.

### Game Design
- Items fall from top, move pet left/right to catch
- Good items: +1 coin. Bad items: -1 life (3 lives)
- 30 second timer, costs 3 energy

### Technical Approach
- components/games/CatchGame.tsx
- requestAnimationFrame game loop
- Arrow key + touch input, pet sprite as catcher

### Files to Change
- components/games/CatchGame.tsx (new)
- hooks/usePetState.ts (addCoins)
- components/GameContainer.tsx (navigation)

---

## Phase 10 - Screen Transitions

Animated transitions between screens.

### Design
- Slide left/right (300ms) or CRT-style wipe
- Forward = slide left, back = slide right

### Technical Approach
- CSS transitions on LcdScreen container
- Transition direction in useNavigation

### Files to Change
- components/LcdScreen.tsx (transitions)
- app/globals.css (slide/wipe keyframes)
- hooks/useNavigation.ts (transition state)

---

## Phase 11 - 8-Bit Background & Day/Night Cycle

Add a **pixel art background** with real-time sun/moon cycle behind the pet sprite, starting with a grass field theme. Architecture supports future purchasable backgrounds via the item shop.

### Design
- 16x16 pixel grid SVG background matching sprite aesthetic (`shape-rendering="crispEdges"`)
- Sky gradient (rows 0-9) that changes color based on real-world time of day
- Sun (3x3 pixel cross, `#ffdd44`) during dawn/day/dusk, arcing across sky
- Moon (2x2 pixel crescent, `#ccccdd`) during night, arcing across sky
- 12 twinkling stars at night, fading in/out during dawn/dusk transitions
- Grass field ground (rows 10-15) with uneven grass tips and progressively darker earth
- Phase boundaries: dawn 5-7am, day 7am-6pm, dusk 6-8pm, night 8pm-5am
- Smooth color blending at phase transitions (20% boundary overlap)

### Technical Approach
- `useTimeOfDay` hook: reads system clock, updates every 60s, computes phase + celestial arc position
- `Background.tsx`: renders inline SVG with `absolute inset-0`, behind pet sprite via z-index layering
- `backgroundConfig.ts`: theme configs with ground colors per phase (grass implemented, beach/urban/forest stubbed)
- `skyColors.ts`: pure color interpolation utilities for smooth sky transitions
- Color changes via CSS `transition: fill 2s` (GPU-composited, no React re-renders for animation)
- `React.memo` with custom comparator (re-renders only on phase change or >1% celestial movement)

### Future: Item Shop Backgrounds
When Phase 6 (Item Shop) is built, add purchasable backgrounds:
- **Beach** - sandy ground, ocean horizon, seagull pixel details
- **Urban** - gray pavement, building silhouettes on horizon
- **Forest** - dark green ground, tree trunk columns, leaf canopy top

Each theme is a config entry in `BACKGROUND_THEMES` with ground colors per phase. The shop updates `petState.backgroundTheme` and the background instantly switches.

### New Files
- types/background.types.ts (BackgroundTheme, DayPhase, TimeOfDayState, BackgroundConfig)
- hooks/useTimeOfDay.ts (real-time cycle hook)
- lib/backgroundConfig.ts (sky colors, star positions, theme configs)
- lib/skyColors.ts (color interpolation utilities)
- components/Background.tsx (pixel art SVG renderer)

### Files to Change
- components/GameContainer.tsx (add Background, useTimeOfDay, z-index layering)
- lib/constants.ts (DAY_CYCLE phase boundaries, TIME_OF_DAY_UPDATE_INTERVAL)
- types/pet.types.ts (add backgroundTheme? to PetState)
- lib/petLogic.ts (add backgroundTheme to migrateState)
- app/globals.css (add twinkle animation)

## Phase 12 - Polish Pass

- Tune coin economy balance
- Sound effects for shop, items, mini-games
- Block mini-games while sleeping/dead/egg
- Keyboard navigation + ARIA labels
- Performance: unnecessary re-renders
- Mobile touch target sizing
- Stat decay rounding edge cases

---

## Architecture Notes

### Navigation Model
Phases 6+ add screens. No router - client-side state:
- useNavigation hook: currentScreen (main/shop/inventory/memory/catch)
- GameContainer renders active screen via switch
- Each screen gets callbacks for navigation and state changes

### State Shape Evolution
PetState grows with optional fields for backward compat:
- coins?: number (Phase 5)
- inventory?: InventoryEntry[] (Phase 6)
- equippedAccessory?: string (Phase 7)
- backgroundTheme?: BackgroundTheme (Phase 11)
migrateState() fills defaults for all new fields.

### Asset Strategy
- Device shell + LCD overlay: pure CSS (no images)
- Accessory overlays: small SVGs positioned over pet sprite
- Mini-game assets: emoji or CSS shapes (lightweight)
