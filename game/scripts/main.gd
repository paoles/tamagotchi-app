extends Node

# ============================================================
# Pixel Pet bootstrap. `-- sim` runs the headless life checks
# and quits with the failure count; otherwise the game boots.
# ============================================================

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "sim" in args:
		var harness: RefCounted = load("res://scripts/harness/sim_harness.gd").new()
		get_tree().quit(harness.run())
		return
