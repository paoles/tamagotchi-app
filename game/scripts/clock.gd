class_name Clock
extends RefCounted

# ============================================================
# The single source of "now", in unix seconds. The harness pins
# time with `fake_now`; the debug panel's time skip moves
# `debug_offset` (persisted in the save). Local-time helpers
# take the timezone bias explicitly so the sim can read it once
# per catch-up instead of once per simulated minute.
# ============================================================

static var fake_now := -1
static var debug_offset := 0
# Minutes east of UTC. `tz_pinned` lets the harness force UTC.
static var tz_pinned := false
static var tz_pinned_bias := 0

static func now() -> int:
	if fake_now >= 0:
		return fake_now
	return int(Time.get_unix_time_from_system()) + debug_offset

static func tz_bias() -> int:
	if tz_pinned:
		return tz_pinned_bias
	return int(Time.get_time_zone_from_system().get("bias", 0))

static func local_minute(unix: int, bias: int) -> int:
	return posmod(floori(unix / 60.0) + bias, 1440)

static func day_key(unix: int, bias: int) -> int:
	return floori((floori(unix / 60.0) + bias) / 1440.0)

# Bedtime window, which may wrap past midnight.
static func in_window(m: int, start: int, end: int) -> bool:
	if start == end:
		return false
	if start < end:
		return m >= start and m < end
	return m >= start or m < end

static func window_len(start: int, end: int) -> int:
	return posmod(end - start, 1440)

static func fmt_hm(m: int) -> String:
	return "%02d:%02d" % [posmod(m, 1440) / 60, posmod(m, 60)]

static func fmt_age(minutes: int) -> String:
	if minutes < 60:
		return "%d min" % minutes
	if minutes < 1440:
		return "%d h" % (minutes / 60)
	var d := minutes / 1440
	var h := (minutes % 1440) / 60
	return "%d d %d h" % [d, h] if h > 0 else "%d d" % d
