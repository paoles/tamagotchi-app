class_name MiniGame
extends Control

# ============================================================
# Shared frame for mini-games: an intro card with the rules, the
# play field (drawn in pixels at SCALE, like the room), and a
# results card. Subclasses implement start_game / update_game /
# draw_game / on_press and call finish(score) when done; the
# frame turns the score into coins and happiness via `reward()`.
# ============================================================

signal finished(result: Dictionary)

const SCALE := 3
const ENERGY := 10.0
const WEIGHT := 2.0

var game: Node
var sfx: Node
var form := "mochi"
var playing := false
var t := 0.0
var field := Vector2(120, 200)     # play field in pixels
var _card: PanelContainer

func title() -> String: return "Mini-game"
func rules() -> String: return ""
func start_game() -> void: pass
func update_game(_delta: float) -> void: pass
func draw_game() -> void: pass
func on_press(_p: Vector2) -> void: pass
func on_drag(_p: Vector2) -> void: pass
func on_key(_key: Key, _pressed: bool) -> void: pass

# Score → reward. Subclasses may override.
func reward(score: int, won: bool) -> Dictionary:
	return {"coins": clampi(score, 0, 25), "happy": 25.0 if won else 12.0}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	var p: Dictionary = game.save.pet
	if not p.is_empty():
		form = p.form
	_show_card(title(), rules(), "Start!", _begin)

func _layout_field() -> void:
	field = Vector2(floorf(size.x / SCALE), floorf(size.y / SCALE))

func _begin() -> void:
	_close_card()
	_layout_field()
	t = 0.0
	playing = true
	grab_focus()
	start_game()

func finish(score: int, won: bool, headline: String) -> void:
	if not playing:
		return
	playing = false
	var r := reward(score, won)
	r["won"] = won
	r["score"] = score
	if sfx:
		sfx.play("win" if won else "lose")
	var lines := "%s\n\n+%d coins   +%d happy" % [headline, int(r.coins), int(r.happy)]
	_show_card("Well played!" if won else "Nice try!", lines, "Collect", func() -> void:
		finished.emit(r)
		queue_free())

func quit() -> void:
	playing = false
	finished.emit({})
	queue_free()

func _process(delta: float) -> void:
	_layout_field()
	if playing:
		t += delta
		update_game(delta)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("cfeefc"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(SCALE, SCALE))
	_backdrop()
	draw_game()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if playing:
		_hud()

func _backdrop() -> void:
	var bands := 5
	for i in bands:
		var y0 := floorf(field.y * 0.6 * i / bands)
		draw_rect(Rect2(0, y0, field.x, field.y * 0.6 / bands + 1), Color("a9d4f5").lerp(Color("e6f6fd"), float(i) / bands))
	draw_rect(Rect2(0, field.y * 0.6, field.x, field.y * 0.4), Color("e6f6fd"))
	# sun
	var sun := Vector2(field.x - 24, 48)
	for dy in range(-5, 6):
		var half := floori(sqrt(25.0 - dy * dy) + 0.35)
		draw_rect(Rect2(sun.x - half, sun.y + dy, half * 2 + 1, 1), Color("fde58f"))
	# clouds
	for i in 4:
		var cx := fmod(i * 47.0 + t * (3.0 + i), field.x + 30.0) - 15.0
		var cy := 70.0 + (i % 3) * 26.0
		draw_rect(Rect2(cx + 3, cy, 8, 2), Color.WHITE)
		draw_rect(Rect2(cx, cy + 2, 16, 3), Color.WHITE)
		draw_rect(Rect2(cx + 2, cy + 5, 12, 1), Color("dcecfa"))

# Score pill in the top corner (UI scale, so the text stays crisp).
var hud_text := ""
var hud_icon := "coin"

func _hud() -> void:
	if hud_text == "":
		return
	var w := PixelFont.text_width(hud_text) * 3 + 46
	var r := Rect2(size.x - w - 14, 12, w, 40)
	draw_style_box(Kit.box(Color(1, 0.98, 0.96, 0.95), Pal.INK, 2, 10, 4), r)
	draw_texture(Icons.tex(hud_icon, 2), r.position + Vector2(8, 10))
	draw_string(PixelFont.font(), r.position + Vector2(34, 30), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.INK)

func _gui_input(e: InputEvent) -> void:
	if not playing:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		on_press(e.position / SCALE)
		accept_event()
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		on_drag(e.position / SCALE)
		accept_event()
	elif e is InputEventScreenDrag:
		on_drag(e.position / SCALE)
		accept_event()

func _unhandled_key_input(e: InputEvent) -> void:
	if playing and e is InputEventKey and not e.echo:
		on_key(e.keycode, e.pressed)

# --- Cards -----------------------------------------------------------

func _show_card(head: String, body: String, button: String, cb: Callable) -> void:
	_close_card()
	_card = PanelContainer.new()
	var v := Kit.vbox(12)
	_card.add_child(v)
	v.add_child(Kit.label(head, Kit.FONT_BIG, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER))
	var pic := Kit.tex_rect(Forms.sprite(form, "happy"), 3)
	v.add_child(pic)
	var b := Kit.para(body)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	var row := Kit.hbox(8)
	if button == "Start!":
		var back := Kit.button("Back", quit, "left")
		back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(back)
	var go := Kit.accent(Kit.button(button, cb, "check"), Pal.MINT)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(go)
	v.add_child(row)
	add_child(_card)
	_card.custom_minimum_size = Vector2(size.x - 40, 0)
	_card.position = Vector2(20, size.y * 0.18)
	_card.size = Vector2(size.x - 40, 0)
	_card.call_deferred("reset_size")
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(_card):
			_card.reset_size(), CONNECT_ONE_SHOT)

func _close_card() -> void:
	if _card and is_instance_valid(_card):
		_card.queue_free()
	_card = null

# --- Drawing helpers ------------------------------------------------

func draw_sprite(tex: Texture2D, center_bottom: Vector2, flip := false) -> void:
	var pos := (center_bottom - Vector2(tex.get_width() / 2.0, tex.get_height())).round()
	if flip:
		draw_set_transform(Vector2((pos.x + tex.get_width()) * SCALE, 0), 0.0, Vector2(-SCALE, SCALE))
		draw_texture(tex, Vector2(0, pos.y))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(SCALE, SCALE))
	else:
		draw_texture(tex, pos)

func draw_ground(y: float, col: Color = Color("bfe8a8"), edge: Color = Color("8fcf7a")) -> void:
	draw_rect(Rect2(0, y, field.x, field.y - y), col)
	draw_rect(Rect2(0, y, field.x, 2), edge)

func draw_text_px(text: String, pos: Vector2, color: Color = Pal.INK) -> void:
	# Text in field pixels: draw at UI scale for crispness.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(PixelFont.font(), pos * SCALE, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(SCALE, SCALE))
