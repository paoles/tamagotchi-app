extends RefCounted

# ============================================================
# Renders contact sheets of generated art to PNG without a GPU:
#   godot --headless --path game -- art [out_dir]
# Everything is composed on the CPU with Image, so this runs in
# CI and headless sessions. Used to eyeball sprites quickly.
# ============================================================

const EXPRS := ["idle", "blink", "happy", "love", "sad", "hungry", "angry", "sleep", "eat_a", "eat_b", "call", "dead"]

func run(out_dir: String) -> int:
	DirAccess.make_dir_recursive_absolute(out_dir)
	_save(_forms_sheet(), out_dir.path_join("forms.png"))
	if ClassDB.class_exists("Icons") or true:
		var extra := _extra_sheets()
		for name in extra:
			_save(extra[name], out_dir.path_join(name + ".png"))
	print("art sheets written to ", out_dir)
	return 0

# PWA icons: the happy Mochi on a pastel tile.
func icons(out_dir: String) -> int:
	DirAccess.make_dir_recursive_absolute(out_dir)
	for spec in [["icon-192.png", 192, false], ["icon-512.png", 512, false], ["icon-maskable-512.png", 512, true], ["icon-180.png", 180, false], ["favicon-32.png", 32, false]]:
		_save(_icon(spec[1], spec[2]), out_dir.path_join(spec[0]))
	print("icons written to ", out_dir)
	return 0

func _icon(px: int, maskable: bool) -> Image:
	var img := Image.create_empty(px, px, false, Image.FORMAT_RGBA8)
	var bg := Color("cdeee0")
	img.fill(bg if maskable else Color(0, 0, 0, 0))
	if not maskable:
		# Rounded tile with a plum border.
		var rad := px * 0.22
		for y in px:
			for x in px:
				var dx := maxf(0.0, maxf(rad - x, x - (px - 1 - rad)))
				var dy := maxf(0.0, maxf(rad - y, y - (px - 1 - rad)))
				var d := sqrt(dx * dx + dy * dy)
				if d <= rad:
					img.set_pixel(x, y, Pal.INK if d > rad - maxf(2.0, px / 40.0) else bg)
	var sprite := Forms.compose("mochi", "happy")
	var scale := maxi(1, floori(px * (0.62 if maskable else 0.78) / 16.0))
	var big := Px.scaled(sprite, scale)
	var bx := (px - big.get_width()) / 2
	# The baby sits low in its 32×32 canvas; centre its visible body.
	var by := (px - big.get_height()) / 2 - roundi(9.0 * scale)
	Px.stamp(img, big, bx, by)
	return img

func _save(img: Image, path: String) -> void:
	var err := img.save_png(path)
	if err != OK:
		push_error("could not save %s (%d)" % [path, err])

func _forms_sheet() -> Image:
	var scale := 4
	var cell := 36
	var cols := EXPRS.size()
	var rows := Cfg.FORM_ORDER.size()
	var sheet := Image.create_empty(cols * cell * scale, rows * cell * scale, false, Image.FORMAT_RGBA8)
	sheet.fill(Pal.BG)
	for r in rows:
		var form: String = Cfg.FORM_ORDER[r]
		for c in cols:
			var bg := Pal.PANEL if (r + c) % 2 == 0 else Pal.PANEL_ALT
			sheet.fill_rect(Rect2i(c * cell * scale, r * cell * scale, cell * scale, cell * scale), bg)
			var img := Forms.compose(form, "crack" if form == "egg" and c == 1 else EXPRS[c])
			Px.stamp(sheet, Px.scaled(img, scale), c * cell * scale + 2 * scale, r * cell * scale + 2 * scale)
	return sheet

# Other generated art (icons, items, font) registers here once written.
func _extra_sheets() -> Dictionary:
	var out := {}
	var script := load("res://scripts/art/icons.gd")
	if script != null and script.has_method("contact_sheet"):
		out["icons"] = script.contact_sheet()
	var items := load("res://scripts/art/items.gd")
	if items != null and items.has_method("contact_sheet"):
		out["items"] = items.contact_sheet()
	out["goods"] = Goods.contact_sheet()
	var font := load("res://scripts/art/pixel_font.gd")
	if font != null and font.has_method("contact_sheet"):
		out["font"] = font.contact_sheet()
	return out
