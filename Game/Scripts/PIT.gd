class_name Pit
extends Control

var pit_size = 3
const OPTIONS = Game.GEMS
var TOOLS = Game.GAME_TOOLS
var pit: Array[Game.Item] = []
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
	
	
	if pit_size == 1:
		var new_tile = background_tile.duplicate()
		new_tile.position = start_pos*Vector2(0,1)

		new_tile.type = Events.Type.pit
		new_tile.show()
		add_child(new_tile)
		background_tiles.append(new_tile)
		return
	
	elif pit_size == 0:
		return
	
	elif pit_size < 0:
		printerr("Must have a positive or zero number of pit squares.")
		assert (false)
	
	
	for x in range(pit_size):
		var new_tile = background_tile.duplicate()
		var rel_pos = Vector2((x/float(pit_size-1))*(Board.width-square_size.x),0)
		new_tile.x = x
		new_tile.position = start_pos + rel_pos
		new_tile.type = Events.Type.pit
		new_tile.show()
		add_child(new_tile)
		background_tiles.append(new_tile)

func refresh():
	draw_background()
	while pit_size < len(pit):
		pit.pop_back()
	while pit_size > len(pit):
		pit.append(Game.Item.AIR)
	fill()
	draw()

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
	for __ in range(pit_size):
		pit.append(0)

func fill(color = null):
	var index = 0
	for item in pit:
		if item == Game.Item.AIR:
			var temp_color
			if color == null:
				temp_color = OPTIONS.pick_random()
			else:
				temp_color = color
			
			set_item(index,temp_color)
		index += 1
