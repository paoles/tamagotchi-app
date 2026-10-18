class_name Outfits
extends RefCounted

# ============================================================
# Draws equipped outfits on the pet using the form's anchors:
# hats sit on the head point, collars under the face, and
# eyewear is drawn procedurally around the eyes so it fits every
# form's eye spacing.
# ============================================================

static func draw(ci: CanvasItem, save: Dictionary, form: String, origin: Vector2) -> void:
	var eq: Dictionary = save.equipped
	var neck: String = eq.get("neck", "")
	if neck != "":
		var t := Goods.tex(neck)
		var a := Forms.anchor(form, "neck")
		ci.draw_texture(t, (origin + a - Vector2(floorf(t.get_width() / 2.0), 1)).round())
	var face: String = eq.get("face", "")
	if face != "":
		draw_face(ci, face, form, origin)
	var head: String = eq.get("head", "")
	if head != "":
		var t := Goods.tex(head)
		var a := Forms.anchor(form, "head")
		var sink := 3.0 if head in ["beanie", "cap", "tiara", "flower_crown"] else 2.0
		ci.draw_texture(t, (origin + a - Vector2(floorf(t.get_width() / 2.0), t.get_height() - sink)).round())

static func draw_face(ci: CanvasItem, id: String, form: String, origin: Vector2) -> void:
	var rec := Forms.recipe(form)
	if rec.get("eyes", "big") == "none":
		return
	var fx: float = rec.face[0]
	var fy: float = rec.face[1]
	var gap: float = rec.gap
	var ink := Pal.INK
	var small: bool = rec.get("eyes", "big") == "small"
	var r := 2 if small else 3
	var eyes := [Vector2(fx - gap / 2.0, fy), Vector2(fx + gap / 2.0, fy)]
	match id:
		"glasses", "shades":
			for e in eyes:
				var c: Vector2 = (origin + e).floor()
				var box := Rect2(c.x - r, c.y - r + 1, r * 2, r * 2 - 1)
				if id == "shades":
					ci.draw_rect(box, Color("3b3047"))
					ci.draw_rect(Rect2(box.position + Vector2(1, 1), Vector2(1, 1)), Color(1, 1, 1, 0.8))
				_ring(ci, box, ink)
			var y := floorf(origin.y + fy - r + 2)
			ci.draw_rect(Rect2(floorf(origin.x + eyes[0].x + r), y, maxf(1.0, gap - r * 2), 1), ink)
		"monocle":
			var c: Vector2 = (origin + eyes[1]).floor()
			var box := Rect2(c.x - r, c.y - r + 1, r * 2, r * 2 - 1)
			_ring(ci, box, Color("f0c050"))
			ci.draw_rect(Rect2(box.end.x - 1, box.end.y, 1, 4), Color("f0c050"))

static func _ring(ci: CanvasItem, box: Rect2, col: Color) -> void:
	ci.draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), col)
	ci.draw_rect(Rect2(box.position.x, box.end.y - 1, box.size.x, 1), col)
	ci.draw_rect(Rect2(box.position, Vector2(1, box.size.y)), col)
	ci.draw_rect(Rect2(box.end.x - 1, box.position.y, 1, box.size.y), col)

# A small stand-alone picture of eyewear for shop cards.
static func face_preview(id: String) -> Image:
	var img := Image.create_empty(14, 7, false, Image.FORMAT_RGBA8)
	var ink := Pal.INK
	match id:
		"glasses", "shades":
			for x0 in [0, 8]:
				if id == "shades":
					img.fill_rect(Rect2i(x0 + 1, 1, 4, 4), Color("3b3047"))
				img.fill_rect(Rect2i(x0, 0, 6, 1), ink)
				img.fill_rect(Rect2i(x0, 5, 6, 1), ink)
				img.fill_rect(Rect2i(x0, 0, 1, 6), ink)
				img.fill_rect(Rect2i(x0 + 5, 0, 1, 6), ink)
			img.fill_rect(Rect2i(6, 1, 2, 1), ink)
		"monocle":
			var gold := Color("f0c050")
			img.fill_rect(Rect2i(4, 0, 6, 1), gold)
			img.fill_rect(Rect2i(4, 5, 6, 1), gold)
			img.fill_rect(Rect2i(4, 0, 1, 6), gold)
			img.fill_rect(Rect2i(9, 0, 1, 6), gold)
			img.fill_rect(Rect2i(9, 6, 1, 1), gold)
	return img
