extends Node

const SQUARES = 3
const OPTIONS = [1,2,3,4]
var TOOLS = range(5,13)
var pit = []
var background_tiles = []
var foreground_tiles = []
var board_padding = 0.5 #Number of squares the pit is from the board.

func draw_background(background_tile):
	for tile in background_tiles:
		tile.queue_free()
	background_tiles.clear()
	var square_width = $"../Board".width / $"../Board".COLUMNS
	var square_height = $"../Board".height / $"../Board".ROWS
	
	var cur_x = $"../Board".start_x
	var y = $"../Board".start_y + $"../Board".height + (board_padding*square_height)
	var x_margin = ($"../Board".width-square_width) / float(SQUARES)
	
	for x in range(SQUARES):
		var new_tile = background_tile.duplicate()
		new_tile.x = x
		new_tile.position = Vector2(cur_x,y)
		new_tile.type = Events.Type.pit
		new_tile.show()
		add_child(new_tile)
		background_tiles.append(new_tile)
		cur_x += x_margin + square_width

func draw(tile_sprite):
	assert (len(background_tiles) == len(pit))
	
	for tile in foreground_tiles:
		tile.queue_free()
	foreground_tiles.clear()
	
	for index in range(len(background_tiles)):
		var tile_value = pit[index]
		var background_tile = background_tiles[index]
		var object = tile_sprite.duplicate()
		object.set_frame(tile_value)
		object.show()
		background_tile.add_child(object)
		foreground_tiles.append(object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for __ in range(SQUARES):
		pit.append(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func set_item(index,value):
	pit[index] = value

func get_item(index):
	return pit[index]

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
