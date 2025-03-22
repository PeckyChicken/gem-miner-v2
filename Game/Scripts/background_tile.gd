extends Sprite2D

class_name BackgroundTile

var x = 0
var y = 0
var hovered = false

@export var type: Events.Type

func _ready() -> void:
	Events.MouseClicked.connect(_on_mouse_clicked)
	
func _process(_delta: float) -> void:
	pass

func _on_mouse_entered() -> void:
	Events.TileHovered.emit(self)
	hovered = true

func _on_mouse_exited() -> void:
	hovered = false

func _on_mouse_clicked(__,___):
	if hovered:
		Events.TileClicked.emit(self)
