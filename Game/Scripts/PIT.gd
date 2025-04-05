extends Node

const SQUARES = 3
const OPTIONS = Item.GEMS
var TOOLS = range(5,13)
var pit: Array[int] = []
var background_tiles = []
var foreground_tiles: Array[GameTile] = []
var board_padding = 2.5 #Number of squares the pit is from the board.

func draw_background():
	var background_tile = $"../pit_background_tile"
	for tile in background_tiles:
		tile.queue_free()
	background_tiles.clear()
	var square_width = $"../Board".size.x / $"../Board".COLUMNS
	var square_height = $"../Board".size.y / $"../Board".ROWS
	
	var cur_x = $"../Board".start_x
	var y = $"../Board".start_y + $"../Board".size.y + (board_padding*square_height)
	var x_margin = ($"../Board".size.x-square_width) / float(SQUARES)
	
	for x in range(SQUARES):
		var new_tile = background_tile.duplicate()
		new_tile.x = x
		new_tile.position = Vector2(cur_x,y)
		new_tile.type = Events.Type.pit
		new_tile.scale = $"../Board".SCALE
		new_tile.show()
		add_child(new_tile)
		background_tiles.append(new_tile)
		cur_x += x_margin + square_width

func draw():
	var tile_sprite = $"../tile"
	assert (len(background_tiles) == len(pit))
	
	for tile in foreground_tiles:
		tile.queue_free()
	foreground_tiles.clear()
	
	for index in range(len(background_tiles)):
		var tile_value = pit[index]
		var background_tile: BackgroundTile = background_tiles[index]
		var object: GameTile = tile_sprite.duplicate()
		object.set_frame(tile_value)
		object.show()
		background_tile.add_child(object)
		
		foreground_tiles.append(object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	empty()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func set_item(index,value):
	pit[index] = value

func get_item(index):
	return pit[index]

func empty():
	pit.clear()
	for __ in range(SQUARES):
		pit.append(0)

func fill(color = null):
	var index = 0
	for item in pit:
		if item == 0:
			var temp_color
			if color == null:
				temp_color = OPTIONS.pick_random()
			else:
				temp_color = color
			
			set_item(index,temp_color)
		index += 1
