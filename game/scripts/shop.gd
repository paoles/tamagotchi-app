class_name Shop
extends RefCounted

# ============================================================
# The shop catalog and the economy rules. Coins, inventory,
# wardrobe and room live on the save (not the pet), so they
# carry over from one generation to the next.
#   food      consumable, stacks to FOOD_STACK, eaten from Feed
#   toy       kept forever, adds a Play option
#   outfit    kept forever, worn on head / face / neck
#   furniture kept forever, placed in a room slot of its kind
#   wallpaper / floor  kept forever, one active at a time
# ============================================================

const FOOD_STACK := 9

const CATALOG := {
	# Foods
	"apple":    {"cat": "food", "name": "Apple", "price": 5, "hunger": 15.0, "happy": 5.0, "weight": 0.5, "desc": "A crunchy, healthy snack."},
	"milk":     {"cat": "food", "name": "Milk", "price": 6, "hunger": 12.0, "energy": 15.0, "weight": 0.5, "desc": "Restores a bit of energy."},
	"salad":    {"cat": "food", "name": "Salad", "price": 8, "hunger": 20.0, "weight": -2.0, "desc": "Filling and helps lose weight."},
	"icecream": {"cat": "food", "name": "Ice cream", "price": 10, "hunger": 5.0, "happy": 25.0, "weight": 2.0, "desc": "Pure joy. Watch the weight."},
	"sushi":    {"cat": "food", "name": "Sushi", "price": 12, "hunger": 30.0, "happy": 10.0, "weight": 1.0, "desc": "A fancy, filling meal."},
	"cake":     {"cat": "food", "name": "Cake", "price": 15, "hunger": 10.0, "happy": 30.0, "weight": 4.0, "desc": "For special days."},
	# Toys
	"ball":   {"cat": "toy", "name": "Beach ball", "price": 20, "happy": 25.0, "energy": 6.0, "weight": 1.0, "desc": "Bouncy fun that burns a little weight."},
	"yarn":   {"cat": "toy", "name": "Yarn", "price": 35, "happy": 30.0, "energy": 5.0, "weight": 0.5, "desc": "Endless tangling."},
	"blocks": {"cat": "toy", "name": "Blocks", "price": 50, "happy": 20.0, "energy": 3.0, "weight": 0.5, "discipline": 5.0, "desc": "Quiet play that builds patience."},
	"robot":  {"cat": "toy", "name": "Robot", "price": 90, "happy": 35.0, "energy": 8.0, "weight": 1.5, "desc": "Beep boop. The best friend."},
	# Outfits
	"bow":          {"cat": "outfit", "slot": "head", "name": "Bow", "price": 30, "desc": "A sweet pink bow."},
	"party_hat":    {"cat": "outfit", "slot": "head", "name": "Party hat", "price": 40, "desc": "Every day is a party."},
	"beanie":       {"cat": "outfit", "slot": "head", "name": "Beanie", "price": 45, "desc": "Cozy on cold days."},
	"cap":          {"cat": "outfit", "slot": "head", "name": "Cap", "price": 50, "desc": "Sporty and cool."},
	"flower_crown": {"cat": "outfit", "slot": "head", "name": "Flower crown", "price": 55, "desc": "Fresh from the meadow."},
	"tiara":        {"cat": "outfit", "slot": "head", "name": "Tiara", "price": 120, "desc": "Royalty, obviously."},
	"glasses":      {"cat": "outfit", "slot": "face", "name": "Glasses", "price": 40, "desc": "Very studious."},
	"shades":       {"cat": "outfit", "slot": "face", "name": "Shades", "price": 60, "desc": "Too cool to care."},
	"monocle":      {"cat": "outfit", "slot": "face", "name": "Monocle", "price": 80, "desc": "Quite distinguished."},
	"bell":         {"cat": "outfit", "slot": "neck", "name": "Bell collar", "price": 25, "desc": "Jingle jingle."},
	"bowtie":       {"cat": "outfit", "slot": "neck", "name": "Bow tie", "price": 30, "desc": "Dressed for dinner."},
	"scarf":        {"cat": "outfit", "slot": "neck", "name": "Scarf", "price": 35, "desc": "Warm and snug."},
	# Furniture
	"pennant":     {"cat": "furniture", "kind": "wall", "name": "Pennant", "price": 35, "desc": "Go team!"},
	"poster_star": {"cat": "furniture", "kind": "wall", "name": "Star poster", "price": 40, "desc": "Reach for the stars."},
	"frame_heart": {"cat": "furniture", "kind": "wall", "name": "Heart frame", "price": 50, "desc": "A little love on the wall."},
	"clock":       {"cat": "furniture", "kind": "wall", "name": "Clock", "price": 60, "desc": "Tick, tock."},
	"shelf":       {"cat": "furniture", "kind": "wall", "name": "Shelf", "price": 70, "desc": "Books and a tiny plant."},
	"cactus":      {"cat": "furniture", "kind": "floor", "name": "Cactus", "price": 35, "desc": "Low maintenance."},
	"plant":       {"cat": "furniture", "kind": "floor", "name": "Plant", "price": 40, "desc": "Leafy and green."},
	"lamp":        {"cat": "furniture", "kind": "floor", "name": "Lamp", "price": 60, "desc": "A warm glow."},
	"teddy":       {"cat": "furniture", "kind": "floor", "name": "Teddy", "price": 70, "desc": "A cuddly friend."},
	"toybox":      {"cat": "furniture", "kind": "floor", "name": "Toy box", "price": 80, "desc": "Where the fun lives."},
	"bookcase":    {"cat": "furniture", "kind": "floor", "name": "Bookcase", "price": 100, "desc": "So many stories."},
	"bed":         {"cat": "furniture", "kind": "floor", "name": "Bed", "price": 120, "desc": "The comfiest spot."},
	"rug_round":   {"cat": "furniture", "kind": "rug", "name": "Round rug", "price": 50, "desc": "Soft lilac rug."},
	"rug_stripe":  {"cat": "furniture", "kind": "rug", "name": "Stripe rug", "price": 60, "desc": "Minty stripes."},
	"rug_heart":   {"cat": "furniture", "kind": "rug", "name": "Heart rug", "price": 80, "desc": "Full of love."},
	"sill_plant":  {"cat": "furniture", "kind": "sill", "name": "Succulent", "price": 25, "desc": "Sits on the sill."},
	"sill_candle": {"cat": "furniture", "kind": "sill", "name": "Candle", "price": 30, "desc": "A cozy flicker."},
	"sill_cat":    {"cat": "furniture", "kind": "sill", "name": "Lucky cat", "price": 45, "desc": "Waves for good luck."},
	# Wallpapers and floors
	"wall_cream":   {"cat": "wallpaper", "name": "Cream stripes", "price": 0, "desc": "The classic."},
	"wall_mint":    {"cat": "wallpaper", "name": "Mint dots", "price": 60, "desc": "Fresh and calm."},
	"wall_peach":   {"cat": "wallpaper", "name": "Peach checks", "price": 70, "desc": "Warm and bright."},
	"wall_butter":  {"cat": "wallpaper", "name": "Butter stars", "price": 70, "desc": "Sunny vibes."},
	"wall_lilac":   {"cat": "wallpaper", "name": "Lilac hearts", "price": 80, "desc": "Sweet and dreamy."},
	"wall_sky":     {"cat": "wallpaper", "name": "Sky clouds", "price": 80, "desc": "Head in the clouds."},
	"floor_oak":    {"cat": "floor", "name": "Oak planks", "price": 0, "desc": "Warm wood."},
	"floor_mint":   {"cat": "floor", "name": "Mint tiles", "price": 60, "desc": "Cool and clean."},
	"floor_pink":   {"cat": "floor", "name": "Pink carpet", "price": 70, "desc": "Soft underfoot."},
	"floor_lilac":  {"cat": "floor", "name": "Lilac tiles", "price": 70, "desc": "Pastel chic."},
	"floor_walnut": {"cat": "floor", "name": "Walnut planks", "price": 80, "desc": "Rich, dark wood."},
	"floor_cloud":  {"cat": "floor", "name": "Cloud carpet", "price": 90, "desc": "Like walking on air."},
}

const TABS := [
	["food", "Food", "hunger"], ["toy", "Toys", "play"], ["outfit", "Style", "wardrobe"],
	["furniture", "Room", "decor"], ["walls", "Walls", "more"],
]
const KIND_SLOTS := {
	"wall": ["wall_l", "wall_r"], "floor": ["floor_l", "floor_r"], "rug": ["rug"], "sill": ["sill"],
}
const SLOT_NAMES := {
	"wall_l": "Wall (left)", "wall_r": "Wall (right)", "floor_l": "Floor (left)",
	"floor_r": "Floor (right)", "rug": "Rug", "sill": "Window sill",
}

static func item(id: String) -> Dictionary:
	return CATALOG.get(id, {})

static func ids_in(cat: String) -> Array:
	var out := []
	for id in CATALOG:
		var c: String = CATALOG[id].cat
		if c == cat or (cat == "walls" and (c == "wallpaper" or c == "floor")):
			out.append(id)
	return out

static func owns(save: Dictionary, id: String) -> bool:
	var it := item(id)
	if it.is_empty():
		return false
	if it.cat == "food":
		return int(save.inventory.get(id, 0)) > 0
	if int(it.price) == 0:
		return true
	return save.owned.get(id, false)

static func count(save: Dictionary, id: String) -> int:
	return int(save.inventory.get(id, 0))

static func _res(ok: bool, why: String, toast: String = "", icon: String = "", anim: String = "") -> Dictionary:
	return {"ok": ok, "why": why, "toast": toast, "icon": icon, "anim": anim, "events": []}

static func buy(save: Dictionary, id: String) -> Dictionary:
	var it := item(id)
	if it.is_empty():
		return _res(false, "unknown")
	var price := int(it.price)
	if it.cat == "food":
		if count(save, id) >= FOOD_STACK:
			return _res(false, "stack_full", "You can carry %d at most." % FOOD_STACK, "cross")
	elif owns(save, id):
		return _res(false, "owned", "Already yours!", "check")
	if int(save.coins) < price:
		return _res(false, "broke", "Not enough coins.", "coin")
	save.coins -= price
	SaveState.bump(save, "coins_spent", price)
	SaveState.bump(save, "bought")
	if it.cat == "food":
		save.inventory[id] = count(save, id) + 1
	else:
		save.owned[id] = true
	return _res(true, "bought", "Got %s!" % it.name, "shop")

static func use_food(save: Dictionary, id: String) -> Dictionary:
	var it := item(id)
	if it.is_empty() or count(save, id) <= 0:
		return _res(false, "none")
	var gate := Care._awake_gate(save)
	if gate != "":
		return {"ok": false, "why": gate, "anim": "refuse", "events": []}
	var pet: Dictionary = save.pet
	var hunger: float = it.get("hunger", 0.0)
	if hunger >= 15.0 and pet.hunger >= Cfg.MEAL_REFUSE_AT:
		return {"ok": false, "why": "full", "anim": "refuse", "events": []}
	var rng := Sim.rng_from(save)
	var events := []
	Care._wake_nap(pet)
	Care._spoil(pet, int(save.sim_time), events)
	save.inventory[id] = count(save, id) - 1
	if count(save, id) <= 0:
		save.inventory.erase(id)
	pet.hunger = clampf(pet.hunger + hunger, 0.0, 100.0)
	pet.happy = clampf(pet.happy + float(it.get("happy", 0.0)) * Sim.trait_mult(pet, "snack_gain"), 0.0, 100.0)
	pet.energy = clampf(pet.energy + float(it.get("energy", 0.0)), 0.0, 100.0)
	pet.weight += float(it.get("weight", 0.0))
	Care._floor_weight(pet)
	if hunger >= 15.0 or rng.randf() < Cfg.SNACK_POOP_CHANCE:
		Care._queue_poop(pet, rng)
	Sim.rng_store(save, rng)
	SaveState.bump(save, "treats")
	return {"ok": true, "why": "food", "anim": "eat", "food": id, "events": events}

static func play_toy(save: Dictionary, id: String) -> Dictionary:
	var it := item(id)
	if it.is_empty() or not owns(save, id):
		return _res(false, "none")
	var res := Care.play(save, it.happy, it.energy, it.weight)
	if res.ok and it.has("discipline"):
		var pet: Dictionary = save.pet
		pet.discipline = clampf(pet.discipline + float(it.discipline), 0.0, 100.0)
	res["toy"] = id
	return res

static func equip(save: Dictionary, id: String) -> void:
	var it := item(id)
	if it.get("cat", "") == "outfit" and owns(save, id):
		save.equipped[it.slot] = id if save.equipped.get(it.slot, "") != id else ""

static func place(save: Dictionary, slot: String, id: String) -> void:
	var slots: Dictionary = save.room.slots
	if id == "":
		slots[slot] = ""
		return
	var it := item(id)
	if it.get("cat", "") != "furniture" or not owns(save, id) or not slot in KIND_SLOTS[it.kind]:
		return
	for s in slots:
		if slots[s] == id:
			slots[s] = ""
	slots[slot] = id

static func set_surface(save: Dictionary, id: String) -> void:
	var it := item(id)
	if not owns(save, id):
		return
	if it.cat == "wallpaper":
		save.room.wallpaper = id
	elif it.cat == "floor":
		save.room.floor = id

static func is_active(save: Dictionary, id: String) -> bool:
	var it := item(id)
	match String(it.get("cat", "")):
		"outfit":
			return save.equipped.get(it.slot, "") == id
		"wallpaper":
			return save.room.wallpaper == id
		"floor":
			return save.room.floor == id
		"furniture":
			return save.room.slots.values().has(id)
	return false

# --- Sprites -------------------------------------------------------

static func sprite(id: String) -> Texture2D:
	var it := item(id)
	if it.is_empty():
		return null
	match String(it.cat):
		"wallpaper", "floor":
			return Px.cached("swatch:" + id, func() -> Image: return _swatch(id))
		"outfit":
			if it.slot == "face":
				return Px.cached("facewear:" + id, func() -> Image: return Outfits.face_preview(id))
	return Goods.tex(id)

static func _swatch(id: String) -> Image:
	var img := Image.create_empty(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Pal.INK)
	var it := item(id)
	if it.cat == "wallpaper":
		var wp: Dictionary = Room.WALLPAPERS[id]
		img.fill_rect(Rect2i(1, 1, 12, 12), wp.base)
		for y in range(2, 12, 4):
			for x in range(2 + (y / 4) % 2 * 2, 12, 4):
				img.fill_rect(Rect2i(x, y, 2, 2), wp.alt)
	else:
		var fl: Dictionary = Room.FLOORS[id]
		img.fill_rect(Rect2i(1, 1, 12, 12), fl.base)
		for y in range(1, 13, 4):
			img.fill_rect(Rect2i(1, y + 3, 12, 1), fl.seam)
			img.fill_rect(Rect2i(1, y + 1, 12, 2), fl.alt)
	return img
