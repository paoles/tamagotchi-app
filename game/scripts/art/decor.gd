class_name Decor
extends RefCounted

# ============================================================
# Draws the furniture the player placed in the room's slots.
# Furniture sprites come from the shop catalog; this only knows
# where each slot sits and how a sprite anchors to it (wall items
# hang centred, floor items stand on their bottom edge).
# ============================================================

const WALL_SLOTS := ["wall_l", "wall_r"]

static func draw(ci: CanvasItem, save: Dictionary, lay: Dictionary, anim_t: float) -> void:
	var slots: Dictionary = save.room.slots
	for slot in ["wall_l", "wall_r", "floor_l", "floor_r", "sill", "rug"]:
		var id: String = slots.get(slot, "")
		if id == "":
			continue
		var tex := Shop.sprite(id)
		if tex == null:
			continue
		var at: Vector2 = lay.slots[slot]
		var size := tex.get_size()
		var pos := Vector2.ZERO
		match slot:
			"wall_l", "wall_r", "rug":
				pos = Vector2(at.x - floorf(size.x / 2.0), at.y - floorf(size.y / 2.0))
			"floor_l":
				pos = Vector2(at.x, at.y - size.y)
			"floor_r":
				pos = Vector2(at.x - size.x, at.y - size.y)
			_:
				pos = Vector2(at.x - floorf(size.x / 2.0), at.y - size.y)
		ci.draw_texture(tex, pos.round())
