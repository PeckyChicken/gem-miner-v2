extends Sprite2D
class_name GameTile

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var brick_particles: CPUParticles2D = $BrickParticles
@onready var rainbow_diamond: AnimatedSprite2D = $RainbowDiamond

signal SpinFinished()

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

func explode(explosion_scale=1):
	var explosion = $ExplosionParticles.duplicate()
	explosion.scale = Vector2(explosion_scale,explosion_scale)
	explosion.show()
	explosion.global_position = global_position + (self.get_rect().size/2)
	$"../..".add_child(explosion)
	await explosion.explode()

func double_diamond_spin(seconds: float):
	const tween_time = 0.1
	align_for_animation()
		
	$RainbowDiamond.show()
	$RainbowDiamond.frame = 0
	var _frame = self.frame
	self.frame = Game.Item.AIR
	var tween = get_tree().create_tween()
	tween.tween_property($RainbowDiamond,"scale",Vector2(2,2),tween_time)
	await tween.finished
	$RainbowDiamond.play("default")
	await get_tree().create_timer(seconds-(2*tween_time)).timeout

	var tween2 = get_tree().create_tween()
	tween2.tween_property($RainbowDiamond,"frame",0,tween_time)
	tween2.tween_property($RainbowDiamond,"scale",Vector2.ONE,tween_time)
	await tween2.finished
	
	$RainbowDiamond.stop()
	$RainbowDiamond.hide()
	SpinFinished.emit()
	self.frame = Game.Item.RAINBOW_DIAMOND
	
	dealign_from_animation()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
