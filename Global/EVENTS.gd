extends Node
class_name event_class

var mouse_position: Vector2 = Vector2.ZERO
var mouse_clicked: bool = false

signal MouseClicked(button,position)
signal MouseReleased(button,position)

signal TileClicked(tile)
signal TileReleased(tile)
signal TilePlaced(x,y,type)
signal TileHovered(tile)

signal PlaySound(path)
signal DeleteTiles(tiles)
signal AddScore(score)
signal DestroyBricks(gems)
signal CreateLightning(point_a,point_b,color)
signal Explode(x,y)

signal GameOver()
signal DeselectTools()

signal UpdateHover()

signal Pause()
signal Resume()
signal Quit()

enum Type {
	board,
	pit,
	tool,
	selected,
	preview
}

func _ready() -> void:
	MouseClicked.connect(_click)
	MouseReleased.connect(func(__,position):_click(__,position,true))

func _click(__,position,release=false):
	mouse_position = position
	mouse_clicked = not release

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
