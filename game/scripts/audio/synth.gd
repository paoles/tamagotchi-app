class_name Synth
extends RefCounted

# ============================================================
# A tiny 8-bit synthesizer that renders straight to
# AudioStreamWAV buffers (no streaming generators, which stutter
# in single-threaded web builds). A sound is a list of notes
# played in sequence:
#   {w: "sq"|"tri"|"saw"|"noise"|"rest", f: Hz, f2: end Hz,
#    d: seconds, v: volume, duty: square duty, a: attack s}
# `mix()` sums several voices of the same length (for music).
# ============================================================

const RATE := 22050

static func voice(notes: Array, rate: int = RATE) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var phase := 0.0
	var lfsr := 0x7ACE
	var noise_val := 1.0
	var noise_phase := 0.0
	for n in notes:
		var w: String = n.get("w", "sq")
		var d: float = n.get("d", 0.1)
		var count := int(d * rate)
		var start := out.size()
		out.resize(start + count)
		if w == "rest":
			continue
		var f1: float = n.get("f", 440.0)
		var f2: float = n.get("f2", f1)
		var vol: float = n.get("v", 0.5)
		var duty: float = n.get("duty", 0.5)
		var att: float = n.get("a", 0.004)
		var rel: float = n.get("r", d * 0.6)
		for i in count:
			var t := float(i) / rate
			var f := lerpf(f1, f2, float(i) / count)
			var env := minf(1.0, t / maxf(att, 0.0001))
			var left := d - t
			if left < rel:
				env *= maxf(0.0, left / rel)
			var s := 0.0
			match w:
				"sq":
					s = 1.0 if phase < duty else -1.0
				"tri":
					s = 4.0 * absf(phase - 0.5) - 1.0
				"saw":
					s = 2.0 * phase - 1.0
				"noise":
					noise_phase += f / rate
					if noise_phase >= 1.0:
						noise_phase -= floorf(noise_phase)
						var bit := (lfsr ^ (lfsr >> 1)) & 1
						lfsr = (lfsr >> 1) | (bit << 14)
						noise_val = 1.0 if (lfsr & 1) == 1 else -1.0
					s = noise_val
			phase += f / rate
			phase -= floorf(phase)
			out[start + i] = s * vol * env
	return out

static func to_wav(samples: PackedFloat32Array, rate: int = RATE, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s

static func render(notes: Array) -> AudioStreamWAV:
	return to_wav(voice(notes))

static func mix(voices: Array, gains: Array) -> PackedFloat32Array:
	var n := 0
	for v in voices:
		n = maxi(n, v.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for vi in voices.size():
		var v: PackedFloat32Array = voices[vi]
		var g: float = gains[vi]
		for i in v.size():
			out[i] += v[i] * g
	return out
