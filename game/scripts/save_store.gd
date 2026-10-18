class_name SaveStore
extends RefCounted

# ============================================================
# Where the save lives. On every platform it goes to
# user://save.json (written atomically, previous copy kept as a
# backup). On the web, user:// is IndexedDB, so the JSON is also
# mirrored to localStorage; on load the newest copy wins.
# ============================================================

const PATH := "user://save.json"
const TMP := "user://save.tmp"
const BAK := "user://save.bak.json"
const LS_KEY := "pixelpet-save"

static var disabled := false   # the harnesses never touch real saves

static func write(save: Dictionary) -> void:
	if disabled:
		return
	save.saved_at = Clock.now()
	save.debug_offset = Clock.debug_offset
	var text := SaveState.to_json(save)
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
		if FileAccess.file_exists(PATH):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BAK))
		DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP), ProjectSettings.globalize_path(PATH))
	_mirror_web(text)

static func read() -> Dictionary:
	if disabled:
		return {}
	var best := {}
	for path in [PATH, BAK]:
		var d := _read_file(path)
		if not d.is_empty() and (best.is_empty() or int(d.saved_at) > int(best.saved_at)):
			best = d
	var web := _read_web()
	if not web.is_empty() and (best.is_empty() or int(web.saved_at) > int(best.saved_at)):
		best = web
	return best

static func clear() -> void:
	for path in [PATH, BAK, TMP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if OS.has_feature("web"):
		var ls: Variant = JavaScriptBridge.get_interface("localStorage")
		if ls != null:
			ls.removeItem(LS_KEY)

static func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	return SaveState.from_json(text)

static func _mirror_web(text: String) -> void:
	if not OS.has_feature("web"):
		return
	var ls: Variant = JavaScriptBridge.get_interface("localStorage")
	if ls != null:
		ls.setItem(LS_KEY, text)

static func _read_web() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var ls: Variant = JavaScriptBridge.get_interface("localStorage")
	if ls == null:
		return {}
	var text: Variant = ls.getItem(LS_KEY)
	if text == null or not (text is String):
		return {}
	return SaveState.from_json(text)
