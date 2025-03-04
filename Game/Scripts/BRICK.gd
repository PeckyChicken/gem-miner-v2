extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.DestroyBricks.connect(destroy_bricks)

func _destroy_brick(brick:Vector2):
	Events.PlaySound.emit("Gameplay/brick_break")
	Events.AddScore.emit(5)
	$"../Board".set_square(brick,0)
	
	var obj = $"../Board"._get_foreground_square(brick)
	
	obj.brick_particles.emitting = true
	obj.align_for_animation()
	
	var tween = get_tree().create_tween()
	tween.tween_property(obj,"scale",Vector2.ZERO,0.2)
	await tween.finished

func destroy_bricks(gems):
	var success = false
	for gem in gems:
		for direction in $"../Board".calculate_directions(gem):
			if $"../Board".get_square(direction) == 13:
				_destroy_brick(direction)
				success = true
		
	return success

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
