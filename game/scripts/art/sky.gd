class_name SkyCycle
extends RefCounted

# ============================================================
# What the window shows: sky colours for the real local time,
# where the sun or moon sits on its arc, how bright the stars
# are, and the day's simulated weather. Weather is a pure
# function of the local date and the hour (seeded hash), so it
# needs no saved state and every device agrees on it.
# ============================================================

# Keyframes: minute of day → [top, bottom] sky colours.
const KEYS := [
	[0,    Color("2b2a55"), Color("4a3f78")],
	[300,  Color("2f2d5c"), Color("5a4a80")],
	[360,  Color("8d7fc4"), Color("f6b9a8")],
	[450,  Color("9ccff2"), Color("fde3c8")],
	[720,  Color("8cc8f5"), Color("d9f0fb")],
	[1050, Color("9ccff2"), Color("f3e6d0")],
	[1140, Color("b28cc8"), Color("f8b48e")],
	[1230, Color("4a3f78"), Color("8a6aa0")],
	[1320, Color("2b2a55"), Color("4a3f78")],
	[1440, Color("2b2a55"), Color("4a3f78")],
]

static func colors(m: int) -> Array:
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if m >= a[0] and m < b[0]:
			var f := float(m - a[0]) / float(b[0] - a[0])
			return [a[1].lerp(b[1], f), a[2].lerp(b[2], f)]
	return [KEYS[0][1], KEYS[0][2]]

static func is_day(m: int) -> bool:
	return m >= 390 and m < 1170

# 0 at night, 1 in deep night (for stars).
static func star_alpha(m: int) -> float:
	if m >= 1260 or m < 300:
		return 1.0
	if m >= 1140 and m < 1260:
		return (m - 1140) / 120.0
	if m >= 300 and m < 420:
		return 1.0 - (m - 300) / 120.0
	return 0.0

# Sun 06:00→20:00, moon 19:00→07:00. Returns {kind, t (0..1 along the arc)}.
static func body(m: int) -> Dictionary:
	if m >= 360 and m < 1200:
		return {"kind": "sun", "t": (m - 360) / 840.0}
	var mm := m if m >= 1140 else m + 1440
	return {"kind": "moon", "t": clampf((mm - 1140) / 720.0, 0.0, 1.0)}

# --- Weather ---------------------------------------------------

const SEASON_WEATHER := {
	# month → weights for clear, cloudy, rain, snow
	1: [3, 3, 0, 4], 2: [3, 3, 1, 3], 3: [4, 3, 3, 1], 4: [4, 3, 4, 0],
	5: [6, 3, 2, 0], 6: [7, 2, 2, 0], 7: [8, 2, 1, 0], 8: [7, 2, 2, 0],
	9: [5, 3, 3, 0], 10: [4, 4, 3, 0], 11: [3, 4, 3, 1], 12: [3, 3, 1, 4],
}
const WEATHER_KINDS := ["clear", "cloudy", "rain", "snow"]

# Weather changes in 4-hour blocks.
static func weather(unix: int, bias: int) -> String:
	var local := unix + bias * 60
	var d := Time.get_datetime_dict_from_unix_time(local)
	var block := int(d.hour) / 4
	var h := hash("%d-%d-%d-%d" % [d.year, d.month, d.day, block])
	var weights: Array = SEASON_WEATHER.get(int(d.month), [5, 3, 2, 0])
	var total := 0
	for w in weights:
		total += int(w)
	var roll := posmod(h, total)
	for i in weights.size():
		roll -= int(weights[i])
		if roll < 0:
			return WEATHER_KINDS[i]
	return "clear"

const STAR_SPOTS := [
	Vector2(0.12, 0.18), Vector2(0.3, 0.1), Vector2(0.52, 0.22), Vector2(0.7, 0.08),
	Vector2(0.86, 0.3), Vector2(0.2, 0.42), Vector2(0.62, 0.45), Vector2(0.42, 0.62),
	Vector2(0.9, 0.6), Vector2(0.08, 0.7),
]
