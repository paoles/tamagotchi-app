class_name Sfx
extends Node

# ============================================================
# Sound effects, synthesized lazily the first time each plays.
# A small pool of players lets sounds overlap.
# ============================================================

const RECIPES := {
	"tap": [{"w": "sq", "f": 880, "f2": 1040, "d": 0.05, "v": 0.25, "duty": 0.25}],
	"blip": [{"w": "sq", "f": 660, "d": 0.04, "v": 0.2, "duty": 0.25}],
	"open": [{"w": "sq", "f": 523, "d": 0.04, "v": 0.2}, {"w": "sq", "f": 784, "d": 0.06, "v": 0.2}],
	"close": [{"w": "sq", "f": 784, "d": 0.04, "v": 0.2}, {"w": "sq", "f": 523, "d": 0.06, "v": 0.2}],
	"eat": [
		{"w": "noise", "f": 3000, "d": 0.05, "v": 0.35}, {"w": "rest", "d": 0.08},
		{"w": "noise", "f": 2600, "d": 0.05, "v": 0.35}, {"w": "rest", "d": 0.08},
		{"w": "noise", "f": 2200, "d": 0.06, "v": 0.35},
	],
	"happy": [
		{"w": "sq", "f": 523, "d": 0.07, "v": 0.22}, {"w": "sq", "f": 659, "d": 0.07, "v": 0.22},
		{"w": "sq", "f": 784, "d": 0.07, "v": 0.22}, {"w": "sq", "f": 1047, "d": 0.14, "v": 0.22},
	],
	"refuse": [{"w": "sq", "f": 220, "f2": 150, "d": 0.2, "v": 0.25, "duty": 0.25}],
	"clean": [{"w": "noise", "f": 1800, "f2": 7000, "d": 0.3, "v": 0.22, "a": 0.05}],
	"lights": [{"w": "sq", "f": 1200, "d": 0.02, "v": 0.2}, {"w": "rest", "d": 0.03}, {"w": "sq", "f": 800, "d": 0.03, "v": 0.2}],
	"scold": [{"w": "sq", "f": 330, "d": 0.1, "v": 0.25}, {"w": "rest", "d": 0.04}, {"w": "sq", "f": 247, "d": 0.18, "v": 0.25}],
	"poop": [{"w": "tri", "f": 420, "f2": 110, "d": 0.2, "v": 0.5}],
	"call": [{"w": "sq", "f": 988, "d": 0.08, "v": 0.2}, {"w": "rest", "d": 0.06}, {"w": "sq", "f": 988, "d": 0.08, "v": 0.2}],
	"evolve": [
		{"w": "sq", "f": 523, "d": 0.06, "v": 0.2}, {"w": "sq", "f": 659, "d": 0.06, "v": 0.2},
		{"w": "sq", "f": 784, "d": 0.06, "v": 0.2}, {"w": "sq", "f": 1047, "d": 0.06, "v": 0.2},
		{"w": "sq", "f": 1319, "d": 0.06, "v": 0.2}, {"w": "sq", "f": 1568, "d": 0.06, "v": 0.2},
		{"w": "sq", "f": 2093, "d": 0.3, "v": 0.2},
	],
	"hatch": [
		{"w": "noise", "f": 4000, "d": 0.05, "v": 0.4}, {"w": "rest", "d": 0.1},
		{"w": "noise", "f": 3500, "d": 0.05, "v": 0.4}, {"w": "rest", "d": 0.12},
		{"w": "sq", "f": 784, "d": 0.08, "v": 0.22}, {"w": "sq", "f": 1047, "d": 0.08, "v": 0.22},
		{"w": "sq", "f": 1319, "d": 0.2, "v": 0.22},
	],
	"coin": [{"w": "sq", "f": 988, "d": 0.06, "v": 0.2}, {"w": "sq", "f": 1319, "d": 0.16, "v": 0.2}],
	"mistake": [{"w": "tri", "f": 392, "d": 0.12, "v": 0.45}, {"w": "tri", "f": 330, "d": 0.12, "v": 0.45}, {"w": "tri", "f": 262, "d": 0.22, "v": 0.45}],
	"death": [
		{"w": "tri", "f": 392, "d": 0.3, "v": 0.45}, {"w": "tri", "f": 349, "d": 0.3, "v": 0.45},
		{"w": "tri", "f": 330, "d": 0.3, "v": 0.45}, {"w": "tri", "f": 262, "d": 0.7, "v": 0.45},
	],
	"nap": [{"w": "tri", "f": 320, "f2": 200, "d": 0.35, "v": 0.35}],
	"buy": [{"w": "sq", "f": 659, "d": 0.05, "v": 0.2}, {"w": "sq", "f": 988, "d": 0.05, "v": 0.2}, {"w": "sq", "f": 1319, "d": 0.12, "v": 0.2}],
	"win": [
		{"w": "sq", "f": 784, "d": 0.08, "v": 0.22}, {"w": "sq", "f": 988, "d": 0.08, "v": 0.22},
		{"w": "sq", "f": 1175, "d": 0.08, "v": 0.22}, {"w": "sq", "f": 1568, "d": 0.24, "v": 0.22},
	],
	"lose": [{"w": "sq", "f": 392, "d": 0.12, "v": 0.2}, {"w": "sq", "f": 311, "d": 0.24, "v": 0.2}],
	"jump": [{"w": "sq", "f": 440, "f2": 880, "d": 0.09, "v": 0.18, "duty": 0.25}],
	"hit": [{"w": "noise", "f": 900, "d": 0.12, "v": 0.35}],
}

var enabled := true
var _cache := {}
var _players: Array = []
var _next := 0

func _ready() -> void:
	for i in 5:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)

func stream(name: String) -> AudioStream:
	if not _cache.has(name):
		_cache[name] = Synth.render(RECIPES.get(name, RECIPES.blip))
	return _cache[name]

func play(name: String) -> void:
	if not enabled or name == "":
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream(name)
	p.play()
