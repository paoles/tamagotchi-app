extends RefCounted

# ============================================================
# Headless checks for the life simulation, run with
#   godot --headless --path game -- sim
# Scripted "players" care for pets across whole lifetimes on a
# fake clock pinned to UTC. Each scenario prints PASS/FAIL and
# the run exits with the number of failures (CI fails on > 0).
# ============================================================

const DAY := 1440

var failures := 0
var t0 := 0

func run() -> int:
	Clock.tz_pinned = true
	Clock.tz_pinned_bias = 0
	t0 = int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 10, "day": 19, "hour": 8, "minute": 0, "second": 0}))
	var started := Time.get_ticks_msec()
	_scenario_perfect()
	_scenario_neglect()
	_scenario_casual()
	_scenario_branches()
	_scenario_catch_up()
	_scenario_save_round_trip()
	_scenario_forecast()
	_scenario_daycare()
	print("sim: %d failure(s) in %.1f s" % [failures, (Time.get_ticks_msec() - started) / 1000.0])
	return failures

func check(ok: bool, label: String) -> void:
	if ok:
		print("  PASS ", label)
	else:
		failures += 1
		print("  FAIL ", label)

# --- World + scripted players ----------------------------------

func new_world(seed_value: int) -> Dictionary:
	Clock.fake_now = t0
	var save := SaveState.new_save(t0)
	save.rng.seed = str(seed_value)
	save.day_key = Clock.day_key(t0, 0)
	Evolution.new_egg(save, t0)
	return save

# A policy is a Dictionary:
#   checks:    minutes of day to visit, or "hourly" (08:00–21:00 every hour)
#   scold:     "all" | "none" | "until50"
#   dirty:     stages during which the player never cleans
#   snacks:    {stage: snacks per visit}
#   lights_at: minute of day at which the player turns the lights off
# Returns {save, events, end}.
func live(save: Dictionary, policy: Dictionary, max_days: float, stop_on_death := true) -> Dictionary:
	var events := []
	var end := t0 + int(max_days * DAY * 60)
	var checks: Array = []
	if policy.get("checks", "hourly") is String:
		for h in range(8, 22):
			checks.append(h * 60)
	else:
		checks = policy.checks
	var t := int(save.sim_time)
	while t < end:
		t += 60
		Clock.fake_now = t
		events.append_array(Sim.advance(save, t))
		var pet: Dictionary = save.pet
		if not pet.alive:
			if stop_on_death:
				break
			continue
		var m := Clock.local_minute(t, 0)
		if checks.has(m):
			act(save, policy)
		if policy.has("lights_at") and m == int(policy.lights_at):
			if pet.lights and pet.stage != "egg":
				Care.toggle_lights(save)
	return {"save": save, "events": events, "end": int(save.sim_time)}

func act(save: Dictionary, policy: Dictionary) -> void:
	var pet: Dictionary = save.pet
	if pet.stage == "egg":
		return
	if pet.name == "":
		Care.set_pet_name(save, "Tester")
	if pet.asleep:
		return
	var scold: String = policy.get("scold", "all")
	if pet.call.kind == "fake":
		if scold == "all" or (scold == "until50" and pet.discipline < 50.0):
			Care.scold(save)
	if not pet.stage in policy.get("dirty", []):
		Care.clean(save)
	for i in 4:
		if pet.hunger >= 75.0:
			break
		Care.feed_meal(save)
	var snacks: int = policy.get("snacks", {}).get(pet.stage, 0)
	for i in snacks:
		Care.feed_snack(save)
	for i in 4:
		if pet.happy >= 75.0 or pet.energy < 30.0:
			break
		Care.play(save)

func count(events: Array, type: String, key := "", value: Variant = null) -> int:
	var n := 0
	for e in events:
		if e.type == type and (key == "" or e.get(key) == value):
			n += 1
	return n

func first(events: Array, type: String) -> Dictionary:
	for e in events:
		if e.type == type:
			return e
	return {}

func forms_reached(events: Array) -> Array:
	var out := []
	for e in events:
		if e.type == "evolved":
			out.append(e.to)
	return out

# --- Scenarios -------------------------------------------------

const PERFECT := {"checks": "hourly", "scold": "all", "lights_at": 21 * 60 + 30}

func _scenario_perfect() -> void:
	print("perfect care")
	var r := live(new_world(1), PERFECT, 20.0)
	var save: Dictionary = r.save
	var death := first(r.events, "died")
	var days := (int(death.get("t", r.end)) - t0) / 86400.0
	print("    forms: ", forms_reached(r.events), "  mistakes: ", save.pet.mistakes_total, "  life: %.2f d" % days)
	check(death.get("cause", "") == "old_age", "dies of old age")
	check(days >= 14.0 and days <= 16.5, "lifetime is 14–16.5 days (%.2f)" % days)
	check(save.pet.form == "starlight", "flawless, disciplined care reaches Starlight")
	check(int(save.pet.mistakes_total) == 0, "no care mistakes")
	Evolution.new_egg(save, int(save.sim_time))
	var child: Dictionary = save.pet
	var parent_entry: Dictionary = save.family[0]
	check(child.stage == "egg" and child.gen == 2, "leaves an egg for generation 2")
	check(parent_entry.traits.has(child.traits[0]), "egg inherits one of the parent's traits")
	check(child.traits[0] != child.traits[1], "egg also rolls a different trait of its own")
	check(save.book.has("starlight") and save.book.has("mochi"), "collection book records forms")

func _scenario_neglect() -> void:
	print("total neglect")
	var save := new_world(2)
	var r := live(save, {"checks": []}, 5.0)
	var death := first(r.events, "died")
	var hours := (int(death.get("t", r.end)) - t0) / 3600.0
	print("    died after %.1f h" % hours)
	check(death.get("cause", "") == "neglect", "dies of neglect")
	check(hours >= 24.0 and hours <= 36.0, "death comes 24–36 h after the egg (%.1f h)" % hours)
	check(int(save.family[0].died) > 0 and save.family[0].cause == "neglect", "memorial entry written")
	Evolution.new_egg(save, int(save.sim_time))
	check(int(save.pet.line) == 2 and int(save.pet.gen) == 1, "neglect starts a new family line")

func _scenario_casual() -> void:
	print("casual care (4 check-ins a day)")
	var r := live(new_world(3), {"checks": [480, 750, 1080, 1290], "scold": "all", "lights_at": 1290}, 20.0)
	var death := first(r.events, "died")
	var save: Dictionary = r.save
	var why := {}
	for e in r.events:
		if e.type == "mistake":
			why[e.why] = int(why.get(e.why, 0)) + 1
	print("    forms: ", forms_reached(r.events), "  mistakes: ", why, "  calls: ", count(r.events, "call"))
	check(death.get("cause", "") == "old_age", "a casual player's pet lives to old age")
	check(int(save.pet.mistakes_total) <= 6, "casual play makes few mistakes (%d)" % int(save.pet.mistakes_total))

func _scenario_branches() -> void:
	print("every adult form is reachable")
	var cases := {
		"lumina":   {"checks": "hourly", "scold": "until50", "lights_at": 1290},
		"sprout":   {"checks": "hourly", "scold": "until50", "lights_at": 1290, "dirty": ["teen"]},
		"comet":    {"checks": "hourly", "scold": "none", "lights_at": 1290},
		"rascal":   {"checks": "hourly", "scold": "none", "lights_at": 1290, "dirty": ["teen"]},
		"dumpling": {"checks": "hourly", "scold": "all", "lights_at": 1290, "dirty": ["baby"]},
		"grumpus":  {"checks": "hourly", "scold": "none", "lights_at": 1290, "dirty": ["baby"]},
		"starlight": PERFECT,
		"chonk":    {"checks": "hourly", "scold": "all", "lights_at": 1290, "snacks": {"teen": 2}},
	}
	var seed_value := 10
	for target in cases:
		seed_value += 1
		var r := live(new_world(seed_value), cases[target], 6.5)
		var forms := forms_reached(r.events)
		check(forms.has(target), "%s via %s" % [target, forms])

func _scenario_catch_up() -> void:
	print("offline catch-up equals live stepping")
	var a := new_world(4)
	live(a, PERFECT, 1.0)
	var b: Dictionary = a.duplicate(true)
	var start := int(a.sim_time)
	for i in 600:
		Sim.advance(a, start + (i + 1) * 60)
	Sim.advance(b, start + 600 * 60)
	check(SaveState.to_json(a) == SaveState.to_json(b), "advance(10 h) == 600 × advance(1 min)")
	var c := new_world(5)
	var perf_start := Time.get_ticks_msec()
	Sim.advance(c, t0 + 14 * 86400)
	var ms := Time.get_ticks_msec() - perf_start
	print("    14 days of catch-up took %d ms" % ms)
	check(ms < 3000, "14-day catch-up is fast enough")

func _scenario_save_round_trip() -> void:
	print("save round-trip and migration")
	var r := live(new_world(6), PERFECT, 3.0)
	var save: Dictionary = r.save
	var text := SaveState.to_json(save)
	var back := SaveState.from_json(text)
	check(SaveState.to_json(back) == SaveState.to_json(SaveState.migrate(JSON.parse_string(text))), "JSON round-trip is stable")
	var before: Dictionary = back.duplicate(true)
	Sim.advance(back, int(back.sim_time) + 3600)
	Sim.advance(before, int(before.sim_time) + 3600)
	check(SaveState.to_json(back) == SaveState.to_json(before), "a reloaded save keeps simulating identically")
	var old: Dictionary = JSON.parse_string(text)
	old.erase("counters")
	old.erase("daycare")
	old.settings.push.erase("fun")
	old.pet.erase("tap_cd")
	old.pet.erase("early_bed")
	old.version = 0
	var migrated := SaveState.migrate(old)
	check(migrated.has("counters") and migrated.daycare.has("used_day"), "missing top-level fields get defaults")
	check(migrated.settings.push.has("fun") and migrated.pet.has("tap_cd") and migrated.pet.has("early_bed"), "missing nested fields get defaults")
	check(int(migrated.version) == Cfg.SAVE_VERSION, "version is bumped")
	check(SaveState.from_json("not json").is_empty() and SaveState.from_json("[1,2]").is_empty(), "garbage input is rejected")

func _scenario_forecast() -> void:
	print("push forecast")
	var save := new_world(7)
	live(save, PERFECT, 2.0 + 12.0 / 24.0)   # day 3, 20:00 — lights still on
	for k in Cfg.PUSH_CATEGORIES:
		save.settings.push[k] = true
	var raw := Forecast.predict(save, Cfg.FORECAST_HORIZON_MIN)
	var alerts := Forecast.alerts(save)
	var sleep_ok := true
	var spacing_ok := true
	var last := -1_000_000
	for a in alerts:
		var m := Clock.local_minute(a.at, 0)
		if Sim.is_bedtime(save, m) and a.cat != "lights":
			sleep_ok = false
		if a.at - last < Cfg.ALERT_SPACING_MIN * 60:
			spacing_ok = false
		last = a.at
	var cats := []
	for a in alerts:
		cats.append("%s@%s" % [a.key, Clock.fmt_hm(Clock.local_minute(a.at, 0))])
	print("    alerts: ", cats)
	check(raw.size() > 0 and alerts.size() > 0, "a neglected future raises alerts")
	check(alerts.size() <= Cfg.ALERT_MAX, "at most %d alerts" % Cfg.ALERT_MAX)
	check(sleep_ok, "nothing but the lights alert during sleep")
	check(spacing_ok, "alerts are at least %d min apart" % Cfg.ALERT_SPACING_MIN)
	var has_lights := false
	for a in alerts:
		if a.cat == "lights":
			has_lights = true
	check(has_lights, "lights left on at bedtime raises the lights alert")
	save.settings.push.lights = false
	var none_lights := true
	for a in Forecast.alerts(save):
		if a.cat == "lights":
			none_lights = false
	check(none_lights, "a disabled category is never scheduled")

func _scenario_daycare() -> void:
	print("babysitter")
	var save := new_world(8)
	live(save, PERFECT, 1.25)
	var before: Dictionary = save.pet.duplicate(true)
	var coins := int(save.coins)
	check(Care.start_daycare(save).ok, "can drop off")
	var events := Sim.advance(save, int(save.sim_time) + 6 * 3600)
	check(save.pet.age_min == before.age_min and is_equal_approx(save.pet.hunger, before.hunger), "time is frozen in daycare")
	check(int(save.coins) == coins - 2 * Cfg.DAYCARE_COINS_PER_HOUR, "hours past the free 4 cost coins (%d → %d)" % [coins, int(save.coins)])
	Sim.advance(save, int(save.sim_time) + 7 * 3600)
	check(not save.daycare.active and count(events, "daycare_paid") >= 1, "a stay ends at the 12 h cap")
