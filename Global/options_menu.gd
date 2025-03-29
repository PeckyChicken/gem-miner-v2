extends Control
class_name OptionsMenu

var pause_menu: PauseMenu

const CLICK = preload("res://assets/Sounds/Gameplay/click.wav")
var audio_player = AudioStreamPlayer.new()

func _ready() -> void:
	audio_player.stream = CLICK
	add_child(audio_player)

	update_values()

func update_values():
	$VBoxContainer/Music/Slider.value = Music.volume * 100
	$VBoxContainer/Music/Percentage.text = "%s%%" % [str(int($VBoxContainer/Music/Slider.value))]
	$VBoxContainer/Sfx/Slider.value = Music.sfx_volume * 100
	$VBoxContainer/Sfx/Percentage.text = "%s%%" % [str(int($VBoxContainer/Sfx/Slider.value))]
	
	$VBoxContainer/Previews/OptionButton.select(Game.preview)

func _on_music_value_changed(value: float) -> void:
	Music.volume = value / 100
	update_values()
	
func _on_music_pressed() -> void:
	Music.volume = 0
	update_values()
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()

func _on_sfx_value_changed(value: float) -> void:
	Music.sfx_volume = value / 100
	update_values()
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()

func _on_sfx_pressed() -> void:
	Music.sfx_volume = 0
	update_values()
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()

func _on_preview_item_selected(index: int) -> void:
	Game.preview = index
	update_values()

func _on_return_pressed() -> void:
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()
	hide()
	if pause_menu:
		pause_menu.show()
	else:
		get_tree().paused = false
		await audio_player.finished
	queue_free()
