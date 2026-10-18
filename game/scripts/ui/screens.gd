class_name Screens
extends RefCounted

# ============================================================
# Builders for every sheet and dialog. Each takes the GameUI and
# opens itself; buttons call back into ui.game. Screens added in
# later milestones register in `EXTRA` (name → Callable).
# ============================================================

static var EXTRA := {}

static func open(ui: GameUI, name: String) -> void:
	if EXTRA.has(name):
		EXTRA[name].call(ui)
		return
	match name:
		"feed": _feed(ui)
		"play": _play(ui)
		"more": _more(ui)
		"status": _status(ui)
		"name": _name(ui)
		"schedule": _schedule(ui)
		"recap": _recap(ui)
		"death": _death(ui)
		"memorial": _memorial(ui)
		"daycare": _daycare(ui)
		"settings": _settings(ui)
		"debug": _debug(ui)
		_:
			ui.toast("Coming soon!", "gift")

static func _act_close(ui: GameUI, action: String) -> Callable:
	return func() -> void:
		ui.close_sheet()
		ui.game.act(action)

# --- Feed / play / more -----------------------------------------

static func _feed(ui: GameUI) -> void:
	var v := Kit.vbox(8)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_child(_big(Kit.tall_button(S.t("feed_meal"), "feed", _act_close(ui, "meal"), Vector2(0, 84))))
	grid.add_child(_big(Kit.tall_button(S.t("feed_snack"), "heart", _act_close(ui, "snack"), Vector2(0, 84))))
	v.add_child(grid)
	v.add_child(Kit.para("Meals fill hunger. Snacks cheer your pet up but add weight.", 16, Pal.INK_SOFT))
	if Screens.EXTRA.has("food_items"):
		v.add_child(Screens.EXTRA.food_items.call(ui))
	ui.open(S.t("act_feed"), v, false, true, "feed")

static func _play(ui: GameUI) -> void:
	var v := Kit.vbox(8)
	v.add_child(Kit.tall_button(S.t("play_basic"), "play", _act_close(ui, "play"), Vector2(0, 76)))
	if Screens.EXTRA.has("play_items"):
		v.add_child(Screens.EXTRA.play_items.call(ui))
	ui.open(S.t("act_play"), v, false, true, "play")

static func _big(b: Button) -> Button:
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

const MORE := [
	["status", "more_status", "status"], ["shop", "more_shop", "shop"], ["wardrobe", "more_wardrobe", "wardrobe"],
	["decor", "more_decor", "decor"], ["book", "more_book", "book"], ["family", "more_family", "family"],
	["badges", "more_achievements", "badge"], ["memorial", "more_memorial", "memorial"], ["daycare", "more_daycare", "daycare"],
	["settings", "more_settings", "settings"],
]

static func _more(ui: GameUI) -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	var items := MORE.duplicate()
	if ui.game.save.settings.debug_unlocked:
		items.append(["debug", "Debug", "game"])
	for m in items:
		var id: String = m[0]
		var label: String = S.t(m[1]) if S.T.has(m[1]) else m[1]
		var b := Kit.tall_button(label.to_upper(), m[2], func() -> void:
			ui.close_sheet()
			ui.open_screen(id), Vector2(0, 76))
		b.add_theme_font_override("font", PixelFont.mini())
		b.add_theme_font_size_override("font_size", 12)
		grid.add_child(_big(b))
	ui.open(S.t("act_more"), grid, false, true, "more")

# --- Status ------------------------------------------------------

static func _status(ui: GameUI) -> void:
	var save: Dictionary = ui.game.save
	var p: Dictionary = save.pet
	var v := Kit.vbox(8)
	if p.is_empty():
		return
	var head := Kit.hbox(12)
	var portrait := Kit.tex_rect(Forms.sprite(p.form, "idle"), 3)
	head.add_child(portrait)
	var who := Kit.vbox(4)
	who.add_child(Kit.label(ui.game.pet_name(), Kit.FONT_BIG))
	who.add_child(Kit.label("%s · %s" % [Cfg.FORMS[p.form].name, S.t("stage_" + String(p.stage))], Kit.FONT, Pal.INK_SOFT))
	who.add_child(Kit.label("%s %d" % [S.t("stat_gen"), int(p.gen)], Kit.FONT, Pal.INK_SOFT))
	head.add_child(who)
	v.add_child(head)
	if p.stage != "egg":
		var stats := Kit.vbox(6)
		stats.add_child(Kit.row(S.t("stat_hunger"), "%d%%" % roundi(p.hunger), "hunger"))
		stats.add_child(Kit.row(S.t("stat_happy"), "%d%%" % roundi(p.happy), "heart"))
		stats.add_child(Kit.row(S.t("stat_energy"), "%d%%" % roundi(p.energy), "energy"))
		stats.add_child(Kit.row(S.t("stat_discipline"), "%d%%" % roundi(p.discipline), "discipline"))
		var wt := "%d g" % roundi(p.weight)
		if Sim.is_overweight(p):
			wt += " (chubby!)"
		stats.add_child(Kit.row(S.t("stat_weight"), wt, "weight"))
		v.add_child(Kit.card(stats))
		var life := Kit.vbox(6)
		life.add_child(Kit.row(S.t("stat_age"), Clock.fmt_age(int(p.age_min))))
		var next := Evolution.minutes_to_next_stage(p)
		var next_label := S.t("stat_next") if p.stage != "adult" else "Life left"
		life.add_child(Kit.row(next_label, "~" + Clock.fmt_age(next)))
		life.add_child(Kit.row(S.t("stat_mistakes"), str(int(p.mistakes))))
		v.add_child(Kit.card(life))
	var tr := Kit.vbox(4)
	tr.add_child(Kit.label(S.t("stat_traits"), Kit.FONT, Pal.INK_SOFT))
	for t in p.traits:
		var line := Kit.vbox(0)
		line.add_child(Kit.label(S.t("trait_" + String(t))))
		line.add_child(Kit.para(S.t("traitd_" + String(t)), Kit.FONT, Pal.INK_SOFT))
		tr.add_child(line)
	v.add_child(Kit.card(tr))
	ui.open(S.t("more_status"), v, false, true, "status")

# --- Hatch flow ---------------------------------------------------

static func _name(ui: GameUI) -> void:
	var v := Kit.vbox(10)
	var p: Dictionary = ui.game.save.pet
	v.add_child(Kit.tex_rect(Forms.sprite(p.form, "happy"), 4))
	v.add_child(Kit.para(S.t("name_hint"), Kit.FONT, Pal.INK_SOFT))
	var edit := LineEdit.new()
	edit.max_length = Cfg.NAME_MAX
	edit.placeholder_text = Cfg.NAME_SUGGESTIONS[randi() % Cfg.NAME_SUGGESTIONS.size()]
	edit.custom_minimum_size = Vector2(0, 44)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(edit)
	if OS.has_feature("web"):
		# Mobile browsers only show a keyboard for real text fields,
		# so typing goes through the browser's own prompt.
		edit.editable = false
		edit.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				var typed := WebBridge.prompt_text("Name your pet (up to %d letters)" % Cfg.NAME_MAX)
				if typed != "":
					edit.text = Care.sanitize_name(typed))
	var row := Kit.hbox(8)
	row.add_child(_big(Kit.button(S.t("name_random"), func() -> void:
		edit.text = Cfg.NAME_SUGGESTIONS[randi() % Cfg.NAME_SUGGESTIONS.size()])))
	var ok := Kit.accent(Kit.button(S.t("name_ok"), func() -> void:
		var n := ui.game.set_pet_name(edit.text if edit.text != "" else edit.placeholder_text)
		ui.sfx.play("happy")
		ui.toast("Hello, %s!" % n, "heart")
		ui.close_sheet()), Pal.MINT)
	row.add_child(_big(ok))
	v.add_child(row)
	ui.open(S.t("name_title"), v, true, false, "heart")

static func _schedule(ui: GameUI) -> void:
	var save: Dictionary = ui.game.save
	var state := {"bed": int(save.schedule.bed), "wake": int(save.schedule.wake)}
	var v := Kit.vbox(10)
	v.add_child(Kit.para(S.t("sched_body"), Kit.FONT, Pal.INK_SOFT))
	var hours := Kit.label("", Kit.FONT, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var labels := {}
	var refresh := func() -> void:
		labels.bed.text = Clock.fmt_hm(state.bed)
		labels.wake.text = Clock.fmt_hm(state.wake)
		var h := Clock.window_len(state.bed, state.wake) / 60.0
		hours.text = "%.1f h of sleep" % h
		hours.add_theme_color_override("font_color", Pal.INK if h >= Cfg.SLEEP_HOURS_MIN and h <= Cfg.SLEEP_HOURS_MAX else Pal.BAD)
	for key in ["bed", "wake"]:
		var r := Kit.hbox(8)
		r.alignment = BoxContainer.ALIGNMENT_CENTER
		r.add_child(Kit.icon("moon" if key == "bed" else "sun", 2))
		var name_l := Kit.label(S.t("sched_" + key))
		name_l.custom_minimum_size.x = 64
		r.add_child(name_l)
		var k: String = key
		r.add_child(Kit.button("", func() -> void:
			state[k] = posmod(state[k] - 30, 1440)
			refresh.call(), "minus", 40))
		var val := Kit.label("", Kit.FONT_BIG, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)
		val.custom_minimum_size.x = 96
		labels[key] = val
		r.add_child(val)
		r.add_child(Kit.button("", func() -> void:
			state[k] = posmod(state[k] + 30, 1440)
			refresh.call(), "plus", 40))
		v.add_child(r)
	v.add_child(hours)
	refresh.call()
	var ok := Kit.accent(Kit.button(S.t("sched_ok"), func() -> void:
		if ui.game.set_schedule(state.bed, state.wake):
			ui.close_sheet()
		else:
			ui.toast(S.t("sched_bad"), "cross")), Pal.MINT)
	v.add_child(ok)
	ui.open(S.t("sched_title"), v, true, save.settings.schedule_set, "moon")

# --- Recap / death -------------------------------------------------

static func recap_lines(events: Array) -> Array:
	var counts := {}
	var lines := []
	for e in events:
		counts[e.type] = int(counts.get(e.type, 0)) + 1
		match String(e.type):
			"hatched":
				lines.append(["heart", S.t("recap_hatched")])
			"evolved":
				lines.append(["badge", S.t("recap_evolved", {"form": Cfg.FORMS[e.to].name})])
			"daily_bonus":
				lines.append(["coin", S.t("recap_bonus", {"coins": e.coins})])
			"daycare_out":
				lines.append(["daycare", S.t("recap_daycare")])
	if counts.has("pooped"):
		lines.append(["poop", S.t("recap_pooped", {"n": counts.pooped})])
	if counts.has("call"):
		lines.append(["alert", S.t("recap_call", {"n": counts.call})])
	if counts.has("nap_start"):
		lines.append(["zzz", S.t("recap_nap", {"n": counts.nap_start})])
	var whys := {}
	for e in events:
		if e.type == "mistake":
			whys[e.why] = int(whys.get(e.why, 0)) + 1
	for why in whys:
		lines.append(["cross", S.t("recap_why_" + String(why), {"n": whys[why]})])
	if lines.is_empty():
		lines.append(["check", S.t("recap_nothing")])
	return lines

static func _recap(ui: GameUI) -> void:
	var v := Kit.vbox(8)
	for line in recap_lines(ui.game.recap_events):
		var r := Kit.hbox(10)
		r.add_child(Kit.icon(line[0], 2))
		var l := Kit.para(line[1])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		v.add_child(r)
	ui.game.recap_events = []
	v.add_child(Kit.accent(Kit.button(S.t("recap_ok"), ui.close_sheet), Pal.MINT))
	ui.open(S.t("recap_title"), v, true, true, "book")

static func _death(ui: GameUI) -> void:
	var p: Dictionary = ui.game.save.pet
	var old: bool = p.cause == "old_age"
	var v := Kit.vbox(10)
	var pics := Kit.hbox(12)
	pics.alignment = BoxContainer.ALIGNMENT_CENTER
	pics.add_child(Kit.tex_rect(Items.tex("ghost" if old else "grave"), 4))
	v.add_child(pics)
	v.add_child(Kit.para(S.t("rip_old_age" if old else "rip_neglect", {"name": ui.game.pet_name()})))
	v.add_child(Kit.label("%s · %s" % [Cfg.FORMS[p.form].name, Clock.fmt_age(int(p.age_min))], Kit.FONT, Pal.INK_SOFT))
	if old:
		v.add_child(Kit.row(S.t("rip_legacy", {"coins": Cfg.LEGACY_COINS}), "", "coin"))
	v.add_child(Kit.para(S.t("rip_old_age_sub" if old else "rip_neglect_sub"), Kit.FONT, Pal.INK_SOFT))
	v.add_child(Kit.accent(Kit.button(S.t("rip_continue"), func() -> void:
		ui.close_sheet()
		ui.game.new_generation()
		ui.sfx.play("happy"), "heart"), Pal.ACCENT))
	ui.open(S.t("memorial_title"), v, true, false, "memorial")

static func _memorial(ui: GameUI) -> void:
	var v := Kit.vbox(8)
	var any := false
	var fam: Array = ui.game.save.family
	for i in range(fam.size() - 1, -1, -1):
		var e: Dictionary = fam[i]
		if int(e.died) == 0:
			continue
		any = true
		var r := Kit.hbox(10)
		r.add_child(Kit.tex_rect(Items.tex("grave"), 2))
		var info := Kit.vbox(2)
		info.add_child(Kit.label(e.name if e.name != "" else "Unnamed"))
		info.add_child(Kit.label("%s · %s" % [Cfg.FORMS.get(e.form, Cfg.FORMS.egg).name, Clock.fmt_age(int(e.age_min))], Kit.FONT, Pal.INK_SOFT))
		info.add_child(Kit.label("%s · Gen %d" % [S.t("cause_" + String(e.cause)), int(e.gen)], Kit.FONT, Pal.INK_SOFT))
		r.add_child(info)
		v.add_child(Kit.card(r))
	if not any:
		v.add_child(Kit.para(S.t("memorial_empty"), Kit.FONT, Pal.INK_SOFT))
	ui.open(S.t("memorial_title"), v, false, true, "memorial")

# --- Daycare -------------------------------------------------------

static func _daycare(ui: GameUI) -> void:
	var save: Dictionary = ui.game.save
	var v := Kit.vbox(10)
	var free_left := maxi(0, Cfg.DAYCARE_FREE_MIN - int(save.daycare.used_day))
	if save.daycare.active:
		v.add_child(Kit.para(S.t("daycare_inside", {"name": ui.game.pet_name()})))
		v.add_child(Kit.label("Stay so far: %s" % Clock.fmt_age(int(save.daycare.min)), Kit.FONT, Pal.INK_SOFT))
		v.add_child(Kit.accent(Kit.button(S.t("daycare_pick"), _act_close(ui, "daycare_out"), "heart"), Pal.MINT))
	else:
		v.add_child(Kit.para(S.t("daycare_body", {"free": Clock.fmt_age(free_left), "cost": Cfg.DAYCARE_COINS_PER_HOUR})))
		v.add_child(Kit.para("Stays end after %d hours." % (Cfg.DAYCARE_MAX_MIN / 60), Kit.FONT, Pal.INK_SOFT))
		v.add_child(Kit.accent(Kit.button(S.t("daycare_drop"), _act_close(ui, "daycare_in"), "daycare"), Pal.BUTTER))
	ui.open(S.t("daycare_title"), v, false, true, "daycare")

# --- Settings ------------------------------------------------------

static func _settings(ui: GameUI) -> void:
	var st: Dictionary = ui.game.save.settings
	var v := Kit.vbox(8)
	v.add_child(Kit.toggle(S.t("set_sound"), st.sound, func(on: bool) -> void:
		st.sound = on
		ui.settings_changed()))
	v.add_child(Kit.toggle(S.t("set_music"), st.music, func(on: bool) -> void:
		st.music = on
		ui.settings_changed()))
	v.add_child(Kit.toggle(S.t("set_motion"), st.reduced_motion, func(on: bool) -> void:
		st.reduced_motion = on
		ui.settings_changed()))
	var s: Dictionary = ui.game.save.schedule
	v.add_child(Kit.button("%s  %s – %s" % [S.t("set_bedtime"), Clock.fmt_hm(s.bed), Clock.fmt_hm(s.wake)], func() -> void:
		ui.close_sheet()
		ui.open_screen("schedule"), "moon"))
	if Screens.EXTRA.has("settings_online"):
		v.add_child(Screens.EXTRA.settings_online.call(ui))
	if st.debug_unlocked:
		v.add_child(Kit.button("Debug tools", func() -> void:
			ui.close_sheet()
			ui.open_screen("debug"), "game"))
	var ver := Kit.label("%s %s" % [S.t("set_version"), ProjectSettings.get_setting("application/config/version", "2.0")], Kit.FONT, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	ver.mouse_filter = Control.MOUSE_FILTER_STOP
	ver.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			ui.debug_tap())
	v.add_child(ver)
	ui.open(S.t("set_title"), v, false, true, "settings")

# --- Debug -----------------------------------------------------------

static func _debug(ui: GameUI) -> void:
	var g := ui.game
	var v := Kit.vbox(8)
	var info := Kit.para("", Kit.FONT, Pal.INK_SOFT)
	var refresh := func() -> void:
		var p: Dictionary = g.save.pet
		info.text = "Offset %s · %s %s · mistakes %d · neglect %d min" % [
			Clock.fmt_age(Clock.debug_offset / 60), p.get("form", "-"), Clock.fmt_age(int(p.get("stage_min", 0))),
			int(p.get("mistakes", 0)), int(p.get("neglect_min", 0))]
	v.add_child(info)
	var grid := GridContainer.new()
	grid.columns = 2
	var add := func(label: String, cb: Callable) -> void:
		var b := Kit.button(label, func() -> void:
			cb.call()
			refresh.call())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	add.call("+1 hour", func() -> void: g.time_skip(3600))
	add.call("+6 hours", func() -> void: g.time_skip(6 * 3600))
	add.call("+1 day", func() -> void: g.time_skip(86400))
	add.call("Reset time", func() -> void:
		Clock.debug_offset = 0
		g.save.debug_offset = 0
		g.save.sim_time = Clock.now()
		g.persist())
	add.call("Evolve now", func() -> void:
		var p: Dictionary = g.save.pet
		if p.alive:
			if p.stage == "adult":
				p.stage_min = int(p.lifespan_min) - 1
			else:
				p.stage_min = int(Cfg.STAGE_MIN[p.stage]) - 1
			p.asleep = false
			p.nap_left = 0
			g.time_skip(61))
	add.call("Spawn poop", func() -> void:
		if g.save.pet.alive:
			g.save.pet.poop_due.append(1)
			g.time_skip(61))
	add.call("Fake call", func() -> void:
		var p: Dictionary = g.save.pet
		p.call = {"kind": "fake", "min": 0, "flag": false, "reason": "attention"}
		g.changed.emit())
	add.call("Fill stats", func() -> void:
		var p: Dictionary = g.save.pet
		p.hunger = 100.0
		p.happy = 100.0
		p.energy = 100.0
		g.changed.emit())
	add.call("Drain stats", func() -> void:
		var p: Dictionary = g.save.pet
		p.hunger = 1.0
		p.happy = 1.0
		p.energy = 15.0
		g.changed.emit())
	add.call("+100 coins", func() -> void:
		g.save.coins += 100
		g.persist())
	add.call("Weather", func() -> void:
		var kinds := ["", "clear", "cloudy", "rain", "snow"]
		g.debug_weather = kinds[(kinds.find(g.debug_weather) + 1) % kinds.size()]
		ui.toast("Weather: %s" % (g.debug_weather if g.debug_weather != "" else "real")))
	add.call("Time of day", func() -> void:
		var marks := [-1, 360, 720, 1110, 1200, 1380]
		g.debug_minute = marks[(marks.find(g.debug_minute) + 1) % marks.size()]
		ui.toast("Sky: %s" % ("real" if g.debug_minute < 0 else Clock.fmt_hm(g.debug_minute))))
	add.call("Kill (neglect)", func() -> void:
		var p: Dictionary = g.save.pet
		if p.alive:
			p.neglect_min = float(Cfg.NEGLECT_DEATH_MIN) - 1.0
			p.hunger = 0.0
			g.step())
	if Screens.EXTRA.has("debug_online"):
		v.add_child(grid)
		v.add_child(Screens.EXTRA.debug_online.call(ui))
	else:
		v.add_child(grid)
	var reset := Kit.accent(Kit.button("Reset save (start over)", func() -> void:
		SaveStore.clear()
		Clock.debug_offset = 0
		g.boot(true)
		ui.close_sheet()
		ui.toast("Fresh start!", "heart")), Pal.BAD)
	v.add_child(reset)
	refresh.call()
	ui.open("Debug", v, false, true, "game")
