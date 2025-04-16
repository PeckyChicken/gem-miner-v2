extends CanvasLayer

const OPTIONS_MENU = preload("res://Global/options_menu.tscn")
const HIGH_SCORE_MENU = preload("res://Global/high_scores.tscn")

var web := false

func _ready() -> void:
	get_viewport().size_changed.connect(update_size)
	
	if OS.get_name() in ["Web","HTML5"]:
		web = true
		$Close.queue_free()
	
	if Config.first_time:
		$MarginContainer/VBoxContainer/HBoxContainer/time_rush.disabled = true
		$MarginContainer/VBoxContainer/HBoxContainer2/obstacle.disabled = true
		$MarginContainer/VBoxContainer/HBoxContainer2/ascension.disabled = true
	
	await $"Fade".fade_out(0.5)
	Music.play("title")


func update_size() -> void:
	pass
	

func _on_pause_pressed() -> void:
	get_tree().paused = true
	var options_menu: OptionsMenu = OPTIONS_MENU.instantiate()
	options_menu.pause_menu = null
	add_child(options_menu)

func _on_high_score_pressed() -> void:
	get_tree().paused = true
	var high_score_menu: HighScores = HIGH_SCORE_MENU.instantiate()
	add_child(high_score_menu)

func _on_close_pressed() -> void:
	get_tree().quit()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		var menu = get_node_or_null("options_menu")
		var high_scores = get_node_or_null("high_score")
		if menu != null:
			get_tree().paused = false
			menu.queue_free()
		elif high_scores != null:
			get_tree().paused = false
			high_scores.queue_free()
		else:
			if not web:
				get_tree().quit()
