extends Node

enum Mode {
	survival,
	time_rush,
	obstacle,
	ascension
}

enum Preview {
	off,
	basic,
	advanced
}

var preview: Preview

var current_mode: Mode

var high_scores: Dictionary
