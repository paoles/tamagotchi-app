class_name Achievements
extends RefCounted

# ============================================================
# Badges. Each is a pure test on the save; `check()` returns the
# ones that just became true, records them and pays their coins.
# ============================================================

const LIST := [
	{"id": "first_hatch", "name": "Hello, world", "desc": "Hatch your first egg.", "coins": 10},
	{"id": "child", "name": "Growing up", "desc": "Raise a pet to a child.", "coins": 10},
	{"id": "teen", "name": "Teen spirit", "desc": "Raise a pet to a teen.", "coins": 20},
	{"id": "adult", "name": "All grown up", "desc": "Raise a pet to an adult.", "coins": 30},
	{"id": "old_age", "name": "A full life", "desc": "Care for a pet until old age.", "coins": 50},
	{"id": "gen3", "name": "Family tree", "desc": "Reach the third generation.", "coins": 40},
	{"id": "gen5", "name": "Dynasty", "desc": "Reach the fifth generation.", "coins": 80},
	{"id": "both_children", "name": "Two paths", "desc": "Discover both child forms.", "coins": 20},
	{"id": "all_teens", "name": "Teen collector", "desc": "Discover all four teens.", "coins": 40},
	{"id": "all_adults", "name": "Complete book", "desc": "Discover all eight adults.", "coins": 150},
	{"id": "starlight", "name": "Shining star", "desc": "Discover the secret Starlight.", "coins": 60},
	{"id": "chonk", "name": "Absolute unit", "desc": "Discover the secret Chonk.", "coins": 30},
	{"id": "perfect_day", "name": "Perfect day", "desc": "Go a whole day without a care mistake.", "coins": 15},
	{"id": "perfect_week", "name": "Perfect week", "desc": "Rack up seven perfect days.", "coins": 50},
	{"id": "coins_500", "name": "Piggy bank", "desc": "Earn 500 coins in total.", "coins": 25},
	{"id": "shopper", "name": "Shopaholic", "desc": "Buy 10 things in the shop.", "coins": 20},
	{"id": "decorator", "name": "Interior designer", "desc": "Fill every decor slot.", "coins": 40},
	{"id": "fashion", "name": "Fashionista", "desc": "Wear a hat, eyewear and a collar at once.", "coins": 30},
	{"id": "gamer", "name": "Game on", "desc": "Play 25 mini-games.", "coins": 30},
	{"id": "tidy", "name": "Squeaky clean", "desc": "Clean up 100 poops.", "coins": 25},
	{"id": "discipline", "name": "Good manners", "desc": "Scold 10 tantrums at the right time.", "coins": 25},
]

static func _c(save: Dictionary, key: String) -> int:
	return int(save.counters.get(key, 0))

static func _has_forms(save: Dictionary, forms: Array) -> bool:
	for f in forms:
		if not save.book.has(f):
			return false
	return true

static func earned(save: Dictionary, id: String) -> bool:
	var book: Dictionary = save.book
	var pet: Dictionary = save.pet
	match id:
		"first_hatch": return _c(save, "hatched") >= 1
		"child": return book.has("puffle") or book.has("smudge")
		"teen": return _has_forms_any(save, ["bloom", "zippy", "pudding", "grumble"])
		"adult": return _has_forms_any(save, Cfg.ADULT_FORMS)
		"old_age": return _c(save, "old_age") >= 1
		"gen3": return not pet.is_empty() and int(pet.gen) >= 3
		"gen5": return not pet.is_empty() and int(pet.gen) >= 5
		"both_children": return _has_forms(save, ["puffle", "smudge"])
		"all_teens": return _has_forms(save, ["bloom", "zippy", "pudding", "grumble"])
		"all_adults": return _has_forms(save, Cfg.ADULT_FORMS)
		"starlight": return book.has("starlight")
		"chonk": return book.has("chonk")
		"perfect_day": return _c(save, "perfect_days") >= 1
		"perfect_week": return _c(save, "perfect_days") >= 7
		"coins_500": return _c(save, "coins_earned") >= 500
		"shopper": return _c(save, "bought") >= 10
		"decorator":
			for v in save.room.slots.values():
				if v == "":
					return false
			return true
		"fashion":
			var eq: Dictionary = save.equipped
			return eq.get("head", "") != "" and eq.get("face", "") != "" and eq.get("neck", "") != ""
		"gamer": return _c(save, "games") >= 25
		"tidy": return _c(save, "poops_cleaned") >= 100
		"discipline": return _c(save, "good_scolds") >= 10
	return false

static func _has_forms_any(save: Dictionary, forms: Array) -> bool:
	for f in forms:
		if save.book.has(f):
			return true
	return false

static func check(save: Dictionary) -> Array:
	var fresh := []
	for a in LIST:
		if save.achievements.has(a.id):
			continue
		if earned(save, a.id):
			save.achievements[a.id] = int(save.sim_time)
			save.coins += int(a.coins)
			SaveState.bump(save, "coins_earned", int(a.coins))
			fresh.append(a)
	return fresh

static func info(id: String) -> Dictionary:
	for a in LIST:
		if a.id == id:
			return a
	return {}
