class_name Online
extends Node

# ============================================================
# Everything that talks to the server: push notifications planned
# from the forecast, the anonymous cloud backup and transfer
# codes. Only active in the web build. Plans and backups are sent
# when the page is hidden (as beacons, so they survive the tab
# closing) and periodically while it stays open.
# ============================================================

signal status(text: String)

const SCHEDULE_EVERY := 600.0
const BACKUP_EVERY := 1800.0

var game: Game
var active := false
var _sched_t := 30.0
var _backup_t := 120.0

func _ready() -> void:
	active = WebBridge.available()
	if not active:
		return
	WebBridge.on_hidden(_on_hidden)
	if WebBridge.flag("push") and String(game.save.settings.get("vapid", "")) == "":
		fetch_key(func(_ok: bool) -> void: pass)

func _process(delta: float) -> void:
	if not active:
		return
	_sched_t -= delta
	_backup_t -= delta
	if _sched_t <= 0.0:
		_sched_t = SCHEDULE_EVERY
		schedule()
	if _backup_t <= 0.0:
		_backup_t = BACKUP_EVERY
		backup(func(_r: Dictionary) -> void: pass)

func creds() -> Dictionary:
	return {"deviceId": game.save.device.id, "secret": game.save.device.secret}

func _with(extra: Dictionary) -> Dictionary:
	var d := creds()
	d.merge(extra, true)
	return d

func push_on() -> bool:
	return active and game.save.settings.push_enabled and WebBridge.permission() == "granted"

# --- Push ----------------------------------------------------------

func fetch_key(done: Callable) -> void:
	WebBridge.api("/api/push/key", {}, func(r: Dictionary) -> void:
		var key := String(r.get("data", {}).get("key", ""))
		if r.get("ok", false) and key != "":
			game.save.settings.vapid = key
			game.persist()
		done.call(key != ""))

# Must be called straight from a tap so the browser allows the prompt.
func enable_push(done: Callable) -> void:
	var key := String(game.save.settings.get("vapid", ""))
	if key == "":
		fetch_key(func(ok: bool) -> void:
			done.call(false, "Couldn't reach the server. Try again." if not ok else "Tap again to turn on."))
		return
	WebBridge.enable_push(key, func(r: Dictionary) -> void:
		if not r.get("ok", false):
			var why := String(r.get("why", ""))
			done.call(false, "Notifications are blocked in your browser settings." if why == "denied" else "Couldn't turn on notifications (%s)." % why)
			return
		WebBridge.api("/api/push/subscribe", _with({"subscription": r.subscription}), func(s: Dictionary) -> void:
			if s.get("ok", false):
				game.save.settings.push_enabled = true
				game.persist()
				schedule()
				done.call(true, "Notifications are on!")
			else:
				done.call(false, "The server didn't accept the subscription.")))

func disable_push(done: Callable) -> void:
	game.save.settings.push_enabled = false
	game.persist()
	WebBridge.api("/api/push/schedule", _with({"alerts": []}), func(_r: Dictionary) -> void: pass)
	WebBridge.api("/api/push/subscribe", _with({"unsubscribe": true}), func(_r: Dictionary) -> void: pass)
	WebBridge.disable_push(func(_r: Dictionary) -> void: done.call())

func alerts_payload() -> Array:
	var out := []
	for a in Forecast.alerts(game.save):
		out.append({"at": int(a.at), "title": a.title, "body": a.body, "tag": a.tag})
	return out

func schedule(done: Callable = Callable()) -> void:
	if not push_on():
		return
	game.step()
	var payload := _with({"alerts": alerts_payload()})
	WebBridge.api("/api/push/schedule", payload, func(r: Dictionary) -> void:
		if done.is_valid():
			done.call(r))

func test_push(done: Callable) -> void:
	WebBridge.api("/api/push/test", creds(), done)

# --- Backup ----------------------------------------------------------

func backup(done: Callable) -> void:
	if not active:
		done.call({"ok": false})
		return
	game.persist()
	var payload := _with({"save": SaveState.to_json(game.save), "savedAt": int(game.save.saved_at)})
	WebBridge.api("/api/backup", payload, func(r: Dictionary) -> void:
		if r.get("ok", false):
			game.save.last_backup = Clock.now()
		done.call(r))

func create_transfer(done: Callable) -> void:
	backup(func(b: Dictionary) -> void:
		if not b.get("ok", false):
			done.call({"ok": false, "data": {"error": "backup failed"}})
			return
		WebBridge.api("/api/transfer/create", creds(), done))

func redeem(code: String, done: Callable) -> void:
	WebBridge.api("/api/transfer/redeem", {"code": code}, func(r: Dictionary) -> void:
		if not r.get("ok", false):
			done.call(false, String(r.get("data", {}).get("error", "That code didn't work.")))
			return
		var loaded := SaveState.from_json(String(r.data.get("save", "")))
		if loaded.is_empty():
			done.call(false, "The backup couldn't be read.")
			return
		SaveStore.write(loaded)
		game.boot()
		done.call(true, "Welcome back, %s!" % game.pet_name()))

func _on_hidden() -> void:
	game.persist()
	if push_on():
		game.step()
		WebBridge.beacon("/api/push/schedule", _with({"alerts": alerts_payload()}))
	# Beacons can't report success, so only throttle on the attempt;
	# `last_backup` is set when a backup is confirmed.
	if Clock.now() - int(game.save.get("backup_try", 0)) > 600:
		game.save.backup_try = Clock.now()
		WebBridge.beacon("/api/backup", _with({"save": SaveState.to_json(game.save), "savedAt": int(game.save.saved_at)}))
