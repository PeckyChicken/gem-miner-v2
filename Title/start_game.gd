extends Button

const NODE_2D = preload("res://Game/Scenes/game.tscn")

@export var mode: Game.Mode = Game.Mode.survival

const CLICK = preload("res://assets/Sounds/Gameplay/click.wav")
var audio_player = AudioStreamPlayer.new()

func _ready() -> void:
	audio_player.stream = CLICK
	add_child(audio_player)

func _on_pressed() -> void:
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()
	var node = NODE_2D.instantiate()
	Game.current_mode = mode
	
	Music.stop(100000)
	await $"../../../../Fade".fade_in(0.5)
	get_tree().root.add_child(node)
	$"../../../..".queue_free()
