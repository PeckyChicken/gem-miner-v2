extends Button

const NODE_2D = preload("res://Game/Scenes/game.tscn")

func _on_pressed() -> void:
	var node = NODE_2D.instantiate()
	node.get_node("background/Board").mode = self.name
	
	Music.stop(100000)
	await $"../../../../Fade".fade_in(0.5)
	get_tree().root.add_child(node)
	get_tree().current_scene.queue_free()
