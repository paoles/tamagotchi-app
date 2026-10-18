class_name Sim
extends RefCounted

# ============================================================
# The pure life simulation. `advance()` walks a save forward in
# 1-minute steps from `save.sim_time` to `t1` and returns what
# happened. The same code drives live play, offline catch-up,
# the push forecast and the headless harness. It touches only
# the save Dictionary: no nodes, no I/O, and randomness comes
# from the RNG state stored in the save, so every run of the
# same save over the same span gives the same result.
# ============================================================

static func advance(save: Dictionary, t1: int) -> Array:
	var events: Array = []
	var rng := rng_from(save)
	var tz := Clock.tz_bias()
	var t := int(save.sim_time)
	while t + Cfg.STEP_SEC <= t1:
		t += Cfg.STEP_SEC
		step(save, t, tz, rng, events)
	save.sim_time = t
	rng_store(save, rng)
	return events

static func rng_from(save: Dictionary) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = String(save.rng.seed).to_int()
	var st := String(save.rng.state).to_int()
	if st != 0:
		r.state = st
	return r

static func rng_store(save: Dictionary, r: RandomNumberGenerator) -> void:
	save.rng.state = str(r.state)

static func ev(t: int, type: String, data: Dictionary = {}) -> Dictionary:
	var e := {"t": t, "type": type}
	e.merge(data)
	return e

# --- One simulated minute -------------------------------------

static func step(save: Dictionary, t: int, tz: int, rng: RandomNumberGenerator, out: Array) -> void:
	var m := Clock.local_minute(t, tz)
	var day := Clock.day_key(t, tz)
	if day != int(save.day_key):
		_new_day(save, day, t, rng, out)
	if save.daycare.active:
		_daycare_tick(save, t, out)
		return
	var pet: Dictionary = save.pet
	if pet.is_empty() or not pet.alive:
		return
	if pet.stage == "egg":
		pet.stage_min += 1
		if pet.stage_min >= Cfg.STAGE_MIN.egg:
			_hatch(save, pet, t, m, rng, out)
		return
	_sleep_tick(save, pet, m, t, rng, out)
	_stats_tick(pet)
	_poop_tick(save, pet, t, rng, out)
	_calls_tick(save, pet, m, t, out)
	_neglect_tick(save, pet, t, out)
	if pet.alive:
		_age_tick(save, pet, t, rng, out)

static func _new_day(save: Dictionary, day: int, t: int, rng: RandomNumberGenerator, out: Array) -> void:
	var first := int(save.day_key) == 0
	save.day_key = day
	save.daycare.used_day = 0
	var pet: Dictionary = save.pet
	if pet.is_empty() or not pet.alive:
		return
	if not first and pet.stage != "egg" and int(pet.day_mistakes) == 0:
		save.coins += Cfg.DAILY_BONUS
		SaveState.bump(save, "perfect_days")
		SaveState.bump(save, "coins_earned", Cfg.DAILY_BONUS)
		out.append(ev(t, "daily_bonus", {"coins": Cfg.DAILY_BONUS}))
	pet.day_mistakes = 0

# Fake calls are planned each morning as offsets (minutes after
# waking), sorted, keeping an hour clear at both ends of the day.
# One that comes due while the pet can't call (napping, already
# calling) waits for the next free minute instead of being lost.
static func schedule_fake_calls(save: Dictionary, pet: Dictionary, rng: RandomNumberGenerator, from_offset: int = 0) -> void:
	var awake_len := Clock.window_len(int(save.schedule.wake), int(save.schedule.bed))
	var lo := maxi(60, from_offset + 30)
	var hi := awake_len - 60
	var times := []
	if hi > lo:
		var n := rng.randi_range(Cfg.FAKE_CALLS_MIN, Cfg.FAKE_CALLS_MAX)
		n += int(trait_mult(pet, "fake_calls", 0.0))
		for i in n:
			times.append(rng.randi_range(lo, hi))
		times.sort()
	pet.fake_today = times

static func awake_offset(save: Dictionary, m: int) -> int:
	return posmod(m - int(save.schedule.wake), 1440)

static func _daycare_tick(save: Dictionary, t: int, out: Array) -> void:
	var dc: Dictionary = save.daycare
	dc.min += 1
	dc.used_day += 1
	var paid_min: int = int(dc.used_day) - Cfg.DAYCARE_FREE_MIN
	if paid_min > 0 and paid_min % 60 == 1:
		if int(save.coins) >= Cfg.DAYCARE_COINS_PER_HOUR:
			save.coins -= Cfg.DAYCARE_COINS_PER_HOUR
			out.append(ev(t, "daycare_paid", {"coins": Cfg.DAYCARE_COINS_PER_HOUR}))
		else:
			end_daycare(save, t, out, "broke")
			return
	if int(dc.min) >= Cfg.DAYCARE_MAX_MIN:
		end_daycare(save, t, out, "max")

static func end_daycare(save: Dictionary, t: int, out: Array, why: String) -> void:
	save.daycare.active = false
	save.daycare.min = 0
	out.append(ev(t, "daycare_out", {"why": why}))

# --- Pieces of a step ----------------------------------------

static func is_bedtime(save: Dictionary, m: int) -> bool:
	return Clock.in_window(m, int(save.schedule.bed), int(save.schedule.wake))

static func _sleep_tick(save: Dictionary, pet: Dictionary, m: int, t: int, rng: RandomNumberGenerator, out: Array) -> void:
	var bedtime := is_bedtime(save, m)
	if bedtime:
		pet.early_bed = false
	if bedtime and not pet.asleep:
		go_to_bed(pet, t, out)
	elif not bedtime and pet.asleep and not pet.early_bed:
		pet.asleep = false
		pet.lights = true
		schedule_fake_calls(save, pet, rng)
		out.append(ev(t, "woke"))
	if pet.asleep:
		if pet.lights:
			pet.lights_min += 1
			if pet.lights_min >= Cfg.LIGHTS_GRACE_MIN and not pet.lights_flag:
				pet.lights_flag = true
				_mistake(save, pet, t, "lights", out)
		return
	if int(pet.nap_left) > 0:
		pet.nap_left -= 1
		if int(pet.nap_left) == 0:
			pet.lights = true
			out.append(ev(t, "nap_end"))
	elif pet.energy < Cfg.NAP_THRESHOLD:
		start_nap(pet, t, out)

static func go_to_bed(pet: Dictionary, t: int, out: Array) -> void:
	pet.asleep = true
	pet.nap_left = 0
	pet.lights_min = 0
	pet.lights_flag = false
	out.append(ev(t, "fell_asleep"))

static func start_nap(pet: Dictionary, t: int, out: Array) -> void:
	pet.nap_left = roundi(Cfg.NAP_MIN * trait_mult(pet, "nap_len"))
	out.append(ev(t, "nap_start"))

static func _stats_tick(pet: Dictionary) -> void:
	var st: String = pet.stage
	var mult := 1.0
	if pet.asleep:
		mult = Cfg.SLEEP_DRAIN_MULT
	elif int(pet.nap_left) > 0:
		mult = Cfg.NAP_DRAIN_MULT
	var hunger_rate: float = Cfg.HUNGER_DRAIN[st] * trait_mult(pet, "hunger_drain")
	var happy_rate: float = Cfg.HAPPY_DRAIN[st] * trait_mult(pet, "happy_drain")
	happy_rate += pet.poops.size() * Cfg.POOP_HAPPY_DRAIN * trait_mult(pet, "poop_penalty")
	if is_overweight(pet):
		happy_rate += Cfg.OVERWEIGHT_HAPPY_DRAIN
	pet.hunger = maxf(0.0, pet.hunger - hunger_rate * mult / 60.0)
	pet.happy = maxf(0.0, pet.happy - happy_rate * mult / 60.0)
	if pet.asleep:
		pet.energy = minf(100.0, pet.energy + Cfg.ENERGY_SLEEP_GAIN / 60.0)
	elif int(pet.nap_left) > 0:
		pet.energy = minf(100.0, pet.energy + Cfg.ENERGY_NAP_GAIN / 60.0)
	else:
		pet.energy = maxf(0.0, pet.energy - Cfg.ENERGY_DRAIN * trait_mult(pet, "energy_drain") / 60.0)
		var base := weight_base(pet)
		if pet.weight > base:
			pet.weight = maxf(base, pet.weight - Cfg.METABOLISM / 60.0)
	if int(pet.tap_cd) > 0:
		pet.tap_cd -= 1

static func _poop_tick(save: Dictionary, pet: Dictionary, t: int, rng: RandomNumberGenerator, out: Array) -> void:
	var due: Array = pet.poop_due
	for i in range(due.size() - 1, -1, -1):
		due[i] = maxi(0, int(due[i]) - 1)
		if due[i] == 0 and not pet.asleep:
			due.remove_at(i)
			if pet.poops.size() < Cfg.POOP_MAX:
				pet.poops.append({"age": 0, "x": snappedf(rng.randf_range(0.12, 0.88), 0.01), "flag": false})
				out.append(ev(t, "pooped"))
	for p in pet.poops:
		p.age = int(p.age) + 1
		if p.age >= Cfg.POOP_MISTAKE_MIN and not p.flag:
			p.flag = true
			_mistake(save, pet, t, "poop", out)

static func _calls_tick(save: Dictionary, pet: Dictionary, m: int, t: int, out: Array) -> void:
	var needs: bool = pet.hunger <= 0.0 or pet.happy <= 0.0
	var call: Dictionary = pet.call
	if call.kind == "need":
		if not needs:
			pet.call = SaveState.no_call()
			out.append(ev(t, "call_end", {"kind": "need"}))
		elif not pet.asleep:
			call.min += 1
			if call.min >= Cfg.NEED_CALL_MISTAKE_MIN and not call.flag:
				call.flag = true
				_mistake(save, pet, t, "ignored_call", out)
	elif call.kind == "fake":
		call.min += 1
		if needs or pet.asleep or call.min >= Cfg.FAKE_CALL_MIN:
			pet.call = SaveState.no_call()
			out.append(ev(t, "call_end", {"kind": "fake"}))
	if not pet.stage in Cfg.FAKE_CALL_STAGES and not pet.fake_today.is_empty():
		pet.fake_today = []
	if pet.call.kind != "" or pet.asleep:
		return
	if needs:
		var reason: String = "hunger" if pet.hunger <= 0.0 else "happy"
		pet.call = {"kind": "need", "min": 0, "flag": false, "reason": reason}
		out.append(ev(t, "call", {"kind": "need", "reason": reason}))
	elif int(pet.nap_left) == 0 and pet.stage in Cfg.FAKE_CALL_STAGES and not pet.fake_today.is_empty() \
			and awake_offset(save, m) >= int(pet.fake_today[0]):
		pet.fake_today.remove_at(0)
		pet.call = {"kind": "fake", "min": 0, "flag": false, "reason": "attention"}
		out.append(ev(t, "call", {"kind": "fake", "reason": "attention"}))

static func _neglect_tick(save: Dictionary, pet: Dictionary, t: int, out: Array) -> void:
	if pet.hunger <= 0.0 or pet.happy <= 0.0:
		pet.neglect_min += 1.0
		if pet.neglect_min >= Cfg.NEGLECT_DEATH_MIN:
			die(save, pet, t, "neglect", out)
	elif pet.hunger > Cfg.NEGLECT_RECOVER_ABOVE and pet.happy > Cfg.NEGLECT_RECOVER_ABOVE:
		pet.neglect_min = maxf(0.0, pet.neglect_min - Cfg.NEGLECT_RECOVER_RATE)

static func _age_tick(save: Dictionary, pet: Dictionary, t: int, rng: RandomNumberGenerator, out: Array) -> void:
	pet.age_min += 1
	pet.stage_min += 1
	if pet.stage == "adult":
		if pet.stage_min >= pet.lifespan_min:
			die(save, pet, t, "old_age", out)
		return
	# Evolution waits for the pet to be awake, like a morning surprise.
	if pet.stage_min >= Cfg.STAGE_MIN[pet.stage] and not pet.asleep and int(pet.nap_left) == 0:
		evolve(save, pet, t, rng, out)

# --- Life events -----------------------------------------------

static func _hatch(save: Dictionary, pet: Dictionary, t: int, m: int, rng: RandomNumberGenerator, out: Array) -> void:
	pet.stage = "baby"
	pet.form = "mochi"
	pet.stage_min = 0
	pet.age_min = 0
	pet.hatched_at = t
	pet.hunger = Cfg.HATCH_HUNGER
	pet.happy = Cfg.HATCH_HAPPY
	pet.energy = Cfg.HATCH_ENERGY
	pet.weight = Cfg.WEIGHT_BASE.baby
	pet.lights = true
	schedule_fake_calls(save, pet, rng, awake_offset(save, m))
	discover(save, "mochi", t)
	var entry := SaveState.family_entry(save, int(pet.id))
	if not entry.is_empty():
		entry.born = t
		entry.form = "mochi"
	SaveState.bump(save, "hatched")
	out.append(ev(t, "hatched"))

static func evolve(save: Dictionary, pet: Dictionary, t: int, rng: RandomNumberGenerator, out: Array) -> void:
	var from: String = pet.form
	var to := Evolution.next_form(pet)
	var old_stage: String = pet.stage
	var new_stage: String = Cfg.FORMS[to].stage
	pet.stage_mistakes[old_stage] = int(pet.mistakes)
	pet.weight += Cfg.WEIGHT_BASE[new_stage] - Cfg.WEIGHT_BASE[old_stage]
	pet.stage = new_stage
	pet.form = to
	pet.stage_min = 0
	pet.mistakes = 0
	if new_stage == "adult":
		pet.lifespan_min = Evolution.lifespan(pet)
	if pet.call.kind == "fake" and not new_stage in Cfg.FAKE_CALL_STAGES:
		pet.call = SaveState.no_call()
	save.coins += Cfg.EVOLVE_COINS
	SaveState.bump(save, "coins_earned", Cfg.EVOLVE_COINS)
	discover(save, to, t)
	var entry := SaveState.family_entry(save, int(pet.id))
	if not entry.is_empty():
		entry.form = to
	out.append(ev(t, "evolved", {"from": from, "to": to, "coins": Cfg.EVOLVE_COINS}))

static func die(save: Dictionary, pet: Dictionary, t: int, cause: String, out: Array) -> void:
	pet.alive = false
	pet.cause = cause
	pet.died_at = t
	pet.call = SaveState.no_call()
	var entry := SaveState.family_entry(save, int(pet.id))
	if not entry.is_empty():
		entry.died = t
		entry.cause = cause
		entry.age_min = int(pet.age_min)
		entry.form = pet.form
	var coins := 0
	if cause == "old_age":
		coins = Cfg.LEGACY_COINS
		save.coins += coins
		SaveState.bump(save, "coins_earned", coins)
		SaveState.bump(save, "old_age")
	else:
		SaveState.bump(save, "neglect_deaths")
	out.append(ev(t, "died", {"cause": cause, "coins": coins}))

static func discover(save: Dictionary, form: String, t: int) -> void:
	if not save.book.has(form):
		save.book[form] = t

static func _mistake(save: Dictionary, pet: Dictionary, t: int, why: String, out: Array) -> void:
	pet.mistakes += 1
	pet.mistakes_total += 1
	pet.day_mistakes += 1
	out.append(ev(t, "mistake", {"why": why}))

# --- Shared rules ----------------------------------------------

static func trait_mult(pet: Dictionary, key: String, fallback: float = 1.0) -> float:
	var v := fallback
	for tr in pet.traits:
		var mods: Dictionary = Cfg.TRAITS.get(tr, {})
		if mods.has(key):
			v = mods[key] if v == fallback else v * mods[key]
	return v

static func weight_base(pet: Dictionary) -> float:
	return Cfg.WEIGHT_BASE.get(pet.stage, 0.0)

static func is_overweight(pet: Dictionary) -> bool:
	var base := weight_base(pet)
	return base > 0.0 and pet.weight > base * Cfg.OVERWEIGHT_FACTOR
