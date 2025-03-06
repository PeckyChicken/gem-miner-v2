@tool
extends Button

const NODE_2D = preload("res://Game/Scenes/game.tscn")

@export var mode: Game.Mode = Game.Mode.survival

func _on_pressed() -> void:
	var node = NODE_2D.instantiate()
	Game.current_mode = mode
	
	Music.stop(100000)
	await $"../../../../Fade".fade_in(0.5)
	get_tree().root.add_child(node)
	$"../../../..".queue_free()
