class_name Evolution
extends RefCounted

# ============================================================
# Which form comes next, how long an adult lives, and how a new
# generation starts. `pet.mistakes` is the count for the stage
# that is ending; discipline and weight carry across stages.
# ============================================================

static func next_form(pet: Dictionary) -> String:
	var mistakes := int(pet.mistakes)
	var disc: float = pet.discipline
	match String(pet.form):
		"mochi":
			return "puffle" if mistakes <= 3 else "smudge"
		"puffle":
			return "bloom" if disc >= 50.0 else "zippy"
		"smudge":
			return "pudding" if disc >= 50.0 else "grumble"
		"bloom", "zippy", "pudding", "grumble":
			if pet.weight > Cfg.WEIGHT_BASE.teen * Cfg.OVERWEIGHT_FACTOR:
				return "chonk"
			if pet.form in ["bloom", "zippy"] and mistakes == 0 and disc >= 100.0:
				return "starlight"
			match String(pet.form):
				"bloom":
					return "lumina" if mistakes <= 2 else "sprout"
				"zippy":
					return "comet" if mistakes <= 2 else "rascal"
				"pudding":
					return "dumpling"
				_:
					return "grumpus"
	return String(pet.form)

# Adult lifespan: 8 days, plus up to 2 more for a pet that made
# it to adulthood with few care mistakes.
static func lifespan(pet: Dictionary) -> int:
	var before := 0
	for st in pet.stage_mistakes:
		before += int(pet.stage_mistakes[st])
	var share := clampf(1.0 - float(before) / Cfg.ADULT_BONUS_MISTAKES, 0.0, 1.0)
	return Cfg.ADULT_BASE_MIN + roundi(Cfg.ADULT_BONUS_MAX_MIN * share)

# Starts the next egg. A pet that died of old age passes one of
# its traits down; after a neglect death a new family line begins.
static func new_egg(save: Dictionary, t: int) -> void:
	var rng := Sim.rng_from(save)
	var parent: Dictionary = save.pet
	var inherited := ""
	var gen := 1
	var line := 1
	var parent_id := 0
	if not parent.is_empty():
		line = int(parent.line)
		if parent.cause == "old_age":
			inherited = parent.traits[rng.randi() % parent.traits.size()]
			gen = int(parent.gen) + 1
			parent_id = int(parent.id)
		else:
			line = int(parent.line) + 1
	if inherited == "":
		inherited = Cfg.TRAIT_IDS[rng.randi() % Cfg.TRAIT_IDS.size()]
	var own := inherited
	while own == inherited:
		own = Cfg.TRAIT_IDS[rng.randi() % Cfg.TRAIT_IDS.size()]
	var pet := SaveState.new_pet(save, t, gen, line, parent_id, [inherited, own])
	save.pet = pet
	save.family.append({
		"id": pet.id, "name": "", "gen": gen, "line": line, "parent": parent_id,
		"form": "egg", "traits": pet.traits.duplicate(),
		"laid": t, "born": 0, "died": 0, "cause": "", "age_min": 0,
	})
	Sim.discover(save, "egg", t)
	Sim.rng_store(save, rng)

static func stage_progress(pet: Dictionary) -> float:
	if pet.stage == "adult":
		return clampf(float(pet.stage_min) / maxf(1.0, float(pet.lifespan_min)), 0.0, 1.0)
	var total: int = Cfg.STAGE_MIN.get(pet.stage, 1)
	return clampf(float(pet.stage_min) / total, 0.0, 1.0)

static func minutes_to_next_stage(pet: Dictionary) -> int:
	if pet.stage == "adult":
		return maxi(0, int(pet.lifespan_min) - int(pet.stage_min))
	return maxi(0, int(Cfg.STAGE_MIN.get(pet.stage, 0)) - int(pet.stage_min))
