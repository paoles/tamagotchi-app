class_name Items
extends RefCounted

# ============================================================
# Sprites for things in the room: poop, food, the grave, the
# ghost that rises when a pet passes. Shop goods (foods, toys,
# outfits, furniture) live in `Shop.CATALOG` and draw from the
# grids registered there.
# ============================================================

const G := {
	"poop": [
		".....k......",
		"....kNk.....",
		"...kNNNk....",
		"...kNWNk....",
		"..kkkkkkk...",
		".kNNNNNNNk..",
		".kNWNNNNNk..",
		"kkkkkkkkkkk.",
		"kNNNNNNNNNNk",
		"kNWNNNNNNNNk",
		".kkkkkkkkkk.",
	],
	"meal": [
		"..k.......k...",
		"...k.....k....",
		"....k...k.....",
		".kkkkkkkkkkkk.",
		"kwwwwWwwwwyywk",
		"kwwwwwwwwyYYyk",
		"kwWwwwwwwwyywk",
		"kbbbbbbbbbbbBk",
		"kbbbpbbbbpbbBk",
		".kbbbbbbbbbBk.",
		"..kbbbbbbbBk..",
		"...kkkkkkkk...",
	],
	"snack": [
		".....kk.....",
		"....krrk....",
		"...kkrRkk...",
		"..kwwwwwwk..",
		".kwWwwwpwwk.",
		".kwwpwwwwwk.",
		"kkkkkkkkkkkk",
		".kpPpPpPpPk.",
		".kpPpPpPpPk.",
		"..kpPpPpPk..",
		"..kkkkkkkk..",
	],
	"grave": [
		"....kkkkkk....",
		"...kggggggk...",
		"..kggWgggggk..",
		"..kgggkkggGk..",
		"..kggkkkkgGk..",
		"..kgggkkggGk..",
		"..kgggkkggGk..",
		"..kggggggggk..",
		"..kgggggggGk..",
		"..kgggggggGk..",
		".kkkkkkkkkkkk.",
		"kdpdkddddkpdDk",
		"kddddddddddddk",
		".kkkkkkkkkkkk.",
	],
	"ghost": [
		"...yyyyyy...",
		"..y......y..",
		"...yyyyyy...",
		"....kkkk....",
		"..kkwwwwkk..",
		".kwwwwwwwwk.",
		".kwKwwwwKwk.",
		"kwwwwwwwwwwk",
		"kwpwwKKwwpwk",
		"kwwwwwwwwwwk",
		"kwwwwwwwwwwk",
		"kwkwwkkwwkwk",
		".k.kk..kk.k.",
	],
	"shell_l": [
		"..kk",
		".kwk",
		"kwwk",
		"kwkk",
		"kk..",
	],
	"shell_r": [
		"kk..",
		"kwk.",
		"kwwk",
		"kkwk",
		"..kk",
	],
}

static func image(name: String) -> Image:
	if G.has(name):
		return Px.grid_image(G[name])
	if Goods.G.has(name) or name == "ball":
		return Goods.image(name)
	return Icons.image(name)

static func tex(name: String) -> Texture2D:
	return Px.cached("item:" + name, func() -> Image: return image(name))

static func contact_sheet() -> Image:
	var names := G.keys()
	var scale := 4
	var cell := 18
	var sheet := Image.create_empty(names.size() * cell * scale, cell * scale, false, Image.FORMAT_RGBA8)
	sheet.fill(Pal.PANEL)
	for i in names.size():
		Px.stamp(sheet, Px.scaled(image(names[i]), scale), i * cell * scale + scale, scale)
	return sheet
