class_name Cfg
extends RefCounted

# ============================================================
# Every tuning number in one place. Durations are in minutes
# and rates are per hour unless a name says otherwise. The sim
# runs in 1-minute steps, so per-hour rates are divided by 60.
# Values target "casual" care: 3–4 check-ins a day.
# ============================================================

const SAVE_VERSION := 1
const STEP_SEC := 60

# --- Life stages ---------------------------------------------
const STAGES := ["egg", "baby", "child", "teen", "adult"]
const STAGE_MIN := {"egg": 10, "baby": 1440, "child": 2880, "teen": 4320}
const ADULT_BASE_MIN := 8 * 1440
const ADULT_BONUS_MAX_MIN := 2 * 1440
# Mistakes made before adulthood that cancel the whole longevity bonus.
const ADULT_BONUS_MISTAKES := 8

# --- Drains --------------------------------------------------
const HUNGER_DRAIN := {"baby": 10.0, "child": 8.0, "teen": 7.0, "adult": 6.0}
const HAPPY_DRAIN := {"baby": 8.0, "child": 7.0, "teen": 6.0, "adult": 5.0}
const SLEEP_DRAIN_MULT := 0.1
const NAP_DRAIN_MULT := 0.5
const POOP_HAPPY_DRAIN := 1.5          # per poop on the floor
const OVERWEIGHT_HAPPY_DRAIN := 2.0

# --- Energy and naps -----------------------------------------
const ENERGY_DRAIN := 5.0
const ENERGY_SLEEP_GAIN := 12.0
const ENERGY_NAP_GAIN := 20.0
const NAP_THRESHOLD := 20.0            # below this the pet dozes off by itself
const NAP_MIN := 45
const LIGHTS_NAP_ENERGY := 70.0        # lights off by day → nap if energy is below this
const EARLY_BED_MIN := 90              # lights off this close to bedtime → off to bed early

# --- Care actions --------------------------------------------
const MEAL_HUNGER := 35.0
const MEAL_WEIGHT := 1.0
const MEAL_REFUSE_AT := 95.0
const SNACK_HUNGER := 10.0
const SNACK_HAPPY := 15.0
const SNACK_WEIGHT := 2.0
const SNACK_POOP_CHANCE := 0.5
const PLAY_HAPPY := 20.0
const PLAY_ENERGY := 5.0
const PLAY_WEIGHT := 0.5
const PLAY_MIN_ENERGY := 5.0
const TAP_HAPPY := 5.0
const TAP_COOLDOWN_MIN := 10
const CLEAN_HAPPY_PER_POOP := 2.0

# --- Poop ----------------------------------------------------
const POOP_DELAY_MIN := 30
const POOP_DELAY_MAX := 90
const POOP_MAX := 4
const POOP_MISTAKE_MIN := 360          # a poop left this long is a care mistake

# --- Sleep and calls -----------------------------------------
const DEFAULT_BED := 22 * 60
const DEFAULT_WAKE := 7 * 60
const SLEEP_HOURS_MIN := 7
const SLEEP_HOURS_MAX := 11
const LIGHTS_GRACE_MIN := 30           # lights still on this long after bedtime = mistake
const NEED_CALL_MISTAKE_MIN := 60
const FAKE_CALL_STAGES := ["child", "teen"]
const FAKE_CALLS_MIN := 2
const FAKE_CALLS_MAX := 3
const FAKE_CALL_MIN := 90              # how long a fake call waits to be scolded
const SCOLD_DISCIPLINE := 25.0
const SPOIL_DISCIPLINE := -5.0
const UNFAIR_SCOLD_HAPPY := -20.0
const REFUSE_DIVISOR := 400.0          # refuse chance = (100 - discipline) / this
const REFUSE_STAGES := ["child", "teen", "adult"]

# --- Weight --------------------------------------------------
const WEIGHT_BASE := {"egg": 0.0, "baby": 5.0, "child": 10.0, "teen": 20.0, "adult": 30.0}
const OVERWEIGHT_FACTOR := 1.5
const METABOLISM := 0.3                # weight burned per awake hour while above base
const WEIGHT_FLOOR_FACTOR := 0.8

# --- Neglect -------------------------------------------------
const NEGLECT_DEATH_MIN := 1440
const NEGLECT_RECOVER_RATE := 2.0
const NEGLECT_RECOVER_ABOVE := 50.0

# --- Starting values -----------------------------------------
const HATCH_HUNGER := 70.0
const HATCH_HAPPY := 70.0
const HATCH_ENERGY := 100.0

# --- Coins ---------------------------------------------------
const START_COINS := 50
const DAILY_BONUS := 10
const EVOLVE_COINS := 20
const LEGACY_COINS := 50

# --- Babysitter ----------------------------------------------
const DAYCARE_FREE_MIN := 240          # free minutes per local day
const DAYCARE_COINS_PER_HOUR := 10
const DAYCARE_MAX_MIN := 720

# --- Forecast / push -----------------------------------------
const FORECAST_HORIZON_MIN := 1440
const ALERT_MAX := 6
const ALERT_SPACING_MIN := 60
const ALERT_LOW_STAT := 20.0
const ALERT_POOP_COUNT := 2
const ALERT_LIGHTS_AFTER_MIN := 15
const ALERT_NEGLECT_MIN := 1080        # neglect this deep → "in danger"
const PUSH_CATEGORIES := ["needs", "poop", "lights", "attention", "milestones", "fun"]
const PUSH_DEFAULTS := {
	"needs": true, "poop": true, "lights": true,
	"attention": false, "milestones": true, "fun": false,
}

# --- Traits --------------------------------------------------
# Each trait scales a few rates. Missing keys mean 1.0.
const TRAITS := {
	"playful":  {"happy_drain": 1.2, "play_gain": 1.3},
	"glutton":  {"hunger_drain": 1.2, "snack_gain": 1.5},
	"sleepy":   {"energy_drain": 1.25, "nap_len": 1.3},
	"tidy":     {"poop_penalty": 1.5, "clean_gain": 2.0},
	"stubborn": {"discipline_gain": 0.6, "fake_calls": 1.0},
	"cheerful": {"happy_drain": 0.8},
}
const TRAIT_IDS := ["playful", "glutton", "sleepy", "tidy", "stubborn", "cheerful"]

# --- Forms ---------------------------------------------------
# The whole family. `hint` is shown in the collection book before
# a form has been discovered.
const FORMS := {
	"egg":       {"stage": "egg",   "name": "Egg",       "hint": "Every story starts here."},
	"mochi":     {"stage": "baby",  "name": "Mochi",     "hint": "Hatches from every egg."},
	"puffle":    {"stage": "child", "name": "Puffle",    "hint": "A baby raised with few mistakes."},
	"smudge":    {"stage": "child", "name": "Smudge",    "hint": "A baby that was left wanting."},
	"bloom":     {"stage": "teen",  "name": "Bloom",     "hint": "A disciplined Puffle."},
	"zippy":     {"stage": "teen",  "name": "Zippy",     "hint": "A Puffle that ran wild."},
	"pudding":   {"stage": "teen",  "name": "Pudding",   "hint": "A disciplined Smudge."},
	"grumble":   {"stage": "teen",  "name": "Grumble",   "hint": "A Smudge nobody scolded."},
	"lumina":    {"stage": "adult", "name": "Lumina",    "hint": "A Bloom cared for carefully."},
	"sprout":    {"stage": "adult", "name": "Sprout",    "hint": "A Bloom with a few rough days."},
	"comet":     {"stage": "adult", "name": "Comet",     "hint": "A Zippy cared for carefully."},
	"rascal":    {"stage": "adult", "name": "Rascal",    "hint": "A Zippy with a few rough days."},
	"dumpling":  {"stage": "adult", "name": "Dumpling",  "hint": "What every Pudding becomes."},
	"grumpus":   {"stage": "adult", "name": "Grumpus",   "hint": "What every Grumble becomes."},
	"starlight": {"stage": "adult", "name": "Starlight", "hint": "Secret: a flawless, perfectly behaved teen."},
	"chonk":     {"stage": "adult", "name": "Chonk",     "hint": "Secret: a teen that loved snacks a bit too much."},
}
const FORM_ORDER := [
	"egg", "mochi", "puffle", "smudge", "bloom", "zippy", "pudding", "grumble",
	"lumina", "sprout", "comet", "rascal", "dumpling", "grumpus", "starlight", "chonk",
]
const ADULT_FORMS := ["lumina", "sprout", "comet", "rascal", "dumpling", "grumpus", "starlight", "chonk"]

# --- Names ---------------------------------------------------
const NAME_MAX := 10
const NAME_SUGGESTIONS := [
	"Mochi", "Pip", "Bean", "Nori", "Tofu", "Kiwi", "Momo", "Biscuit",
	"Pebble", "Juno", "Sprinkle", "Waffle", "Miso", "Peach", "Dot", "Bun",
]
