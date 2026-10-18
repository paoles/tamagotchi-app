class_name Hud
extends Control

# ============================================================
# The always-visible strip at the top: name, coins, and four
# mini meters (hunger, happy, energy, discipline). Each meter is
# an icon plus five segments, so the level reads from the count
# as well as the colour. Tapping it opens the status card.
# ============================================================

signal tapped

const HEIGHT := 72.0
const METERS := [["hunger", "hunger"], ["happy", "heart"], ["energy", "energy"], ["discipline", "discipline"]]

var game: Node
var _name: Label
var _coins: Label
var _sub: Label
var _t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_name = Kit.label("", Kit.FONT)
	_name.position = Vector2(16, 9)
	add_child(_name)
	_sub = Kit.label("", Kit.FONT, Pal.INK_SOFT)
	_sub.position = Vector2(16, 40)
	add_child(_sub)
	_coins = Kit.label("", Kit.FONT, Pal.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	add_child(_coins)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit()
		accept_event()

func _process(delta: float) -> void:
	_t += delta
	if game == null:
		return
	var save: Dictionary = game.save
	var p: Dictionary = save.pet
	_coins.text = str(int(save.coins))
	_coins.size = Vector2(120, 22)
	_coins.position = Vector2(size.x - 16 - 26 - 120, 9)
	var title := S.t("title")
	if not p.is_empty():
		if p.stage == "egg":
			title = S.t("stage_egg")
		else:
			title = p.name if p.name != "" else Cfg.FORMS[p.form].name
	_name.text = title
	_sub.visible = false
	if p.is_empty():
		pass
	elif save.daycare.active:
		_sub.visible = true
		_sub.text = S.t("more_daycare")
	elif p.stage == "egg":
		_sub.visible = true
		_sub.text = "Hatching in %s" % Clock.fmt_age(maxi(1, Evolution.minutes_to_next_stage(p)))
	elif not p.alive:
		_sub.visible = true
		_sub.text = S.t("cause_" + String(p.cause))
	queue_redraw()

func _draw() -> void:
	draw_style_box(Kit.box(Color(1, 0.98, 0.96, 0.94), Pal.INK, 2, 12, 4), Rect2(6, 4, size.x - 12, HEIGHT - 6))
	draw_texture(Icons.tex("coin", 2), Vector2(size.x - 16 - 20, 10))
	if game == null:
		return
	var p: Dictionary = game.save.pet
	if not p.is_empty() and p.alive and p.call.kind != "" and fmod(_t, 0.8) < 0.5:
		var w := PixelFont.text_width(_name.text) * 2
		draw_texture(Icons.tex("alert", 2), Vector2(16 + w + 8, 8))
	if p.is_empty() or p.stage == "egg" or not p.alive or game.save.daycare.active:
		return
	var cell := (size.x - 28) / 4.0
	for i in METERS.size():
		var stat: String = METERS[i][0]
		var value: float = p.get(stat, 0.0)
		var x := 14.0 + i * cell
		var y := 38.0
		draw_texture(Icons.tex(METERS[i][1], 2), Vector2(x, y + 1))
		_meter(Vector2(x + 26, y + 5), value, cell - 32)

func _meter(at: Vector2, value: float, width: float) -> void:
	var segs := 5
	var gap := 2.0
	var sw := floorf((width - gap * (segs - 1)) / segs)
	var filled := ceili(clampf(value, 0.0, 100.0) / 20.0)
	var col := Pal.GOOD if filled >= 3 else (Pal.WARN if filled == 2 else Pal.BAD)
	var low := filled <= 1 and fmod(_t, 1.0) < 0.5
	for s in segs:
		var r := Rect2(at.x + s * (sw + gap), at.y, sw, 12)
		draw_rect(r, Pal.INK)
		var inner := r.grow(-2)
		if s < filled:
			draw_rect(inner, col.lightened(0.25) if low else col)
			draw_rect(Rect2(inner.position, Vector2(inner.size.x, 2)), Color(1, 1, 1, 0.35))
		else:
			draw_rect(inner, Color("f3e9e2"))
