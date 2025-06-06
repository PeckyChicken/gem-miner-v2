extends Node2D

var sound_cache = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.PlaySound.connect(play_sound)

func play_sound(path,pitch_variation=0,starting_pitch=1):
	var temp_player: AudioStreamPlayer = $AudioStreamPlayer.duplicate()
	temp_player.pitch_scale = randf_range(starting_pitch-pitch_variation,starting_pitch+pitch_variation)
	var sound: Resource
	if path in sound_cache:
		sound = sound_cache[path]
	else:
		sound = load("res://assets/Sounds/%s.wav" % [path])
		sound_cache[path] = sound
	temp_player.stream = sound
	add_child(temp_player)
	temp_player.volume_db = linear_to_db(Music.sfx_volume)
	temp_player.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
