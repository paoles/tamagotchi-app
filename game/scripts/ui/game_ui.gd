class_name GameUI
extends Control

# ============================================================
# The screen: a portrait column (centred with pastel margins on
# wide screens) holding the room, the HUD, the action bar, toasts
# and any open sheet. Turns game events into sounds, toasts and
# pet animations, and routes buttons to the game.
# ============================================================

const COLUMN_ASPECT := 0.62   # widest column = height × this

var game: Game
var sfx: Sfx
var music: Node
var world: World
var hud: Hud
var bar: ActionBar
var column: Control
var world_view: Control
var overlay: Control
var toasts: VBoxContainer
var _sheet: Sheet = null
var _queue: Array = []        # dialogs waiting for the current one to close
var _debug_taps := 0

func _ready() -> void:
	theme = Kit.theme()
	column = Control.new()
	column.clip_contents = true
	add_child(column)

	world_view = Control.new()
	world_view.clip_contents = true
	world_view.mouse_filter = Control.MOUSE_FILTER_STOP
	world_view.gui_input.connect(_on_world_input)
	column.add_child(world_view)
	world = World.new()
	world.game = game
	world_view.add_child(world)
	world.pet_view.anim_finished.connect(_on_anim_finished)

	hud = Hud.new()
	hud.game = game
	hud.tapped.connect(func() -> void: open_screen("status"))
	column.add_child(hud)

	bar = ActionBar.new()
	bar.game = game
	bar.action.connect(_on_action)
	column.add_child(bar)

	toasts = Kit.vbox(6)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(toasts)

	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(overlay)

	game.event.connect(_on_event)
	game.acted.connect(_on_acted)
	game.caught_up.connect(_on_caught_up)
	get_viewport().size_changed.connect(_layout)
	_apply_settings()
	_layout()
	call_deferred("_startup_dialogs")

func _layout() -> void:
	var vs := get_viewport_rect().size
	size = vs
	var w := minf(vs.x, floorf(vs.y * COLUMN_ASPECT))
	column.position = Vector2(floorf((vs.x - w) / 2.0), 0)
	column.size = Vector2(w, vs.y)
	world_view.position = Vector2.ZERO
	world_view.size = column.size
	hud.position = Vector2(0, 0)
	hud.size = Vector2(w, Hud.HEIGHT)
	bar.size = Vector2(w, ActionBar.HEIGHT)
	bar.position = Vector2(0, vs.y - ActionBar.HEIGHT)
	toasts.position = Vector2(20, Hud.HEIGHT + 8)
	toasts.size = Vector2(w - 40, 10)
	overlay.position = Vector2.ZERO
	overlay.size = column.size
	if has_sheet():
		_sheet.resize_to(overlay.size)
	world.set_view(column.size, Hud.HEIGHT, ActionBar.HEIGHT)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("f3e4ef"))
	if column.position.x > 0.0:
		var c := Color("ead6e6")
		var step := 24.0
		var y := 0.0
		while y < size.y:
			var x := fmod(y * 0.5, step)
			while x < size.x:
				if x < column.position.x - 4 or x > column.position.x + column.size.x + 4:
					draw_rect(Rect2(x, y, 6, 6), c)
				x += step
			y += step
		draw_rect(Rect2(column.position.x - 3, 0, 3, size.y), Pal.INK)
		draw_rect(Rect2(column.position.x + column.size.x, 0, 3, size.y), Pal.INK)

func _apply_settings() -> void:
	var st: Dictionary = game.save.settings
	sfx.enabled = st.sound
	world.pet_view.reduced_motion = st.reduced_motion
	if music != null:
		music.set_enabled(st.music)

# --- Input -------------------------------------------------------

func _on_world_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var room_pos: Vector2 = e.position / World.SCALE
	match world.hit(room_pos):
		"pet":
			var p: Dictionary = game.save.pet
			if not p.is_empty() and p.stage == "egg":
				sfx.play("tap")
				world.burst("spark", 3, 8, 10)
			else:
				game.act("tap")
		"poop":
			game.act("clean")

func _on_action(id: String) -> void:
	sfx.play("blip")
	match id:
		"feed":
			open_screen("feed")
		"play":
			open_screen("play")
		"clean":
			game.act("clean")
		"lights":
			game.act("lights")
		"scold":
			game.act("scold")
		"more":
			open_screen("more")

# --- Sheets -------------------------------------------------------

func open(title: String, content: Control, centered := false, dismissible := true, icon := "") -> Sheet:
	close_sheet()
	var s := Sheet.new()
	s.reduced_motion = game.save.settings.reduced_motion
	s.setup(title, content, centered, dismissible, icon)
	s.size = overlay.size
	overlay.add_child(s)
	s.resize_to(overlay.size)
	_sheet = s
	s.closed.connect(func() -> void:
		if _sheet == s:
			_sheet = null
		call_deferred("_next_dialog"))
	return s

func close_sheet() -> void:
	if _sheet != null and is_instance_valid(_sheet):
		var s := _sheet
		_sheet = null
		s.queue_free()
		# A queued dialog (e.g. bedtime after naming) opens next.
		call_deferred("_next_dialog")

func has_sheet() -> bool:
	return _sheet != null and is_instance_valid(_sheet)

func open_screen(name: String) -> void:
	Screens.open(self, name)

# Dialogs that must not interrupt each other wait in line.
func queue_dialog(name: String) -> void:
	if not _queue.has(name):
		_queue.append(name)
	if not has_sheet():
		_next_dialog()

func _next_dialog() -> void:
	if has_sheet() or _queue.is_empty():
		return
	var name: String = _queue.pop_front()
	Screens.open(self, name)

func _startup_dialogs() -> void:
	var p: Dictionary = game.save.pet
	if not game.recap_events.is_empty():
		queue_dialog("recap")
	if not p.is_empty() and not p.alive:
		queue_dialog("death")
	elif not p.is_empty() and p.stage != "egg" and p.name == "":
		queue_dialog("name")
	elif not game.save.settings.schedule_set and not p.is_empty() and p.stage != "egg":
		queue_dialog("schedule")

# --- Feedback -----------------------------------------------------

func toast(text: String, icon: String = "") -> void:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", Kit.box(Color(1, 0.98, 0.96, 0.96), Pal.INK, 2, 10, 3, 8))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := Kit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon != "":
		row.add_child(Kit.icon(icon, 2))
	var l := Kit.label(text)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	pill.add_child(row)
	toasts.add_child(pill)
	while toasts.get_child_count() > 3:
		toasts.get_child(0).queue_free()
		toasts.remove_child(toasts.get_child(0))
	var tw := create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(pill, "modulate:a", 0.0, 0.4)
	tw.tween_callback(pill.queue_free)

func _say(key: String, args: Dictionary = {}, icon: String = "") -> void:
	var a := {"name": game.pet_name()}
	a.merge(args, true)
	toast(S.t(key, a), icon)

func _on_event(e: Dictionary) -> void:
	match String(e.type):
		"hatched":
			sfx.play("hatch")
			world.burst("spark", 6, 14, 16)
			_say("t_hatched", {}, "heart")
			queue_dialog("name")
			if not game.save.settings.schedule_set:
				queue_dialog("schedule")
		"evolved":
			sfx.play("evolve")
			world.burst("spark", 8, 16, 18)
			_say("t_evolved", {"form": Cfg.FORMS[e.to].name}, "badge")
		"pooped":
			sfx.play("poop")
		"call":
			sfx.play("call")
		"mistake":
			sfx.play("mistake")
			_say("t_mistake", {}, "alert")
		"daily_bonus":
			sfx.play("coin")
			_say("t_daily_bonus", {"coins": e.coins}, "coin")
		"died":
			sfx.play("death")
			queue_dialog("death")
		"nap_start":
			sfx.play("nap")
		"daycare_out":
			_say("p_daycare", {}, "daycare")
		"spoiled":
			_say("t_spoiled", {}, "angry")
		"badge":
			sfx.play("win")
			toast("Badge: %s  +%d" % [e.name, int(e.coins)], "badge")

func _on_caught_up(events: Array) -> void:
	if events.is_empty():
		return
	var types := []
	for e in events:
		types.append(e.type)
	queue_dialog("recap")
	if "died" in types:
		sfx.play("death")
		queue_dialog("death")
	elif "hatched" in types and game.save.pet.name == "":
		queue_dialog("name")
		if not game.save.settings.schedule_set:
			queue_dialog("schedule")

func _on_acted(action: String, res: Dictionary) -> void:
	var pv := world.pet_view
	if not res.ok:
		world.say({"full": "cross", "stubborn": "angry", "tired": "zzz", "unfair": "tear", "not_sleepy": "cross"}.get(res.why, "question"))
		var key := "t_" + String(res.why)
		if String(res.get("toast", "")) != "":
			toast(res.toast, res.get("icon", ""))
			sfx.play("refuse")
			return
		if S.T.has(key):
			_say(key, {}, "cross" if res.why != "asleep" else "zzz")
		if res.anim in ["refuse", "sad"]:
			pv.play(res.anim)
			sfx.play("refuse")
		elif res.why == "unfair":
			pv.play("sad")
			sfx.play("refuse")
		return
	match action:
		"meal", "snack":
			sfx.play("eat")
			pv.play("eat", action)
		"food":
			sfx.play("eat")
			pv.play("eat", res.get("food", "snack"))
		"toy":
			sfx.play("happy")
			pv.play("play", res.get("toy", ""))
			world.burst("mini_heart", 5)
		"buy":
			sfx.play("buy")
		"game":
			sfx.play("coin")
			pv.play("happy")
			world.burst("mini_heart", 6)
		"play":
			sfx.play("happy")
			pv.play("play")
			world.burst("mini_heart", 5)
		"clean":
			sfx.play("clean")
			for i in 6:
				world.fx.add("bubble", Vector2(randf_range(world.lay.walk_min, world.lay.walk_max), world.lay.ground - randf_range(0, 6)), Vector2(randf_range(-4, 4), -randf_range(10, 20)), 1.2, 0.0)
		"lights":
			sfx.play("lights")
		"scold":
			sfx.play("scold")
			pv.play("scolded")
			world.say("sweat")
			_say("t_disciplined", {}, "discipline")
		"tap":
			sfx.play("tap")
			if res.why == "loved":
				pv.play("tap")
				world.burst("mini_heart", 3, 8, 12)
				world.say("heart", 1.4)
			else:
				pv.play("happy")
	if res.has("toast"):
		toast(res.toast, res.get("icon", ""))

var minigame_active := false

func _process(_delta: float) -> void:
	if music == null:
		return
	var p: Dictionary = game.save.pet
	var song := "day"
	if minigame_active:
		song = "game"
	elif not p.is_empty() and p.alive and (p.asleep or not p.lights):
		song = "night"
	elif SkyCycle.star_alpha(world.minute_now()) > 0.6:
		song = "night"
	music.want(song)

# --- Mini-games -------------------------------------------------------

const GAMES := {
	"left_right": "res://scripts/minigames/left_right.gd",
	"catch_food": "res://scripts/minigames/catch_food.gd",
	"jump_runner": "res://scripts/minigames/jump_runner.gd",
}

func open_minigame(kind: String) -> void:
	var gate := Care._awake_gate(game.save)
	if gate != "":
		_say("t_" + gate, {}, "cross")
		return
	if game.save.pet.energy < MiniGame.ENERGY:
		_say("t_tired", {}, "zzz")
		return
	close_sheet()
	var mg: MiniGame = load(GAMES[kind]).new()
	mg.game = game
	mg.sfx = sfx
	mg.position = Vector2.ZERO
	mg.size = column.size
	column.add_child(mg)
	minigame_active = true
	mg.finished.connect(func(r: Dictionary) -> void:
		minigame_active = false
		if r.is_empty():
			return
		game.step()
		var res := Care.game_reward(game.save, int(r.coins), float(r.happy), MiniGame.ENERGY, MiniGame.WEIGHT)
		res["toast"] = "+%d coins" % int(r.coins)
		res["icon"] = "coin"
		game.apply(res, "game"))

func _on_anim_finished(name: String) -> void:
	if name == "eat":
		world.burst("crumb", 3, 6, 6)

# Settings changes come back through here so sound/motion update live.
func settings_changed() -> void:
	_apply_settings()
	game.persist()

func debug_tap() -> void:
	_debug_taps += 1
	if _debug_taps >= 7 and not game.save.settings.debug_unlocked:
		game.save.settings.debug_unlocked = true
		game.persist()
		toast("Debug tools unlocked", "settings")
