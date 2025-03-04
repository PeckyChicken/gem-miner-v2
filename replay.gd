extends Button

@onready var node_2d: Node2D = $"../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_pressed() -> void:
	var current_scene = get_tree().current_scene
	var new_scene = load(get_tree().current_scene.scene_file_path).instantiate()

	await $"../../../Fade".fade_in(0.5)
	get_tree().root.add_child(new_scene)  # Add the new scene first
	
	current_scene.queue_free()  # Then remove the old one
