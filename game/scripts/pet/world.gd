class_name World
extends Node2D

# ============================================================
# The room scene, drawn in room pixels and scaled by SCALE. The
# room and poops draw here; the pet, particles and the lights-off
# overlay are children so they stack on top in that order.
# ============================================================

const SCALE := 3

var game: Node
var pet_view: PetView
var fx: FX
var night: Night
var bubble: Bubble
var lay: Dictionary = {}
var anim_t := 0.0
var _size := Vector2(120, 213)
var _top := 20.0
var _bottom := 30.0
var _zzz_t := 0.0
var _stink_t := 0.0
var _chat_t := 6.0

func _ready() -> void:
	scale = Vector2(SCALE, SCALE)
	pet_view = PetView.new()
	pet_view.game = game
	pet_view.world = self
	add_child(pet_view)
	night = Night.new()
	night.world = self
	add_child(night)
	fx = FX.new()
	add_child(fx)
	bubble = Bubble.new()
	bubble.world = self
	add_child(bubble)
	_relayout()

# `units` is the visible area in UI units; top/bottom are the UI
# units covered by the HUD and the action bar.
func set_view(units: Vector2, top_units: float, bottom_units: float) -> void:
	_size = Vector2(ceilf(units.x / SCALE), ceilf(units.y / SCALE))
	_top = ceilf(top_units / SCALE)
	_bottom = ceilf(bottom_units / SCALE)
	_relayout()

func _relayout() -> void:
	lay = Room.layout(_size, _top, _bottom)
	if pet_view:
		pet_view.walk_min = lay.walk_min
		pet_view.walk_max = lay.walk_max
		pet_view.ground = lay.ground
	queue_redraw()

func minute_now() -> int:
	var dbg: int = game.debug_minute if game != null else -1
	if dbg >= 0:
		return dbg
	return Clock.local_minute(Clock.now(), Clock.tz_bias())

func weather_now() -> String:
	if game != null and game.debug_weather != "":
		return game.debug_weather
	return SkyCycle.weather(Clock.now(), Clock.tz_bias())

func _process(delta: float) -> void:
	anim_t += delta
	var p: Dictionary = game.save.pet if game != null else {}
	if not p.is_empty() and p.alive and p.stage != "egg" and not game.save.daycare.active:
		if p.asleep or int(p.nap_left) > 0:
			_zzz_t -= delta
			if _zzz_t <= 0.0:
				_zzz_t = 1.4
				fx.add("zzz", pet_view.position + Vector2(6 * pet_view._facing, -26), Vector2(4, -8), 2.2, 0.0)
		if not p.poops.is_empty():
			_stink_t -= delta
			if _stink_t <= 0.0:
				_stink_t = 1.1
				var poop: Dictionary = p.poops[randi() % p.poops.size()]
				fx.add("stink", poop_pos(poop) + Vector2(randf_range(-2, 2), -10), Vector2(0, -5), 1.4, 0.0)
	_update_bubble(delta, p)
	queue_redraw()

# --- Speech bubbles ------------------------------------------------

func say(icon: String, sec: float = 2.2) -> void:
	bubble.show_icon(icon, sec)

func _update_bubble(delta: float, p: Dictionary) -> void:
	if p.is_empty() or not p.alive or p.stage == "egg" or game.save.daycare.active:
		bubble.persist("")
		bubble.hide_now()
		return
	if p.call.kind != "":
		var icon := "alert"
		if p.call.kind == "need":
			icon = "hunger" if p.call.reason == "hunger" else "tear"
		bubble.persist(icon)
		return
	bubble.persist("")
	if p.asleep or int(p.nap_left) > 0 or pet_view.busy():
		return
	_chat_t -= delta
	if _chat_t > 0.0:
		return
	_chat_t = randf_range(9.0, 18.0)
	var icon := _chatter(p)
	if icon != "":
		say(icon)
		if icon in ["heart", "note"] and randf() < 0.5:
			pet_view.play("happy")

func _chatter(p: Dictionary) -> String:
	if p.hunger < 30.0:
		return "hunger"
	if not p.poops.is_empty():
		return "poop"
	if p.energy < 25.0:
		return "zzz"
	if p.happy < 35.0:
		return "tear"
	if Sim.is_overweight(p) and randf() < 0.3:
		return "weight"
	if weather_now() in ["rain", "snow"] and randf() < 0.3:
		return "cloud"
	if p.happy > 65.0:
		return ["heart", "note", "spark", "sun"][randi() % 4]
	return ""

func poop_pos(poop: Dictionary) -> Vector2:
	var x := lerpf(lay.walk_min - 8.0, lay.walk_max + 8.0, float(poop.x))
	return Vector2(roundf(x), lay.ground + 1)

func _draw() -> void:
	if lay.is_empty() or game == null:
		return
	Room.draw_room(self, lay, game.save.room, minute_now(), weather_now(), anim_t)
	Decor.draw(self, game.save, lay, anim_t)
	var p: Dictionary = game.save.pet
	if p.is_empty() or game.save.daycare.active:
		return
	var tex := Items.tex("poop")
	for poop in p.poops:
		var pos := poop_pos(poop)
		draw_texture(tex, Vector2(pos.x - 6, pos.y - 11))

# What's under a tap, in room pixels.
func hit(room_pos: Vector2) -> String:
	if pet_view.contains_point(room_pos):
		return "pet"
	var p: Dictionary = game.save.pet
	if not p.is_empty():
		for poop in p.poops:
			if Rect2(poop_pos(poop) - Vector2(7, 12), Vector2(14, 14)).has_point(room_pos):
				return "poop"
	return ""

func burst(icon: String, count: int, spread: float = 10.0, up: float = 14.0) -> void:
	var base := pet_view.position + Vector2(0, -20)
	for i in count:
		var v := Vector2(randf_range(-spread, spread), -randf_range(up * 0.6, up))
		fx.add(icon, base + Vector2(randf_range(-6, 6), randf_range(-4, 4)), v, randf_range(0.8, 1.3), 6.0)

# --- Particles ---------------------------------------------------

class FX:
	extends Node2D
	var parts: Array = []

	func add(icon: String, pos: Vector2, vel: Vector2, life: float, gravity: float) -> void:
		if parts.size() > 60:
			parts.pop_front()
		parts.append({"icon": icon, "pos": pos, "vel": vel, "life": life, "max": life, "g": gravity})

	func _process(delta: float) -> void:
		for i in range(parts.size() - 1, -1, -1):
			var p: Dictionary = parts[i]
			p.life -= delta
			if p.life <= 0.0:
				parts.remove_at(i)
				continue
			p.vel.y += p.g * delta
			p.pos += p.vel * delta
		queue_redraw()

	func _draw() -> void:
		for p in parts:
			var tex := Icons.tex(p.icon)
			var a := clampf(p.life / (p.max * 0.4), 0.0, 1.0)
			var pos: Vector2 = p.pos
			draw_texture(tex, Vector2(roundf(pos.x - tex.get_width() / 2.0), roundf(pos.y - tex.get_height() / 2.0)), Color(1, 1, 1, a))

# --- Speech bubble -------------------------------------------------

class Bubble:
	extends Node2D
	var world: Node2D
	var _icon := ""
	var _left := 0.0
	var _sticky := ""
	var _t := 0.0

	func show_icon(icon: String, sec: float) -> void:
		_icon = icon
		_left = sec

	func persist(icon: String) -> void:
		_sticky = icon

	func hide_now() -> void:
		_left = 0.0

	func _process(delta: float) -> void:
		_t += delta
		_left = maxf(0.0, _left - delta)
		queue_redraw()

	func _draw() -> void:
		var icon := _icon if _left > 0.0 else _sticky
		if icon == "":
			return
		if _sticky != "" and _left <= 0.0 and fmod(_t, 1.0) > 0.7:
			return
		var pv: Node2D = world.pet_view
		var tex := Icons.tex(icon)
		var inner := tex.get_size() + Vector2(6, 6)
		var size := Vector2(maxf(15, inner.x), maxf(15, inner.y))
		var side: float = 1.0 if pv.position.x < world.lay.w - 30 else -1.0
		var head_y := 14.0
		var pet: Dictionary = world.game.save.pet
		if not pet.is_empty():
			head_y = Forms.anchor(pet.form, "head").y
		var base := pv.position + Vector2(side * 9.0, -32.0 + head_y - 3.0)
		var r := Rect2((base - Vector2(size.x / 2.0, size.y)).round(), size)
		var ink := Pal.INK
		draw_rect(r.grow(1), ink)
		draw_rect(r, Color.WHITE)
		# rounded corners
		for c in [r.position, Vector2(r.end.x - 1, r.position.y), Vector2(r.position.x, r.end.y - 1), r.end - Vector2.ONE]:
			draw_rect(Rect2(c, Vector2.ONE), ink)
		# tail
		var tx := r.position.x + (3.0 if side > 0 else r.size.x - 6.0)
		draw_rect(Rect2(tx, r.end.y, 3, 1), Color.WHITE)
		draw_rect(Rect2(tx - 1, r.end.y, 1, 2), ink)
		draw_rect(Rect2(tx + 3, r.end.y, 1, 1), ink)
		draw_rect(Rect2(tx, r.end.y + 1, 1, 1), Color.WHITE)
		draw_rect(Rect2(tx + 1, r.end.y + 1, 2, 1), ink)
		draw_rect(Rect2(tx, r.end.y + 2, 1, 1), ink)
		draw_texture(tex, (r.position + (size - tex.get_size()) / 2.0).round())

# --- Lights-off overlay ------------------------------------------

class Night:
	extends Node2D
	var world: Node2D
	var _alpha := 0.0

	func _process(delta: float) -> void:
		var target := 0.0
		var g: Node = world.game
		if g != null and not g.save.pet.is_empty() and not g.save.pet.lights and not g.save.daycare.active:
			target = 0.62
		_alpha = move_toward(_alpha, target, delta * 1.5)
		queue_redraw()

	func _draw() -> void:
		if _alpha <= 0.01 or world.lay.is_empty():
			return
		draw_rect(Rect2(0, 0, world.lay.w, world.lay.h), Color(0.1, 0.08, 0.22, _alpha))
		# The window still glows a little.
		var r: Rect2 = world.lay.window
		draw_rect(r, Color(0.4, 0.4, 0.7, _alpha * 0.25))
