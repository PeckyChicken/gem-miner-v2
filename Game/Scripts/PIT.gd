extends Control

const SQUARE_COUNT = 3
const OPTIONS = Game.GEMS
var TOOLS = range(5,13)
var pit: Array[int] = []
@onready var Board: brd = $"../Board"

var background_tiles = []
var foreground_tiles: Array[GameTile] = []
var screen_padding = 0.25 #Number of squares the pit is from the bottom of the screen.

func draw_background():
	var background_tile = $"../pit_background_tile"
	for tile in background_tiles:
		tile.queue_free()
	background_tiles.clear()
	
	var square_size = Vector2(Board.width/Board.COLUMNS,Board.height/Board.ROWS)
	var start_pos = -Vector2(Board.width / 2.0,square_size.y*(screen_padding+1))
	
	
	if SQUARE_COUNT == 1:
		var new_tile = background_tile.duplicate()
		new_tile.position = start_pos*Vector2(0,1)

		new_tile.type = Events.Type.pit
		new_tile.show()
		add_child(new_tile)
		background_tiles.append(new_tile)
		return
	elif SQUARE_COUNT == 0:
		return
	elif SQUARE_COUNT < 0:
		printerr("Must have a positive or zero number of pit squares.")
		assert (false)
	
	
	for x in range(SQUARE_COUNT):
		var new_tile = background_tile.duplicate()
		var rel_pos = Vector2((x/float(SQUARE_COUNT-1))*(Board.width-square_size.x),0)
		new_tile.x = x
		new_tile.position = start_pos + rel_pos
		new_tile.type = Events.Type.pit
		new_tile.show()
		add_child(new_tile)
		background_tiles.append(new_tile)

func draw():
	var tile_sprite = $"../tile"
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
	for __ in range(SQUARE_COUNT):
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
