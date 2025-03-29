extends Node

var playing = null

var track_cache: Dictionary[String,Dictionary] = {}
var sound_file_cache = {}

var players: Array[AudioStreamPlayer] = [AudioStreamPlayer.new(),AudioStreamPlayer.new()]

var current_player: int = 0

var path: String
var loop_start: float
var loop_end: float
var sound: Resource

var volume: float = 0.25
var sfx_volume: float = 0.5

var volume_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for player in players:
		player.volume_db = linear_to_db(volume)
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)

func play(track:String,fade_in:int=0):
	stop()
	var track_data: Dictionary
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
	if fade_in:
		await _tween_players(fade_in,0,volume)
	playing = track

func _tween_players(time,start,end):
	playing = null
	volume_tween = get_tree().create_tween()
	volume_tween.set_parallel()
		
	for player in players:
		player.volume_db = linear_to_db(start)
		
		volume_tween.tween_property(player,"volume_db",linear_to_db(end),time)
	#print(volume_tween.is_running())
	await volume_tween.finished
	

func stop(fade_out=0):
	if fade_out:
		await _tween_players(fade_out,volume,0)
	for player in players:
		player.stop()
	playing = null
	current_player = 0
	if volume_tween and volume_tween.is_running():
		volume_tween.stop()
	
func _process(_delta: float) -> void:
	if playing:
		players[current_player].volume_db = linear_to_db(volume)
		if players[current_player].get_playback_position() >= loop_end:
			current_player += 1
			current_player %= len(players)
			players[current_player].play(loop_start)
			
	
