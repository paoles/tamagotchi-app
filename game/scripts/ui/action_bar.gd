class_name ActionBar
extends Control

# ============================================================
# The bottom row of six big buttons. The game decides what each
# does; this only lays them out and greys out what can't be used
# right now (egg, daycare, a pet that has passed).
# ============================================================

signal action(name: String)

const HEIGHT := 96.0
const ACTIONS := [
	["feed", "act_feed", "feed"],
	["play", "act_play", "play"],
	["clean", "act_clean", "clean"],
	["lights", "act_lights", "lights"],
	["scold", "act_scold", "scold"],
	["more", "act_more", "more"],
]

var game: Node
var _buttons := {}
var _row: HBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_row = Kit.hbox(4)
	_row.position = Vector2(10, 12)
	add_child(_row)
	for a in ACTIONS:
		var id: String = a[0]
		var b := Kit.tall_button(S.t(a[1]).to_upper(), a[2], func() -> void: action.emit(id), Vector2(0, 72))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_constant_override("h_separation", 2)
		b.add_theme_font_override("font", PixelFont.mini())
		b.add_theme_font_size_override("font_size", 12)
		b.clip_text = false
		var sb: StyleBoxFlat = Kit.box(Pal.PANEL, Pal.INK, 2, 8, 5, 4)
		b.add_theme_stylebox_override("normal", sb)
		var hv := Kit.box(Color("fff4ea"), Pal.INK, 2, 8, 5, 4)
		b.add_theme_stylebox_override("hover", hv)
		var pr := Kit.box(Pal.PANEL_ALT, Pal.INK, 2, 8, 2, 4)
		pr.content_margin_top += 3
		b.add_theme_stylebox_override("pressed", pr)
		b.add_theme_stylebox_override("disabled", Kit.box(Color("efe6de"), Pal.INK_SOFT, 2, 8, 3, 4))
		_row.add_child(b)
		_buttons[id] = b
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if _row:
		_row.size = Vector2(size.x - 20, 72)
		_row.position = Vector2(10, size.y - 72 - 14)

func _process(_delta: float) -> void:
	if game == null:
		return
	var save: Dictionary = game.save
	var p: Dictionary = save.pet
	var alive_pet: bool = not p.is_empty() and p.alive and p.stage != "egg" and not save.daycare.active
	for id in ["feed", "play", "scold"]:
		_buttons[id].disabled = not alive_pet
	_buttons.clean.disabled = not alive_pet
	_buttons.lights.disabled = not alive_pet
	if alive_pet:
		var on: bool = p.lights
		_buttons.lights.icon = Icons.tex("lights" if on else "moon", 2)

func _draw() -> void:
	draw_style_box(Kit.box(Color(1, 0.98, 0.96, 0.94), Pal.INK, 2, 14, 4), Rect2(4, size.y - 94, size.x - 8, 90))
