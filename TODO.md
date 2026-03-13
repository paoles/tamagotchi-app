## Deployment

- [x] Publish to GitHub (https://github.com/paoles/tamagotchi-app)
- [x] Deploy to Vercel (auto-deploys on push to main)
- [x] Fix TypeScript build errors (ActionEffects FOOD_EMOJIS, usePetState name cast)

---

# Tamagotchi App - TODO

Actionable checklist. See PLAN.md for detailed design per phase.

---

## Phase 1 - Device Shell

- [x] Create components/DeviceShell.tsx with rounded plastic body shape
- [x] Add CSS gradients for matte plastic surface look
- [x] Add multi-layer box-shadows for 3D depth
- [x] Add decorative screw dots in corners
- [x] Add brand/logo text above screen area
- [x] Add lanyard loop decoration
- [x] Inset screen viewport area within the shell
- [x] Layout button zone below the screen
- [x] Make device responsive (scales with viewport, maintains aspect ratio)
- [x] Update app/page.tsx to render DeviceShell wrapping GameContainer
- [x] Move the TAMAGOTCHI title into the device shell header
- [x] Test on mobile and desktop viewport sizes

## Phase 2 - LCD Screen Overhaul

- [x] Create components/LcdScreen.tsx reusable wrapper
- [x] Add pale green-yellow LCD background color (#9bbc0f palette)
- [x] Add CSS pixel grid overlay (repeating-linear-gradient)
- [x] Add inner shadow for recessed screen depth
- [x] Replace green LCD aesthetic with pastel mint screen (#d4f0e0) — light playful feel
- [x] Remove LCD pixel grid overlay; update sprite drop-shadow and text colors for mint bg
- [x] Replace screen bezel div in GameContainer with LcdScreen
- [x] Verify all moods/stages look good on LCD background
- [x] Ensure activity log text is readable on green background

## Phase 3 - Physical Buttons

- [x] Redesign ActionButton.tsx with 3D raised plastic styling
- [x] Add multi-layer box-shadow for convex button surface
- [x] Add :active press animation (invert shadows, translate down)
- [x] Style button labels as engraved text below buttons
- [x] Rework cooldown indicator (rAF-animated drain bar — no layout shift)
- [x] Arrange buttons in device-appropriate layout (row below screen)
- [x] Ensure disabled state is visually distinct
- [x] Test button press feel and timing

## Phase 4 - Stat Display Rework

- [x] Rewrite StatBar.tsx as circular SVG progress rings (icon in center)
- [x] SVG stroke-dasharray/dashoffset for smooth arc fill
- [x] Maintain color coding (green > yellow > red thresholds)
- [x] Keep flash-warning animation for stats below 15%
- [x] All 4 circles fit in one row below LCD; LCD screen grows to fill freed space
- [x] Tested on desktop and mobile — consistent sizing

## Pre-Phase 5 - Gameplay Mechanics

- [x] Actions consume energy: feed (-3), play (-8), clean (-5)
- [x] Actions reduce hygiene: feed (-5), play (-10)

## Phase 5 - Pet Interactivity & Animation

- [x] Add CSS keyframes: blink, yawn, fidget, chew, jump, spin-clean, pet-tap, droop, head-shake (globals.css)
- [x] Idle animation system in PetSprite.tsx (random 4-10s interval: blink/yawn/fidget)
- [x] Action animations: feed → chew, play → jump, clean → spin (usePetState.ts + PetSprite.tsx)
- [x] Mood-based animations: sad → droop, hungry → head-shake (PetSprite.tsx)
- [x] Click/tap pet → +5 happiness, hearts effect, log entry (30s cooldown) (usePetState.ts)
- [x] Wrap pet sprite in clickable button (PetSprite.tsx)
- [x] Thread actionAnimation + onPetClick props through Pet.tsx
- [x] Wire handlePetTap in GameContainer.tsx
- [x] Expand RANDOM_EVENTS from 6 to 15 events (constants.ts)
- [x] Fix pet-tap: gate sound on cooldown result, move actionAnimation priority above critical, improve keyframe (0.5s bounce+scale+rotate)
- [x] Change feed floating particles from hearts to food emojis (ActionEffects.tsx)

## Phase 6 - Coin Economy

- [ ] Add coins?: number to PetState in types/pet.types.ts
- [ ] Add coin reward constants to lib/constants.ts
- [ ] Add awardCoins pure function to lib/petLogic.ts
- [ ] Update migrateState() to default coins: 0
- [ ] Award coins on feed (+1) in usePetState.ts
- [ ] Award coins on play (+2) in usePetState.ts
- [ ] Award coins on clean (+1) in usePetState.ts
- [ ] Add daily survival bonus (+10 coins)
- [ ] Add care score bonus coin logic
- [ ] Display coin counter in GameContainer header
- [ ] Add coin earn sound effect
- [ ] Add coin earn visual feedback (floating +N)

## Phase 7 - Item Shop

- [ ] Create types/item.types.ts (ShopItem, ItemCategory, InventoryEntry)
- [ ] Create lib/shopData.ts with food item catalog
- [ ] Add toy items to catalog
- [ ] Add accessory items to catalog
- [ ] Create hooks/useNavigation.ts for screen switching
- [ ] Create components/ShopScreen.tsx with item grid
- [ ] Add buy button with coin cost display
- [ ] Add purchase logic (deduct coins, add to inventory)
- [ ] Add insufficient funds feedback
- [ ] Add inventory?: InventoryEntry[] to PetState
- [ ] Update migrateState() for inventory default
- [ ] Add Shop navigation button to main screen
- [ ] Add Back button to shop screen
- [ ] Add purchase sound effect

## Phase 8 - Inventory and Usage

- [ ] Create components/InventoryScreen.tsx
- [ ] Add item list with use/equip buttons
- [ ] Implement food usage (apply stat effect, remove from inventory)
- [ ] Implement toy usage (apply effect, remove from inventory)
- [ ] Add equippedAccessory?: string to PetState
- [ ] Implement equip/unequip for accessories
- [ ] Add accessory overlay rendering in PetSprite.tsx
- [ ] Create public/sprites/accessories/hat.svg
- [ ] Create public/sprites/accessories/bow.svg
- [ ] Create public/sprites/accessories/glasses.svg
- [ ] Add Inventory navigation button to main screen
- [ ] Add item use sound effect

## Phase 9 - Mini-Game: Memory Match

- [ ] Create components/games/MemoryMatch.tsx
- [ ] Implement 4x3 card grid with shuffled pairs
- [ ] Add card flip animation (CSS 3D transform)
- [ ] Add match detection logic
- [ ] Add move counter
- [ ] Calculate coin reward based on moves (5-15 coins)
- [ ] Deduct 2 energy on game start
- [ ] Add win screen with coin reward display
- [ ] Add flip/match/win sound effects
- [ ] Add Games navigation button to main screen
- [ ] Block access if energy < 2 or sleeping/dead/egg

## Phase 10 - Mini-Game: Catch Game

- [ ] Create components/games/CatchGame.tsx
- [ ] Implement falling item spawner
- [ ] Implement requestAnimationFrame game loop
- [ ] Add left/right movement (arrow keys)
- [ ] Add touch/swipe input for mobile
- [ ] Add on-screen left/right buttons
- [ ] Pet sprite as catcher at bottom
- [ ] Good items: +1 coin on catch
- [ ] Bad items: -1 life on catch (3 lives)
- [ ] 30 second game timer
- [ ] Deduct 3 energy on game start
- [ ] End screen with coin total
- [ ] Add catch/miss/game-over sound effects
- [ ] Block access if energy < 3 or sleeping/dead/egg

## Phase 11 - Screen Transitions

- [ ] Add transition state to useNavigation.ts
- [ ] Add slide-left CSS keyframe animation
- [ ] Add slide-right CSS keyframe animation
- [ ] Wrap screen content in LcdScreen with transition class
- [ ] Forward navigation = slide left
- [ ] Back navigation = slide right
- [ ] Ensure transitions are 300ms and snappy
- [ ] Test all screen switch paths

## Constraints

- [x] Screen size must stay consistent at all times — no layout shifts or size changes between states, screens, or interactions
- [x] Entire device must fit within the viewport at all times — zoom scales down on small screens, activity log moved to popup overlay
- [x] Desktop/mobile parity: max-height 780px cap, lanyard visible on both, rounded body on mobile, New Egg button always inline

## Phase 12 - 8-Bit Background & Day/Night Cycle

### Types & Constants
- [ ] Create types/background.types.ts (BackgroundTheme, DayPhase, TimeOfDayState, BackgroundConfig)
- [ ] Add DAY_CYCLE phase boundary constants to lib/constants.ts
- [ ] Add TIME_OF_DAY_UPDATE_INTERVAL constant to lib/constants.ts

### Pure Logic & Config
- [ ] Create lib/skyColors.ts with lerpColor() and getSkyColors() utilities
- [ ] Create lib/backgroundConfig.ts with SKY_COLORS, STAR_POSITIONS, BACKGROUND_THEMES
- [ ] Add grass theme ground colors for all 4 phases (dawn, day, dusk, night)
- [ ] Stub beach, urban, forest theme configs (ground colors only, for future shop)

### Hook
- [ ] Create hooks/useTimeOfDay.ts (reads system clock, computes phase + celestial position)
- [ ] Update every 60s via setInterval
- [ ] Compute celestial arc position (parabolic: horizon -> zenith -> horizon)

### Background Component
- [ ] Create components/Background.tsx with 16x16 SVG viewBox
- [ ] Render sky gradient (rows 0-9) with phase-based colors
- [ ] Render sun (3x3 pixel cross) during dawn/day/dusk with arc positioning
- [ ] Render moon (2x2 pixel crescent) during night with arc positioning
- [ ] Render 12 twinkling stars during night (fade in/out during dawn/dusk)
- [ ] Render grass field ground (rows 10-15) with uneven grass tips
- [ ] Add progressively darker earth rows for depth
- [ ] Wrap in React.memo with custom comparator for performance
- [ ] Add CSS transition on fill for smooth color changes

### Integration
- [ ] Add backgroundTheme? field to PetState in types/pet.types.ts
- [ ] Update migrateState() in lib/petLogic.ts to default backgroundTheme to "grass"
- [ ] Add twinkle keyframe animation to app/globals.css
- [ ] Import and call useTimeOfDay() in GameContainer.tsx
- [ ] Add Background component to screen bezel div (before Pet, absolute inset-0)
- [ ] Add z-index layering: background z-0, pet z-10, effects z-20
- [ ] Ensure overflow-hidden on screen bezel for proper clipping

### Verification
- [ ] Verify sky color matches current time of day
- [ ] Verify sun visible during daytime, moon at night
- [ ] Verify stars twinkle at night, fade during transitions
- [ ] Verify grass field renders with proper pixel art aesthetic
- [ ] Verify pet sprite renders correctly on top of background
- [ ] Verify all pet animations (bounce, tremble, sleep-bob) still work
- [ ] Verify screen shake on critical mood still works
- [ ] Verify egg stage looks good with background
- [ ] Test by temporarily compressing DAY_CYCLE to verify all phases

### Future: Item Shop Backgrounds (do NOT implement now)
- [ ] Beach background (sandy ground, ocean horizon) - available in shop
- [ ] Urban background (gray pavement, building silhouettes) - available in shop
- [ ] Forest background (dark green ground, tree trunks, leaf canopy) - available in shop


## Phase 13 - Polish Pass

- [ ] Play-test and tune coin reward amounts
- [ ] Play-test and tune item prices
- [ ] Play-test and tune mini-game difficulty
- [ ] Add sound effects: shop purchase, item use, mini-game events
- [ ] Block mini-game access while sleeping/dead/egg
- [ ] Add keyboard navigation for all interactive elements
- [ ] Add ARIA labels to buttons and game elements
- [ ] Profile for unnecessary re-renders
- [ ] Test mobile touch targets (min 44x44px)
- [ ] Fix any stat decay rounding issues near zero
- [ ] Final visual review of device shell on various screen sizes
