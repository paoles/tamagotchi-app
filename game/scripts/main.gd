extends Node

# ============================================================
# Pixel Pet bootstrap. Builds the game, audio and UI, wires them
# together and hands control to the player. Development modes:
#   -- sim          headless life checks (exit code = failures)
#   -- art [dir]    headless contact sheets of the generated art
#   -- snap [dir]   screenshots of every screen (needs a window)
# ============================================================

var game: Game
var ui: GameUI
var sfx: Sfx

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "sim" in args:
		var harness: RefCounted = load("res://scripts/harness/sim_harness.gd").new()
		get_tree().quit(harness.run())
		return
	if "art" in args:
		var art: RefCounted = load("res://scripts/harness/art_harness.gd").new()
		get_tree().quit(art.run(ProjectSettings.globalize_path(_arg_after(args, "art", "user://snaps/art"))))
		return
	var snapping := "snap" in args
	if snapping:
		SaveStore.disabled = true

	ScreensShop.register()
	ScreensMeta.register()
	game = Game.new()
	game.name = "Game"
	add_child(game)
	game.boot(snapping)

	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)

	var music := Music.new()
	music.name = "Music"
	add_child(music)

	ui = GameUI.new()
	ui.name = "UI"
	ui.game = game
	ui.sfx = sfx
	ui.music = music
	add_child(ui)

	if snapping:
		var snap: Node = load("res://scripts/harness/snap_harness.gd").new()
		snap.main = self
		snap.out_dir = ProjectSettings.globalize_path(_arg_after(args, "snap", "user://snaps"))
		add_child(snap)

func _arg_after(args: PackedStringArray, flag: String, fallback: String) -> String:
	var i := args.find(flag)
	if i >= 0 and i + 1 < args.size() and not String(args[i + 1]).begins_with("-"):
		return args[i + 1]
	return fallback
