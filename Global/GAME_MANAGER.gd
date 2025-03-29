extends Node

enum Mode {
	survival,
	time_rush,
	obstacle,
	chromablitz,
	ascension
}

enum Preview {
	off,
	basic,
	advanced
}

var preview = Preview.basic

var current_mode = Mode.survival
