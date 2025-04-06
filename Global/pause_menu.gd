extends Control
class_name PauseMenu

const OPTIONS_MENU: Resource = preload("res://Global/options_menu.tscn")
var options_menu: OptionsMenu

func _ready() -> void:
	$AnimationPlayer.play("pause")

func _on_resume_pressed() -> void:
	Events.PlaySound.emit("Gameplay/click")
	Events.Resume.emit()

func _on_quit_pressed() -> void:
	Events.PlaySound.emit("Gameplay/click")
	Events.Quit.emit()
	Events.Resume.emit()

func _on_options_pressed() -> void:
	Events.PlaySound.emit("Gameplay/click")
	options_menu = OPTIONS_MENU.instantiate()
	get_parent().add_child(options_menu)
	options_menu.pause_menu = self
	hide()
