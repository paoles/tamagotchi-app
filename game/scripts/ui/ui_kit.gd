class_name Kit
extends RefCounted

# ============================================================
# The UI theme and small widget constructors. Everything is
# built in code: chunky pastel panels with a thick bottom border
# for a pressable, plastic feel, and the runtime pixel font.
# ============================================================

const FONT := 16
const FONT_BIG := 24
const PAD := 10

static var _theme: Theme = null

static func box(bg: Color, border: Color = Pal.INK, width: int = 2, radius: int = 8, bottom: int = -1, margin: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	if bottom >= 0:
		s.border_width_bottom = bottom
	s.set_corner_radius_all(radius)
	s.anti_aliasing = false
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin - 2
	s.content_margin_bottom = margin - 2
	return s

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = PixelFont.font()
	t.default_font_size = FONT
	t.set_color("font_color", "Label", Pal.INK)
	t.set_constant("line_spacing", "Label", 4)

	var normal := box(Pal.PANEL, Pal.INK, 2, 8, 5)
	var hover := box(Color("fff4ea"), Pal.INK, 2, 8, 5)
	var pressed := box(Pal.PANEL_ALT, Pal.INK, 2, 8, 2)
	pressed.content_margin_top += 3
	var disabled := box(Color("efe6de"), Pal.INK_SOFT, 2, 8, 3)
	for kind in ["Button", "OptionButton"]:
		t.set_stylebox("normal", kind, normal)
		t.set_stylebox("hover", kind, hover)
		t.set_stylebox("pressed", kind, pressed)
		t.set_stylebox("hover_pressed", kind, pressed)
		t.set_stylebox("disabled", kind, disabled)
		t.set_stylebox("focus", kind, StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			t.set_color(c, kind, Pal.INK)
		t.set_color("font_disabled_color", kind, Pal.INK_SOFT)
		t.set_constant("h_separation", kind, 6)
		t.set_constant("icon_max_width", kind, 0)

	t.set_stylebox("panel", "PanelContainer", box(Pal.PANEL, Pal.INK, 3, 14, 3, 14))
	t.set_stylebox("panel", "Panel", box(Pal.PANEL, Pal.INK, 3, 14, 3, 14))

	var le := box(Color.WHITE, Pal.INK, 2, 6, 2, 8)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, Pal.ACCENT_DEEP, 2, 6, 2, 8))
	t.set_color("font_color", "LineEdit", Pal.INK)
	t.set_color("caret_color", "LineEdit", Pal.INK)
	t.set_color("font_placeholder_color", "LineEdit", Pal.INK_SOFT)

	var grab := box(Pal.LILAC, Pal.INK, 0, 3, 0, 0)
	var track := box(Color(0, 0, 0, 0.05), Pal.INK, 0, 3, 0, 0)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("h_separation", "GridContainer", 8)
	t.set_constant("v_separation", "GridContainer", 8)
	_theme = t
	return t

# --- Constructors ------------------------------------------------

static func label(text: String, size: int = FONT, color: Color = Pal.INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

static func para(text: String, size: int = FONT, color: Color = Pal.INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 40
	return l

static func button(text: String, cb: Callable, icon: String = "", min_h: int = 44) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_h)
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if icon != "":
		b.icon = Icons.tex(icon, 2)
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

static func tall_button(text: String, icon: String, cb: Callable, min_size: Vector2 = Vector2(0, 72)) -> Button:
	var b := button(text, cb, icon, int(min_size.y))
	b.custom_minimum_size = min_size
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b

static func accent(b: Button, color: Color) -> Button:
	b.add_theme_stylebox_override("normal", box(color, Pal.INK, 2, 8, 5))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.1), Pal.INK, 2, 8, 5))
	var p := box(color.darkened(0.06), Pal.INK, 2, 8, 2)
	p.content_margin_top += 3
	b.add_theme_stylebox_override("pressed", p)
	return b

static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func icon(name: String, scale: int = 2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Icons.tex(name, scale)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r

static func tex_rect(tex: Texture2D, scale: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = tex.get_size() * scale
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r

static func spacer(h: float = 0.0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	if expand:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

static func row(left: String, right: String, icon_name: String = "") -> HBoxContainer:
	var h := hbox(8)
	if icon_name != "":
		h.add_child(icon(icon_name, 2))
	var l := label(left)
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(label(right, FONT, Pal.INK, HORIZONTAL_ALIGNMENT_RIGHT))
	return h

static func card(content: Control, bg: Color = Pal.PANEL_ALT) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, Pal.INK, 2, 10, 3, 10))
	p.add_child(content)
	return p

static func toggle(text: String, on: bool, cb: Callable) -> Button:
	var b := button("", Callable(), "")
	b.toggle_mode = true
	b.button_pressed = on
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var refresh := func() -> void:
		b.text = "%s  %s" % ["[ON] " if b.button_pressed else "[OFF]", text]
	refresh.call()
	b.toggled.connect(func(v: bool) -> void:
		refresh.call()
		cb.call(v))
	return b
