extends Node
class_name game_manager


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

enum Item {
	AIR,
	RUBY,
	TOPAZ,
	EMERALD,
	SAPPHIRE,
	RED_DIAMOND,
	YELLOW_DIAMOND,
	GREEN_DIAMOND,
	BLUE_DIAMOND,
	RAINBOW_DIAMOND,
	H_DRILL,
	V_DRILL,
	BOMB,
	BRICK,
	RED_BRICK,
	YELLOW_BRICK,
	GREEN_BRICK,
	BLUE_BRICK,
	CROSS
}

const GEMS = [Item.RUBY,Item.TOPAZ,Item.EMERALD,Item.SAPPHIRE]

const DRILLS = [Item.H_DRILL,Item.V_DRILL]

const DIAMONDS = [Item.RED_DIAMOND,Item.YELLOW_DIAMOND,Item.GREEN_DIAMOND,Item.BLUE_DIAMOND]

var GAME_TOOLS = [Item.H_DRILL,Item.V_DRILL,Item.BOMB] + DIAMONDS

const BRICKS = [Item.BRICK,Item.RED_BRICK,Item.YELLOW_BRICK,Item.GREEN_BRICK,Item.BLUE_BRICK]
const COLORED_BRICKS = [Item.RED_BRICK,Item.YELLOW_BRICK,Item.GREEN_BRICK,Item.BLUE_BRICK]

var preview: Preview

var current_mode: Mode

var high_scores: Dictionary
