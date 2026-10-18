class_name Px
extends RefCounted

# ============================================================
# Pixel-art plumbing: text grids → Image → cached Texture, plus
# a tiny shape rasterizer for creature recipes. Shapes paint a
# grid of palette characters back to front; each part draws a
# 1-px outline ring first, so overlapping parts get a clean line
# between them, then its fill with a shaded bottom-right rim and
# a light top-left rim.
# ============================================================

static var _tex := {}

static func color_of(ch: String, colors: Dictionary) -> Color:
	if colors.has(ch):
		return colors[ch]
	return Pal.C.get(ch, Color.MAGENTA)

static func grid_image(rows: Array, colors: Dictionary = {}) -> Image:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create_empty(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == "." or ch == " ":
				continue
			img.set_pixel(x, y, color_of(ch, colors))
	return img

static func cached(key: String, maker: Callable) -> Texture2D:
	if not _tex.has(key):
		var img: Image = maker.call()
		_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]

static func grid_tex(key: String, rows: Array, colors: Dictionary = {}) -> Texture2D:
	return cached(key, func() -> Image: return grid_image(rows, colors))

static func flipped(img: Image) -> Image:
	var c := img.duplicate()
	c.flip_x()
	return c

static func scaled(img: Image, s: int) -> Image:
	var c := img.duplicate()
	c.resize(img.get_width() * s, img.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c

# Draws `src` onto `dst` with its top-left at (x, y), alpha-blended.
static func stamp(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))

# Adds a 1-px outline around everything opaque in `img`.
static func outlined(img: Image, color: Color) -> Image:
	var w := img.get_width() + 2
	var h := img.get_height() + 2
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = Vector2i(x + 1, y + 1) + d
					out.set_pixelv(q, color)
	out.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i(1, 1))
	return out

# --- Shape canvas ----------------------------------------------

class Canvas:
	var w: int
	var h: int
	var cells: Array = []

	func _init(width: int, height: int) -> void:
		w = width
		h = height
		for y in h:
			var row := []
			row.resize(w)
			row.fill(".")
			cells.append(row)

	func at(x: int, y: int) -> String:
		if x < 0 or y < 0 or x >= w or y >= h:
			return "."
		return cells[y][x]

	func put(x: int, y: int, ch: String) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			cells[y][x] = ch

	func rows() -> Array:
		var out := []
		for r in cells:
			out.append("".join(r))
		return out

	# Paints one part. `mask` is a Dictionary used as a set of Vector2i.
	func paint(mask: Dictionary, mat: String, shade: String, light: String, outline := true, rim := true) -> void:
		if outline:
			for p in mask:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if not mask.has(q):
						put(q.x, q.y, "k")
		for p in mask:
			put(p.x, p.y, mat)
		if not rim:
			return
		for p in mask:
			var right := not mask.has(p + Vector2i(1, 0))
			var below := not mask.has(p + Vector2i(0, 1))
			var diag := not mask.has(p + Vector2i(1, 1))
			if shade != "" and (right or below or diag):
				put(p.x, p.y, shade)
			elif light != "" and (not mask.has(p + Vector2i(-1, 0)) or not mask.has(p + Vector2i(0, -1))):
				put(p.x, p.y, light)

# --- Masks -----------------------------------------------------

static func mask_of(part: Dictionary, w: int, h: int) -> Dictionary:
	var m := {}
	match String(part.t):
		"blob", "egg":
			var cx: float = part.x
			var cy: float = part.y
			var rx: float = part.rx
			var ry: float = part.ry
			var n: float = part.get("n", 2.0)
			var k: float = part.get("k", 0.0)
			for y in range(maxi(0, floori(cy - ry - 1)), mini(h, ceili(cy + ry + 1))):
				for x in range(maxi(0, floori(cx - rx * 1.4 - 1)), mini(w, ceili(cx + rx * 1.4 + 1))):
					var dy := (y + 0.5 - cy) / ry
					var widen := 1.0 + k * dy
					var dx := (x + 0.5 - cx) / (rx * widen)
					if pow(absf(dx), n) + pow(absf(dy), n) <= 1.0:
						m[Vector2i(x, y)] = true
		"rect":
			for y in range(int(part.y), int(part.y) + int(part.h)):
				for x in range(int(part.x), int(part.x) + int(part.w)):
					if x >= 0 and y >= 0 and x < w and y < h:
						m[Vector2i(x, y)] = true
		"tri":
			var a: Vector2 = part.p[0]
			var b: Vector2 = part.p[1]
			var c: Vector2 = part.p[2]
			var lo := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.y, minf(b.y, c.y)))
			var hi := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.y, maxf(b.y, c.y)))
			for y in range(maxi(0, floori(lo.y)), mini(h, ceili(hi.y) + 1)):
				for x in range(maxi(0, floori(lo.x)), mini(w, ceili(hi.x) + 1)):
					if _in_tri(Vector2(x + 0.5, y + 0.5), a, b, c):
						m[Vector2i(x, y)] = true
		"line":
			var a: Vector2 = part.a
			var b: Vector2 = part.b
			var steps := maxi(1, ceili(a.distance_to(b) * 2.0))
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps)
				m[Vector2i(floori(p.x), floori(p.y))] = true
		"star":
			var cx: float = part.x
			var cy: float = part.y
			var r: float = part.r
			var pts := []
			for i in 10:
				var ang := -PI / 2.0 + i * PI / 5.0
				var rr := r if i % 2 == 0 else r * 0.45
				pts.append(Vector2(cx + cos(ang) * rr, cy + sin(ang) * rr))
			for i in 10:
				var tri := {"t": "tri", "p": [Vector2(cx, cy), pts[i], pts[(i + 1) % 10]]}
				m.merge(mask_of(tri, w, h))
		"group":
			for sub in part.parts:
				m.merge(mask_of(sub, w, h))
	return m

static func _in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := (p - b).cross(a - b)
	var d2 := (p - c).cross(b - c)
	var d3 := (p - a).cross(c - a)
	var neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (neg and pos)

# Paints a list of parts. Each part: {t, ...shape, m: material,
# ol: outline (true), rim: shading (true), shine: bool}.
static func paint_parts(canvas: Canvas, parts: Array) -> void:
	for part in parts:
		var mask := mask_of(part, canvas.w, canvas.h)
		var mat: String = part.m
		var shade: String = part.get("sh", SHADE_OF.get(mat, ""))
		var light: String = part.get("li", LIGHT_OF.get(mat, ""))
		canvas.paint(mask, mat, shade, light, part.get("ol", true), part.get("rim", true))
		if part.get("shine", false):
			var sx := floori(float(part.x) - float(part.rx) * 0.5)
			var sy := floori(float(part.y) - float(part.ry) * 0.55)
			canvas.put(sx, sy, "W")
			canvas.put(sx + 1, sy, "W")
			canvas.put(sx, sy + 1, "W")

const SHADE_OF := {"1": "2", "a": "A", "b": "B", "c": "C", "w": "C", "p": "P", "m": "M", "y": "Y", "l": "L", "o": "O", "d": "D", "n": "N", "g": "G", "r": "R"}
const LIGHT_OF := {"1": "3"}
