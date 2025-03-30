extends Node

class_name cfg

@onready var _window_size = get_viewport().get_visible_rect().size
@onready var WINDOW_WIDTH = _window_size.x
@onready var WINDOW_HEIGHT = _window_size.y

var game_over = false
var first_time = false

var user_config = ConfigFile.new()

const DEFAULT_HIGH_SCORES = {
	Game.Mode.survival:0,
	Game.Mode.time_rush:0,
	Game.Mode.obstacle:0,
	Game.Mode.ascension:0,
}

func _ready() -> void:
	load_config()

func load_config(filepath="user://settings.cfg"):
	var err = user_config.load(filepath)
	if err != OK: #Defaults
		user_config.save(filepath)
		user_config.load(filepath)
	
	Music.volume = user_config.get_value("volume","music",0.25)
	Music.sfx_volume = user_config.get_value("volume","sfx",0.5)
	Game.high_scores = user_config.get_value("game","high_scores",DEFAULT_HIGH_SCORES.duplicate())
	Game.preview = user_config.get_value("game","previews",Game.Preview.basic)
	first_time = user_config.get_value("game","first_time",true)
	

func save_config(filepath="user://settings.cfg"):
	if len(Game.high_scores) > len(Game.Mode):
		for item in Game.high_scores.keys():
			if not Game.Mode.find_key(item):
				Game.high_scores.erase(item)
	user_config.clear()
	
	user_config.set_value("volume","music",Music.volume)
	user_config.set_value("volume","sfx",Music.sfx_volume)
	user_config.set_value("game","high_scores",Game.high_scores)
	user_config.set_value("game","previews",Game.preview)
	user_config.set_value("game","first_time",first_time)
	
	user_config.save(filepath)
