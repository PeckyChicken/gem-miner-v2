extends CanvasLayer

const BACKGROUNDS = {Game.Mode.survival:1,Game.Mode.time_rush:2,Game.Mode.obstacles:3,Game.Mode.ascension:7}

var PRESSED_KEYS = []

@onready var Board: brd = $background/Board
@onready var Preview: previewer = $background/Preview
@onready var Upgrade: upgrade_class = $background/Upgrade

const PAUSE_MENU_SCENE = preload("res://Global/pause_menu.tscn")
var pause_menu: PauseMenu

var time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup.call_deferred()
	await $Fade.fade_out(0.5)
	if Game.current_mode == Game.Mode.survival:
		if Music.playing not in ["survival1","survival2"]:
			Music.play(["survival1","survival2"].pick_random())
	else:
		if Game.Mode.keys()[Game.current_mode] != Music.playing:
			Music.play(Game.Mode.keys()[Game.current_mode])

func _process(delta: float) -> void:

	if Game.current_mode == Game.Mode.time_rush and not Board.game_over:
		time += delta
		if time >= 1:
			if not get_tree().paused:
				add_bricks()
			while time >= 1:
				time -= 1
			if Board.evaluate_game_over():
				Events.GameOver.emit()

func setup():
	set_background(Game.current_mode)

	Events.TileClicked.connect(tile_clicked)
	Events.TileHovered.connect(tile_hovered)
	Events.Pause.connect(pause)
	Events.Resume.connect(resume)
	
	Board.draw_background()
	Board.draw()
	$background/Pit.draw_background()
	$background/Pit.fill()
	
	if Config.first_time:
		var tutorial_color = Game.GEMS.pick_random()
		var mid = Vector2(floori(Board.COLUMNS/2.0),floori(Board.ROWS/2.0))
		Board.set_square(mid,tutorial_color)
		Board.set_square(mid+Vector2(1,0),tutorial_color)
		Board.set_square(mid+Vector2(0,1),Game.Item.BRICK)
		Board.set_square(mid+Vector2(1,1),Game.Item.BRICK)
		Board.set_square(mid-Vector2(0,1),Game.Item.BRICK)
		Board.set_square(mid-Vector2(-1,1),Game.Item.BRICK)
		$background/Pit.set_item(0,tutorial_color)
	else:
		random_place($background/Pit.OPTIONS)
		random_place($background/Pit.OPTIONS)
		
		random_place([Game.Item.BRICK])
		if Game.current_mode != Game.Mode.obstacles:
			random_place([Game.Item.BRICK])
			random_place([Game.Item.BRICK])
			random_place([Game.Item.BRICK])
		
		random_place([Game.Item.RAINBOW_DIAMOND])
	
	Board.draw()
	$background/Pit.draw()
	

func set_background(mode):

	if mode == Game.Mode.ascension:
		$ascension_particles.show()
	else:
		$ascension_particles.queue_free()
	
	if mode == Game.Mode.obstacles:
		$background/Hud/Goal.hide()
		$background/Hud/Goal_Label.hide()
		$background/Hud/Moves.show()
		$background/Hud/Moves_Label.show()
	
	#$background.frame = BACKGROUNDS[mode]

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
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			get_tree().paused = false
			Events.Resume.emit()
		else:
			Events.Pause.emit()
	
	if get_tree().paused:
		return
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index not in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		Events.MouseClicked.emit(event.button_index,event.position)
	
	if event is InputEventKey and event.is_pressed():
		var character = char(event.unicode)
		if character.is_valid_int():
			var pos = int(character) - 1
			if len($background/Pit.pit) > pos:
				select_pit_item(pos)
				Events.UpdateHover.emit()

func pause():
	Events.PlaySound.emit("Gameplay/click")
	if pause_menu:
		var player: AnimationPlayer = pause_menu.get_node("AnimationPlayer")
		if player.is_playing():
			await player.animation_finished
	get_tree().paused = true
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	

func resume():
	if pause_menu.options_menu:
		pause_menu.options_menu.queue_free()
		pause_menu.show()
	var player: AnimationPlayer = pause_menu.get_node("AnimationPlayer")
	if player.is_playing():
		await player.animation_finished
	
	get_tree().paused = false
	
	player.play("unpause")
	await player.animation_finished
	pause_menu.queue_free()

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
			tool = Game.Item.V_DRILL
		
		elif len(vertical_matches) == 4: #Horizontal drill
			tool = Game.Item.H_DRILL
		else:
			printerr("4 gems were cleared but there was not a line of 4 in either direction.\nTHIS SHOULD NOT BE HAPPENING.")
			assert(false)
		
		sound = "Drill/create"
	
	if len(horizontal_matches) >= 5 or len(vertical_matches) >= 5: #Diamonds
		if len(horizontal_matches) >= 5 and len(vertical_matches) >= 5:
			tool = Game.Item.RAINBOW_DIAMOND
			sound = "Diamond/double_create"
		else:
			#The diamonds are 4 offsets from the gems
			tool = Board.get_square(location)+4
			sound = "Diamond/create"
	
	elif len(horizontal_matches) >= 3 and len(vertical_matches) >= 3: #Bombs
		tool = Game.Item.BOMB
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

func diamond(location:Vector2,type,replacements:Array=[Game.Item.AIR],preview=false) -> Array[Vector2]:
	var lights = []
	var squares: Array[Vector2] = []
	for square_x in Board.COLUMNS:
		for square_y in Board.ROWS:
			var square_location = Vector2(square_x,square_y)
			if Board.get_square(square_location) == type-4:
				squares.append(square_location)
				if preview:
					continue
				
				var tile: GameTile = Board._get_foreground_square(square_location)
				tile.z_index = 2
				tile.align_for_animation()
				tile.animation_player.play("energized")
				var lightning = create_lightning(location,square_location,Board.COLORS[type-5])
				lightning.z_index = 1
				lightning.animation_player.play("energized")
				lights.append(lightning)
	
	replace_squares(type-4,replacements,preview)
	
	if preview:
		Preview.create_preview(location,Game.Item.AIR)
		return squares
	
	
	
		
	Events.AddScore.emit(10)
	Board.set_square(location,Game.Item.AIR)
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
	
	if type == Game.Item.RAINBOW_DIAMOND:
		await double_diamond(location,preview)
	
	if calculate_combo:
		var combo = calculate_tool_combo(location)
		if len(combo) > 1:
			await evaluate_tool_combo(location,combo,preview)
		if board_empty():
			random_place($background/Pit.OPTIONS)
			Events.PlaySound.emit("Gameplay/place")
		if len(combo) > 1:
			return
			
	
	if type in Game.DIAMONDS and type != Game.Item.RAINBOW_DIAMOND:
		await diamond(location,type,[0],preview)
	
	if type == Game.Item.H_DRILL:
		if !preview:
			Events.PlaySound.emit("Drill/use")
		await clear_line(location,"h",true,Color.WHITE,preview)
		
	if type == Game.Item.V_DRILL:
		if !preview:
			Events.PlaySound.emit("Drill/use")
		await clear_line(location,"v",true,Color.WHITE,preview)
		
	if type == Game.Item.BOMB:
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
	var PRIORITIES = [Game.DIAMONDS,[Game.Item.BOMB],Game.DRILLS,[Game.Item.AIR]]
	var priority = 0
	for p in PRIORITIES:
		if item_type in p:
			break
		priority += 1
	return priority

func double_diamond(location:Vector2,preview:bool=false):
	var square = Board._get_foreground_square(location)
	var lights = []
	if !preview:
		Events.PlaySound.emit("Diamond/double_diamond")
		square.double_diamond_spin(3)
	
	for cur_x in Board.COLUMNS:
		for cur_y in Board.ROWS:
			var cur_location = Vector2(cur_x,cur_y)
			var item = Board.get_square(cur_location)
			if preview:
				if item != Game.Item.AIR:
					Preview.create_preview(cur_location,Game.Item.AIR)
				continue
			var item_object = Board._get_foreground_square(cur_location)
			if item != 0:
				var color = Board.COLORS[len(lights)%len(Board.COLORS)]
				var light = create_lightning(location,cur_location,color)
				lights.append(light)
				light.animation_player.play("energized")
			if not item_object.animation_player.is_playing():
				if not cur_location == location:
					item_object.animation_player.play("energized")
	
	if preview:
		return
	
	if len(lights) > 0:
		await lights[0].animation_player.animation_finished
	for light in lights:
		light.queue_free()
	
	
	Events.AddScore.emit(100)
	Board.clear_board()
	await square.SpinFinished
	square.animation_player.play("vanish")
	await square.animation_player.animation_finished
	Board.evaluate_next_level()

func evaluate_tool_combo(location:Vector2,combo:Array,preview=false):
	if !preview:
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
	
	var sorted_combo = combo.duplicate()
	sorted_combo.sort_custom(func(item,item2): return _get_priority(Board.get_square(item)) < _get_priority(Board.get_square(item2)))
	
	for item in sorted_combo:
		var item_type = Board.get_square(item)
		var priority = _get_priority(item_type)
		var index = 0
		for top in top_two:
			if priority < _get_priority(top):
				top_two[index] = item_type
				break
			index += 1
		
		if !preview:
			Board.set_square(item,Game.Item.AIR)
		
	assert (0 not in top_two)
	
	if top_two[0] in Game.DIAMONDS and top_two[1] in Game.DIAMONDS:
		if !preview:
			Board.set_square(location,Game.Item.RAINBOW_DIAMOND)
		await double_diamond(location,preview)
		if preview:
			return
	
	if top_two.any(func(n):return n in Game.DIAMONDS):
		var color
		for item in top_two:
			if item in Game.DIAMONDS:
				color = item
		
		var tool_type: Array
		if Game.Item.H_DRILL in top_two or Game.Item.V_DRILL in top_two:
			tool_type = Game.DRILLS
		elif Game.Item.BOMB in top_two:
			tool_type = [Game.Item.BOMB]
		
		var replacements: Array[Vector2] = await diamond(location,color,tool_type,preview)
		replacements.shuffle()
		for replacement in replacements:
			if Board.get_square(replacement) == Game.Item.AIR:
				continue
			await evaluate_game_tool(replacement,false)
	
	if top_two == [Game.Item.BOMB,Game.Item.BOMB]:
		if !preview:
			Events.PlaySound.emit("Bomb/use")
			Board._get_foreground_square(location).explode(2)
			
		clear_blast(location,2,preview)
	
	if top_two.any(func(x): return x in Game.DRILLS):
		if Game.Item.BOMB in top_two:
			if !preview:
				Events.PlaySound.emit("Drill/use")
			const V_SHIFT = Vector2(0,1)
			const H_SHIFT = Vector2(1,0)
			
			clear_line(location-H_SHIFT,"V",true,Color.WHITE,preview)
			clear_line(location,"V",true,Color.WHITE,preview)
			clear_line(location+H_SHIFT,"V",true,Color.WHITE,preview)
			
			clear_line(location-V_SHIFT,"H",true,Color.WHITE,preview)
			clear_line(location,"H",true,Color.WHITE,preview)
			clear_line(location+V_SHIFT,"H",true,Color.WHITE,preview)
	
	if top_two[0] in Game.DRILLS and top_two[1] in Game.DRILLS:
		if !preview:
			Events.PlaySound.emit("Drill/use")
		clear_line(location,"V",true,Color.WHITE,preview)
		clear_line(location,"H",true,Color.WHITE,preview)
	

func handle_lines(location:Vector2,lines:Array[Array],preview=false):
	var horizontal_matches = lines[0]
	var vertical_matches = lines[1]
	var clears = []
	if len(horizontal_matches) >= 3:
		clears += horizontal_matches
		
	if len(vertical_matches) >= 3:
		clears += vertical_matches
	
	if !preview:
		if len(clears) == 0:
			if Game.current_mode not in [Game.Mode.obstacles,Game.Mode.time_rush]:
				add_bricks()
			return
		var mult = 1
		var type = Board.get_square(location)
		Board.clear_gems(clears)
		Board.set_square(location,type)
		
		Events.PlaySound.emit("Gameplay/break")
		
		if Game.current_mode == Game.Mode.ascension:
			for item in Upgrade.upgraded_gems:
				if Board.get_square(location) == item:
					mult *= 2
		Events.AddScore.emit(10*(len(horizontal_matches+vertical_matches)) * mult)
		
		Events.DestroyBricks.emit(clears)

		
		await $background/Line.animate_line_clear(location,clears)
	
	if len(clears) == 3:
		if preview:
			for clear in clears:
				Preview.create_preview(clear,Board.get_square(clear))
		else:
			vanish_gems(location)
			Board.set_square(location,Game.Item.AIR)
	
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
	return Board.board.all(func(__): return __ == Game.Item.AIR)

func _place(location,value,preview=false):
	if preview:
		Preview.create_preview(location,value)
		return
	Board.set_square(location,value)
	Events.PlaySound.emit("Gameplay/place")
	
	Board.draw(location)
	Board.select(Game.Item.AIR)
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
			if Board.get_square(cur_location) in Game.GAME_TOOLS:
				if external_tool or (cur_location != location):
					chains.append(cur_location)
			
			if preview:
				if Preview.previews.any(func(_preview): return _preview.location == cur_location):
					continue
				Preview.create_preview(cur_location,Game.Item.AIR)
				continue
			
			if Board.get_square(cur_location) != Game.Item.AIR:
				Events.AddScore.emit(10)
			if Board.get_square(cur_location) in Game.BRICKS:
				$background/Brick._destroy_brick(cur_location)
			
			
			if Board.get_square(cur_location) in Game.GEMS:
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
			Preview.create_preview(clear,Game.Item.AIR)
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

	if !preview:
		Board.remove_square(location,false)

	while cur_x <= location.x + radius:
		cur_y = location.y - radius
		while cur_y <= location.y + radius:
			var cur_location = Vector2(cur_x,cur_y)
			if Board.within_board(cur_location):
				if preview:
					Preview.create_preview(cur_location,Game.Item.AIR)
					cur_y += 1
					continue
				
				if cur_location != location:
					evaluate_game_tool(cur_location,false,preview)

				
				if Board.get_square(cur_location) != Game.Item.AIR:
					Events.AddScore.emit(10)
				
				if Board.get_square(cur_location) in Game.BRICKS:
					$background/Brick._destroy_brick(cur_location)
				
				if Board.get_square(cur_location) in Game.GEMS:
					Board.remove_square(cur_location)
			cur_y += 1
		cur_x += 1

func select_pit_item(pos:int):
	if Board.game_over:
		return
	
	if $background/Tools.selected_tool != null:
		Events.DeselectTools.emit()
	
	var temp = Board.selected
	Board.select($background/Pit.get_item(pos))
	$background/Pit.set_item(pos,temp)
	$background/Pit.draw()

func replace_squares(type,replacements:Array,preview):
	var index = 0
	var replaced_squares = []
	for item in Board.board:
		if item == type:
			# Rotating through replacements
			var replace = replacements[len(replaced_squares) % len(replacements)]
			
			if preview:
				Preview.create_preview(Board._index_to_coords(index),replace)
			else:
				Board.board[index] = replace
				Events.AddScore.emit(10)
				
			replaced_squares.append(Board._index_to_coords(index))
			
		index += 1
	return replaced_squares

func place_tile(tile,location,preview=false):
	if !preview:
		Preview.delete_all_previews()
	if not validate_tile_placement(location):
		if Board.get_square(location) == Game.Item.AIR:
			Preview.create_preview(location,Game.Item.CROSS)
		
		if preview:
			return
		Events.PlaySound.emit("Gameplay/nomatch")
		return
	
	if Game.current_mode == Game.Mode.obstacles and !preview:
		Board.moves -= 1
		Events.AddScore.emit(0)
	
	var lines
	if !preview:
		Board.set_square(location,tile)
		lines = $background/Line.detect_lines(location)
		await _place(location,tile)
	var temp_board: Array[int] = Board.board.duplicate()
	if preview:
		Board.set_square(location,tile)
		lines = $background/Line.detect_lines(location)
	
	handle_lines(location,lines,preview)
	if preview:
		Board.board = temp_board.duplicate()
		return
	if Board.evaluate_game_over() and Game.current_mode == Game.Mode.obstacles:
		#If player is out of moves on obstacles, check if they've at least cleared the level.
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

func find_best_pit() -> Array[int]:
	var colors: Array[int] = []
	var used_squares: Array = []
	
	#Step 1: Find any lines of 2 on the board, and give the missing color to complete those.
	for x in range(Board.COLUMNS):
		for y in range(Board.ROWS):
			if Board.get_square(Vector2(x,y)) not in Game.GEMS:
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
	if len(colors) == 0 and Board.board.any(func(item):return item in Game.GEMS):
		var _board = Board.board.duplicate()
		_board.shuffle()
		for item in _board:
			if item in Game.GEMS:
				colors.append(item)
			if len(colors) >= $background/Pit.SQUARES:
				break
	
	#Step 3: If there's a diamond on the board, give players colors of the diamond.
	if len(colors) == 0 and Board.board.any(func(item):return item in Game.DIAMONDS):
		var _board = Board.board.duplicate()
		_board.shuffle()
		for item in _board:
			if item in Game.DIAMONDS:
				colors.append(item-4)
			if len(colors) >= $background/Pit.SQUARES:
				break
		
		# If just 1 color, duplicate it.
		if len(colors) == 1:
			colors.append(colors[0])
	
	#Step 4: If there's no colors at all on the board, give players 2 of the same color.
	if len(colors) == 0:
		var _color = $background/Pit.OPTIONS.pick_random()
		colors.append(_color)
		colors.append(_color)
	
	#Step 5: Fill the remainder of the pit with random colors
	if len(colors) < $background/Pit.SQUARES:
		for __ in range($background/Pit.SQUARES - len(colors)):
			colors.append($background/Pit.OPTIONS.pick_random())
	
	#Step 6: Trim down the list of colors to the size of the pit and return it.
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
	
	if (tool == Tools.pickaxe) and (square_type == Game.Item.AIR) and !preview:
		Events.PlaySound.emit("Gameplay/nomatch")
		return
	
	if use_tool:
		var tool_index = $background/Tools.active_tools.find(tool)
		$background/Tools.tool_counts[tool_index] -= 1
		$background/Tools.get_tool(tool).count = $background/Tools.tool_counts[tool_index]
		Events.DeselectTools.emit()
		Board.select(Game.Item.AIR)
	
	
	match tool:
		Tools.pickaxe:
			if preview:
				if square_type == Game.Item.AIR:
					Preview.create_preview(location,Game.Item.CROSS)
					return
				Preview.create_preview(location,Game.Item.AIR)
				return
			Events.AddScore.emit(10)
			Events.PlaySound.emit("Tools/pickaxe")
			if square_type in Game.GAME_TOOLS:
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
	if get_tree().paused:
		return
	
	if tile.type == Events.Type.preview:
		return
	
	Preview.delete_all_previews()
	
	if Board.game_over:
		return
	
	if not Game.preview:
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
	if Board.game_over or get_tree().paused:
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
