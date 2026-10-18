class_name Game
extends Node

# ============================================================
# Owns the save and the clock. Every second it catches the sim
# up to real time and broadcasts what happened; player actions
# go through `act()`, which catches up first so an action always
# lands on the present. The UI listens to the signals and never
# edits the save itself.
# ============================================================

signal changed
signal event(e: Dictionary)
signal acted(action: String, res: Dictionary)
signal caught_up(events: Array)   # a long gap was simulated in one go

const RECAP_GAP := 15 * 60

var save: Dictionary = {}
var recap_events: Array = []
var debug_minute := -1        # debug override for the sky
var debug_weather := ""
var _tick := 0.0
var _autosave := 0.0

func boot(fresh: bool = false) -> void:
	var loaded := {} if fresh else SaveStore.read()
	var now := Clock.now()
	if loaded.is_empty():
		save = SaveState.new_save(now)
		save.day_key = Clock.day_key(now, Clock.tz_bias())
		Evolution.new_egg(save, now)
	else:
		save = loaded
	Clock.debug_offset = int(save.get("debug_offset", 0))
	var gap := Clock.now() - int(save.sim_time)
	var events := Sim.advance(save, Clock.now())
	recap_events = events if gap > 15 * 60 else []
	persist()

func _process(delta: float) -> void:
	_tick += delta
	_autosave += delta
	if _tick >= 1.0:
		_tick = 0.0
		step()
	if _autosave >= 30.0:
		persist()

func step() -> void:
	# Browsers pause hidden tabs, so a long gap can show up here too:
	# summarize it instead of replaying every event.
	if Clock.now() - int(save.sim_time) > RECAP_GAP:
		_catch_up()
		return
	var events := Sim.advance(save, Clock.now())
	events.append_array(_badges())
	for e in events:
		event.emit(e)
	if not events.is_empty():
		persist()
	changed.emit()

func persist() -> void:
	_autosave = 0.0
	SaveStore.write(save)

func act(action: String) -> Dictionary:
	step()
	var res := {}
	match action:
		"meal":
			res = Care.feed_meal(save)
		"snack":
			res = Care.feed_snack(save)
		"play":
			res = Care.play(save)
		"clean":
			res = Care.clean(save)
		"lights":
			res = Care.toggle_lights(save)
		"scold":
			res = Care.scold(save)
		"tap":
			res = Care.tap(save)
		"daycare_in":
			res = Care.start_daycare(save)
		"daycare_out":
			res = Care.end_daycare(save)
		_:
			res = {"ok": false, "why": "unknown", "anim": "", "events": []}
	for e in res.events:
		event.emit(e)
	acted.emit(action, res)
	for e in _badges():
		event.emit(e)
	persist()
	changed.emit()
	return res

func _badges() -> Array:
	var out := []
	for a in Achievements.check(save):
		out.append({"t": int(save.sim_time), "type": "badge", "id": a.id, "name": a.name, "coins": a.coins})
	return out

# Shop, games and decor report through here so saving and the
# change signal stay in one place.
func apply(res: Dictionary, action: String) -> Dictionary:
	for e in res.get("events", []):
		event.emit(e)
	acted.emit(action, res)
	for e in _badges():
		event.emit(e)
	persist()
	changed.emit()
	return res

func new_generation() -> void:
	Evolution.new_egg(save, int(save.sim_time))
	persist()
	changed.emit()

func set_pet_name(name: String) -> String:
	var n := Care.set_pet_name(save, name)
	persist()
	changed.emit()
	return n

func set_schedule(bed: int, wake: int) -> bool:
	var ok := Care.set_schedule(save, bed, wake)
	if ok:
		persist()
		changed.emit()
	return ok

func time_skip(seconds: int) -> void:
	Clock.debug_offset += seconds
	save.debug_offset = Clock.debug_offset
	step()

func pet_name() -> String:
	var p: Dictionary = save.pet
	if p.is_empty():
		return "Your pet"
	if p.name != "":
		return p.name
	return Cfg.FORMS[p.form].name

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if not save.is_empty():
			persist()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		if not save.is_empty() and Clock.now() - int(save.sim_time) > RECAP_GAP:
			_catch_up()

func _catch_up() -> void:
	var events := Sim.advance(save, Clock.now())
	events.append_array(_badges())
	recap_events = events
	persist()
	caught_up.emit(events)
	changed.emit()
