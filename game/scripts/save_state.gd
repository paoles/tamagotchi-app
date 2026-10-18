class_name SaveState
extends RefCounted

# ============================================================
# The save schema. The whole game is one Dictionary that goes
# to JSON as-is. Every age, timer and countdown is a minute
# counter rather than a timestamp, so the babysitter can freeze
# a pet just by not stepping it. Any field added later gets a
# default in `migrate()`, so older saves keep loading.
# ============================================================

static func new_save(t: int) -> Dictionary:
	var save := {
		"version": Cfg.SAVE_VERSION,
		"created_at": t,
		"saved_at": t,
		"sim_time": t,
		"rng": {"seed": str(randi()), "state": "0"},
		"next_id": 1,
		"day_key": 0,
		"device": {"id": _uuid(), "secret": _uuid()},
		"settings": {
			"sound": true, "music": true, "reduced_motion": false,
			"push": Cfg.PUSH_DEFAULTS.duplicate(), "push_enabled": false,
			"debug_unlocked": false, "schedule_set": false,
		},
		"schedule": {"bed": Cfg.DEFAULT_BED, "wake": Cfg.DEFAULT_WAKE},
		"pet": {},
		"coins": Cfg.START_COINS,
		"inventory": {},
		"owned": {},
		"equipped": {"head": "", "face": "", "neck": ""},
		"room": {
			"wallpaper": "wall_cream", "floor": "floor_oak",
			"slots": {"wall_l": "", "wall_r": "", "floor_l": "", "floor_r": "", "corner": "", "rug": "", "sill": ""},
		},
		"book": {},
		"family": [],
		"achievements": {},
		"counters": {},
		"daycare": {"active": false, "min": 0, "used_day": 0},
		"recap": [],
		"debug_offset": 0,
		"last_backup": 0,
	}
	return save

static func new_pet(save: Dictionary, t: int, gen: int, line: int, parent_id: int, traits: Array) -> Dictionary:
	var id := int(save.next_id)
	save.next_id = id + 1
	return {
		"id": id, "name": "", "gen": gen, "line": line, "parent": parent_id,
		"alive": true, "cause": "", "died_at": 0, "laid_at": t, "hatched_at": 0,
		"stage": "egg", "form": "egg", "stage_min": 0, "age_min": 0, "lifespan_min": 0,
		"traits": traits,
		"hunger": 0.0, "happy": 0.0, "energy": 0.0, "discipline": 0.0, "weight": 0.0,
		"asleep": false, "early_bed": false, "lights": true, "nap_left": 0, "lights_min": 0, "lights_flag": false,
		"poops": [], "poop_due": [],
		"call": no_call(),
		"fake_today": [],
		"mistakes": 0, "mistakes_total": 0, "day_mistakes": 0, "stage_mistakes": {},
		"neglect_min": 0.0, "tap_cd": 0,
	}

static func no_call() -> Dictionary:
	return {"kind": "", "min": 0, "flag": false, "reason": ""}

# Fills defaults for anything missing (older or hand-edited saves)
# and turns JSON's floats back into ints where they are whole numbers.
static func migrate(raw: Dictionary) -> Dictionary:
	var save: Dictionary = normalize(raw)
	var fresh := new_save(int(save.get("created_at", Clock.now())))
	_fill(save, fresh)
	if not save.pet.is_empty():
		var pet_defaults := new_pet({"next_id": 0}, 0, 1, 1, 0, [])
		_fill(save.pet, pet_defaults)
		_fill(save.pet.call, no_call())
	for k in Cfg.PUSH_DEFAULTS:
		if not save.settings.push.has(k):
			save.settings.push[k] = Cfg.PUSH_DEFAULTS[k]
	save.version = Cfg.SAVE_VERSION
	return save

static func _fill(target: Dictionary, defaults: Dictionary) -> void:
	for k in defaults:
		if not target.has(k):
			target[k] = defaults[k]
		elif target[k] is Dictionary and defaults[k] is Dictionary and k != "push" and k != "slots":
			_fill(target[k], defaults[k])

static func normalize(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = normalize(v[k])
		return out
	if v is Array:
		var arr := []
		for x in v:
			arr.append(normalize(x))
		return arr
	if v is float and is_finite(v) and v == floorf(v) and absf(v) < 9.0e15:
		return int(v)
	return v

static func to_json(save: Dictionary) -> String:
	return JSON.stringify(save)

static func from_json(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed: Variant = json.data
	if parsed is Dictionary and parsed.has("version") and parsed.has("pet"):
		return migrate(parsed)
	return {}

static func family_entry(save: Dictionary, pet_id: int) -> Dictionary:
	for e in save.family:
		if int(e.id) == pet_id:
			return e
	return {}

static func bump(save: Dictionary, counter: String, by: int = 1) -> void:
	save.counters[counter] = int(save.counters.get(counter, 0)) + by

static func _uuid() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
