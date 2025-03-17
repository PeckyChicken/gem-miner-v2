extends Node2D
class_name Lightning

@onready var line: Line2D = $Line
@onready var animation_player: AnimationPlayer = $AnimationPlayer



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.animation_finished.connect(destroy)

func destroy(__=null):
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
