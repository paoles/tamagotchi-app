class_name Forms
extends RefCounted

# ============================================================
# The 16 creatures as shape recipes on a 32×32 canvas (floor at
# the bottom row). Each recipe lists parts back to front, the
# body colours for keys 1/2/3 (main/shade/light) and a/A, b/B
# (accents), and where the face and outfits sit:
#   face: [x, y] centre between the eyes · gap: eye spacing
#   head: [x, y] top of the head (hats) · eyes: "small" | "big"
#   mouth: default mouth · mood: default eye style when idle
# `sprite(form, expression)` returns the composed, cached texture.
# ============================================================

const SIZE := 32

static func _b(x: float, y: float, rx: float, ry: float, m: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"t": "blob", "x": x, "y": y, "rx": rx, "ry": ry, "n": 2.0, "m": m}
	d.merge(extra, true)
	return d

static func _tri(a: Vector2, b: Vector2, c: Vector2, m: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"t": "tri", "p": [a, b, c], "m": m}
	d.merge(extra, true)
	return d

static func _line(a: Vector2, b: Vector2, m: String) -> Dictionary:
	return {"t": "line", "a": a, "b": b, "m": m, "ol": false, "rim": false}

static func _feet(y: float, gap: float, m: String = "2") -> Array:
	return [_b(16 - gap, y, 2.5, 1.3, m, {"rim": false}), _b(16 + gap, y, 2.5, 1.3, m, {"rim": false})]

static var _recipes := {}

static func recipe(form: String) -> Dictionary:
	if _recipes.is_empty():
		_recipes = _build()
	return _recipes.get(form, _recipes.mochi)

static func _build() -> Dictionary:
	var r := {}
	r.egg = {
		"pal": {"1": Color("fff7ef"), "2": Color("ecdcc9"), "3": Color("ffffff"), "a": Color("a8e0c8"), "b": Color("f4a7b9")},
		"parts": [
			{"t": "egg", "x": 16.0, "y": 22.0, "rx": 7.0, "ry": 9.0, "k": 0.16, "m": "1", "shine": true},
			_b(13.5, 18.5, 1.6, 1.4, "a", {"ol": false, "rim": false}), _b(19.0, 23.0, 2.0, 1.6, "b", {"ol": false, "rim": false}),
			_b(14.0, 27.0, 1.4, 1.1, "a", {"ol": false, "rim": false}), _b(19.5, 16.5, 1.0, 0.9, "b", {"ol": false, "rim": false}),
		],
		"face": [16, 22], "gap": 6, "head": [16, 13], "eyes": "none",
	}
	r.mochi = {
		"pal": {"1": Color("fff3e6"), "2": Color("efd3ba"), "3": Color("ffffff")},
		"parts": [
			_line(Vector2(16, 19.5), Vector2(17.5, 17.5), "2"),
			_b(16, 25.5, 7.5, 5.5, "1", {"n": 2.5, "shine": true}),
		],
		"face": [16, 25], "gap": 6, "head": [16, 20], "eyes": "small", "mouth": "smile_small",
	}
	r.puffle = {
		"pal": {"1": Color("f8c3d2"), "2": Color("e894ad"), "3": Color("fde7ee"), "a": Color("f4a7b9")},
		"parts": [
			_b(10, 15.5, 2.8, 2.8, "1"), _b(22, 15.5, 2.8, 2.8, "1"),
			_b(10, 15.5, 1.2, 1.2, "a", {"ol": false, "rim": false}), _b(22, 15.5, 1.2, 1.2, "a", {"ol": false, "rim": false}),
			_b(16, 23.5, 9.0, 7.5, "1", {"n": 2.3, "shine": true}),
			_b(16, 27.0, 4.5, 2.8, "3", {"ol": false, "rim": false}),
		] + _feet(30.0, 4.5),
		"face": [16, 22], "gap": 7, "head": [16, 16], "eyes": "big", "mouth": "smile",
	}
	r.smudge = {
		"pal": {"1": Color("cdc5dc"), "2": Color("a59cba"), "3": Color("e8e3ef"), "a": Color("f4a7b9"), "A": Color("e07a98")},
		"parts": [
			_line(Vector2(16, 18), Vector2(18.5, 14.5), "k"),
			_b(19, 13.5, 1.6, 1.6, "a"),
			_b(16, 24.5, 9.5, 6.5, "1", {"n": 2.6, "shine": true}),
			_b(10.5, 26.5, 1.6, 1.0, "2", {"ol": false, "rim": false}),
		] + _feet(30.2, 5.0),
		"face": [16, 23], "gap": 7, "head": [16, 18], "eyes": "big", "mouth": "smile", "mood": "tired",
	}
	var petals := []
	for i in 5:
		var ang := -PI / 2.0 + i * TAU / 5.0
		petals.append(_b(16 + cos(ang) * 3.0, 8.5 + sin(ang) * 3.0, 2.2, 2.2, "a"))
	r.bloom = {
		"pal": {"1": Color("b9e9d4"), "2": Color("86cdb0"), "3": Color("e4f8ef"), "a": Color("f8b6c8"), "A": Color("e88aa6"), "b": Color("fbe38e"), "B": Color("f0c050")},
		"parts": [_line(Vector2(16, 11.5), Vector2(16, 14.5), "D")] + petals + [
			_b(16, 8.5, 1.6, 1.6, "b", {"ol": false}),
			_b(6.8, 23.5, 2.2, 2.6, "1"), _b(25.2, 23.5, 2.2, 2.6, "1"),
			_b(16, 22.5, 9.5, 8.5, "1", {"n": 2.2, "shine": true}),
			_b(16, 26.5, 5.5, 3.6, "3", {"ol": false, "rim": false}),
		] + _feet(30.2, 4.5),
		"face": [16, 21], "gap": 8, "head": [16, 14], "eyes": "big", "mouth": "smile",
	}
	r.zippy = {
		"pal": {"1": Color("fde58f"), "2": Color("f0c050"), "3": Color("fff5cc"), "a": Color("f0c050"), "A": Color("d99c30")},
		"parts": [
			_tri(Vector2(8.5, 7), Vector2(11, 17), Vector2(15, 15), "1"),
			_tri(Vector2(23.5, 7), Vector2(21, 17), Vector2(17, 15), "1"),
			_tri(Vector2(23, 25), Vector2(31, 18.5), Vector2(27, 28.5), "a"),
			_b(16, 23.0, 9.0, 8.0, "1", {"n": 2.3, "shine": true}),
			_b(16, 26.8, 4.8, 3.0, "3", {"ol": false, "rim": false}),
		] + _feet(30.2, 4.5),
		"face": [16, 22], "gap": 8, "head": [16, 15], "eyes": "big", "mouth": "cat", "cheek": "r",
	}
	r.pudding = {
		"pal": {"1": Color("fde9ad"), "2": Color("f0c878"), "3": Color("fff6dc"), "a": Color("cf8f60"), "A": Color("a86c48")},
		"parts": [
			_line(Vector2(16, 12.5), Vector2(17.8, 9.8), "D"),
			_b(16, 23.5, 9.5, 7.2, "1", {"n": 3.0, "shine": false}),
			{"t": "group", "m": "a", "parts": [
				_b(16, 17.8, 8.6, 3.4, "a", {"n": 2.4}),
				_b(10.0, 20.5, 1.2, 1.8, "a"), _b(14.5, 21.2, 1.1, 1.6, "a"), _b(20.5, 20.8, 1.2, 1.9, "a"),
			]},
			_b(16, 13.5, 1.9, 1.9, "r", {"shine": false}),
		] + _feet(30.4, 5.0),
		"face": [16, 24.5], "gap": 7, "head": [16, 14], "eyes": "big", "mouth": "smile",
	}
	r.grumble = {
		"pal": {"1": Color("aebde0"), "2": Color("8295c4"), "3": Color("d9e0f1"), "b": Color("fbe9d7"), "B": Color("e2c7ac")},
		"parts": [
			_tri(Vector2(9.5, 11), Vector2(10.5, 17.5), Vector2(14, 16), "b"),
			_tri(Vector2(22.5, 11), Vector2(21.5, 17.5), Vector2(18, 16), "b"),
			_b(16, 23.0, 9.5, 8.0, "1", {"n": 2.6, "shine": true}),
			_b(16, 27.0, 5.0, 2.6, "3", {"ol": false, "rim": false}),
		] + _feet(30.2, 5.0),
		"face": [16, 22], "gap": 8, "head": [16, 15], "eyes": "big", "mouth": "flat", "mood": "grump",
	}
	r.lumina = {
		"pal": {"1": Color("dccdf2"), "2": Color("ad98d8"), "3": Color("f3edfc"), "b": Color("eef7ff"), "B": Color("bcd8f2"), "a": Color("fbe38e"), "A": Color("f0c050")},
		"parts": [
			_b(4.8, 18.5, 4.0, 5.5, "b", {"n": 2.0}), _b(27.2, 18.5, 4.0, 5.5, "b", {"n": 2.0}),
			_line(Vector2(13, 11), Vector2(10.5, 5.5), "k"), _line(Vector2(19, 11), Vector2(21.5, 5.5), "k"),
			_b(10.5, 4.6, 1.8, 1.8, "a"), _b(21.5, 4.6, 1.8, 1.8, "a"),
			_b(16, 21.0, 10.0, 9.8, "1", {"n": 2.2, "shine": true}),
			_b(16, 25.5, 6.0, 4.2, "3", {"ol": false, "rim": false}),
		] + _feet(30.4, 5.0),
		"face": [16, 19.5], "gap": 9, "head": [16, 11.5], "eyes": "big", "mouth": "smile",
	}
	r.sprout = {
		"pal": {"1": Color("c6e9ab"), "2": Color("94cc78"), "3": Color("ebf8de"), "a": Color("8fcf7a"), "A": Color("5aa25a")},
		"parts": [
			_line(Vector2(16, 11.5), Vector2(17, 8), "D"),
			_b(21, 6.5, 5.0, 2.6, "a"),
			_line(Vector2(17, 7), Vector2(25, 6), "A"),
			_b(5.0, 21.5, 2.6, 3.6, "a"), _b(27.0, 21.5, 2.6, 3.6, "a"),
			_b(16, 21.5, 10.5, 9.5, "1", {"n": 2.3, "shine": true}),
			_b(16, 26.0, 6.0, 3.8, "3", {"ol": false, "rim": false}),
		] + _feet(30.4, 5.0),
		"face": [16, 20], "gap": 9, "head": [16, 12], "eyes": "big", "mouth": "smile",
	}
	r.comet = {
		"pal": {"1": Color("c0e1fa"), "2": Color("8cc0ec"), "3": Color("e9f5ff"), "a": Color("fde58f"), "A": Color("f0b040"), "b": Color("fff8e0"), "B": Color("fde58f")},
		"parts": [
			_tri(Vector2(23, 25), Vector2(31.5, 16), Vector2(28.5, 28), "a"),
			{"t": "star", "x": 29.0, "y": 15.5, "r": 3.2, "m": "b"},
			_tri(Vector2(11.5, 13), Vector2(16, 2.5), Vector2(20.5, 13), "a"),
			_tri(Vector2(13.5, 13), Vector2(16, 6.5), Vector2(18.5, 13), "b", {"ol": false, "rim": false}),
			_b(16, 21.5, 10.0, 9.5, "1", {"n": 2.2, "shine": true}),
			_b(16, 26.0, 5.8, 3.8, "3", {"ol": false, "rim": false}),
		] + _feet(30.4, 5.0),
		"face": [16, 20], "gap": 9, "head": [16, 12], "eyes": "big", "mouth": "smile",
	}
	r.rascal = {
		"pal": {"1": Color("f9be90"), "2": Color("ec9562"), "3": Color("fff2e6"), "a": Color("fff2e6"), "A": Color("f1dcc8")},
		"parts": [
			_b(27.0, 22.5, 4.0, 6.2, "1"),
			_b(27.6, 17.4, 2.6, 2.2, "a"),
			_tri(Vector2(6, 6), Vector2(8.5, 16.5), Vector2(14, 13), "1"),
			_tri(Vector2(26, 6), Vector2(23.5, 16.5), Vector2(18, 13), "1"),
			_tri(Vector2(8, 9), Vector2(9.5, 14.5), Vector2(12.5, 13), "a", {"ol": false, "rim": false}),
			_tri(Vector2(24, 9), Vector2(22.5, 14.5), Vector2(19.5, 13), "a", {"ol": false, "rim": false}),
			_b(16, 21.5, 10.0, 9.0, "1", {"n": 2.2, "shine": true}),
			_b(16, 24.2, 5.4, 3.4, "3", {"ol": false, "rim": false}),
		] + _feet(30.4, 5.0),
		"face": [16, 20], "gap": 9, "head": [16, 12.5], "eyes": "big", "mouth": "fang",
	}
	r.dumpling = {
		"pal": {"1": Color("fff6ec"), "2": Color("ead8c6"), "3": Color("ffffff")},
		"parts": [
			{"t": "group", "m": "1", "shine": false, "parts": [
				_b(16, 23.5, 12.5, 7.2, "1", {"n": 2.0}),
				_b(16, 17.5, 6.5, 4.0, "1", {"n": 2.0}),
			]},
			_line(Vector2(13, 15), Vector2(14, 18), "2"), _line(Vector2(16, 14), Vector2(16, 17.5), "2"),
			_line(Vector2(19, 15), Vector2(18, 18), "2"),
		],
		"face": [16, 23.5], "gap": 10, "head": [16, 13.5], "eyes": "big", "mouth": "smile", "cheek_big": true,
	}
	r.grumpus = {
		"pal": {"1": Color("aba3d4"), "2": Color("7f76b0"), "3": Color("dbd5ef"), "b": Color("fbe9d7"), "B": Color("e2c7ac")},
		"parts": [
			_tri(Vector2(6.5, 5.5), Vector2(8.5, 15.5), Vector2(13, 13), "b"),
			_tri(Vector2(25.5, 5.5), Vector2(23.5, 15.5), Vector2(19, 13), "b"),
			_b(16, 21.5, 11.0, 9.5, "1", {"n": 2.6, "shine": true}),
			_b(16, 26.2, 6.0, 3.6, "3", {"ol": false, "rim": false}),
		] + _feet(30.4, 5.5),
		"face": [16, 20], "gap": 9, "head": [16, 12], "eyes": "big", "mouth": "fang", "mood": "grump",
	}
	r.starlight = {
		"pal": {"1": Color("fff5cc"), "2": Color("f2d488"), "3": Color("ffffff"), "a": Color("fbe38e"), "A": Color("f0b840"), "b": Color("ffffff"), "B": Color("e6e0f2")},
		"parts": [
			_b(5.5, 17.5, 3.2, 4.4, "b"), _b(26.5, 17.5, 3.2, 4.4, "b"),
			{"t": "star", "x": 16.0, "y": 7.0, "r": 5.0, "m": "a"},
			_b(16, 21.0, 10.0, 9.8, "1", {"n": 2.2, "shine": true}),
			_b(16, 25.5, 6.0, 4.0, "3", {"ol": false, "rim": false}),
		] + _feet(30.4, 5.0),
		"face": [16, 20], "gap": 9, "head": [16, 11.5], "eyes": "big", "mouth": "smile", "cheek": "p",
	}
	r.chonk = {
		"pal": {"1": Color("fbcbb8"), "2": Color("ef9f88"), "3": Color("fde9df")},
		"parts": [
			_b(9.5, 14.0, 2.2, 2.2, "1"), _b(22.5, 14.0, 2.2, 2.2, "1"),
			_b(16, 22.5, 14.5, 8.5, "1", {"n": 2.0, "shine": true}),
			_b(16, 25.5, 8.0, 4.6, "3", {"ol": false, "rim": false}),
		] + _feet(30.6, 7.0),
		"face": [16, 20], "gap": 10, "head": [16, 14], "eyes": "big", "mouth": "smile", "cheek_big": true,
	}
	return r

# --- Faces -----------------------------------------------------

const EYES := {
	"small": ["WK", "KK"],
	"big": ["WK", "KK", "KK"],
	"happy": [".K.", "K.K"],
	"closed": ["KKK"],
	"content": ["K.K", ".K."],
	"blink": ["KK"],
	"sad": ["..K", ".K.", "...", "KK.", "KK."],
	"angry": ["K..", ".K.", "...", ".KK", ".KK"],
	"grump": ["KKK", "...", ".WK", ".KK"],
	"tired": ["KKK", "WK.", "KK."],
	"dead": ["K.K", ".K.", "K.K"],
	"wide": ["KKK", "KWK", "KKK"],
}
const MOUTHS := {
	"smile": ["K..K", ".KK."],
	"smile_small": ["K.K", ".K."],
	"open": [".KK.", "KPPK", ".KK."],
	"chew": ["KKK"],
	"frown": [".KK.", "K..K"],
	"flat": ["KKK"],
	"cat": ["K.K.K", ".K.K."],
	"fang": ["K...K", ".KKK.", ".W..."],
	"o": [".K.", "K.K", ".K."],
}
# expression → [eyes, mouth, cheeks]. "*" means the form's default.
const EXPR := {
	"idle": ["*", "*", true],
	"happy": ["happy", "open", true],
	"love": ["happy", "*", true],
	"sad": ["sad", "frown", false],
	"hungry": ["*", "open", false],
	"angry": ["angry", "flat", false],
	"refuse": ["angry", "frown", false],
	"sleep": ["closed", "o", true],
	"eat_a": ["happy", "open", true],
	"eat_b": ["happy", "chew", true],
	"blink": ["blink", "*", true],
	"surprised": ["wide", "o", false],
	"sick": ["sad", "flat", false],
	"dead": ["dead", "flat", false],
	"scolded": ["closed", "frown", false],
	"call": ["wide", "open", true],
}

static func sprite(form: String, expression: String = "idle") -> Texture2D:
	return Px.cached("form:%s:%s" % [form, expression], func() -> Image: return compose(form, expression))

static func body_image(form: String) -> Image:
	var rec := recipe(form)
	var canvas := Px.Canvas.new(SIZE, SIZE)
	Px.paint_parts(canvas, rec.parts)
	return Px.grid_image(canvas.rows(), rec.pal)

static func compose(form: String, expression: String) -> Image:
	var rec := recipe(form)
	var img := body_image(form)
	if rec.get("eyes", "big") == "none":
		if expression == "crack":
			Px.stamp(img, Px.grid_image(["..K.K.", ".K.K.K", "K....."]), 13, 15)
		return img
	var spec: Array = EXPR.get(expression, EXPR.idle)
	var eye_key: String = spec[0]
	if eye_key == "*":
		eye_key = rec.get("mood", rec.get("eyes", "big"))
	elif eye_key == "angry" and rec.get("mood", "") == "grump":
		eye_key = "angry"
	var mouth_key: String = spec[1]
	if mouth_key == "*":
		mouth_key = rec.get("mouth", "smile")
	if rec.get("eyes", "big") == "small":
		if eye_key in ["big", "tired", "grump"]:
			eye_key = "small"
		if mouth_key in ["smile", "fang", "cat"]:
			mouth_key = "smile_small"
	var fx: float = rec.face[0]
	var fy: float = rec.face[1]
	var gap: float = rec.gap
	var eye := Px.grid_image(EYES[eye_key])
	var ew := eye.get_width()
	var eh := eye.get_height()
	var ey := roundi(fy - eh / 2.0)
	var lx := roundi(fx - gap / 2.0 - ew / 2.0)
	var rx := roundi(fx + gap / 2.0 - ew / 2.0)
	Px.stamp(img, eye, lx, ey)
	Px.stamp(img, Px.flipped(eye), rx, ey)
	var mouth := Px.grid_image(MOUTHS[mouth_key])
	var mdy := 3 if rec.get("eyes", "big") == "small" else 3
	Px.stamp(img, mouth, roundi(fx - mouth.get_width() / 2.0), roundi(fy + mdy - 0.5))
	if spec[2]:
		var cheek_col: String = rec.get("cheek", "p")
		var rows := ["%s%s" % [cheek_col, cheek_col]]
		if rec.get("cheek_big", false):
			rows = [".%s%s" % [cheek_col, cheek_col], "%s%s%s" % [cheek_col, cheek_col, cheek_col]]
		var cheek := Px.grid_image(rows)
		var cy := roundi(fy + 2)
		Px.stamp(img, cheek, roundi(fx - gap / 2.0 - ew / 2.0 - cheek.get_width() + 0.5), cy)
		Px.stamp(img, Px.flipped(cheek), roundi(fx + gap / 2.0 + ew / 2.0 - 0.5), cy)
	return img

static func anchor(form: String, which: String) -> Vector2:
	var rec := recipe(form)
	match which:
		"head":
			return Vector2(rec.head[0], rec.head[1])
		"face":
			return Vector2(rec.face[0], rec.face[1])
		"neck":
			return Vector2(rec.face[0], rec.face[1] + 6)
	return Vector2(16, 16)

# All-white version of a body, for evolve / hatch flashes.
static func silhouette(form: String) -> Texture2D:
	return Px.cached("silhouette:" + form, func() -> Image:
		var img := body_image(form)
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					img.set_pixel(x, y, Color.WHITE)
		return img)
