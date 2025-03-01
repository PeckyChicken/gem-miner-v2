extends Node2D

var PRESSED_KEYS = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup.call_deferred()

func setup():
	Events.TileClicked.connect(tile_clicked)
	Board.draw_background($background/background_tile)
	Board.draw($background/tile)
	Pit.draw_background($background/tool_background_tile)
	Pit.fill()
	Pit.draw($background/tile)
	
	$background/selection_tile.type = Events.Type.selected
	random_place(Pit.OPTIONS)
	random_place(Pit.OPTIONS)
	random_place([13])
	random_place([13])
	random_place([13])
	random_place([13])

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
	Board.draw($background/tile,selection)
	Board.pop_in(selection)

func _process(_delta: float) -> void:
	pass

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index not in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		Events.MouseClicked.emit(event.button_index,event.position)
	
	if event is InputEventKey and event.is_pressed():
		var character = char(event.unicode)
		if character.is_valid_int():
			var pos = int(character) - 1
			select_pit_item(pos)

func validate_tile_placement(location:Vector2):
	if Board.get_square(location) != 0:
		return false
	
	var directions = Board.calculate_directions(location)
	
	if  directions.all(func(c): return Board.get_square(c) == 0):
		return false
	
	return true

func add_bricks():
	var count = 1
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

func create_game_tool(location:Vector2,clears,horizontal_matches,vertical_matches):
	if len(clears) == 4: #Drills
		if len(horizontal_matches) == 4: #Vertical drill
			Board.set_square(location,11)
		
		elif len(vertical_matches) == 4: #Horizontal drill
			Board.set_square(location,10)
		else:
			printerr("4 gems were cleared but there was not a line of 4 in either direction.\nTHIS SHOULD NOT BE HAPPENING.")
			assert(false)
		
		Events.PlaySound.emit("Drill/create")
	
	if len(horizontal_matches) >= 5 or len(vertical_matches) >= 5: #Diamonds
		if len(horizontal_matches) >= 5 and len(vertical_matches) >= 5:
			Board.set_square(location,9)
			Events.PlaySound.emit("Diamond/double_create")
		else:
			#The diamonds are 4 offsets from the gems
			Board.set_square(location,Board.get_square(location)+4)
			Events.PlaySound.emit("Diamond/create")
	
	elif len(horizontal_matches) >= 3 and len(vertical_matches) >= 3: #Bombs
		Board.set_square(location,12)
		Events.PlaySound.emit("Bomb/create")
	
	for l in [location] + clears:
		Board.draw($background/tile,l)
	
	await Board.pop_in(location)

func create_lightning(point_a:Vector2,point_b:Vector2,color: Color) -> Node2D:
	var lightning = $Lightning.duplicate()
	var lightning_line: Line2D = lightning.get_node("Line")
	lightning_line.position = Vector2(Board.width/Board.ROWS / 2,Board.height/Board.COLUMNS / 2)
	
	var point_a_node = Board._get_background_square(point_a)
	
	var dx = point_b[0] - point_a[0]
	var dy = point_b[1] - point_a[1]
	dx *= Board.width/Board.ROWS
	dy *= Board.height/Board.COLUMNS

	lightning_line.points = [Vector2(0,0), Vector2(dx,dy)]
	lightning.modulate = color
	
	lightning.show()
	point_a_node.add_child(lightning)
	
	return lightning

func diamond(location:Vector2,type):
	var lights = []
	var squares = []
	for square_x in Board.COLUMNS:
		for square_y in Board.ROWS:
			var square_location = Vector2(square_x,square_y)
			if Board.get_square(square_location) == type-4:
				Board._get_foreground_square(square_location).align_for_animation()
				Board._get_foreground_square(square_location).animation_player.play("energized")
				squares.append(square_location)
				
				var lightning = create_lightning(location,square_location,Board.COLORS[type-5])
				lightning.animation_player.play("energized")
				lights.append(lightning)
	
	replace_squares(type-4,0)
	Events.AddScore.emit(10)
	Board.set_square(location,0)
	Events.PlaySound.emit("Diamond/use")
	Board._get_foreground_square(location).animation_player.play("diamond")
	if len(lights) > 0:
		await lights[0].animation_player.animation_finished
	for light in lights:
		light.queue_free()
	Brick.destroy_bricks(squares+[location])
	
	await Board._get_foreground_square(location).animation_player.animation_finished

func evaluate_game_tool(location,calculate_combo=true):
	var type = Board.get_square(location)
	var GAME_TOOLS = range(5,13)
	
	if type not in GAME_TOOLS:
		return
	
	if type == 9:
		await double_diamond(location)
	
	if calculate_combo:
		var combo = calculate_tool_combo(location)
		if len(combo) > 1:
			await evaluate_tool_combo(location,combo)
		if board_empty():
			random_place(Pit.OPTIONS)
			Events.PlaySound.emit("Gameplay/place")
		if len(combo) > 1:
			return
			
	
	if type >= 5 and type <= 8:
		await diamond(location,type)
		
	if type == 10:
		clear_line(location,"h")
		Events.PlaySound.emit("Drill/use")
		
	if type == 11:
		clear_line(location,"v")
		Events.PlaySound.emit("Drill/use")
		
	if type == 12:
		clear_blast(location,1)
		Events.PlaySound.emit("Bomb/use")
		#await Board._get_foreground_square(x,y).explode()
	
	Board.draw($background/tile)
	
	if board_empty():
		random_place(Pit.OPTIONS)
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

func evaluate_tool_combo(location:Vector2,combo):
	await Line.animate_line_clear(location,combo,false)
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
	assert (0 not in top_two)
	
	if top_two[0] in [5,6,7,8] and top_two[1] in [5,6,7,8]:
		await double_diamond(location)
	
	if top_two.any(func(n):return n in [5,6,7,8,9]):
		var color
		for one in top_two:
			if one in [5,6,7,8,9]:
				color = one-4
		if 10 in top_two or 11 in top_two:
			var replacements = replace_squares(color,[10,11])
			for replacement in replacements:
				evaluate_game_tool(replacement,false)
		if 13 in top_two:
			var replacements = replace_squares(color,13)
			for replacement in replacements:
				evaluate_game_tool(replacement,false)
	
	if top_two[0] == 12 and top_two[1] == 12:
		Events.PlaySound.emit("Bomb/use")
		clear_blast(location,2)
	
	if top_two[0] in [10,11] and top_two[1] in [10,11]:
		Events.PlaySound.emit("Drill/use")
		clear_line(location,"V")
		clear_line(location,"H")
	

func handle_lines(location:Vector2):
	var lines = Line.detect_lines(location)
	var horizontal_matches = lines[0]
	var vertical_matches = lines[1]
	var clears = []
	if len(horizontal_matches) >= 3:
		clears += horizontal_matches
		
	if len(vertical_matches) >= 3:
		clears += vertical_matches
	
	if len(clears) == 0:
		add_bricks()
		return
	
	var type = Board.get_square(location)
	Board.clear_gems(clears)
	Board.set_square(location,type)
	
	Events.PlaySound.emit("Gameplay/break")
	Events.AddScore.emit(10*(len(horizontal_matches+vertical_matches)))
	
	Events.DestroyBricks.emit(clears)

	
	await Line.animate_line_clear(location,clears)
	
	if len(clears) == 3:
		vanish_gems(location)
		Board.set_square(location,0)
	else:
		await create_game_tool(location,clears,horizontal_matches,vertical_matches)
	
	for item in clears:
		Board._get_foreground_square(item).queue_free()
		Board.draw($background/tile,item)
	
	if board_empty():
		random_place(Pit.OPTIONS)
		Events.PlaySound.emit("Gameplay/place")

func board_empty():
	return Board.board.all(func(__): return __ == 0)

func place(location,value):
	Board.set_square(location,value)
	Events.PlaySound.emit("Gameplay/place")
	
	Board.draw($background/tile,location)
	Board.select(0,$background/tile,$background/selection_tile)
	Pit.fill()
	Pit.draw($background/tile)
	Events.AddScore.emit(1)
	await Board.pop_in(location)

func clear_line(location,direction:String):
	assert (direction.to_lower() in ["h","v"])
	var x_positions = []
	var y_positions = []
	if direction.to_lower() == "h":
		x_positions = range(Board.COLUMNS)
	else:
		x_positions.resize(Board.COLUMNS)
		x_positions.fill(location.x)
	
	if direction.to_lower() == "v":
		y_positions = range(Board.ROWS)
	else:
		y_positions.resize(Board.ROWS)
		y_positions.fill(location.y)
	
	
	for cur_x in x_positions:
		for cur_y in y_positions:
			var cur_location = Vector2(cur_x,cur_y)
			if Board.get_square(cur_location) != 0:
				Events.AddScore.emit(10)
			if cur_location != location:
				evaluate_game_tool(cur_location,false)
			Board.remove_square(cur_location)

func clear_blast(location,radius:int):
	var cur_x = location.x - radius
	var cur_y
	while cur_x <= location.x + radius:
		cur_y = location.y - radius
		while cur_y <= location.y + radius:
			var cur_location = Vector2(cur_x,cur_y)
			if Board.within_board(cur_location):
				if Board.get_square(cur_location) != 0:
					Events.AddScore.emit(10)
				if cur_location != location:
					evaluate_game_tool(cur_location,false)
				Board.remove_square(cur_location)
			cur_y += 1
		cur_x += 1

func select_pit_item(pos:int):
	var temp = Board.selected
	Board.select(Pit.get_item(pos),$background/tile,$background/selection_tile)
	Pit.set_item(pos,temp)
	Pit.draw($background/tile)

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

func tile_clicked(tile):
	var location = Vector2(tile.x,tile.y)
	if tile.type == Events.Type.board:
		if Board.selected:
			if validate_tile_placement(location):
				if Board.mode == "obstacle":
					Board.moves -= 1
					Events.AddScore.emit(0)
				await place(location,Board.selected)
				handle_lines(location)
				if Board.evaluate_game_over():
					get_tree().quit()

			else:
				Events.PlaySound.emit("Gameplay/nomatch")
		else:
			evaluate_game_tool(location)
	
	if tile.type == Events.Type.pit:
		select_pit_item(tile.x)
