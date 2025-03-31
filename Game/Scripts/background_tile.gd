extends Sprite2D

class_name BackgroundTile

var x = 0
var y = 0
var hovered = false
var clicked = false

const COLLISION_OFFSET = Vector2(0,150)

@export var type: Events.Type

func _ready() -> void:
	Events.MouseClicked.connect(_on_mouse_clicked)
	Events.MouseReleased.connect(_on_mouse_released)
	
	Events.UpdateHover.connect(update_hover)
	
	if type == Events.Type.board:
		$Area2D/CollisionShape2D.position += COLLISION_OFFSET*0.5

func update_hover():
	if hovered:
		Events.TileHovered.emit(self)

func _on_mouse_entered() -> void:
	Events.TileHovered.emit(self)
	hovered = true

func _on_mouse_exited() -> void:
	hovered = false

func _on_mouse_clicked(__,___):
	clicked = true
	await get_tree().process_frame
	if hovered:
		Events.TileClicked.emit(self)

func _on_mouse_released(__,___):
	clicked = false
	await get_tree().process_frame
	if hovered:
		Events.TileReleased.emit(self)
