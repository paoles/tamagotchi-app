class_name Care
extends RefCounted

# ============================================================
# Player actions. Each one acts on the save at `save.sim_time`
# (the caller catches the sim up to "now" first) and returns
# {ok, why, anim, events}. `why` names the refusal reason or
# the outcome, which the UI turns into a bubble icon; `anim`
# tells the pet view what to play.
# ============================================================

static func _res(ok: bool, why: String = "", anim: String = "", events: Array = []) -> Dictionary:
	return {"ok": ok, "why": why, "anim": anim, "events": events}

# Common gate: what stops any interaction right now.
static func blocked(save: Dictionary) -> String:
	if save.daycare.active:
		return "daycare"
	var pet: Dictionary = save.pet
	if pet.is_empty() or not pet.alive:
		return "no_pet"
	if pet.stage == "egg":
		return "egg"
	return ""

static func _awake_gate(save: Dictionary) -> String:
	var b := blocked(save)
	if b != "":
		return b
	if save.pet.asleep:
		return "asleep"
	return ""

static func _refuses(save: Dictionary, pet: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not pet.stage in Cfg.REFUSE_STAGES:
		return false
	return rng.randf() < (100.0 - pet.discipline) / Cfg.REFUSE_DIVISOR

# Feeding or playing during a fake call rewards the tantrum.
static func _spoil(pet: Dictionary, t: int, events: Array) -> void:
	if pet.call.kind == "fake":
		pet.call = SaveState.no_call()
		pet.discipline = clampf(pet.discipline + Cfg.SPOIL_DISCIPLINE, 0.0, 100.0)
		events.append(Sim.ev(t, "spoiled"))

static func _wake_nap(pet: Dictionary) -> void:
	if int(pet.nap_left) > 0:
		pet.nap_left = 0
		pet.lights = true

static func _queue_poop(pet: Dictionary, rng: RandomNumberGenerator) -> void:
	pet.poop_due.append(rng.randi_range(Cfg.POOP_DELAY_MIN, Cfg.POOP_DELAY_MAX))

static func _floor_weight(pet: Dictionary) -> void:
	pet.weight = maxf(pet.weight, Sim.weight_base(pet) * Cfg.WEIGHT_FLOOR_FACTOR)

static func feed_meal(save: Dictionary) -> Dictionary:
	var gate := _awake_gate(save)
	if gate != "":
		return _res(false, gate, "refuse")
	var pet: Dictionary = save.pet
	var t := int(save.sim_time)
	var rng := Sim.rng_from(save)
	var events := []
	_wake_nap(pet)
	if pet.hunger >= Cfg.MEAL_REFUSE_AT:
		return _res(false, "full", "refuse")
	if _refuses(save, pet, rng):
		Sim.rng_store(save, rng)
		return _res(false, "stubborn", "refuse")
	_spoil(pet, t, events)
	pet.hunger = minf(100.0, pet.hunger + Cfg.MEAL_HUNGER)
	pet.weight += Cfg.MEAL_WEIGHT
	_queue_poop(pet, rng)
	Sim.rng_store(save, rng)
	SaveState.bump(save, "meals")
	return _res(true, "meal", "eat", events)

static func feed_snack(save: Dictionary) -> Dictionary:
	var gate := _awake_gate(save)
	if gate != "":
		return _res(false, gate, "refuse")
	var pet: Dictionary = save.pet
	var t := int(save.sim_time)
	var rng := Sim.rng_from(save)
	var events := []
	_wake_nap(pet)
	_spoil(pet, t, events)
	pet.hunger = minf(100.0, pet.hunger + Cfg.SNACK_HUNGER)
	pet.happy = minf(100.0, pet.happy + Cfg.SNACK_HAPPY * Sim.trait_mult(pet, "snack_gain"))
	pet.weight += Cfg.SNACK_WEIGHT
	if rng.randf() < Cfg.SNACK_POOP_CHANCE:
		_queue_poop(pet, rng)
	Sim.rng_store(save, rng)
	SaveState.bump(save, "snacks")
	return _res(true, "snack", "eat", events)

static func play(save: Dictionary, happy: float = Cfg.PLAY_HAPPY, energy: float = Cfg.PLAY_ENERGY, weight: float = Cfg.PLAY_WEIGHT) -> Dictionary:
	var gate := _awake_gate(save)
	if gate != "":
		return _res(false, gate, "refuse")
	var pet: Dictionary = save.pet
	var t := int(save.sim_time)
	var rng := Sim.rng_from(save)
	var events := []
	_wake_nap(pet)
	if pet.energy < maxf(Cfg.PLAY_MIN_ENERGY, energy):
		return _res(false, "tired", "refuse")
	if _refuses(save, pet, rng):
		Sim.rng_store(save, rng)
		return _res(false, "stubborn", "refuse")
	Sim.rng_store(save, rng)
	_spoil(pet, t, events)
	pet.happy = minf(100.0, pet.happy + happy * Sim.trait_mult(pet, "play_gain"))
	pet.energy = maxf(0.0, pet.energy - energy)
	pet.weight -= weight
	_floor_weight(pet)
	SaveState.bump(save, "plays")
	return _res(true, "play", "play", events)

static func clean(save: Dictionary) -> Dictionary:
	var gate := blocked(save)
	if gate != "":
		return _res(false, gate)
	var pet: Dictionary = save.pet
	var n: int = pet.poops.size()
	if n == 0:
		return _res(false, "clean_already")
	pet.poops = []
	if not pet.asleep:
		pet.happy = minf(100.0, pet.happy + n * Cfg.CLEAN_HAPPY_PER_POOP * Sim.trait_mult(pet, "clean_gain"))
	SaveState.bump(save, "poops_cleaned", n)
	return _res(true, "clean", "happy" if not pet.asleep else "")

static func toggle_lights(save: Dictionary) -> Dictionary:
	var gate := blocked(save)
	if gate != "":
		return _res(false, gate)
	var pet: Dictionary = save.pet
	var t := int(save.sim_time)
	var events := []
	if pet.asleep:
		pet.lights = not pet.lights
		if pet.lights and pet.early_bed:
			pet.asleep = false
			pet.early_bed = false
			return _res(true, "lights_on", "", [Sim.ev(t, "woke")])
		return _res(true, "lights_off" if not pet.lights else "lights_on")
	if not pet.lights:
		pet.lights = true
		_wake_nap(pet)
		return _res(true, "lights_on")
	var m := Clock.local_minute(t, Clock.tz_bias())
	if posmod(int(save.schedule.bed) - m, 1440) <= Cfg.EARLY_BED_MIN:
		pet.lights = false
		pet.early_bed = true
		Sim.go_to_bed(pet, t, events)
		return _res(true, "bed_early", "", events)
	if pet.energy < Cfg.LIGHTS_NAP_ENERGY:
		pet.lights = false
		Sim.start_nap(pet, t, events)
		return _res(true, "nap", "", events)
	return _res(false, "not_sleepy", "refuse")

static func scold(save: Dictionary) -> Dictionary:
	var gate := blocked(save)
	if gate != "":
		return _res(false, gate)
	var pet: Dictionary = save.pet
	var t := int(save.sim_time)
	if pet.call.kind == "fake":
		pet.call = SaveState.no_call()
		pet.discipline = clampf(pet.discipline + Cfg.SCOLD_DISCIPLINE * Sim.trait_mult(pet, "discipline_gain"), 0.0, 100.0)
		SaveState.bump(save, "good_scolds")
		return _res(true, "disciplined", "scolded", [Sim.ev(t, "disciplined")])
	pet.happy = clampf(pet.happy + Cfg.UNFAIR_SCOLD_HAPPY, 0.0, 100.0)
	return _res(false, "unfair", "sad")

static func tap(save: Dictionary) -> Dictionary:
	var gate := _awake_gate(save)
	if gate != "":
		return _res(false, gate)
	var pet: Dictionary = save.pet
	if int(pet.nap_left) > 0:
		return _res(false, "napping")
	if int(pet.tap_cd) > 0:
		return _res(true, "giggle", "happy")
	pet.happy = minf(100.0, pet.happy + Cfg.TAP_HAPPY)
	pet.tap_cd = Cfg.TAP_COOLDOWN_MIN
	SaveState.bump(save, "pets")
	return _res(true, "loved", "happy")

static func set_pet_name(save: Dictionary, raw: String) -> String:
	var name := sanitize_name(raw)
	if name == "":
		name = Cfg.NAME_SUGGESTIONS[randi() % Cfg.NAME_SUGGESTIONS.size()]
	save.pet.name = name
	var entry := SaveState.family_entry(save, int(save.pet.id))
	if not entry.is_empty():
		entry.name = name
	return name

static func sanitize_name(raw: String) -> String:
	var out := ""
	for i in raw.length():
		var c := raw[i]
		var code := c.unicode_at(0)
		var ok := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or c in [" ", "-", "'"]
		if ok:
			out += c
	return out.strip_edges().left(Cfg.NAME_MAX)

static func set_schedule(save: Dictionary, bed: int, wake: int) -> bool:
	var hours := Clock.window_len(bed, wake) / 60.0
	if hours < Cfg.SLEEP_HOURS_MIN or hours > Cfg.SLEEP_HOURS_MAX:
		return false
	save.schedule.bed = posmod(bed, 1440)
	save.schedule.wake = posmod(wake, 1440)
	save.settings.schedule_set = true
	return true

static func start_daycare(save: Dictionary) -> Dictionary:
	var gate := blocked(save)
	if gate != "":
		return _res(false, gate)
	var free_left := Cfg.DAYCARE_FREE_MIN - int(save.daycare.used_day)
	if free_left <= 0 and int(save.coins) < Cfg.DAYCARE_COINS_PER_HOUR:
		return _res(false, "broke")
	save.daycare.active = true
	save.daycare.min = 0
	return _res(true, "daycare_in")

static func end_daycare(save: Dictionary) -> Dictionary:
	if not save.daycare.active:
		return _res(false, "not_in_daycare")
	var events := []
	Sim.end_daycare(save, int(save.sim_time), events, "picked_up")
	return _res(true, "daycare_out", "happy", events)

# Mini-game finished: rewards scale with how well it went.
static func game_reward(save: Dictionary, coins: int, happy: float, energy: float, weight: float) -> Dictionary:
	var pet: Dictionary = save.pet
	pet.happy = minf(100.0, pet.happy + happy * Sim.trait_mult(pet, "play_gain"))
	pet.energy = maxf(0.0, pet.energy - energy)
	pet.weight -= weight
	_floor_weight(pet)
	save.coins += coins
	SaveState.bump(save, "coins_earned", coins)
	SaveState.bump(save, "games")
	return _res(true, "game", "happy")
