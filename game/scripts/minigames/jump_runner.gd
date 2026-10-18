extends MiniGame

# ============================================================
# Jump Runner: the pet runs; tap to hop over cacti and rocks and
# grab floating coins. One bump ends the run.
# ============================================================

const GRAVITY := 420.0
const JUMP := 150.0

var y := 0.0
var vy := 0.0
var scroll := 0.0
var obstacles: Array = []
var coins: Array = []
var next_obstacle := 60.0
var collected := 0
var dist := 0.0

func title() -> String: return "Jump Runner"
func rules() -> String: return "Tap (or press space) to jump. Hop over obstacles and grab coins!"

func reward(score: int, won: bool) -> Dictionary:
	return {"coins": clampi(score, 0, 25), "happy": 25.0 if won else 12.0}

func start_game() -> void:
	y = 0.0
	vy = 0.0
	scroll = 0.0
	obstacles = []
	coins = []
	next_obstacle = 80.0
	collected = 0
	dist = 0.0

func _jump() -> void:
	if y >= -0.5:
		vy = -JUMP
		if sfx:
			sfx.play("jump")

func on_press(_p: Vector2) -> void:
	_jump()

func on_key(key: Key, pressed: bool) -> void:
	if pressed and key in [KEY_SPACE, KEY_UP, KEY_W]:
		_jump()

func _score() -> int:
	return collected + int(dist / 120.0)

func update_game(delta: float) -> void:
	var speed := 55.0 + t * 2.2
	var ground := field.y - 40.0
	var px := 30.0
	vy += GRAVITY * delta
	y = minf(0.0, y + vy * delta)
	if y >= 0.0:
		vy = 0.0
	scroll += speed * delta
	dist += speed * delta
	next_obstacle -= speed * delta
	if next_obstacle <= 0.0:
		var kind := "cactus" if randf() < 0.6 else "rock"
		obstacles.append({"x": field.x + 10.0, "kind": kind})
		if randf() < 0.6:
			coins.append({"x": field.x + 10.0 + randf_range(-6, 6), "h": randf_range(22.0, 34.0)})
		next_obstacle = randf_range(70.0, 120.0) * (1.0 + t * 0.01)
	for o in obstacles:
		o.x -= speed * delta
	for c in coins:
		c.x -= speed * delta
	obstacles = obstacles.filter(func(o: Dictionary) -> bool: return o.x > -20.0)
	for i in range(coins.size() - 1, -1, -1):
		var c: Dictionary = coins[i]
		if absf(c.x - px) < 8.0 and absf((ground + y - 14.0) - (ground - c.h)) < 10.0:
			coins.remove_at(i)
			collected += 1
			if sfx:
				sfx.play("coin")
		elif c.x < -10.0:
			coins.remove_at(i)
	for o in obstacles:
		var half := 4.0 if o.kind == "cactus" else 5.0
		var height := 11.0 if o.kind == "cactus" else 6.0
		if absf(o.x - px) < half + 6.0 and -y < height:
			if sfx:
				sfx.play("hit")
			var s := _score()
			finish(s, s >= 12, "Ran %d m and grabbed %d coins." % [int(dist / 10.0), collected])
			return

func draw_game() -> void:
	var ground := field.y - 40.0
	# Parallax hills
	for i in 4:
		var hx := fmod(i * 50.0 - scroll * 0.3, field.x + 60.0) - 30.0
		draw_rect(Rect2(hx, ground - 14, 40, 14), Color("d8f0c8"))
		draw_rect(Rect2(hx + 6, ground - 20, 28, 6), Color("d8f0c8"))
	draw_ground(ground)
	for i in int(field.x / 12.0) + 2:
		var gx := fmod(i * 12.0 - scroll, field.x + 12.0)
		draw_rect(Rect2(gx, ground + 5, 4, 1), Color("8fcf7a"))
	for o in obstacles:
		var tex: Texture2D = Goods.tex("cactus") if o.kind == "cactus" else Icons.tex("rock")
		draw_texture(tex, Vector2(roundf(o.x - tex.get_width() / 2.0), ground - tex.get_height() + 1))
	for c in coins:
		draw_texture(Icons.tex("coin"), Vector2(roundf(c.x - 4), roundf(ground - c.h - 4)))
	var expr := "happy" if y < -1.0 else ("idle" if fmod(t, 0.3) < 0.15 else "blink")
	var bob := 0.0 if y < -0.5 else (-1.0 if fmod(t, 0.2) < 0.1 else 0.0)
	draw_sprite(Forms.sprite(form, expr), Vector2(30, ground + 1 + y + bob))
	hud_text = str(_score())
