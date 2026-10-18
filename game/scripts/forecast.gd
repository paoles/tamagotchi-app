class_name Forecast
extends RefCounted

# ============================================================
# Predicts when the pet will need you if nobody touches it, by
# running a copy of the save through the same Sim with no input.
# The push backend schedules one notification per alert. Alerts
# are filtered by the player's categories, silenced while the pet
# sleeps (except the lights alert), spaced out and capped.
# ============================================================

static func alerts(save: Dictionary, horizon_min: int = Cfg.FORECAST_HORIZON_MIN) -> Array:
	var raw := predict(save, horizon_min)
	var enabled: Dictionary = save.settings.push
	var out := []
	var last := -1_000_000_000
	for a in raw:
		if not enabled.get(a.cat, false):
			continue
		if a.asleep and a.cat != "lights":
			continue
		if a.at - last < Cfg.ALERT_SPACING_MIN * 60:
			continue
		out.append(a)
		last = a.at
		if out.size() >= Cfg.ALERT_MAX:
			break
	return out

# Every alert the future would raise, unfiltered and in time order.
static func predict(save: Dictionary, horizon_min: int) -> Array:
	var s: Dictionary = save.duplicate(true)
	if s.pet.is_empty() or not s.pet.alive:
		return []
	var rng := Sim.rng_from(s)
	var tz := Clock.tz_bias()
	var name: String = s.pet.name if s.pet.name != "" else "Your pet"
	var raised := {}
	var out := []
	var t := int(s.sim_time)
	for i in horizon_min:
		t += Cfg.STEP_SEC
		var events := []
		Sim.step(s, t, tz, rng, events)
		var pet: Dictionary = s.pet
		var asleep: bool = pet.asleep
		for e in events:
			match String(e.type):
				"hatched":
					_add(out, t, "milestones", "p_hatch", name, false)
				"evolved":
					_add(out, t, "milestones", "p_evolved", name, false)
				"call":
					if e.kind == "fake":
						_add(out, t, "attention", "p_attention", name, false)
				"daycare_out":
					_add(out, t, "milestones", "p_daycare", name, false)
		if not pet.alive:
			break
		if pet.stage == "egg" or s.daycare.active:
			continue
		if not raised.has("hunger") and pet.hunger <= Cfg.ALERT_LOW_STAT:
			raised.hunger = true
			_add(out, t, "needs", "p_hungry", name, asleep)
		if not raised.has("happy") and pet.happy <= Cfg.ALERT_LOW_STAT:
			raised.happy = true
			_add(out, t, "needs", "p_happy", name, asleep)
		if not raised.has("poop") and pet.poops.size() >= Cfg.ALERT_POOP_COUNT:
			raised.poop = true
			_add(out, t, "poop", "p_poop", name, asleep)
		if not raised.has("lights") and asleep and pet.lights and int(pet.lights_min) >= Cfg.ALERT_LIGHTS_AFTER_MIN:
			raised.lights = true
			_add(out, t, "lights", "p_lights", name, asleep)
		if not raised.has("danger") and pet.neglect_min >= Cfg.ALERT_NEGLECT_MIN:
			raised.danger = true
			_add(out, t, "needs", "p_danger", name, false)
		if pet.stage == "adult" and not raised.has("old") and int(pet.lifespan_min) - int(pet.stage_min) <= 60:
			raised.old = true
			_add(out, t, "milestones", "p_old_age", name, false)
	return out

static func _add(out: Array, t: int, cat: String, key: String, name: String, asleep: bool) -> void:
	out.append({
		"at": t, "cat": cat, "key": key, "asleep": asleep,
		"title": S.t("title"), "body": S.t(key, {"name": name}), "tag": key,
	})
