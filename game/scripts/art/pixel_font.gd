class_name PixelFont
extends RefCounted

# ============================================================
# A proportional 5×7 pixel font built at runtime: glyph grids are
# packed into an atlas Image and registered on a FontFile as a
# bitmap font (no font file to ship). Lowercase draws as caps.
# Base size is 8 (7 ascent + 1 descent), so sizes 16/24/32 scale
# crisply by whole pixels. Anything missing falls back to the
# engine font.
# ============================================================

const BASE := 8
const ASCENT := 7

const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
	".": [".", ".", ".", ".", ".", ".", "#"],
	",": ["..", "..", "..", "..", "..", ".#", "#."],
	"!": ["#", "#", "#", "#", "#", ".", "#"],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"'": ["#", "#", ".", ".", ".", ".", "."],
	"\"": ["#.#", "#.#", "...", "...", "...", "...", "..."],
	"-": ["...", "...", "...", "###", "...", "...", "..."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"=": ["...", "...", "###", "...", "###", "...", "..."],
	":": [".", ".", "#", ".", ".", "#", "."],
	";": ["..", "..", ".#", "..", "..", ".#", "#."],
	"/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
	"(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
	")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
	"<": ["...#", "..#.", ".#..", "#...", ".#..", "..#.", "...#"],
	">": ["#...", ".#..", "..#.", "...#", "..#.", ".#..", "#..."],
	"*": [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."],
	"_": [".....", ".....", ".....", ".....", ".....", ".....", "#####"],
	"#": [".#.#.", "#####", ".#.#.", ".#.#.", ".#.#.", "#####", ".#.#."],
	"&": [".##..", "#..#.", ".##..", ".#...", "#.#.#", "#..#.", ".##.#"],
	"×": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
	"…": [".....", ".....", ".....", ".....", ".....", ".....", "#.#.#"],
	"°": ["###", "#.#", "###", "...", "...", "...", "..."],
}
const SPACE_ADVANCE := 4

# 3×5 mini font for button labels and captions (size 12 = 2×).
const MINI_BASE := 6
const MINI_ASCENT := 5
const MINI := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"], "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."], "P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "##.", ".##"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"], "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "Z": ["###", "..#", ".#.", "#..", "###"],
	"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
	".": [".", ".", ".", ".", "#"], "!": ["#", "#", "#", ".", "#"],
	"?": ["##.", "..#", ".#.", "...", ".#."], "-": ["...", "...", "###", "...", "..."],
	"+": ["...", ".#.", "###", ".#.", "..."], ":": [".", "#", ".", "#", "."],
	"/": ["..#", "..#", ".#.", "#..", "#.."], "%": ["#.#", "..#", ".#.", "#..", "#.#"],
	"'": ["#", "#", ".", ".", "."], ",": [".", ".", ".", "#", "#"],
	"(": [".#", "#.", "#.", "#.", ".#"], ")": ["#.", ".#", ".#", ".#", "#."],
}

static var _font: Font = null
static var _mini: Font = null

static func font() -> Font:
	if _font == null:
		_font = _build(GLYPHS, BASE, ASCENT, SPACE_ADVANCE)
	return _font

static func mini() -> Font:
	if _mini == null:
		_mini = _build(MINI, MINI_BASE, MINI_ASCENT, 3)
	return _mini

static func _trim(rows: Array) -> Array:
	return rows

static func _build(glyphs: Dictionary, base: int, ascent: int, space: int) -> Font:
	var keys := glyphs.keys()
	var x := 0
	var rects := {}
	for k in keys:
		var w: int = String(glyphs[k][0]).length()
		rects[k] = Rect2i(x, 0, w, ascent)
		x += w + 1
	var atlas := Image.create_empty(maxi(1, x), base, false, Image.FORMAT_RGBA8)
	for k in keys:
		var r: Rect2i = rects[k]
		var rows: Array = glyphs[k]
		for y in rows.size():
			var row: String = rows[y]
			for gx in row.length():
				if row[gx] == "#":
					atlas.set_pixel(r.position.x + gx, y, Color.WHITE)
	var f := FontFile.new()
	f.fixed_size = base
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.generate_mipmaps = false
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.allow_system_fallback = false
	var sz := Vector2i(base, 0)
	f.set_cache_ascent(0, base, ascent)
	f.set_cache_descent(0, base, base - ascent)
	f.set_cache_underline_position(0, base, 1)
	f.set_cache_underline_thickness(0, base, 1)
	f.set_texture_image(0, sz, 0, atlas)
	for k in keys:
		var r: Rect2i = rects[k]
		var codes := [String(k).unicode_at(0)]
		var lower := String(k).to_lower()
		if lower != String(k) and not glyphs.has(lower):
			codes.append(lower.unicode_at(0))
		for code in codes:
			f.set_glyph_advance(0, base, code, Vector2(r.size.x + 1, 0))
			f.set_glyph_offset(0, sz, code, Vector2(0, -ascent))
			f.set_glyph_size(0, sz, code, Vector2(r.size))
			f.set_glyph_uv_rect(0, sz, code, Rect2(r))
			f.set_glyph_texture_idx(0, sz, code, 0)
	f.set_glyph_advance(0, base, 32, Vector2(space, 0))
	f.set_glyph_offset(0, sz, 32, Vector2.ZERO)
	f.set_glyph_size(0, sz, 32, Vector2.ZERO)
	f.set_glyph_uv_rect(0, sz, 32, Rect2())
	f.set_glyph_texture_idx(0, sz, 32, 0)
	f.fallbacks = [ThemeDB.fallback_font]
	return f

# Measures a string in base pixels (for layout without a renderer).
static func text_width(text: String) -> int:
	var w := 0
	for i in text.length():
		var ch := text[i]
		if ch == " ":
			w += SPACE_ADVANCE
			continue
		var up := ch.to_upper()
		if GLYPHS.has(ch):
			w += String(GLYPHS[ch][0]).length() + 1
		elif GLYPHS.has(up):
			w += String(GLYPHS[up][0]).length() + 1
		else:
			w += 6
	return maxi(0, w - 1)

# Draws text into an Image on the CPU (used by headless sheets
# and for baking the PWA icons).
static func draw_into(img: Image, text: String, x: int, y: int, color: Color, scale: int = 1) -> void:
	var cx := x
	for i in text.length():
		var ch := text[i]
		if ch == " ":
			cx += SPACE_ADVANCE * scale
			continue
		var key := ch if GLYPHS.has(ch) else ch.to_upper()
		if not GLYPHS.has(key):
			cx += 6 * scale
			continue
		var rows: Array = GLYPHS[key]
		for gy in rows.size():
			var row: String = rows[gy]
			for gx in row.length():
				if row[gx] == "#":
					img.fill_rect(Rect2i(cx + gx * scale, y + gy * scale, scale, scale), color)
		cx += (String(rows[0]).length() + 1) * scale

static func contact_sheet() -> Image:
	var lines := [
		"THE QUICK BROWN FOX",
		"JUMPS OVER THE LAZY DOG",
		"0123456789 .,!?'\"-+=:;",
		"/()%<>*_#&×°",
		"Pixel Pet: feed, play & love!",
		"Hunger 72%  Coins 1,250",
	]
	var scale := 3
	var img := Image.create_empty(560, lines.size() * 11 * scale + 8, false, Image.FORMAT_RGBA8)
	img.fill(Pal.PANEL)
	for i in lines.size():
		draw_into(img, lines[i], 6, 6 + i * 11 * scale, Pal.INK, scale)
	return img
