class_name Room
extends RefCounted

# ============================================================
# Draws the pet's room in room pixels (the world node is scaled
# 3×): wallpaper, floor, baseboard, the window with the live sky
# and weather, curtains, and the decor slots. Layout comes from
# `layout(size)` so the world, decor and input share one source.
# ============================================================

const WALLPAPERS := {
	"wall_cream":  {"base": Color("fbe9d7"), "alt": Color("f6dcc6"), "pattern": "stripes"},
	"wall_mint":   {"base": Color("d6f1e4"), "alt": Color("bfe8d4"), "pattern": "dots"},
	"wall_lilac":  {"base": Color("e8def5"), "alt": Color("d8caee"), "pattern": "hearts"},
	"wall_sky":    {"base": Color("dcecfa"), "alt": Color("ffffff"), "pattern": "clouds"},
	"wall_peach":  {"base": Color("fde0cf"), "alt": Color("f8cdb6"), "pattern": "checks"},
	"wall_butter": {"base": Color("fdf1c4"), "alt": Color("f6e2a0"), "pattern": "stars"},
}
const FLOORS := {
	"floor_oak":    {"base": Color("dfb994"), "alt": Color("d2a880"), "seam": Color("b88a66"), "pattern": "planks"},
	"floor_mint":   {"base": Color("bfe8d4"), "alt": Color("a8e0c8"), "seam": Color("8ccdb2"), "pattern": "tiles"},
	"floor_pink":   {"base": Color("f8c8d4"), "alt": Color("f4b6c6"), "seam": Color("e8a0b4"), "pattern": "carpet"},
	"floor_lilac":  {"base": Color("d8caee"), "alt": Color("c9b6e4"), "seam": Color("b09ad6"), "pattern": "tiles"},
	"floor_walnut": {"base": Color("b88a66"), "alt": Color("a87a58"), "seam": Color("8a5e44"), "pattern": "planks"},
	"floor_cloud":  {"base": Color("f2f4fa"), "alt": Color("e4e8f4"), "seam": Color("cfd6ea"), "pattern": "carpet"},
}

const INK := Color("5a4a6a")

# Everything in room pixels. `top` / `bottom` are the room pixels
# hidden behind the HUD and the action bar.
static func layout(size: Vector2, top: float, bottom: float) -> Dictionary:
	var w := size.x
	var h := size.y
	var floor_y := floorf(lerpf(top, h - bottom, 0.5) + 4.0)
	var ground := floorf(lerpf(floor_y, h - bottom, 0.62))
	var win_w := clampf(roundf(w * 0.42), 40.0, 64.0)
	var win_h := clampf(roundf((floor_y - top) * 0.55), 30.0, 52.0)
	var win := Rect2(floorf((w - win_w) / 2.0), floorf(top + 10.0), win_w, win_h)
	return {
		"w": w, "h": h, "floor_y": floor_y, "ground": ground, "window": win,
		"walk_min": 22.0, "walk_max": w - 22.0,
		"slots": {
			"wall_l":  Vector2(floorf(win.position.x / 2.0), win.position.y + 14),
			"wall_r":  Vector2(floorf((win.end.x + w) / 2.0), win.position.y + 14),
			"sill":    Vector2(floorf(win.position.x + win_w * 0.78), win.end.y + 2),
			"floor_l": Vector2(3, floorf(lerpf(floor_y, ground, 0.45))),
			"floor_r": Vector2(w - 3, floorf(lerpf(floor_y, ground, 0.45))),
			"rug":     Vector2(floorf(w / 2.0), ground + 1),
		},
	}

static func draw_room(ci: CanvasItem, lay: Dictionary, room: Dictionary, minute: int, weather: String, anim_t: float) -> void:
	var w: float = lay.w
	var h: float = lay.h
	var floor_y: float = lay.floor_y
	var wp: Dictionary = WALLPAPERS.get(room.get("wallpaper", ""), WALLPAPERS.wall_cream)
	var fl: Dictionary = FLOORS.get(room.get("floor", ""), FLOORS.floor_oak)
	# Wall
	ci.draw_rect(Rect2(0, 0, w, floor_y), wp.base)
	_wall_pattern(ci, wp, w, floor_y)
	ci.draw_rect(Rect2(0, 0, w, 2), wp.alt.darkened(0.08))
	# Floor
	ci.draw_rect(Rect2(0, floor_y, w, h - floor_y), fl.base)
	_floor_pattern(ci, fl, w, floor_y, h)
	# Baseboard
	ci.draw_rect(Rect2(0, floor_y - 3, w, 3), Color("fffaf4"))
	ci.draw_rect(Rect2(0, floor_y, w, 1), INK.lerp(fl.seam, 0.5))
	# Window
	_window(ci, lay.window, minute, weather, anim_t)

static func _wall_pattern(ci: CanvasItem, wp: Dictionary, w: float, h: float) -> void:
	var alt: Color = wp.alt
	match String(wp.pattern):
		"stripes":
			var x := 2.0
			while x < w:
				ci.draw_rect(Rect2(x, 0, 3, h), alt)
				x += 10.0
		"dots":
			for y in range(6, int(h) - 4, 9):
				var off := 4 if (y / 9) % 2 == 0 else 0
				for x in range(off + 3, int(w), 9):
					ci.draw_rect(Rect2(x, y, 2, 2), alt)
		"checks":
			for y in range(0, int(h), 8):
				for x in range(0, int(w), 8):
					if ((x + y) / 8) % 2 == 0:
						ci.draw_rect(Rect2(x, y, 8, 8), alt)
		"hearts":
			for y in range(8, int(h) - 6, 14):
				var off := 7 if (y / 14) % 2 == 0 else 0
				for x in range(off + 4, int(w), 14):
					ci.draw_rect(Rect2(x, y, 1, 1), alt)
					ci.draw_rect(Rect2(x + 2, y, 1, 1), alt)
					ci.draw_rect(Rect2(x - 1, y + 1, 5, 1), alt)
					ci.draw_rect(Rect2(x, y + 2, 3, 1), alt)
					ci.draw_rect(Rect2(x + 1, y + 3, 1, 1), alt)
		"clouds":
			for y in range(10, int(h) - 8, 18):
				var off := 10 if (y / 18) % 2 == 0 else 0
				for x in range(off + 2, int(w), 22):
					ci.draw_rect(Rect2(x + 2, y, 4, 1), alt)
					ci.draw_rect(Rect2(x, y + 1, 9, 2), alt)
		"stars":
			for y in range(8, int(h) - 6, 13):
				var off := 6 if (y / 13) % 2 == 0 else 0
				for x in range(off + 3, int(w), 13):
					ci.draw_rect(Rect2(x + 1, y, 1, 3), alt)
					ci.draw_rect(Rect2(x, y + 1, 3, 1), alt)

static func _floor_pattern(ci: CanvasItem, fl: Dictionary, w: float, top: float, h: float) -> void:
	match String(fl.pattern):
		"planks":
			var row := 0
			var y := top + 1
			while y < h:
				var ph := 5.0 + row
				if row % 2 == 1:
					ci.draw_rect(Rect2(0, y, w, ph), fl.alt)
				ci.draw_rect(Rect2(0, y + ph - 1, w, 1), fl.seam)
				var seam_x := 14.0 + (row * 23) % 31
				while seam_x < w:
					ci.draw_rect(Rect2(seam_x, y, 1, ph - 1), fl.seam)
					seam_x += 38.0
				y += ph
				row += 1
		"tiles":
			var size := 10
			for y in range(int(top) + 1, int(h), size):
				for x in range(0, int(w), size):
					if ((x + y) / size) % 2 == 0:
						ci.draw_rect(Rect2(x, y, size, size), fl.alt)
				ci.draw_rect(Rect2(0, y, w, 1), fl.seam)
		"carpet":
			for y in range(int(top) + 3, int(h), 4):
				for x in range((y / 4) % 2 * 2, int(w), 4):
					ci.draw_rect(Rect2(x, y, 1, 1), fl.alt)

static func _window(ci: CanvasItem, r: Rect2, minute: int, weather: String, anim_t: float) -> void:
	var frame := Color("fffaf4")
	ci.draw_rect(r.grow(3), INK)
	ci.draw_rect(r.grow(2), frame)
	ci.draw_rect(r.grow(1), INK)
	# Sky: vertical bands so it stays pixel-crisp.
	var cols := SkyCycle.colors(minute)
	var bands := 6
	for i in bands:
		var y0 := r.position.y + floorf(r.size.y * i / bands)
		var y1 := r.position.y + floorf(r.size.y * (i + 1) / bands)
		ci.draw_rect(Rect2(r.position.x, y0, r.size.x, y1 - y0), cols[0].lerp(cols[1], float(i) / (bands - 1)))
	var cloudy := weather != "clear"
	# Stars
	var sa := SkyCycle.star_alpha(minute)
	if sa > 0.0 and not cloudy:
		for i in SkyCycle.STAR_SPOTS.size():
			var p: Vector2 = SkyCycle.STAR_SPOTS[i]
			var tw := 0.6 + 0.4 * sin(anim_t * 2.0 + i * 1.7)
			ci.draw_rect(Rect2(floorf(r.position.x + p.x * r.size.x), floorf(r.position.y + p.y * r.size.y * 0.8), 1, 1), Color(1, 1, 0.9, sa * tw))
	# Sun or moon on a shallow arc
	var b := SkyCycle.body(minute)
	var bx := r.position.x + 4 + (r.size.x - 8) * float(b.t)
	var by := r.position.y + r.size.y * 0.62 - sin(PI * float(b.t)) * r.size.y * 0.42
	var alpha := 0.35 if cloudy else 1.0
	if b.kind == "sun":
		_disc(ci, Vector2(floorf(bx), floorf(by)), 4, Color(1.0, 0.89, 0.45, alpha))
	else:
		_disc(ci, Vector2(floorf(bx), floorf(by)), 3, Color(1.0, 0.97, 0.85, alpha))
		_disc(ci, Vector2(floorf(bx) + 2, floorf(by) - 1), 3, cols[0].lerp(cols[1], 0.3))
	# Weather
	match weather:
		"cloudy", "rain", "snow":
			var drift := fmod(anim_t * 2.0, r.size.x + 20)
			for i in 3:
				var cx := r.position.x + fmod(drift + i * (r.size.x / 3.0 + 7), r.size.x + 20) - 10
				var cy := r.position.y + 3 + (i % 2) * 6
				var cc := Color(1, 1, 1, 0.92) if weather == "cloudy" else Color("d8d4e6")
				if SkyCycle.star_alpha(minute) > 0.5:
					cc = cc.darkened(0.45)
				_cloud(ci, Vector2(floorf(cx), floorf(cy)), cc, r)
	if weather == "rain":
		for i in 14:
			var px := r.position.x + fmod(i * 7.3 + anim_t * 6.0, r.size.x)
			var py := r.position.y + fmod(i * 11.1 + anim_t * 46.0, r.size.y)
			ci.draw_rect(Rect2(floorf(px), floorf(py), 1, 2), Color("8fb8e8"))
	elif weather == "snow":
		for i in 14:
			var px := r.position.x + fmod(i * 7.3 + sin(anim_t + i) * 2.0 + r.size.x, r.size.x)
			var py := r.position.y + fmod(i * 11.1 + anim_t * 9.0, r.size.y)
			ci.draw_rect(Rect2(floorf(px), floorf(py), 1, 1), Color.WHITE)
	# Cross bars
	ci.draw_rect(Rect2(r.position.x + floorf(r.size.x / 2.0) - 1, r.position.y, 2, r.size.y), frame)
	ci.draw_rect(Rect2(r.position.x, r.position.y + floorf(r.size.y / 2.0) - 1, r.size.x, 2), frame)
	# Sill
	ci.draw_rect(Rect2(r.position.x - 5, r.end.y + 2, r.size.x + 10, 3), INK)
	ci.draw_rect(Rect2(r.position.x - 4, r.end.y + 2, r.size.x + 8, 2), frame)
	# Curtains
	var cur := Color("f8c8d4")
	var cur_d := Color("ec9fb4")
	for side in [-1, 1]:
		var cx := r.position.x - 6 if side < 0 else r.end.x + 1
		ci.draw_rect(Rect2(cx - 1, r.position.y - 5, 7, r.size.y + 9), INK)
		ci.draw_rect(Rect2(cx, r.position.y - 4, 5, r.size.y + 7), cur)
		ci.draw_rect(Rect2(cx + (3 if side < 0 else 1), r.position.y - 4, 1, r.size.y + 7), cur_d)
	ci.draw_rect(Rect2(r.position.x - 8, r.position.y - 6, r.size.x + 16, 2), Color("c89878"))

static func _disc(ci: CanvasItem, c: Vector2, rad: int, col: Color) -> void:
	for dy in range(-rad, rad + 1):
		var half := floori(sqrt(float(rad * rad - dy * dy)) + 0.35)
		ci.draw_rect(Rect2(c.x - half, c.y + dy, half * 2 + 1, 1), col)

static func _cloud(ci: CanvasItem, p: Vector2, col: Color, clip: Rect2) -> void:
	var parts := [Rect2(p.x + 2, p.y, 5, 1), Rect2(p.x, p.y + 1, 10, 2), Rect2(p.x + 1, p.y + 3, 8, 1)]
	for part in parts:
		var c: Rect2 = part.intersection(clip)
		if c.has_area():
			ci.draw_rect(c, col)
