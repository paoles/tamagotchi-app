class_name S
extends RefCounted

# ============================================================
# Every player-facing string. `S.t("key", {"name": n})` fills
# {placeholders}. English only for now; a translation would be
# another table with the same keys.
# ============================================================

const T := {
	"title": "Pixel Pet",
	"tagline": "A tiny friend that lives in real time.",

	# Actions
	"act_feed": "Feed", "act_play": "Play", "act_clean": "Clean",
	"act_lights": "Light", "act_scold": "Scold", "act_more": "More",
	"feed_meal": "Meal", "feed_snack": "Snack",
	"play_basic": "Play together",
	"more_status": "Status", "more_shop": "Shop", "more_wardrobe": "Wardrobe",
	"more_decor": "Decorate", "more_book": "Book", "more_family": "Family",
	"more_memorial": "Memorial", "more_daycare": "Daycare", "more_settings": "Settings",
	"more_achievements": "Badges",

	# Stats
	"stat_hunger": "Hunger", "stat_happy": "Happy", "stat_energy": "Energy",
	"stat_discipline": "Discipline", "stat_weight": "Weight", "stat_age": "Age",
	"stat_stage": "Stage", "stat_traits": "Traits", "stat_gen": "Generation",
	"stat_mistakes": "Care mistakes", "stat_next": "Next stage in",
	"stage_egg": "Egg", "stage_baby": "Baby", "stage_child": "Child",
	"stage_teen": "Teen", "stage_adult": "Adult",

	# Traits
	"trait_playful": "Playful", "trait_glutton": "Glutton", "trait_sleepy": "Sleepy",
	"trait_tidy": "Tidy", "trait_stubborn": "Stubborn", "trait_cheerful": "Cheerful",
	"traitd_playful": "Gets bored faster, loves games more.",
	"traitd_glutton": "Gets hungry faster, adores snacks.",
	"traitd_sleepy": "Tires faster, naps longer.",
	"traitd_tidy": "Hates mess, loves a clean room.",
	"traitd_stubborn": "Acts up more, slow to learn.",
	"traitd_cheerful": "Stays happy longer.",

	# Toasts
	"t_full": "{name} is full!",
	"t_stubborn": "{name} refuses!",
	"t_tired": "{name} is too tired.",
	"t_asleep": "Shh... {name} is sleeping.",
	"t_egg": "The egg is still warming up.",
	"t_daycare": "{name} is at daycare.",
	"t_clean_already": "Already spotless!",
	"t_not_sleepy": "{name} isn't sleepy.",
	"t_unfair": "{name} didn't do anything wrong...",
	"t_disciplined": "{name} behaves!",
	"t_napping": "{name} is napping.",
	"t_spoiled": "{name} got away with a tantrum.",
	"t_evolved": "{name} grew into a {form}!",
	"t_hatched": "The egg hatched!",
	"t_daily_bonus": "Perfect day! +{coins} coins",
	"t_mistake": "Care mistake...",
	"t_coins": "+{coins} coins",
	"t_saved": "Saved",

	# Hatch flow
	"name_title": "Name your pet",
	"name_hint": "Up to 10 letters",
	"name_ok": "Done!",
	"name_random": "Surprise me",
	"sched_title": "Bedtime",
	"sched_body": "When should your pet sleep? Pick hours that match your day. No alerts while it sleeps.",
	"sched_bed": "Bed", "sched_wake": "Wake",
	"sched_ok": "Sounds good",
	"sched_bad": "Sleep must be 7 to 11 hours.",

	# Away recap
	"recap_title": "Welcome back!",
	"recap_ok": "Okay!",
	"recap_hatched": "The egg hatched",
	"recap_evolved": "Grew into a {form}",
	"recap_pooped": "Pooped {n}x",
	"recap_mistake": "{n} care mistake(s)",
	"recap_why_lights": "Lights left on at bedtime",
	"recap_why_poop": "Poop left too long ({n}x)",
	"recap_why_ignored_call": "Calls went unanswered ({n}x)",
	"recap_call": "Called for you {n}x",
	"recap_slept": "Slept",
	"recap_nap": "Took {n} nap(s)",
	"recap_bonus": "Daily bonus +{coins}",
	"recap_daycare": "Came home from daycare",
	"recap_nothing": "Not much happened.",

	# Death / memorial
	"rip_old_age": "{name} lived a long, happy life.",
	"rip_neglect": "{name} has passed away...",
	"rip_old_age_sub": "It left an egg behind.",
	"rip_neglect_sub": "A new egg appeared. Take good care of it.",
	"rip_continue": "Welcome the new egg",
	"rip_legacy": "Legacy bonus +{coins} coins",
	"memorial_title": "Memorial",
	"memorial_empty": "No graves. Keep it that way!",
	"cause_old_age": "Old age", "cause_neglect": "Neglect",

	# Daycare
	"daycare_title": "Daycare",
	"daycare_body": "Time stops for your pet while it's here. {free} free today, then {cost} coins an hour.",
	"daycare_drop": "Drop off", "daycare_pick": "Pick up",
	"daycare_inside": "{name} is playing at daycare. Time is paused.",

	# Settings
	"set_title": "Settings",
	"set_sound": "Sound effects", "set_music": "Music", "set_motion": "Reduced motion",
	"set_push": "Notifications", "set_push_enable": "Turn on notifications",
	"set_push_on": "Notifications are on", "set_push_unsupported": "Not supported here. Add Pixel Pet to your Home Screen first.",
	"set_bedtime": "Bedtime", "set_transfer": "Move to another device",
	"set_backup": "Cloud backup", "set_version": "Version",
	"push_needs": "Needs (hungry, sad)", "push_poop": "Poop", "push_lights": "Lights at bedtime",
	"push_attention": "Attention calls", "push_milestones": "Hatch & evolve", "push_fun": "Fun moments",

	# Push
	"p_hungry": "{name} is getting hungry!",
	"p_happy": "{name} feels lonely.",
	"p_poop": "{name}'s room needs cleaning.",
	"p_lights": "{name} can't sleep with the lights on.",
	"p_attention": "{name} is calling you!",
	"p_danger": "{name} is in danger! Please check on it.",
	"p_hatch": "The egg is hatching!",
	"p_evolved": "{name} is growing up!",
	"p_old_age": "Come say goodbye to {name}.",
	"p_daycare": "{name} is home from daycare.",

	"ok": "OK", "close": "Close", "back": "Back", "cancel": "Cancel", "yes": "Yes", "no": "No",
}

static func t(key: String, args: Dictionary = {}) -> String:
	var s: String = T.get(key, key)
	if args.is_empty():
		return s
	return s.format(args)
