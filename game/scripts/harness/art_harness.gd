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
	var font := load("res://scripts/art/pixel_font.gd")
	if font != null and font.has_method("contact_sheet"):
		out["font"] = font.contact_sheet()
	return out
