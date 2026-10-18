extends MiniGame

# ============================================================
# Left or Right: the classic. Guess which way the pet will look.
# Five rounds; three correct guesses wins.
# ============================================================

const ROUNDS := 5

var round_i := 0
var correct := 0
var looking := 0          # -1 left, 1 right, 0 facing you
var reveal_t := 0.0
var last_guess := 0
var results: Array = []

func title() -> String: return "Left or Right?"
func rules() -> String: return "Guess which way your pet will look. Tap the left or right half of the screen. Win 3 of 5!"

func reward(score: int, won: bool) -> Dictionary:
	return {"coins": score * 3 + (5 if won else 0), "happy": 25.0 if won else 12.0}

func start_game() -> void:
	round_i = 0
	correct = 0
	looking = 0
	reveal_t = 0.0
	results = []

func on_press(p: Vector2) -> void:
	if reveal_t > 0.0 or round_i >= ROUNDS:
		return
	last_guess = -1 if p.x < field.x / 2.0 else 1
	looking = -1 if randf() < 0.5 else 1
	var hit := looking == last_guess
	if hit:
		correct += 1
	results.append(hit)
	if sfx:
		sfx.play("coin" if hit else "refuse")
	reveal_t = 1.1

func on_key(key: Key, pressed: bool) -> void:
	if not pressed:
		return
	if key == KEY_LEFT:
		on_press(Vector2(1, 1))
	elif key == KEY_RIGHT:
		on_press(Vector2(field.x - 1, 1))

func update_game(delta: float) -> void:
	if reveal_t > 0.0:
		reveal_t -= delta
		if reveal_t <= 0.0:
			round_i += 1
			looking = 0
			if round_i >= ROUNDS:
				finish(correct, correct >= 3, "You guessed %d of %d." % [correct, ROUNDS])

func draw_game() -> void:
	hud_text = "%d/%d" % [correct, ROUNDS]
	hud_icon = "check"
	var ground := floorf(field.y * 0.66)
	draw_ground(ground)
	# Arrows on each half
	var mid := field.x / 2.0
	draw_rect(Rect2(mid, ground - 70, 1, 60), Color(0.35, 0.29, 0.42, 0.15))
	draw_texture(Icons.tex("left"), Vector2(8, ground - 46))
	draw_texture(Icons.tex("right"), Vector2(field.x - 13, ground - 46))
	var expr := "idle"
	if reveal_t > 0.0:
		expr = "happy" if results[-1] else "sad"
	var tex := Forms.sprite(form, expr)
	var x := mid + looking * 10.0
	draw_sprite(tex, Vector2(x, ground + 1), looking < 0)
	if looking != 0:
		# The pet turns its whole body and an arrow shows which way.
		var arrow := Icons.tex("left" if looking < 0 else "right")
		draw_texture(arrow, Vector2(x + looking * 18.0 - 2.0, ground - 22.0))
		draw_texture(arrow, Vector2(x + looking * 24.0 - 2.0, ground - 22.0))
	if reveal_t > 0.0:
		draw_texture(Icons.tex("check" if results[-1] else "cross"), Vector2(mid - 4, ground - 44))
	# Round dots
	for i in ROUNDS:
		var c := Color("e3d8de")
		if i < results.size():
			c = Pal.GOOD if results[i] else Pal.BAD
		draw_rect(Rect2(mid - ROUNDS * 4 + i * 8, 20, 6, 6), Pal.INK)
		draw_rect(Rect2(mid - ROUNDS * 4 + i * 8 + 1, 21, 4, 4), c)
