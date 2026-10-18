class_name WebBridge
extends RefCounted

# ============================================================
# Thin wrapper over window.PixelPet (web-static/pixelpet.js).
# Async calls take a GDScript Callable that receives a parsed
# Dictionary. Everything returns harmlessly off the web.
# ============================================================

static var _pp: JavaScriptObject = null
static var _keep: Array = []   # JS callbacks must stay referenced until called

static func available() -> bool:
	return _iface() != null

static func _iface() -> JavaScriptObject:
	if not OS.has_feature("web"):
		return null
	if _pp == null:
		_pp = JavaScriptBridge.get_interface("PixelPet")
	return _pp

static func _cb(done: Callable) -> JavaScriptObject:
	var js := JavaScriptBridge.create_callback(func(args: Array) -> void:
		var parsed: Variant = JSON.parse_string(String(args[0]) if args.size() > 0 else "{}")
		done.call(parsed if parsed is Dictionary else {}))
	_keep.append(js)
	if _keep.size() > 40:
		_keep.pop_front()
	return js

static func flag(method: String) -> bool:
	var pp := _iface()
	if pp == null:
		return false
	match method:
		"push": return bool(pp.pushSupported())
		"standalone": return bool(pp.isStandalone())
		"ios": return bool(pp.isIOS())
		"install": return bool(pp.canInstall())
	return false

static func permission() -> String:
	var pp := _iface()
	return String(pp.pushPermission()) if pp != null else "unsupported"

static func api(path: String, payload: Dictionary, done: Callable) -> void:
	var pp := _iface()
	if pp == null:
		done.call({"ok": false, "status": 0, "data": {"error": "offline"}})
		return
	pp.api(path, JSON.stringify(payload), _cb(done), false)

static func beacon(path: String, payload: Dictionary) -> void:
	var pp := _iface()
	if pp != null:
		pp.beacon(path, JSON.stringify(payload))

static func enable_push(vapid_key: String, done: Callable) -> void:
	var pp := _iface()
	if pp == null:
		done.call({"ok": false, "why": "unsupported"})
		return
	pp.enablePush(vapid_key, _cb(done))

static func disable_push(done: Callable) -> void:
	var pp := _iface()
	if pp == null:
		done.call({"ok": true})
		return
	pp.disablePush(_cb(done))

static func on_hidden(cb: Callable) -> void:
	var pp := _iface()
	if pp == null:
		return
	var js := JavaScriptBridge.create_callback(func(_args: Array) -> void: cb.call())
	_keep.append(js)
	pp.onHidden(js)

static func prompt_install(done: Callable) -> void:
	var pp := _iface()
	if pp != null:
		pp.promptInstall(_cb(done))

static func prompt_text(message: String, fallback: String = "") -> String:
	var pp := _iface()
	if pp == null:
		return ""
	return String(pp.promptText(message, fallback))

static func vibrate(ms: int) -> void:
	var pp := _iface()
	if pp != null:
		pp.vibrate(ms)
