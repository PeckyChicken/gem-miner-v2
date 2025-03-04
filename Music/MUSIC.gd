extends Node

var playing = null

var track_cache = {}
var sound_file_cache = {}

var players: Array[AudioStreamPlayer] = [AudioStreamPlayer.new(),AudioStreamPlayer.new()]

var current_player = 0

var path: String
var loop_start: float
var loop_end: float
var sound: Resource

var volume = 0.25

func _ready() -> void:
	for player in players:
		player.volume_db = linear_to_db(volume)
		add_child(player)

func play(track:String):
	stop()
	var track_data
	if track in track_cache:
		track_data = track_cache[track]
	else:
		var config_file = load("res://Music/%s.json" % [track])
		track_data = config_file.data
		track_cache[track] = track_data
	
	path = track_data["path"]
	loop_start = track_data["loop_start"]
	loop_end = track_data["loop_end"]
	
	if path in sound_file_cache:
		sound = sound_file_cache[path]
	else:
		sound = load(path)
		sound_file_cache[path] = sound
	
	for player in players:
		player.stream = sound
	
	players[0].play()
	playing = track
	
	
func stop():
	for player in players:
		player.stop()
	playing = null
	current_player = 0
	
func _process(_delta: float) -> void:
	if playing:
		players[current_player].volume_db = linear_to_db(volume)
		if players[current_player].get_playback_position() >= loop_end:
			current_player += 1
			current_player %= len(players)
			players[current_player].play(loop_start)
			
	
