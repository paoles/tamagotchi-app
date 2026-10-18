class_name Pal
extends RefCounted

# ============================================================
# The pastel palette. Single characters name colours inside
# pixel grids; "." is transparent. Form recipes add their own
# body colours on the digit keys 1/2/3 (main/shade/light) and
# a/A, b/B (accent and its shade).
# ============================================================

const C := {
	"k": Color("5a4a6a"),   # outline plum
	"K": Color("3b3047"),   # eyes, deepest
	"w": Color("fffaf4"),   # white
	"W": Color("ffffff"),   # pure highlight
	"c": Color("fbe9d7"),   # cream
	"C": Color("eccfb4"),   # cream shade
	"p": Color("f4a7b9"),   # pink
	"P": Color("e07a98"),   # deep pink
	"m": Color("a8e0c8"),   # mint
	"M": Color("6cbfa0"),   # deep mint
	"l": Color("c9b6e4"),   # lilac
	"L": Color("9a84c4"),   # deep lilac
	"y": Color("fbe38e"),   # butter
	"Y": Color("f0c050"),   # gold
	"b": Color("a9d4f5"),   # sky
	"B": Color("6aa6dc"),   # deep sky
	"o": Color("fbc4a0"),   # peach
	"O": Color("f09a70"),   # deep peach
	"g": Color("e2dae2"),   # light grey
	"G": Color("a89cae"),   # grey
	"r": Color("ef7d7d"),   # red
	"R": Color("c95561"),   # deep red
	"n": Color("c89878"),   # wood
	"N": Color("9c6c50"),   # deep wood
	"d": Color("8fcf7a"),   # leaf green
	"D": Color("5aa25a"),   # deep leaf
	"s": Color("8a7a9a"),   # soft shadow
}

# UI colours
const BG := Color("fdf4ec")
const INK := Color("5a4a6a")
const INK_SOFT := Color("8a7a9a")
const PANEL := Color("fffaf4")
const PANEL_ALT := Color("f6eadf")
const ACCENT := Color("f4a7b9")
const ACCENT_DEEP := Color("e07a98")
const MINT := Color("a8e0c8")
const BUTTER := Color("fbe38e")
const SKY := Color("a9d4f5")
const LILAC := Color("c9b6e4")
const GOOD := Color("6cbfa0")
const WARN := Color("f0c050")
const BAD := Color("ef7d7d")
const SHADE := Color(0.23, 0.19, 0.28, 0.55)
