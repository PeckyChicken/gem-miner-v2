extends CenterContainer

@onready var node_2d: Node2D = $".."

func _ready() -> void:
	Events.GameOver.connect(game_over)
	Events.Quit.connect(quit)
	pivot_offset = size / 2
	$MarginContainer.pivot_offset = $MarginContainer.size / 2

func game_over():
	config.game_over = true
	position = Vector2(config.WINDOW_WIDTH/2,config.WINDOW_HEIGHT/2)
	$MarginContainer/AnimationPlayer.play("pop_in")
	
	Music.play("game_over")


func _on_replay_pressed() -> void:
	var new_scene: Node = load("res://Game/Scenes/game.tscn").instantiate()
	
	await $"../Fade".fade_in(0.5)
	
	get_tree().root.add_child(new_scene)  # Add the new scene first
	node_2d.queue_free()


func _on_switch_pressed() -> void:
	Events.Quit.emit()

func quit():
	var new_scene: Node = load("res://Title/title.tscn").instantiate()
	
	await $"../Fade".fade_in(0.5)
	
	get_tree().root.add_child(new_scene)  # Add the new scene first
	node_2d.queue_free()
