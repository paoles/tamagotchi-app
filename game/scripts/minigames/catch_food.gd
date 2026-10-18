extends MiniGame

# ============================================================
# Catch the Food: slide the pet left and right to catch falling
# treats; dodge the poops. 30 seconds, three lives.
# ============================================================

const DURATION := 30.0
const GOOD := ["apple", "sushi", "cake", "icecream", "coin"]

var pet_x := 60.0
var items: Array = []
var spawn_t := 0.0
var score := 0
var lives := 3
var hurt_t := 0.0
var held := 0

func title() -> String: return "Catch the Food"
func rules() -> String: return "Drag to move. Catch treats, dodge poop! 30 seconds, three lives."

func reward(s: int, won: bool) -> Dictionary:
	return {"coins": clampi(s, 0, 25), "happy": 25.0 if won else 12.0}

func start_game() -> void:
	pet_x = field.x / 2.0
	items = []
	spawn_t = 0.5
	score = 0
	lives = 3

func on_press(p: Vector2) -> void:
	pet_x = clampf(p.x, 10.0, field.x - 10.0)

func on_drag(p: Vector2) -> void:
	on_press(p)

func on_key(key: Key, pressed: bool) -> void:
	if key == KEY_LEFT:
		held = -1 if pressed else (0 if held == -1 else held)
	elif key == KEY_RIGHT:
		held = 1 if pressed else (0 if held == 1 else held)

func update_game(delta: float) -> void:
	var ground := field.y - 34.0
	pet_x = clampf(pet_x + held * 70.0 * delta, 10.0, field.x - 10.0)
	hurt_t = maxf(0.0, hurt_t - delta)
	var speed := 38.0 + t * 1.6
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = maxf(0.35, 0.9 - t * 0.018)
		var bad := randf() < 0.25 + t * 0.006
		items.append({"id": "poop" if bad else GOOD[randi() % GOOD.size()], "x": randf_range(8.0, field.x - 8.0), "y": 30.0, "bad": bad})
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		it.y += speed * delta
		if it.y >= ground - 18.0 and it.y <= ground and absf(it.x - pet_x) < 12.0:
			items.remove_at(i)
			if it.bad:
				lives -= 1
				hurt_t = 0.6
				if sfx:
					sfx.play("hit")
				if lives <= 0:
					finish(score, score >= 15, "Caught %d treats." % score)
					return
			else:
				score += 1
				if sfx:
					sfx.play("coin")
		elif it.y > field.y:
			items.remove_at(i)
	if t >= DURATION:
		finish(score, score >= 15, "Caught %d treats!" % score)

func draw_game() -> void:
	var ground := field.y - 34.0
	draw_ground(ground)
	for it in items:
		var tex: Texture2D = Items.tex(it.id) if it.id != "coin" else Icons.tex("coin")
		draw_texture(tex, Vector2(roundf(it.x - tex.get_width() / 2.0), roundf(it.y - tex.get_height())))
	var expr := "sad" if hurt_t > 0.0 else ("happy" if fmod(t, 0.6) < 0.3 else "idle")
	draw_sprite(Forms.sprite(form, expr), Vector2(pet_x, ground + 1))
	# HUD
	for i in 3:
		draw_texture(Icons.tex("mini_heart" if i < lives else "cross"), Vector2(6 + i * 8, 10))
	hud_text = str(score)
	var left := maxf(0.0, DURATION - t)
	draw_rect(Rect2(6, 22, (field.x - 60) * left / DURATION, 3), Pal.ACCENT_DEEP)
