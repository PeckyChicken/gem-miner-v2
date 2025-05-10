extends Node2D
class_name previewer
var previews: Array[Preview] = []

class Preview:
	var background: BackgroundTile
	var foreground: GameTile
	var location: Vector2
	func queue_free():
		background.queue_free()
		foreground.queue_free()

func delete_all_previews():
	for preview in previews:
		preview.queue_free()
	previews.clear()

func create_preview(location: Vector2,image: int,alpha=1) -> Preview:
	var preview = Preview.new()
	
	var background_tile: BackgroundTile = $"../background_tile".duplicate()
	var foreground_tile: GameTile = $"../tile".duplicate()
	
	background_tile.type = Events.Type.preview
	foreground_tile.frame = image
	background_tile.position = $"../Board".get_absolute_coords(location)
	
	foreground_tile.modulate.a = alpha
	
	background_tile.show()
	foreground_tile.show()
	
	background_tile.add_child(foreground_tile)
	add_child(background_tile)
	
	preview.background = background_tile
	preview.foreground = foreground_tile
	preview.location = location
	
	previews.append(preview)
	return preview
