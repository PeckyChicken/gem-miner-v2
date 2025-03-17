extends Sprite2D
class_name GameTile

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var brick_particles: CPUParticles2D = $BrickParticles


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.DeleteTiles.connect(delete)

func delete(tiles):
	if self not in tiles:
		return
	if animation_player.is_playing():
		await animation_player.animation_finished
	if  brick_particles.emitting:
		await brick_particles.finished
	queue_free()

func align_for_animation():
	centered = true
	position = Vector2.ZERO + (self.get_rect().size/2)

func dealign_from_animation():
	centered = false
	position = Vector2.ZERO

func explode():
	var explosion = $ExplosionParticles.duplicate()
	explosion.show()
	$"..".add_child(explosion)
	await explosion.explode()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
