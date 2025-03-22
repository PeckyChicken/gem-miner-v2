extends Node2D

const MODE_TO_STRING = {Game.Mode.survival:"survival",Game.Mode.time_rush:"time_rush",Game.Mode.obstacle:"obstacle",Game.Mode.chromablitz:"chromablitz",Game.Mode.ascension:"ascension"}
const BACKGROUNDS = {Game.Mode.survival:1,Game.Mode.time_rush:2,Game.Mode.obstacle:3,Game.Mode.chromablitz:4,Game.Mode.ascension:7}

var PRESSED_KEYS = []
@onready var Board: brd = $background/Board
@onready var Preview: previewer = $background/Preview

var time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup.call_deferred()
	await $Fade.fade_out(0.5)
	if Game.current_mode == Game.Mode.survival:
		if Music.playing not in ["survival1","survival2"]:
			Music.play(["survival1","survival2"].pick_random())
	else:
		if MODE_TO_STRING[Game.current_mode] != Music.playing:
			Music.play(MODE_TO_STRING[Game.current_mode])

func _process(delta: float) -> void:
	if Game.current_mode == Game.Mode.time_rush and not Board.game_over:
		time += delta
		if time >= 1:
			add_bricks()
			while time >= 1:
				time -= 1
			if Board.evaluate_game_over():
				Events.GameOver.emit()

func setup():
	set_background(Game.current_mode)

	Events.TileClicked.connect(tile_clicked)
	Events.TileHovered.connect(tile_hovered)
	Board.draw_background()
	Board.draw()
	$background/Pit.draw_background()
	$background/Pit.fill()
	$background/Pit.draw()
	
	
	random_place($background/Pit.OPTIONS)
	random_place($background/Pit.OPTIONS)
	
	random_place([13])
	if Game.current_mode != Game.Mode.obstacle:
		random_place([13])
		random_place([13])
		random_place([13])
	
	Board.draw()

func set_background(mode):

	if mode == Game.Mode.ascension:
		$ascension_particles.show()
	else:
		$ascension_particles.queue_free()
	
	if mode == Game.Mode.obstacle:
		$background/Hud/Goal.hide()
		$background/Hud/Goal_Label.hide()
		$background/Hud/Moves.show()
		$background/Hud/Moves_Label.show()
	
	$background.frame = BACKGROUNDS[mode]

func random_place(items:Array):
	assert (0 in Board.board)
	
	var coordinates = []
	for x in range(Board.COLUMNS):
		for y in range(Board.ROWS):
			coordinates.append(Vector2(x,y))
	
	coordinates.shuffle()
	var selection
	
	for coordinate in coordinates:
		if Board.get_square(coordinate) == 0:
			selection = coordinate
			break
	
	
	Board.set_square(selection,items.pick_random())
	Board.draw(selection)
	Board.pop_in(selection)

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index not in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		Events.MouseClicked.emit(event.button_index,event.position)
	
	if event is InputEventKey and event.is_pressed():
		var character = char(event.unicode)
		if character.is_valid_int():
			var pos = int(character) - 1
			if len($background/Pit.pit) > pos:
				select_pit_item(pos)
				Events.UpdateHover.emit()

func validate_tile_placement(location:Vector2):
	if Board.get_square(location) != 0:
		return false
	
	var directions = Board.calculate_directions(location)
	
	if  directions.all(func(c): return Board.get_square(c) == 0):
		return false
	
	return true

func add_bricks(count=null):
	if count == null:
		count = 1
		count += floori(Board.level / 5.0)
		if randi_range(0,4) < Board.level % 5:
			count += 1
	
	for __ in range(count):
		if 0 not in Board.board:
			break
		random_place([13])
		Events.PlaySound.emit("Gameplay/brick_placed")

func vanish_gems(location:Vector2):
	var vanish = $background/vanish.duplicate()
	vanish.show()
	Board._get_background_square(location).add_child(vanish)
	vanish.position += Vector2(Board.width/Board.COLUMNS/2,Board.height/Board.ROWS/2)
	vanish.get_child(0).play("vanish")

func create_game_tool(location:Vector2,clears,horizontal_matches,vertical_matches,preview=false):
	var tool: int
	var sound: String
	if len(clears) == 4: #Drills
		if len(horizontal_matches) == 4: #Vertical drill
			tool = Item.V_DRILL
		
		elif len(vertical_matches) == 4: #Horizontal drill
			tool = Item.H_DRILL
		else:
			printerr("4 gems were cleared but there was not a line of 4 in either direction.\nTHIS SHOULD NOT BE HAPPENING.")
			assert(false)
		
		sound = "Drill/create"
	
	if len(horizontal_matches) >= 5 or len(vertical_matches) >= 5: #Diamonds
		if len(horizontal_matches) >= 5 and len(vertical_matches) >= 5:
			tool = Item.RAINBOW_DIAMOND
			sound = "Diamond/double_create"
		else:
			#The diamonds are 4 offsets from the gems
			tool = Board.get_square(location)+4
			sound = "Diamond/create"
	
	elif len(horizontal_matches) >= 3 and len(vertical_matches) >= 3: #Bombs
		tool = Item.BOMB
		sound = "Bomb/create"
	
	if preview:
		assert (tool != 0)
		for clear in clears:
			if clear == location:
				Preview.create_preview(location,tool)
				continue
			Preview.create_preview(clear,Board.get_square(clear))
		return
	
	Events.PlaySound.emit(sound)
	Board.set_square(location,tool)
	
	for l in [location] + clears:
		Board.draw(l)
	
	await Board.pop_in(location)

func create_lightning(point_a:Vector2,point_b:Vector2,color: Color,offsets=[Vector2.ZERO,Vector2.ZERO]) -> Lightning:
	var lightning = $Lightning.duplicate()
	var lightning_line: Line2D = lightning.get_node("Line")
	lightning_line.position = Vector2(Board.width/Board.ROWS / 2,Board.height/Board.COLUMNS / 2)
	
	var square_size = Vector2(Board.width/Board.ROWS,Board.height/Board.COLUMNS)
	
	var point_a_node = Board._get_background_square(point_a)
	
	var delta = point_b - point_a
	delta *= square_size
	
	offsets[0] *= square_size
	offsets[1] *= square_size
	
	lightning_line.points = [offsets[0]/lightning_line.scale, (delta+offsets[1])/lightning_line.scale]
	lightning.modulate = color
	
	lightning.show()
	point_a_node.add_child(lightning)
	
	return lightning

func diamond(location:Vector2,type,replacement=Item.AIR) -> Array[Vector2]:
	var lights = []
	var squares: Array[Vector2] = []
	for square_x in Board.COLUMNS:
		for square_y in Board.ROWS:
			var square_location = Vector2(square_x,square_y)
			if Board.get_square(square_location) == type-4:
				var tile: GameTile = Board._get_foreground_square(square_location)
				tile.z_index = 2
				tile.align_for_animation()
				tile.animation_player.play("energized")
				squares.append(square_location)
				
				var lightning = create_lightning(location,square_location,Board.COLORS[type-5])
				lightning.z_index = 1
				lightning.animation_player.play("energized")
				lights.append(lightning)
	
	replace_squares(type-4,replacement)
	Events.AddScore.emit(10)
	Board.set_square(location,Item.AIR)
	Events.PlaySound.emit("Diamond/use")
	Board._get_foreground_square(location).animation_player.play("diamond")
	if len(lights) > 0:
		await lights[0].animation_player.animation_finished
	for light in lights:
		light.queue_free()
	$background/Brick.destroy_bricks(squares+[location])
	for square in squares:
		Board.draw(square)
		Board.pop_in(square)
	
	await Board._get_foreground_square(location).animation_player.animation_finished
	return squares

func evaluate_game_tool(location,calculate_combo=true,preview=false):
	var type = Board.get_square(location)
	var GAME_TOOLS = range(5,13)
	
	if type not in GAME_TOOLS:
		return
	
	if type == Item.RAINBOW_DIAMOND:
		await double_diamond(location)
	
	if calculate_combo:
		var combo = calculate_tool_combo(location)
		if len(combo) > 1:
			await evaluate_tool_combo(location,combo)
		if board_empty():
			random_place($background/Pit.OPTIONS)
			Events.PlaySound.emit("Gameplay/place")
		if len(combo) > 1:
			return
			
	
	if type in Item.DIAMONDS and type != Item.RAINBOW_DIAMOND:
		await diamond(location,type)
	
	if type == Item.H_DRILL:
		if !preview:
			Events.PlaySound.emit("Drill/use")
		await clear_line(location,"h",true,Color.WHITE,preview)
		
	if type == Item.V_DRILL:
		if !preview:
			Events.PlaySound.emit("Drill/use")
		await clear_line(location,"v",true,Color.WHITE,preview)
		
	if type == Item.BOMB:
		if !preview:
			Events.PlaySound.emit("Bomb/use")
		clear_blast(location,1,preview)
		if !preview:
			await Board._get_foreground_square(location).explode()
	
	Board.draw()
	
	if board_empty():
		random_place($background/Pit.OPTIONS)
		Events.PlaySound.emit("Gameplay/place")

func calculate_tool_combo(location):
	var combo = [location]
	var GAME_TOOLS = range(5,13)
	var directions = Board.calculate_directions(location)
	for direction in directions:
		if direction == location:
			continue
		if Board.get_square(direction) in GAME_TOOLS:
			combo.append(direction)
	
	return combo

func _get_priority(item_type):
	const PRIORITIES = [[5,6,7,8,9],[12],[10,11],[0]]
	var priority = 0
	for p in PRIORITIES:
		if item_type in p:
			break
		priority += 1
	return priority

func double_diamond(location:Vector2):
	Board._get_foreground_square(location).animation_player.play("double_diamond")
	Events.PlaySound.emit("Diamond/double_diamond")
	var lights = []
	for cur_x in Board.COLUMNS:
		for cur_y in Board.ROWS:
			var cur_location = Vector2(cur_x,cur_y)
			var item = Board.get_square(cur_location)
			var item_object = Board._get_foreground_square(cur_location)
			if item != 0:
				var color = Board.COLORS[len(lights)%len(Board.COLORS)]
				var light = create_lightning(location,cur_location,color)
				lights.append(light)
				light.animation_player.play("energized")
			if not item_object.animation_player.is_playing():
				item_object.animation_player.play("energized")
	if len(lights) > 0:
		await lights[0].animation_player.animation_finished
	for light in lights:
		light.queue_free()

	Events.AddScore.emit(100)
	Board.clear_board()
	await Board._get_foreground_square(location).animation_player.animation_finished
	Board.evaluate_next_level()

func evaluate_tool_combo(location:Vector2,combo):
	await $background/Line.animate_line_clear(location,combo,false)
	var background_square = Board._get_background_square(location)
	var _square
	var _squares = []
	for item in combo:
		if item != location:
			_square = Board._get_foreground_square(item)
			_square.reparent(background_square)
			_square.z_index -= 1
			
			_square.animation_player.play("vanish")
			_squares.append(_square)
	await _square.animation_player.animation_finished
	for square in _squares:
		square.hide()
	
	var top_two = [0,0]

	for item in combo:
		var item_type = Board.get_square(item)
		var priority = _get_priority(item_type)
		var index = 0
		for top in top_two:
			if priority < _get_priority(top):
				top_two[index] = item_type
				break
			index += 1
		Board.set_square(item,0)
	print(top_two)
	assert (0 not in top_two)
	
	if top_two[0] in [5,6,7,8] and top_two[1] in [5,6,7,8]:
		await double_diamond(location)
	
	if top_two.any(func(n):return n in Item.DIAMONDS):
		var color
		for item in top_two:
			if item in [5,6,7,8,9]:
				color = item
		
		var tool_type
		if Item.H_DRILL in top_two or Item.V_DRILL in top_two:
			tool_type = Item.DRILLS
		elif Item.BOMB in top_two:
			tool_type = Item.BOMB
		
		var replacements: Array[Vector2] = await diamond(location,color,tool_type)
		replacements.shuffle()
		for replacement in replacements:
			if Board.get_square(replacement) == Item.AIR:
				continue
			await evaluate_game_tool(replacement,false)
	
	if top_two[0] == Item.BOMB and top_two[1] == Item.BOMB:
		Events.PlaySound.emit("Bomb/use")
		clear_blast(location,2)
	
	if top_two[0] in Item.DRILLS and top_two[1] in Item.DRILLS:
		Events.PlaySound.emit("Drill/use")
		clear_line(location,"V")
		clear_line(location,"H")
	

func handle_lines(location:Vector2,preview=false):
	var lines = $background/Line.detect_lines(location)
	var horizontal_matches = lines[0]
	var vertical_matches = lines[1]
	var clears = []
	if len(horizontal_matches) >= 3:
		clears += horizontal_matches
		
	if len(vertical_matches) >= 3:
		clears += vertical_matches
	
	if !preview:
		if len(clears) == 0:
			if Game.current_mode not in [Game.Mode.obstacle,Game.Mode.time_rush]:
				add_bricks()
			return
		
		var type = Board.get_square(location)
		Board.clear_gems(clears)
		Board.set_square(location,type)
		
		Events.PlaySound.emit("Gameplay/break")
		Events.AddScore.emit(10*(len(horizontal_matches+vertical_matches)))
		
		Events.DestroyBricks.emit(clears)

		
		await $background/Line.animate_line_clear(location,clears)
	
	if len(clears) == 3:
		if preview:
			for clear in clears:
				Preview.create_preview(clear,Board.get_square(clear))
		else:
			vanish_gems(location)
			Board.set_square(location,0)
	
	elif len(clears) > 3:
		await create_game_tool(location,clears,horizontal_matches,vertical_matches,preview)
	else:
		if preview:
			Preview.create_preview(location,Board.get_square(location))
	
	if preview:
		return
	
	for item in clears:
		Board._get_foreground_square(item).queue_free()
		Board.draw(item)
	
	if board_empty():
		random_place($background/Pit.OPTIONS)
		Events.PlaySound.emit("Gameplay/place")

func board_empty():
	return Board.board.all(func(__): return __ == Item.AIR)

func _place(location,value,preview=false):
	if preview:
		Preview.create_preview(location,value)
		return
	Board.set_square(location,value)
	Events.PlaySound.emit("Gameplay/place")
	
	Board.draw(location)
	Board.select(Item.AIR)
	$background/Pit.fill()
	$background/Pit.draw()
	Events.AddScore.emit(1)
	await Board.pop_in(location)

func clear_line(location,direction:String,show_lightning=true,color=Color.WHITE,preview=false,external_tool=false):
	if preview:
		show_lightning = false
	else:
		if !external_tool:
			Board.remove_square(location,external_tool)
	direction = direction.to_lower()
	assert (direction in ["h","v"])
	
	
	var x_positions = []
	var y_positions = []
	if direction == "h":
		x_positions = range(Board.COLUMNS)
	else:
		x_positions.resize(Board.COLUMNS)
		x_positions.fill(location.x)
	
	if direction == "v":
		y_positions = range(Board.ROWS)
	else:
		y_positions.resize(Board.ROWS)
		y_positions.fill(location.y)
	
	var start_pos = Vector2(x_positions[0],y_positions[0])
	var end_pos = Vector2(x_positions[-1],y_positions[-1])
	
	var lightning: Lightning
	if show_lightning:
		var offsets
		if direction == "v":
			offsets = [Vector2(0,-0.5),Vector2(0,0.5)]
		elif direction == "h":
			offsets = [Vector2(-0.5,0),Vector2(0.5,0)]
		lightning = create_lightning(start_pos,end_pos,color,offsets)
		lightning.animation_player.speed_scale = 5
		lightning.animation_player.play("energized")
	
	var chains = []
	for cur_x in x_positions:
		for cur_y in y_positions:
			var cur_location = Vector2(cur_x,cur_y)
			if Board.get_square(cur_location) in Item.GAME_TOOLS:
				if external_tool or (cur_location != location):
					chains.append(cur_location)
			
			if preview:
				if Preview.previews.any(func(_preview): return _preview.location == cur_location):
					continue
				Preview.create_preview(cur_location,Item.AIR)
				continue
			
			if Board.get_square(cur_location) != Item.AIR:
				Events.AddScore.emit(10)
			if Board.get_square(cur_location) in Item.BRICKS:
				$background/Brick._destroy_brick(cur_location)
			
			
			if Board.get_square(cur_location) in Item.GEMS:
				Board.remove_square(cur_location)
	
	if preview:
		return
	
	if len(chains) > 0:
		await lightning.animation_player.animation_finished
		for chain in chains:
			evaluate_game_tool(chain,false)
	
	if show_lightning:
		await lightning.animation_player.animation_finished
		lightning.queue_free()

func clear_diagonal_lines(location:Vector2, show_lightning=true,preview=false):
	if preview:
		show_lightning = false
	var clears = []
	
	var top_left = location
	var top_right = location
	var bottom_left = location
	var bottom_right = location
	
	while Board.within_board(top_left + Vector2(-1,-1)):
		top_left += Vector2(-1,-1)
		clears.append(top_left)
	while Board.within_board(top_right + Vector2(1,-1)):
		top_right += Vector2(1,-1)
		clears.append(top_right)
	while Board.within_board(bottom_left + Vector2(-1,1)):
		bottom_left += Vector2(-1,1)
		clears.append(bottom_left)
	while Board.within_board(bottom_right + Vector2(1,1)):
		bottom_right += Vector2(1,1)
		clears.append(bottom_right)
	
	var lightning: Array[Lightning] = []
	if show_lightning:
		lightning.append(create_lightning(top_left,bottom_right,Color.GOLDENROD,[Vector2(-0.5,-0.5),Vector2(0.5,0.5)]))
		lightning.append(create_lightning(top_right,bottom_left,Color.GOLDENROD,[Vector2(0.5,-0.5),Vector2(-0.5,0.5)]))
	
	for light in lightning:
		light.animation_player.speed_scale = 5
		light.animation_player.play("energized")
	
	for clear in clears:
		if preview:
			Preview.create_preview(clear,Item.AIR)
			continue
		Board.remove_square(clear)
	
	if not preview:
		Board.remove_square(location)
	
	if show_lightning:
		await lightning[0].animation_player.animation_finished
		for light in lightning:
			light.queue_free()


func clear_blast(location,radius:int,preview=false):
	var cur_x = location.x - radius
	var cur_y
	while cur_x <= location.x + radius:
		cur_y = location.y - radius
		while cur_y <= location.y + radius:
			var cur_location = Vector2(cur_x,cur_y)
			if Board.within_board(cur_location):
				if preview:
					Preview.create_preview(cur_location,Item.AIR)
					cur_y += 1
					continue
				
				if cur_location != location:
					evaluate_game_tool(cur_location,false,preview)

				
				if Board.get_square(cur_location) != Item.AIR:
					Events.AddScore.emit(10)
				
				if Board.get_square(cur_location) in Item.BRICKS:
					$background/Brick._destroy_brick(cur_location)
				
				if Board.get_square(cur_location) in Item.GEMS:
					Board.remove_square(cur_location)
			cur_y += 1
		cur_x += 1
	
	if !preview:
		Board.remove_square(location,false)

func select_pit_item(pos:int):
	if Board.game_over:
		return
	
	if $background/Tools.selected_tool != null:
		Events.DeselectTools.emit()
	
	var temp = Board.selected
	Board.select($background/Pit.get_item(pos))
	$background/Pit.set_item(pos,temp)
	$background/Pit.draw()

func replace_squares(type,replacement):
	var index = 0
	var replaced_squares = []
	for item in Board.board:
		if item == type:
			var replace
			if replacement is Array:
				replace = replacement.pick_random()
			else:
				replace = replacement
			Board.board[index] = replace
			replaced_squares.append(Board._index_to_coords(index))
			
			Events.AddScore.emit(10)
		index += 1
	return replaced_squares

func place_tile(tile,location,preview=false):
	if !preview:
		Preview.delete_all_previews()
	if not validate_tile_placement(location):
		if Board.get_square(location) == Item.AIR:
			Preview.create_preview(location,Item.CROSS)
		
		if preview:
			return
		Events.PlaySound.emit("Gameplay/nomatch")
		return
	
	if Game.current_mode == Game.Mode.obstacle and !preview:
		Board.moves -= 1
		Events.AddScore.emit(0)
	
	if !preview:
		await _place(location,tile)
	var temp_board: Array[int] = Board.board.duplicate()
	if preview:
		Board.set_square(location,tile)
	
	handle_lines(location,preview)
	if preview:
		Board.board = temp_board.duplicate()
		return
	if Board.evaluate_game_over() and Game.current_mode == Game.Mode.obstacle:
		#If player is out of moves on obstacle, check if they've at least cleared the level.
		Board.evaluate_next_level()
		#If not, then it's game over.
	if Board.evaluate_game_over():
		Events.GameOver.emit()

func return_selected_to_pit():
	var _pit: Array[int] = $background/Pit.pit
	
	if 0 in _pit:
		_pit[_pit.find(0)] = Board.selected
	
	$background/Pit.draw()

func select_tool(bg_tile: BackgroundTile):
	var tool_tile: Tool = bg_tile.get_child(-1)
	var tool_type = tool_tile.tool
	#var tool_index = $background/Tools.active_tools.find(tool_type)
	
	if tool_tile.count < 1:
		return
	
	if tool_tile.selected:
		Events.DeselectTools.emit()
		Board.select(0)
		return
	
	return_selected_to_pit()
	
	Events.DeselectTools.emit()
	
	tool_tile.selected = true
	$background/Tools.selected_tool = tool_type
	Board.select(tool_type,Events.Type.tool)

	Events.PlaySound.emit("Tools/selected")

func find_best_pit() -> Array:
	var colors = []
	var used_squares = []
	
	#Step 1: Find any lines of 2 on the board, and give the missing color to complete those.
	for x in range(Board.COLUMNS):
		for y in range(Board.ROWS):
			if Board.get_square(Vector2(x,y)) not in Item.GEMS:
				continue
			var lines = $background/Line.detect_lines(Vector2(x,y))
			for line in lines:
				if used_squares.any(func(item): return item in line):
					break
				
				if len(line) >= 2:
					used_squares += line
					colors.append(Board.get_square(Vector2(x,y)))
					break
			if len(colors) >= 3:
				break
		if len(colors) >= 3:
			break
	
	#Step 2:
	#If we found no lines, find single gems on the board and add them to the pit.
	if len(colors) == 0 and Board.board.any(func(item):return item in Item.GEMS):
		var _board = Board.board.duplicate()
		_board.shuffle()
		for item in _board:
			if item in Item.GEMS:
				colors.append(item)
			if len(colors) >= $background/Pit.SQUARES:
				break
	
	#Step 3: If there's no colors at all on the board, give players 2 of the same color.
	if len(colors) == 0:
		var _color = $background/Pit.OPTIONS.pick_random()
		colors.append(_color)
		colors.append(_color)
	
	#Step 4: Fill the remainder of the pit with random colors
	if len(colors) < $background/Pit.SQUARES:
		for __ in range($background/Pit.SQUARES - len(colors)):
			colors.append($background/Pit.OPTIONS.pick_random())
	
	#Step 5: Trim down the list of colors to the size of the pit and return it.
	
	assert (len(colors) >= $background/Pit.SQUARES)
	
	colors.shuffle()
	return colors.slice(0,$background/Pit.SQUARES)

func evaluate_external_tool(location,tool,use_tool=true,preview=false):
	if preview:
		use_tool = false
	else:
		Preview.delete_all_previews()
	var Tools = $background/Tools.Tools
	
	var square_type
	if location is int:
		square_type = $background/Pit.get_item(location)
	elif location is Vector2:
		square_type = Board.get_square(location)
	else:
		printerr('"location" parameter needs to be of type "int" or "Vector2", not %s.' % [typeof(location)])
	
	$background/Tools.get_tool($background/Tools.selected_tool)
	
	if (tool == Tools.pickaxe) and (square_type == Item.AIR) and !preview:
		Events.PlaySound.emit("Gameplay/nomatch")
		return
	
	if use_tool:
		var tool_index = $background/Tools.active_tools.find(tool)
		$background/Tools.tool_counts[tool_index] -= 1
		$background/Tools.get_tool(tool).count = $background/Tools.tool_counts[tool_index]
		Events.DeselectTools.emit()
		Board.select(Item.AIR)
	
	
	match tool:
		Tools.pickaxe:
			if preview:
				if square_type == Item.AIR:
					Preview.create_preview(location,Item.CROSS)
					return
				Preview.create_preview(location,Item.AIR)
				return
			Events.AddScore.emit(10)
			Events.PlaySound.emit("Tools/pickaxe")
			if square_type in Item.GAME_TOOLS:
				evaluate_game_tool(location,false)
				return
			Board.remove_square(location)
		
		Tools.axe:
			if preview:
				clear_line(location,"h",false,Color.WHITE,true,true)
				return
			Events.PlaySound.emit("Drill/use")
			clear_line(location,"h",true,Color.WHITE,false,true)
		
		Tools.jackhammer:
			if preview:
				clear_line(location,"v",false,Color.WHITE,true,true)
				return
			Events.PlaySound.emit("Drill/use")
			clear_line(location,"v",true,Color.WHITE,false,true)
		
		Tools.star:
			if preview:
				clear_line(location,"h",false,Color.WHITE,true)
				clear_line(location,"v",false,Color.WHITE,true)
				clear_diagonal_lines(location,false,true)
				return
				
			Events.PlaySound.emit("Tools/star")
			clear_line(location,"v",true,Color.GOLDENROD)
			clear_line(location,"h",true,Color.GOLDENROD)
			await clear_diagonal_lines(location)
		
		Tools.bucket:
			printerr("Bucket tool is not yet implemented")
			assert (false)
		
		Tools.dice:
			Events.PlaySound.emit("Tools/dice")
			var last_tile
			for tile in $background/Pit.foreground_tiles:
				tile.animation_player.play("vanish")
				last_tile = tile
			await last_tile.animation_player.animation_finished
			
			var old_pit: Array = $background/Pit.pit
			var new_pit = find_best_pit()
			old_pit.clear()
			old_pit.append_array(new_pit)
			$background/Pit.draw()
			for tile in $background/Pit.foreground_tiles:
				tile.animation_player.play("pop")
				last_tile = tile
			await last_tile.animation_player.animation_finished
	
	if preview:
		return
	
	if location is Vector2:
		Board.draw()
	
	if board_empty():
		await get_tree().create_timer(0.5).timeout
		random_place($background/Pit.OPTIONS)
		Events.PlaySound.emit("Gameplay/place")

func tile_hovered(tile: BackgroundTile):
	if tile.type == Events.Type.preview:
		return
	
	Preview.delete_all_previews()
	
	if Board.game_over:
		return
	
	var location = Vector2(tile.x,tile.y)
	
	if tile.type == Events.Type.board:
		if $background/Tools.selected_tool != null:
			if $background/Tools.selected_tool == $background/Tools.Tools.dice:
				return
			evaluate_external_tool(location,$background/Tools.selected_tool,false,true)
		
		elif Board.selected:
			place_tile(Board.selected,location,true)
		
		else: evaluate_game_tool(location,true,true)

func tile_clicked(tile):
	if Board.game_over:
		return
	var location = Vector2(tile.x,tile.y)
	if tile.type == Events.Type.board:
		if $background/Tools.selected_tool != null:
			if $background/Tools.selected_tool == $background/Tools.Tools.dice:
				return
			evaluate_external_tool(location,$background/Tools.selected_tool)
			
		
		elif Board.selected:
			place_tile(Board.selected,location)
		else:
			evaluate_game_tool(location)
		
	
	if tile.type == Events.Type.pit:
		if $background/Tools.selected_tool == $background/Tools.Tools.dice:
			evaluate_external_tool(tile.x,$background/Tools.selected_tool)
			return
		select_pit_item(tile.x)
	
	if tile.type == Events.Type.tool:
		select_tool(tile)
