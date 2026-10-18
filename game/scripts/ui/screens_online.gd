class_name ScreensOnline
extends RefCounted

# ============================================================
# Settings rows for notifications, install, cloud backup and
# moving to another device, plus debug buttons for push.
# ============================================================

static var online: Online

static func register(o: Online) -> void:
	online = o
	Screens.EXTRA["settings_online"] = _settings
	Screens.EXTRA["debug_online"] = _debug

static func _settings(ui: GameUI) -> Control:
	var v := Kit.vbox(8)
	var st: Dictionary = ui.game.save.settings
	v.add_child(Kit.label(S.t("set_push"), Kit.FONT, Pal.INK_SOFT))
	if not online.active:
		v.add_child(Kit.para("Notifications and cloud backup work in the web app.", Kit.FONT, Pal.INK_SOFT))
		return v
	var push_box := Kit.vbox(6)
	v.add_child(push_box)
	var refresh := func(_r: Callable) -> void:
		pass
	refresh = func(self_ref: Callable) -> void:
		ScreensShop._clear(push_box)
		if not WebBridge.flag("push"):
			var msg := S.t("set_push_unsupported")
			if WebBridge.flag("ios") and not WebBridge.flag("standalone"):
				msg = "On iPhone and iPad: tap Share, then Add to Home Screen, and open Pixel Pet from there to get notifications."
			push_box.add_child(Kit.para(msg, Kit.FONT, Pal.INK_SOFT))
		elif online.push_on():
			push_box.add_child(Kit.row(S.t("set_push_on"), "", "check"))
			for cat in Cfg.PUSH_CATEGORIES:
				var c: String = cat
				push_box.add_child(Kit.toggle(S.t("push_" + c), st.push.get(c, false), func(on: bool) -> void:
					st.push[c] = on
					ui.game.persist()
					online.schedule()))
			push_box.add_child(Kit.button("Turn notifications off", func() -> void:
				online.disable_push(func() -> void:
					ui.toast("Notifications off", "mute")
					self_ref.call(self_ref)), "mute"))
		else:
			push_box.add_child(Kit.para("Get a nudge when your pet needs you. Quiet while it sleeps.", Kit.FONT, Pal.INK_SOFT))
			push_box.add_child(Kit.accent(Kit.button(S.t("set_push_enable"), func() -> void:
				online.enable_push(func(ok: bool, msg: String) -> void:
					ui.toast(msg, "check" if ok else "cross")
					if ok:
						ui.sfx.play("happy")
					self_ref.call(self_ref)), "alert"), Pal.BUTTER))
		if WebBridge.flag("install"):
			push_box.add_child(Kit.button("Install Pixel Pet", func() -> void:
				WebBridge.prompt_install(func(_r: Dictionary) -> void: self_ref.call(self_ref)), "plus"))
	refresh.call(refresh)

	v.add_child(Kit.label(S.t("set_backup"), Kit.FONT, Pal.INK_SOFT))
	var last := int(ui.game.save.get("last_backup", 0))
	var when := "never" if last == 0 else Time.get_datetime_string_from_unix_time(last + Clock.tz_bias() * 60, true).substr(0, 16)
	var last_l := Kit.label("Last backup: %s" % when, Kit.FONT, Pal.INK_SOFT)
	v.add_child(last_l)
	v.add_child(Kit.button("Back up now", func() -> void:
		online.backup(func(r: Dictionary) -> void:
			ui.toast("Backed up!" if r.get("ok", false) else "Backup failed. Are you online?", "check" if r.get("ok", false) else "cross")
			if r.get("ok", false):
				last_l.text = "Last backup: just now"), "cloud"))
	v.add_child(Kit.button("Get a transfer code", func() -> void:
		online.create_transfer(func(r: Dictionary) -> void:
			if r.get("ok", false):
				_show_code(ui, String(r.data.code))
			else:
				ui.toast("Couldn't make a code. Are you online?", "cross")), "gift"))
	v.add_child(Kit.button("Enter a transfer code", func() -> void:
		var code := WebBridge.prompt_text("Enter the 6-character code from your other device")
		if code.strip_edges() == "":
			return
		online.redeem(code, func(ok: bool, msg: String) -> void:
			ui.close_sheet()
			ui.toast(msg, "heart" if ok else "cross")), "right"))
	return v

static func _show_code(ui: GameUI, code: String) -> void:
	var v := Kit.vbox(10)
	v.add_child(Kit.para("On your other device, open Settings → Enter a transfer code. The code works once, for 24 hours. Your pet moves with it, so stop playing here.", Kit.FONT, Pal.INK_SOFT))
	v.add_child(Kit.label(code, 32, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.accent(Kit.button(S.t("ok"), ui.close_sheet), Pal.MINT))
	ui.open("Transfer code", v, true, true, "gift")

static func _debug(ui: GameUI) -> Control:
	var v := Kit.vbox(6)
	v.add_child(Kit.label("Online", Kit.FONT, Pal.INK_SOFT))
	var alerts := Forecast.alerts(ui.game.save)
	var lines := []
	for a in alerts:
		lines.append("%s %s" % [Clock.fmt_hm(Clock.local_minute(int(a.at), Clock.tz_bias())), a.key])
	v.add_child(Kit.para("Next alerts: " + (", ".join(lines) if not lines.is_empty() else "none"), Kit.FONT, Pal.INK_SOFT))
	var g := ScreensShop._grid(2)
	var b1 := Kit.button("Test push", func() -> void:
		online.test_push(func(r: Dictionary) -> void:
			ui.toast("Sent!" if r.get("ok", false) else "Failed: %s" % r.get("data", {}).get("error", r.get("status", "?")), "alert")))
	var b2 := Kit.button("Schedule now", func() -> void:
		online.schedule(func(r: Dictionary) -> void:
			ui.toast("Scheduled %s" % str(r.get("data", {}).get("scheduled", "?")) if r.get("ok", false) else "Failed", "alert")))
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(b1)
	g.add_child(b2)
	v.add_child(g)
	return v
