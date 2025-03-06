extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.DestroyBricks.connect(destroy_bricks)

func _destroy_brick(brick:Vector2):
	Events.PlaySound.emit("Gameplay/brick_break")
	Events.AddScore.emit(5)
	$"../Board".set_square(brick,Item.AIR)
	
	var obj = $"../Board"._get_foreground_square(brick)
	
	obj.brick_particles.emitting = true
	obj.align_for_animation()
	
	var tween = get_tree().create_tween()
	tween.tween_property(obj,"scale",Vector2.ZERO,0.2)
	await tween.finished
	if Game.current_mode == Game.Mode.obstacle:
		$"../Board".evaluate_next_level()

func destroy_bricks(gems):
	var success = false
	for gem in gems:
		for direction in $"../Board".calculate_directions(gem):
			if $"../Board".get_square(direction) == Item.BRICK:
				_destroy_brick(direction)
				success = true
	
	return success

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
