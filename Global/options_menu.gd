extends CanvasLayer
class_name OptionsMenu

var pause_menu: PauseMenu

const CLICK = preload("res://assets/Sounds/Gameplay/click.wav")
var audio_player = AudioStreamPlayer.new()

func _ready() -> void:
	create_dropdowns()
	audio_player.stream = CLICK
	add_child(audio_player)

	update_values()

func create_dropdowns():
	var preview_options: OptionButton = find_child("PreviewSelect")
	preview_options.clear()
	for item in Game.Preview.keys():
		preview_options.add_item(TranslationServer.translate("preview_"+item))
	
	var language_options: OptionButton = find_child("LanguageSelect")
	language_options.clear()
	for item in Config.SupportedLanguages.keys():
		language_options.add_item(TranslationServer.translate(item))

func update_values():
	
	find_child("MusicSlider").value = Music.volume * 100
	find_child("MusicPercentage").text = "%s%%" % [str(int(find_child("MusicSlider").value))]
	find_child("SfxSlider").value = Music.sfx_volume * 100
	find_child("SfxPercentage").text = "%s%%" % [str(int(find_child("SfxSlider").value))]
	
	find_child("PreviewSelect").select(Game.preview)
	
	find_child("LanguageSelect").select(Config.SupportedLanguages[Config.language])
	
	Config.save_config()

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
	Game.preview = index as Game.Preview
	update_values()
	
func _on_language_item_selected(index: int) -> void:
	Config.language = Config.SupportedLanguages.keys()[index]
	TranslationServer.set_locale(Config.language)
	Events.LanguageChanged.emit(Config.language)
	create_dropdowns()
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
