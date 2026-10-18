class_name Sheet
extends Control

# ============================================================
# A modal panel over the room: a dim backdrop plus either a
# bottom sheet (menus) or a centred card (dialogs). Tapping the
# backdrop closes dismissible sheets. The panel width is fixed
# first; its height is measured a frame later, once wrapped text
# knows its width, and capped so long content scrolls.
# ============================================================

signal closed

const MARGIN := 10.0
const PAD := 14.0

var dismissible := true
var centered := false
var reduced_motion := false
var panel: PanelContainer
var body: VBoxContainer
var _head: Control
var _scroll: ScrollContainer
var _dim: ColorRect
var _ready_done := false

func setup(title: String, content: Control, is_centered: bool = false, can_dismiss: bool = true, title_icon: String = "") -> Sheet:
	centered = is_centered
	dismissible = can_dismiss
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.23, 0.19, 0.28, 0.45)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	panel = PanelContainer.new()
	panel.clip_contents = true
	add_child(panel)
	var outer := Kit.vbox(10)
	panel.add_child(outer)
	var head := Kit.hbox(8)
	if title_icon != "":
		head.add_child(Kit.icon(title_icon, 2))
	var t := Kit.label(title, Kit.FONT_BIG if title.length() <= 11 else Kit.FONT)
	t.clip_text = true
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if dismissible:
		var x := Kit.button("", close, "close", 40)
		x.custom_minimum_size = Vector2(44, 40)
		head.add_child(x)
	head.visible = title != "" or dismissible
	outer.add_child(head)
	_head = head
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_scroll)
	body = Kit.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(body)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(content)
	return self

func _ready() -> void:
	_apply_width()
	panel.modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_fit()
	_ready_done = true
	panel.modulate.a = 1.0
	if reduced_motion:
		return
	if centered:
		panel.modulate.a = 0.0
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.15)
	else:
		var target_y := panel.position.y
		panel.position.y = size.y
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(panel, "position:y", target_y, 0.25)

func resize_to(s: Vector2) -> void:
	size = s
	if _dim:
		_dim.size = s
	if _ready_done:
		_apply_width()
		_fit()

func _apply_width() -> void:
	_dim.position = Vector2.ZERO
	_dim.size = size
	var w := size.x - MARGIN * 2
	panel.custom_minimum_size = Vector2(w, 0)
	panel.size = Vector2(w, panel.size.y)
	panel.position.x = MARGIN

func _fit() -> void:
	var w := size.x - MARGIN * 2
	var head_h: float = _head.get_combined_minimum_size().y if _head.visible else 0.0
	var body_h: float = body.get_combined_minimum_size().y
	var chrome := PAD * 2 + (10.0 if _head.visible else 0.0) + 6.0
	var max_h := size.y * (0.82 if centered else 0.78)
	var h := clampf(head_h + body_h + chrome, 120.0, max_h)
	_scroll.custom_minimum_size = Vector2(0, maxf(0.0, h - head_h - chrome))
	panel.size = Vector2(w, h)
	if centered:
		panel.position = Vector2(MARGIN, floorf((size.y - h) / 2.0))
	else:
		panel.position = Vector2(MARGIN, size.y - h - MARGIN)

func _on_dim_input(e: InputEvent) -> void:
	if dismissible and e is InputEventMouseButton and e.pressed:
		close()

func close() -> void:
	closed.emit()
	queue_free()
