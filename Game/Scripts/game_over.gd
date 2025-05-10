extends CenterContainer

@onready var root: CanvasLayer = $".."

func _ready() -> void:
	Events.GameOver.connect(game_over)
	Events.Quit.connect(quit)
	Events.Restart.connect(restart)
	pivot_offset = size / 2
	$MarginContainer.pivot_offset = $MarginContainer.size / 2

func game_over():
	Config.game_over = true
	$MarginContainer/AnimationPlayer.play("pop_in")
	
	Music.play("game_over")


func _on_replay_pressed() -> void:
	Events.Restart.emit()

func restart():
	var new_scene: Node = load("res://Game/Scenes/game.tscn").instantiate()
	
	await $"../background/Fade".fade_in(0.5)
	
	get_tree().root.add_child(new_scene)  # Add the new scene first
	root.queue_free()


func _on_switch_pressed() -> void:
	Events.Quit.emit()

func quit():
	var new_scene: Node = load("res://Title/title.tscn").instantiate()
	
	await $"../background/Fade".fade_in(0.5)
	
	get_tree().root.add_child(new_scene)  # Add the new scene first
	root.queue_free()
