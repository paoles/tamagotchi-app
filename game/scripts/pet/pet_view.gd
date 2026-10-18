class_name PetView
extends Node2D

# ============================================================
# The pet on screen. Reads the save every frame (never writes),
# picks an expression from its mood, wanders the floor, and
# plays one-shot animations (eat, play, refuse, evolve...) that
# the game triggers. Motion uses whole-pixel offsets only, so
# the art never gets resampled.
# ============================================================

signal anim_finished(name: String)

var game: Node
var world: Node2D
var walk_min := 22.0
var walk_max := 98.0
var ground := 100.0

var _t := 0.0
var _anim := ""
var _anim_t := 0.0
var _anim_len := 0.0
var _food := ""
var _target_x := -1.0
var _next_walk := 2.0
var _facing := 1
var _blink_at := 3.0
var _blinking := 0.0
var _flash := 0.0
var _last_form := ""
var reduced_motion := false

const ANIM_LEN := {
	"eat": 1.8, "play": 1.4, "happy": 0.9, "refuse": 0.9, "sad": 1.2,
	"scolded": 1.2, "evolve": 2.2, "hatch": 1.4, "tap": 0.6, "bed": 0.6,
}

func pet() -> Dictionary:
	return game.save.pet if game != null else {}

func play(anim: String, food: String = "") -> void:
	if anim == "":
		return
	_anim = anim
	_anim_t = 0.0
	_anim_len = ANIM_LEN.get(anim, 1.0)
	_food = food
	if anim == "evolve" or anim == "hatch":
		_flash = _anim_len

func busy() -> bool:
	return _anim != ""

func _process(delta: float) -> void:
	_t += delta
	var p := pet()
	if p.is_empty():
		return
	if position.x <= 0.0:
		position.x = (walk_min + walk_max) / 2.0
	position.y = ground
	if _last_form != String(p.form):
		if _last_form != "" and _anim == "":
			play("evolve" if p.stage != "baby" or _last_form != "egg" else "hatch")
		_last_form = String(p.form)
	if _anim != "":
		_anim_t += delta
		if _anim_t >= _anim_len:
			var done := _anim
			_anim = ""
			_food = ""
			anim_finished.emit(done)
	if _flash > 0.0:
		_flash -= delta
	_update_blink(delta)
	_update_walk(delta, p)
	queue_redraw()

func _update_blink(delta: float) -> void:
	if _blinking > 0.0:
		_blinking -= delta
	elif _t >= _blink_at:
		_blinking = 0.14
		_blink_at = _t + randf_range(2.5, 5.5)

func _can_walk(p: Dictionary) -> bool:
	return p.alive and p.stage != "egg" and not p.asleep and int(p.nap_left) == 0 and _anim == "" \
		and p.call.kind == "" and not game.save.daycare.active

func _update_walk(delta: float, p: Dictionary) -> void:
	if not _can_walk(p):
		_target_x = -1.0
		return
	if _target_x < 0.0:
		_next_walk -= delta
		if _next_walk <= 0.0:
			_target_x = roundf(randf_range(walk_min, walk_max))
			_next_walk = randf_range(2.5, 6.0)
		return
	var dx := _target_x - position.x
	if absf(dx) < 1.0:
		_target_x = -1.0
		return
	_facing = 1 if dx > 0.0 else -1
	position.x += signf(dx) * minf(absf(dx), 14.0 * delta)

func walking() -> bool:
	return _target_x >= 0.0

func expression(p: Dictionary) -> String:
	if not p.alive:
		return "dead"
	match _anim:
		"eat":
			return "eat_a" if fmod(_anim_t, 0.36) < 0.18 else "eat_b"
		"play", "happy", "tap":
			return "happy"
		"refuse":
			return "refuse"
		"sad":
			return "sad"
		"scolded":
			return "scolded"
		"bed":
			return "sleep"
	if p.asleep or int(p.nap_left) > 0:
		return "sleep"
	if p.call.kind == "fake":
		return "call"
	if p.call.kind == "need":
		return "hungry" if p.call.reason == "hunger" else "sad"
	if p.neglect_min > 120.0:
		return "sick"
	if p.hunger < 20.0:
		return "hungry"
	if p.happy < 25.0:
		return "sad"
	if _blinking > 0.0:
		return "blink"
	if p.happy > 85.0 and fmod(_t, 9.0) < 1.6:
		return "love"
	return "idle"

func _offset(p: Dictionary) -> Vector2:
	if reduced_motion:
		return Vector2.ZERO
	var off := Vector2.ZERO
	match _anim:
		"play":
			off.y = -roundf(absf(sin(_anim_t * TAU * 1.4)) * 7.0)
		"happy", "tap":
			off.y = -roundf(absf(sin(_anim_t * TAU * 1.6)) * 4.0)
		"refuse":
			off.x = (1.0 if fmod(_anim_t, 0.2) < 0.1 else -1.0)
		"evolve", "hatch":
			off.x = (1.0 if fmod(_anim_t, 0.12) < 0.06 else -1.0) if _anim_t < _anim_len * 0.6 else 0.0
		"scolded":
			off.y = 1.0
	if _anim == "":
		if p.stage == "egg":
			var shake := Evolution.stage_progress(p) > 0.75
			var period := 1.4 if shake else 3.2
			if fmod(_t, period) < 0.3:
				off.x = 1.0 if fmod(_t, 0.12) < 0.06 else -1.0
		elif walking():
			off.y = -1.0 if fmod(_t, 0.3) < 0.15 else 0.0
		elif p.asleep or int(p.nap_left) > 0:
			off.y = 1.0 if fmod(_t, 3.0) < 1.5 else 0.0
		else:
			off.y = -1.0 if fmod(_t, 1.6) < 0.8 else 0.0
	return off

func _draw() -> void:
	var p := pet()
	if p.is_empty() or game.save.daycare.active:
		return
	var form: String = p.form
	var expr := expression(p)
	if p.stage == "egg":
		expr = "crack" if Evolution.stage_progress(p) > 0.75 else "idle"
	var tex := Forms.sprite(form, expr)
	var off := _offset(p)
	# Soft shadow on the floor.
	var sw := 18.0 if p.stage in ["baby", "egg"] else 24.0
	draw_rect(Rect2(-sw / 2.0 + 1, -1, sw - 2, 2), Color(0.35, 0.25, 0.3, 0.18))
	draw_rect(Rect2(-sw / 2.0 + 3, 0, sw - 6, 1), Color(0.35, 0.25, 0.3, 0.12))
	var flip: bool = _facing < 0 and p.stage != "egg"
	var origin := Vector2(-16, -32) + off
	if flip:
		draw_set_transform(Vector2(off.x, off.y), 0.0, Vector2(-1, 1))
		draw_texture(tex, Vector2(-16, -32))
		_draw_outfit(p, form, Vector2(-16, -32))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture(tex, origin)
		_draw_outfit(p, form, origin)
	if _flash > 0.0 and fmod(_flash, 0.24) < 0.12:
		draw_texture(Forms.silhouette(form), origin, Color(1, 1, 1, 0.9))
	if _food != "" and (_anim == "eat" or _anim == "play"):
		var bite := clampf(_anim_t / _anim_len, 0.0, 1.0)
		if bite < 0.85:
			var ft := Items.tex(_food)
			var fx := 10.0 if _facing > 0 else -10.0 - ft.get_width()
			draw_texture(ft, Vector2(fx + (6 if _facing > 0 else 0), -ft.get_height() - 1))

func _draw_outfit(p: Dictionary, form: String, origin: Vector2) -> void:
	if p.stage != "egg":
		Outfits.draw(self, game.save, form, origin)

func contains_point(local_room: Vector2) -> bool:
	var p := pet()
	if p.is_empty():
		return false
	var r := Rect2(position.x - 13, position.y - 28, 26, 30)
	return r.has_point(local_room)
