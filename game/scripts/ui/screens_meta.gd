class_name ScreensMeta
extends RefCounted

# ============================================================
# Collection book, family tree, badges, and the mini-game list
# shown in the Play sheet.
# ============================================================

static func register() -> void:
	Screens.EXTRA["book"] = _book
	Screens.EXTRA["family"] = _family
	Screens.EXTRA["badges"] = _badges
	Screens.EXTRA["game_items"] = _game_items

static func _silhouette(form: String) -> Texture2D:
	return Px.cached("shadow:" + form, func() -> Image:
		var img := Forms.body_image(form)
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					img.set_pixel(x, y, Color("cfc4d8"))
		return img)

static func _book(ui: GameUI) -> void:
	var save: Dictionary = ui.game.save
	var v := Kit.vbox(10)
	var found := 0
	for f in Cfg.FORM_ORDER:
		if save.book.has(f):
			found += 1
	v.add_child(Kit.row("Discovered", "%d / %d" % [found, Cfg.FORM_ORDER.size()], "book"))
	var detail := Kit.para("Tap a form to learn about it.", Kit.FONT, Pal.INK_SOFT)
	v.add_child(detail)
	var stages := [["egg", "Egg"], ["baby", "Baby"], ["child", "Children"], ["teen", "Teens"], ["adult", "Adults"]]
	for st in stages:
		var forms := []
		for f in Cfg.FORM_ORDER:
			if Cfg.FORMS[f].stage == st[0]:
				forms.append(f)
		v.add_child(Kit.label(st[1], Kit.FONT, Pal.INK_SOFT))
		var g := ScreensShop._grid(4)
		for f in forms:
			var known: bool = save.book.has(f)
			var tex := Forms.sprite(f, "idle") if known else _silhouette(f)
			var name: String = Cfg.FORMS[f].name if known else "???"
			var form: String = f
			var tile := ScreensShop._tile(tex, name, "", false, func() -> void:
				var info: Dictionary = Cfg.FORMS[form]
				if save.book.has(form):
					var when := Time.get_date_string_from_unix_time(int(save.book[form]) + Clock.tz_bias() * 60)
					detail.text = "%s: first raised %s. %s" % [info.name, when, info.hint]
				else:
					detail.text = "???: %s" % info.hint
				ui.sfx.play("blip"))
			tile.custom_minimum_size.y = 84
			g.add_child(tile)
		v.add_child(g)
	ui.open(S.t("more_book"), v, false, true, "book")

static func _family(ui: GameUI) -> void:
	var save: Dictionary = ui.game.save
	var v := Kit.vbox(8)
	var fam: Array = save.family
	var line := -1
	for e in fam:
		if int(e.line) != line:
			line = int(e.line)
			v.add_child(Kit.label("Family line %d" % line, Kit.FONT_BIG))
		elif int(e.gen) > 1:
			var arrow := Kit.icon("right", 2)
			arrow.rotation_degrees = 90
			arrow.pivot_offset = Vector2(5, 7)
			var row := Kit.hbox(0)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(arrow)
			v.add_child(row)
		var r := Kit.hbox(10)
		var alive: bool = int(e.died) == 0
		r.add_child(Kit.tex_rect(Forms.sprite(e.form, "idle" if alive else "sleep"), 2))
		var info := Kit.vbox(2)
		var nm: String = e.name if e.name != "" else ("Egg" if e.form == "egg" else "Unnamed")
		info.add_child(Kit.label("%s · Gen %d" % [nm, int(e.gen)]))
		info.add_child(Kit.label(Cfg.FORMS.get(e.form, Cfg.FORMS.egg).name, Kit.FONT, Pal.INK_SOFT))
		var traits: Array = e.get("traits", [])
		var tnames := []
		for t in traits:
			tnames.append(S.t("trait_" + String(t)))
		info.add_child(Kit.label(", ".join(tnames), Kit.FONT, Pal.INK_SOFT))
		if alive:
			info.add_child(Kit.label("Living now", Kit.FONT, Pal.GOOD))
		else:
			info.add_child(Kit.label("%s · %s" % [Clock.fmt_age(int(e.age_min)), S.t("cause_" + String(e.cause))], Kit.FONT, Pal.INK_SOFT))
		r.add_child(info)
		v.add_child(Kit.card(r, Pal.PANEL_ALT if alive else Color("efe8ee")))
	ui.open(S.t("more_family"), v, false, true, "family")

static func _badges(ui: GameUI) -> void:
	var save: Dictionary = ui.game.save
	var v := Kit.vbox(8)
	v.add_child(Kit.row("Earned", "%d / %d" % [save.achievements.size(), Achievements.LIST.size()], "badge"))
	for a in Achievements.LIST:
		var got: bool = save.achievements.has(a.id)
		var r := Kit.hbox(10)
		r.add_child(Kit.icon("badge" if got else "lock", 2))
		var info := Kit.vbox(2)
		info.add_child(Kit.label(a.name, Kit.FONT, Pal.INK if got else Pal.INK_SOFT))
		info.add_child(Kit.para(a.desc, Kit.FONT, Pal.INK_SOFT))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		r.add_child(Kit.label("+%d" % int(a.coins), Kit.FONT, Pal.INK_SOFT))
		v.add_child(Kit.card(r, Color("fdf1c4") if got else Pal.PANEL_ALT))
	ui.open(S.t("more_achievements"), v, false, true, "badge")

static func _game_items(ui: GameUI) -> Control:
	var v := Kit.vbox(6)
	v.add_child(Kit.label("Mini-games (-%d energy)" % int(MiniGame.ENERGY), Kit.FONT, Pal.INK_SOFT))
	var g := ScreensShop._grid(3)
	for m in [["left_right", "Left/Right", "left"], ["catch_food", "Catch", "hunger"], ["jump_runner", "Runner", "energy"]]:
		var kind: String = m[0]
		var tile := ScreensShop._tile(Icons.tex(m[2], 2), m[1], "Play", false, func() -> void:
			ui.open_minigame(kind))
		g.add_child(tile)
	v.add_child(g)
	return v
