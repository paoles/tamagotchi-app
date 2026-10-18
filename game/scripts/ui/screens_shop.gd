class_name ScreensShop
extends RefCounted

# ============================================================
# Shop, wardrobe, decorating, plus the treat and toy rows that
# appear in the Feed and Play sheets. Registered into
# Screens.EXTRA at boot. Sheets refresh their grids in place so
# buying or equipping doesn't replay the slide-in.
# ============================================================

static func register() -> void:
	Screens.EXTRA["shop"] = _shop
	Screens.EXTRA["wardrobe"] = _wardrobe
	Screens.EXTRA["decor"] = _decor
	Screens.EXTRA["food_items"] = _food_items
	Screens.EXTRA["play_items"] = _play_items

static func _mini(b: Button) -> Button:
	b.add_theme_font_override("font", PixelFont.mini())
	b.add_theme_font_size_override("font_size", 12)
	return b

static func _caption(text: String, color: Color = Pal.INK) -> Label:
	var l := Kit.label(text.to_upper(), 12, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", PixelFont.mini())
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l

# A tappable tile: sprite, caption, and a footer line.
static func _tile(tex: Texture2D, caption: String, footer: String, highlight: bool, cb: Callable, footer_icon: String = "") -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	if highlight:
		Kit.accent(b, Pal.MINT)
	b.pressed.connect(cb)
	var v := Kit.vbox(2)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 6
	v.offset_bottom = -6
	v.offset_left = 4
	v.offset_right = -4
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var pic := TextureRect.new()
	pic.texture = tex
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex != null:
		var s := 2 if maxf(tex.get_width(), tex.get_height()) > 16 else 3
		if tex.get_width() > 24:
			s = 1
		pic.texture = Px.cached("tile:%s:%d" % [tex.get_rid().get_id(), s], func() -> Image:
			var img := tex.get_image()
			return Px.scaled(img, s))
	v.add_child(pic)
	var cap := _caption(caption)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cap)
	var foot := Kit.hbox(4)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if footer_icon != "":
		var ic := Kit.icon(footer_icon, 1)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foot.add_child(ic)
	var fl := _caption(footer, Pal.INK_SOFT)
	fl.clip_text = false
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(fl)
	v.add_child(foot)
	return b

static func _grid(cols: int = 3) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g

static func _clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()

# --- Shop ------------------------------------------------------------

static func _shop(ui: GameUI) -> void:
	var state := {"tab": "food"}
	var v := Kit.vbox(10)
	var coins := Kit.row("Your coins", "", "coin")
	v.add_child(coins)
	var tabs := Kit.hbox(4)
	v.add_child(tabs)
	var grid := _grid(3)
	v.add_child(grid)
	var desc := Kit.para("", Kit.FONT, Pal.INK_SOFT)
	v.add_child(desc)
	var render := func(_r: Callable) -> void:
		pass
	render = func(self_ref: Callable) -> void:
		var save: Dictionary = ui.game.save
		(coins.get_child(coins.get_child_count() - 1) as Label).text = str(int(save.coins))
		_clear(tabs)
		for t in Shop.TABS:
			var tid: String = t[0]
			var tb := _mini(Kit.button(String(t[1]).to_upper(), func() -> void:
				state.tab = tid
				desc.text = ""
				self_ref.call(self_ref), "", 40))
			tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if tid == state.tab:
				Kit.accent(tb, Pal.BUTTER)
			tabs.add_child(tb)
		_clear(grid)
		for id in Shop.ids_in(state.tab):
			var it := Shop.item(id)
			var footer := str(int(it.price))
			var ficon := "coin"
			var owned := false
			if it.cat == "food":
				var n := Shop.count(save, id)
				if n > 0:
					footer = "%s · ×%d" % [footer, n]
			elif Shop.owns(save, id):
				footer = "Owned"
				ficon = "check"
				owned = true
			var item_id: String = id
			grid.add_child(_tile(Shop.sprite(id), it.name, footer, owned, func() -> void:
				desc.text = "%s: %s" % [it.name, it.desc]
				if owned:
					return
				var res := Shop.buy(ui.game.save, item_id)
				ui.game.apply(res, "buy")
				self_ref.call(self_ref), ficon))
	render.call(render)
	ui.open(S.t("more_shop"), v, false, true, "shop")

# --- Wardrobe ----------------------------------------------------------

class Preview:
	extends Control
	var game: Node
	var scale_px := 4

	func _ready() -> void:
		custom_minimum_size = Vector2(32 * scale_px, 32 * scale_px)

	func _draw() -> void:
		var p: Dictionary = game.save.pet
		if p.is_empty():
			return
		var off := Vector2(floorf((size.x - 32 * scale_px) / 2.0), 0)
		draw_set_transform(off, 0.0, Vector2(scale_px, scale_px))
		draw_texture(Forms.sprite(p.form, "happy"), Vector2.ZERO)
		if p.stage != "egg":
			Outfits.draw(self, game.save, p.form, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _wardrobe(ui: GameUI) -> void:
	var v := Kit.vbox(10)
	var preview := Preview.new()
	preview.game = ui.game
	v.add_child(preview)
	var body := Kit.vbox(10)
	v.add_child(body)
	var render := func(_r: Callable) -> void:
		pass
	render = func(self_ref: Callable) -> void:
		preview.queue_redraw()
		_clear(body)
		var save: Dictionary = ui.game.save
		var any := false
		for slot in [["head", "Head"], ["face", "Face"], ["neck", "Neck"]]:
			var owned := []
			for id in Shop.ids_in("outfit"):
				if Shop.item(id).slot == slot[0] and Shop.owns(save, id):
					owned.append(id)
			if owned.is_empty():
				continue
			any = true
			body.add_child(Kit.label(slot[1], Kit.FONT, Pal.INK_SOFT))
			var g := _grid(3)
			for id in owned:
				var it := Shop.item(id)
				var on := Shop.is_active(save, id)
				var item_id: String = id
				g.add_child(_tile(Shop.sprite(id), it.name, "Wearing" if on else "Wear", on, func() -> void:
					Shop.equip(ui.game.save, item_id)
					ui.sfx.play("blip")
					ui.game.persist()
					self_ref.call(self_ref)))
			body.add_child(g)
		if not any:
			body.add_child(Kit.para("No outfits yet. The shop has hats, glasses and more!", Kit.FONT, Pal.INK_SOFT))
			body.add_child(Kit.button("Go to the shop", func() -> void:
				ui.close_sheet()
				ui.open_screen("shop"), "shop"))
	render.call(render)
	ui.open(S.t("more_wardrobe"), v, false, true, "wardrobe")

# --- Decorate ------------------------------------------------------------

static func _decor(ui: GameUI) -> void:
	var body := Kit.vbox(10)
	var render := func(_r: Callable) -> void:
		pass
	render = func(self_ref: Callable) -> void:
		_clear(body)
		var save: Dictionary = ui.game.save
		for cat in [["wallpaper", "Wallpaper"], ["floor", "Floor"]]:
			body.add_child(Kit.label(cat[1], Kit.FONT, Pal.INK_SOFT))
			var g := _grid(3)
			for id in Shop.ids_in(cat[0]):
				if not Shop.owns(save, id):
					continue
				var on := Shop.is_active(save, id)
				var item_id: String = id
				g.add_child(_tile(Shop.sprite(id), Shop.item(id).name, "In use" if on else "Use", on, func() -> void:
					Shop.set_surface(ui.game.save, item_id)
					ui.sfx.play("blip")
					ui.game.persist()
					self_ref.call(self_ref)))
			body.add_child(g)
		for kind in ["wall", "floor", "rug", "sill"]:
			var owned := []
			for id in Shop.ids_in("furniture"):
				if Shop.item(id).kind == kind and Shop.owns(save, id):
					owned.append(id)
			for slot in Shop.KIND_SLOTS[kind]:
				body.add_child(Kit.label(Shop.SLOT_NAMES[slot], Kit.FONT, Pal.INK_SOFT))
				var g := _grid(3)
				var current: String = save.room.slots.get(slot, "")
				var slot_id: String = slot
				g.add_child(_tile(Icons.tex("cross"), "Empty", "", current == "", func() -> void:
					Shop.place(ui.game.save, slot_id, "")
					ui.game.persist()
					self_ref.call(self_ref)))
				for id in owned:
					var item_id: String = id
					g.add_child(_tile(Shop.sprite(id), Shop.item(id).name, "Here" if current == id else "Place", current == id, func() -> void:
						Shop.place(ui.game.save, slot_id, item_id)
						ui.sfx.play("blip")
						ui.game.persist()
						self_ref.call(self_ref)))
				body.add_child(g)
		if save.owned.is_empty():
			body.add_child(Kit.para("Buy furniture, wallpaper and floors in the shop, then place them here.", Kit.FONT, Pal.INK_SOFT))
	render.call(render)
	ui.open(S.t("more_decor"), body, false, true, "decor")

# --- Feed / Play extras ----------------------------------------------------

static func _food_items(ui: GameUI) -> Control:
	var v := Kit.vbox(6)
	var save: Dictionary = ui.game.save
	var g := _grid(3)
	for id in Shop.ids_in("food"):
		var n := Shop.count(save, id)
		if n <= 0:
			continue
		var item_id: String = id
		g.add_child(_tile(Shop.sprite(id), Shop.item(id).name, "×%d" % n, false, func() -> void:
			ui.close_sheet()
			ui.game.apply(Shop.use_food(ui.game.save, item_id), "food")))
	if g.get_child_count() > 0:
		v.add_child(Kit.label("Treats", Kit.FONT, Pal.INK_SOFT))
		v.add_child(g)
	else:
		v.add_child(Kit.para("Buy treats in the shop for extra variety.", Kit.FONT, Pal.INK_SOFT))
	return v

static func _play_items(ui: GameUI) -> Control:
	var v := Kit.vbox(6)
	var save: Dictionary = ui.game.save
	var g := _grid(3)
	for id in Shop.ids_in("toy"):
		if not Shop.owns(save, id):
			continue
		var item_id: String = id
		g.add_child(_tile(Shop.sprite(id), Shop.item(id).name, "Play", false, func() -> void:
			ui.close_sheet()
			ui.game.apply(Shop.play_toy(ui.game.save, item_id), "toy")))
	if g.get_child_count() > 0:
		v.add_child(Kit.label("Toys", Kit.FONT, Pal.INK_SOFT))
		v.add_child(g)
	if Screens.EXTRA.has("game_items"):
		v.add_child(Screens.EXTRA.game_items.call(ui))
	return v
