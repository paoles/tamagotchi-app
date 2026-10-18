class_name Music
extends Node

# ============================================================
# Chiptune background music. Songs are written as step strings
# (one token per 8th note: a note like C5, "-" holds, "." rests)
# for a square lead, a triangle bass and noise drums. Each song
# is rendered once, a few thousand samples per frame so the web
# build never freezes, then loops. Day, night and game themes
# switch with the pet's situation.
# ============================================================

const RATE := 11025
const SONGS := {
	"day": {
		"bpm": 118,
		"lead": "E5 . G5 . C6 - B5 A5 G5 - E5 . D5 E5 C5 . F5 . A5 . C6 - B5 A5 G5 - - - . . . . E5 . G5 . C6 - D6 C6 B5 - G5 . A5 B5 C6 . A5 . F5 . G5 . E5 D5 C5 - - - . . . .",
		"bass": "C3 . G3 . C3 . G3 . C3 . G3 . E3 . G3 . F3 . C4 . F3 . C4 . G3 . D4 . G3 . B3 . C3 . G3 . C3 . G3 . E3 . B3 . E3 . G3 . F3 . C4 . G3 . B3 . C3 . G3 . C3 - - .",
		"drums": "k . h . k k h . k . h . k k h . k . h . k k h . k . h . k . h h k . h . k k h . k . h . k k h . k . h . k k h . k . h . k . . .",
		"lead_wave": "sq", "lead_duty": 0.25, "lead_vol": 0.16, "bass_vol": 0.32, "drum_vol": 0.07,
	},
	"night": {
		"bpm": 76,
		"lead": "A4 - C5 - E5 - D5 C5 B4 - - - G4 - - - A4 - C5 - E5 - G5 F5 E5 - - - - - . . F4 - A4 - C5 - B4 A4 G4 - B4 - D5 - C5 B4 A4 - E5 - D5 - C5 B4 A4 - - - - - . .",
		"bass": "A2 . E3 . A2 . E3 . G2 . D3 . G2 . D3 . F2 . C3 . F2 . C3 . E2 . B2 . E2 . B2 . D3 . A3 . D3 . A3 . G2 . D3 . G2 . D3 . F2 . C3 . E2 . B2 . A2 . E3 . A2 - - .",
		"drums": "",
		"lead_wave": "tri", "lead_duty": 0.5, "lead_vol": 0.3, "bass_vol": 0.22, "drum_vol": 0.0,
	},
	"game": {
		"bpm": 150,
		"lead": "C5 E5 G5 E5 C6 . G5 . A5 C6 E6 C6 A5 . G5 . F5 A5 C6 A5 G5 . E5 . D5 E5 F5 D5 C5 . . .",
		"bass": "C3 . C4 . C3 . C4 . A2 . A3 . A2 . A3 . F2 . F3 . G2 . G3 . C3 . G2 . C3 . . .",
		"drums": "k h h h k h k h k h h h k h k h k h h h k h k h k h k h k . . .",
		"lead_wave": "sq", "lead_duty": 0.5, "lead_vol": 0.13, "bass_vol": 0.3, "drum_vol": 0.08,
	},
}

var enabled := true
var current := ""
var wanted := ""
var _player: AudioStreamPlayer
var _streams := {}
var _job: Dictionary = {}     # song being rendered in slices

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -10.0
	add_child(_player)

func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		_player.stop()
		current = ""
	elif wanted != "":
		var w := wanted
		wanted = ""
		want(w)

func want(song: String) -> void:
	if song == wanted:
		return
	wanted = song
	if not enabled:
		return
	if _streams.has(song):
		_start(song)
	elif _job.is_empty() or _job.song != song:
		_job = _new_job(song)

func _start(song: String) -> void:
	if current == song and _player.playing:
		return
	current = song
	_player.stream = _streams[song]
	_player.play()

func _process(_delta: float) -> void:
	if _job.is_empty():
		return
	var budget := 6000
	while budget > 0 and not _job.is_empty():
		budget -= _render_slice(_job, 2000)
		if _job.done:
			var song: String = _job.song
			_streams[song] = Synth.to_wav(_job.out, RATE, true)
			_job = {}
			if wanted == song and enabled:
				_start(song)

# --- Rendering ---------------------------------------------------

static func note_hz(name: String) -> float:
	const SEMI := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var n: int = SEMI[name[0]]
	var i := 1
	if name.length() > 2 and name[1] == "#":
		n += 1
		i = 2
	var octave := int(name.substr(i))
	var midi := (octave + 1) * 12 + n
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

# Turns a step string into a flat list of notes, merging holds.
static func parse(steps: String, step_s: float, wave: String, vol: float, duty: float) -> Array:
	var out := []
	if steps.strip_edges() == "":
		return out
	for tok in steps.split(" ", false):
		if tok == "-" and not out.is_empty():
			out[-1].d += step_s
		elif tok == "." or tok == "-":
			out.append({"w": "rest", "d": step_s})
		elif tok == "k":
			out.append({"w": "noise", "f": 400.0, "d": step_s, "v": vol * 1.6, "r": step_s * 0.9})
		elif tok == "h":
			out.append({"w": "noise", "f": 6000.0, "d": step_s, "v": vol * 0.7, "r": step_s * 0.5})
		else:
			out.append({"w": wave, "f": note_hz(tok), "d": step_s, "v": vol, "duty": duty, "a": 0.01, "r": step_s * 0.7})
	return out

func _new_job(song: String) -> Dictionary:
	var s: Dictionary = SONGS[song]
	var step_s := 60.0 / float(s.bpm) / 2.0
	var voices := [
		parse(s.lead, step_s, s.lead_wave, s.lead_vol, s.lead_duty),
		parse(s.bass, step_s, "tri", s.bass_vol, 0.5),
		parse(s.drums, step_s, "noise", s.drum_vol, 0.5),
	]
	var total := 0
	for n in voices[0]:
		total += int(n.d * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	return {"song": song, "voices": voices, "out": out, "voice": 0, "note": 0, "pos": 0, "sample": 0, "phase": 0.0, "lfsr": 0x7ACE, "nv": 1.0, "np": 0.0, "done": false}

# Renders up to `budget` samples of the current job; returns how
# many it rendered.
func _render_slice(job: Dictionary, budget: int) -> int:
	var done := 0
	var out: PackedFloat32Array = job.out
	job.out = PackedFloat32Array()   # drop the second reference so writes don't copy
	while done < budget:
		var voices: Array = job.voices
		if job.voice >= voices.size():
			job.done = true
			job.out = out
			return done
		var notes: Array = voices[job.voice]
		if job.note >= notes.size():
			job.voice += 1
			job.note = 0
			job.pos = 0
			job.sample = 0
			job.phase = 0.0
			continue
		var n: Dictionary = notes[job.note]
		var count := int(float(n.d) * RATE)
		var w: String = n.w
		var f: float = n.get("f", 0.0)
		var vol: float = n.get("v", 0.0)
		var duty: float = n.get("duty", 0.5)
		var att: float = n.get("a", 0.004)
		var rel: float = n.get("r", float(n.d) * 0.6)
		while job.sample < count and done < budget:
			var i: int = job.sample
			var idx: int = job.pos + i
			if w != "rest" and idx < out.size():
				var t := float(i) / RATE
				var env := minf(1.0, t / att)
				var left := float(n.d) - t
				if left < rel:
					env *= maxf(0.0, left / rel)
				var s := 0.0
				var ph: float = job.phase
				match w:
					"sq":
						s = 1.0 if ph < duty else -1.0
					"tri":
						s = 4.0 * absf(ph - 0.5) - 1.0
					"noise":
						job.np += f / RATE
						if job.np >= 1.0:
							job.np -= floorf(job.np)
							var lf: int = job.lfsr
							var bit := (lf ^ (lf >> 1)) & 1
							lf = (lf >> 1) | (bit << 14)
							job.lfsr = lf
							job.nv = 1.0 if (lf & 1) == 1 else -1.0
						s = job.nv
				ph += f / RATE
				job.phase = ph - floorf(ph)
				out[idx] += s * vol * env
			job.sample = i + 1
			done += 1
		if job.sample >= count:
			job.pos += count
			job.note += 1
			job.sample = 0
	job.out = out
	return done
