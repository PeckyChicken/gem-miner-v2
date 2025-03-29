extends Node2D

const OPTIONS_MENU = preload("res://Global/options_menu.tscn")

func _ready() -> void:

	await $"Fade".fade_out(0.5)
	Music.play("title")

func _on_pause_pressed() -> void:
	get_tree().paused = true
	var options_menu: OptionsMenu = OPTIONS_MENU.instantiate()
	options_menu.pause_menu = null
	add_child(options_menu)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		var menu = get_node_or_null("options_menu")
		print(menu)
		if menu:
			get_tree().paused = false
			menu.queue_free()
		else:
			get_tree().quit()
