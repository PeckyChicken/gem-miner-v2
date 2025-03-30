extends Node
class_name brd

const ROWS = 7
const COLUMNS = 7
const REL_Y= 0.1
const REL_X = 0.5
const SCALE = 1

const COLORS = [Color(1,0,0),Color(1,1,0),Color(0,1,0),Color(0,0,1)]

var background_tiles: Array[Sprite2D] = []
var foreground_tiles = []
var board: Array[int] = []
var selected = 0
var selected_tile = null

var level = 1
var score = 0
var goal = 500
var moves = 15

var game_over = false

var width
var height
var start_x
var start_y

func _ready():
	clear_board()
	Events.GameOver.connect(func():game_over=true)
	
func within_board(location:Vector2):
	var board_start = Vector2.ZERO
	var board_end = Vector2(COLUMNS-1,ROWS-1)
	return (location.x >= board_start.x and location.x <= board_end.x) and (location.y >= board_start.y and location.y <= board_end.y)

func _index_to_coords(index):
	return Vector2(floori(index / COLUMNS),index % COLUMNS)

func clear_gems(matches:Array):
	for item in matches:
		set_square(item,0)

func set_square(location:Vector2,value):
	board[location.x*COLUMNS+location.y] = value

func get_square(location:Vector2):
	return board[location.x*COLUMNS+location.y]

func get_absolute_coords(location:Vector2):
	return _get_background_square(location).position

func _get_foreground_square(location:Vector2) -> GameTile:
	return foreground_tiles[location.x*COLUMNS+location.y]

func calculate_directions(location:Vector2):
	var up =  location - Vector2(0,1)
	var down= location + Vector2(0,1)
	var left= location - Vector2(1,0)
	var right=location + Vector2(1,0)
	
	if not within_board(up):
		up = location
	if not within_board(down):
		down = location
	if not within_board(left):
		left = location
	if not within_board(right):
		right = location
	
	return [up,down,left,right]

func _get_background_square(location:Vector2):
	return background_tiles[location.x*COLUMNS+location.y]

func clear_board():
	board.clear()
	for __ in range(ROWS*COLUMNS):
		board.append(0)

func pop_in(location:Vector2):
	var tile = _get_foreground_square(location)
	tile.animation_player.play("pop")
	await tile.animation_player.animation_finished

func draw_background():
	var background_tile = $"../background_tile"
	for tile in background_tiles:
		tile.queue_free()
	background_tiles.clear()
	
	var square_width = background_tile.texture.get_width() *SCALE
	var square_height =background_tile.texture.get_height()*SCALE
	
	width = square_width*COLUMNS
	@warning_ignore("unused_variable")
	height = square_height*ROWS
	
	start_x = Config.WINDOW_WIDTH*REL_X - (width/2.0)
	var cur_x = start_x
	start_y = Config.WINDOW_HEIGHT*REL_Y
	var cur_y = start_y
	
	for x in range(COLUMNS):
		for y in range(ROWS):
			var new_tile = background_tile.duplicate()
			new_tile.x = x
			new_tile.y = y
			new_tile.position = Vector2(cur_x,cur_y)
			new_tile.type = Events.Type.board
			new_tile.show()
			add_child(new_tile)
			background_tiles.append(new_tile)
			cur_y += square_height
			
		cur_x += square_width
		cur_y = start_y

func select(value,type=Events.Type.pit):
	var tile_sprite
	if type == Events.Type.pit:
		selected = value
		tile_sprite = $"../tile"
	elif type == Events.Type.tool:
		selected = Item.AIR
		tile_sprite = $"../Tools/Tool".get_node("Image")
	else:
		printerr('"type" parameter set to an unsupported value (%s)' % [type])
		assert(false)
	
	var selection_object = $"../selection_tile"
	
	if selected_tile:
		selected_tile.queue_free()
	var tile = tile_sprite.duplicate()
	tile.set_frame(value)
	tile.show()
	selection_object.add_child(tile)
	selected_tile = tile

func next_level():
	level += 1
	Events.PlaySound.emit("Gameplay/next_level")
	
	if level % 2 == 0:
		goal *= 2
	else:
		goal *= 5
	
	if Game.current_mode == Game.Mode.obstacle:
		$"../Tools".tool_counts[randi_range(0,len($"../Tools".tool_counts)-1)] += 1
		moves += level

		$"../..".add_bricks(level)
	else:
		$"../Tools".tool_counts = [1,1,1,1,1]
	
	Events.AddScore.emit(0) #Forces an update of the displays

func remove_square(location:Vector2,trigger_tools=true):
	var tile = _get_foreground_square(location)
	if tile.animation_player.is_playing():
		await tile.animation_player.animation_finished
	if get_square(location) in Item.BRICKS:
		await $"../Brick"._destroy_brick(location)
		return
	elif get_square(location) in Item.GAME_TOOLS and trigger_tools:
		$"../..".evaluate_game_tool(location,false)
		return
	tile.animation_player.play("vanish")
	set_square(location,0)
	await tile.animation_player.animation_finished

func evaluate_next_level():
	if Game.current_mode == Game.Mode.obstacle:
		if Item.BRICK not in board:
			next_level()
		return
	
	if score >= goal:
		next_level()

func evaluate_game_over():
	var _game_over = false
	if Game.current_mode == Game.Mode.obstacle:
		if moves <= 0:
			_game_over = true
	
	if Item.AIR not in board:
		if not board.any(func (x): return x in $"../Pit".TOOLS):
			_game_over = true
	
	return _game_over

func draw(location:Vector2=Vector2.INF):
	var tile_sprite = $"../tile"
	assert (len(background_tiles) == len(board))
	
	if location != Vector2.INF:
		Events.DeleteTiles.emit(_get_background_square(location).get_children())
		var index = foreground_tiles.find(_get_foreground_square(location))
		
		var tile_value = get_square(location)
		var background_tile = _get_background_square(location)
		var object = tile_sprite.duplicate()
		object.set_frame(tile_value)
		object.show()
		background_tile.add_child(object)
		
		foreground_tiles[index] = object
		return
	
	Events.DeleteTiles.emit(foreground_tiles)
	foreground_tiles.clear()
	for index in range(len(background_tiles)):
		var tile_value = board[index]
		var background_tile = background_tiles[index]
		var object = tile_sprite.duplicate()
		object.set_frame(tile_value)
		object.show()
		background_tile.add_child(object)
		foreground_tiles.append(object)
