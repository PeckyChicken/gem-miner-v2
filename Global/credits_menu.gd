extends CanvasLayer

class_name Credits

const CLICK = preload("res://assets/Sounds/Gameplay/click.wav")
var audio_player = AudioStreamPlayer.new()

func _ready() -> void:
	audio_player.stream = CLICK
	add_child(audio_player)
	
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()

func _on_return_pressed() -> void:
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()
	hide()
	get_tree().paused = false
	await audio_player.finished
	queue_free()
