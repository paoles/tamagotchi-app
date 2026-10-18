extends Node

# ============================================================
# Screenshots of every screen, for eyeballing layout without
# playing:   godot --path game -- snap [out_dir]
# Needs a real window (rendering). Puts the game into each state
# by editing the in-memory save (saving is disabled in this mode),
# waits for animations to settle, then captures the viewport.
# ============================================================

var main: Node
var out_dir := ""
var _n := 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_size(Vector2i(390, 844))
	await _wait(0.6)
	await _run()
	print("snaps written to ", out_dir)
	get_tree().quit(0)

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func shot(name: String) -> void:
	await _wait(0.5)
	var img := get_viewport().get_texture().get_image()
	_n += 1
	img.save_png(out_dir.path_join("%02d_%s.png" % [_n, name]))

func reset_ui() -> void:
	var ui: GameUI = main.ui
	ui._queue = []
	ui.close_sheet()
	for c in ui.toasts.get_children():
		c.queue_free()

func pet() -> Dictionary:
	return main.game.save.pet

func set_form(form: String) -> void:
	var p := pet()
	p.form = form
	p.stage = Cfg.FORMS[form].stage
	p.alive = true
	p.asleep = false
	p.nap_left = 0
	p.lights = true
	p.hunger = 80.0
	p.happy = 80.0
	p.energy = 80.0
	p.weight = Cfg.WEIGHT_BASE[p.stage]
	p.call = SaveState.no_call()
	if p.stage == "adult":
		p.lifespan_min = Cfg.ADULT_BASE_MIN
	if p.name == "":
		p.name = "Mochi"

func _run() -> void:
	var g: Game = main.game
	var ui: GameUI = main.ui
	g.debug_minute = 720
	g.debug_weather = "clear"
	await shot("egg")
	pet().stage_min = Cfg.STAGE_MIN.egg - 1
	g.time_skip(61)
	await _wait(1.6)
	await shot("hatch_name_dialog")
	if ui.has_sheet():
		ui._sheet.close()
	await _wait(0.3)
	await shot("schedule_dialog")
	reset_ui()
	pet().name = "Mochi"
	g.save.settings.schedule_set = true
	pet().poops = [{"age": 10, "x": 0.2, "flag": false}, {"age": 30, "x": 0.8, "flag": false}]
	await shot("baby_day_poop")
	ui.open_screen("feed")
	await shot("feed_sheet")
	reset_ui()
	ui.open_screen("status")
	await shot("status_sheet")
	reset_ui()
	ui.open_screen("more")
	await shot("more_sheet")
	reset_ui()
	pet().poops = []
	for form in ["puffle", "smudge", "bloom", "zippy", "pudding", "grumble"]:
		set_form(form)
		await shot("form_" + form)
	for pair in [["lumina", 1140, "cloudy"], ["comet", 1380, "clear"], ["rascal", 400, "rain"], ["dumpling", 720, "snow"]]:
		set_form(pair[0])
		g.debug_minute = pair[1]
		g.debug_weather = pair[2]
		await shot("adult_%s_%s" % [pair[0], pair[2]])
	g.debug_minute = 1380
	g.debug_weather = "clear"
	set_form("sprout")
	pet().asleep = true
	pet().lights = false
	await _wait(1.2)
	await shot("night_lights_off")
	set_form("grumpus")
	pet().call = {"kind": "fake", "min": 0, "flag": false, "reason": "attention"}
	g.debug_minute = 720
	await shot("fake_call")
	pet().call = SaveState.no_call()
	ui.open_screen("settings")
	await shot("settings")
	reset_ui()
	ui.open_screen("daycare")
	await shot("daycare")
	reset_ui()
	g.recap_events = [
		{"t": 0, "type": "pooped"}, {"t": 0, "type": "pooped"}, {"t": 0, "type": "call", "kind": "need"},
		{"t": 0, "type": "evolved", "from": "mochi", "to": "puffle"}, {"t": 0, "type": "daily_bonus", "coins": 10},
	]
	ui.open_screen("recap")
	await shot("recap")
	reset_ui()
	g.save.settings.debug_unlocked = true
	ui.open_screen("debug")
	await shot("debug")
	reset_ui()
	set_form("starlight")
	var p := pet()
	g.save.family[0].name = "Mochi"
	Sim.die(g.save, p, int(g.save.sim_time), "old_age", [])
	ui.open_screen("death")
	await shot("death_old_age")
	reset_ui()
	ui.open_screen("memorial")
	await shot("memorial")
	reset_ui()
	for name in Screens.EXTRA.keys():
		if name.begins_with("snap_"):
			await Screens.EXTRA[name].call(self)
