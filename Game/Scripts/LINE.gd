extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _get_directional_line(location:Vector2,delta:Vector2,color):
	var line = []
	var cur_location = location
	while $"../Board".within_board(cur_location) and $"../Board".get_square(cur_location) == color:
		if cur_location not in line:
			line.append(cur_location)
		cur_location += delta
	return line

func remove_duplicates(list:Array):
	var used_values = []
	var index = 0
	for item in list:
		if item in used_values:
			list.pop_at(index)
		else:
			used_values.append(item)
		index += 1

func detect_lines(location:Vector2):
	var vertical_matches = []
	var horizontal_matches = []
	var line_color = $"../Board".get_square(location)
	
	vertical_matches += _get_directional_line(location,Vector2(0,-1),line_color)
	vertical_matches += _get_directional_line(location,Vector2(0,1),line_color)
	
	horizontal_matches += _get_directional_line(location,Vector2(-1,0),line_color)
	horizontal_matches += _get_directional_line(location,Vector2(1,0),line_color)
	
	remove_duplicates(vertical_matches)
	remove_duplicates(horizontal_matches)
	
	return [horizontal_matches,vertical_matches]

func animate_line_clear(location:Vector2,matches: Array,disappear=true):
	var tween = get_tree().create_tween().set_parallel()
	var square_width = $"../Board".width/$"../Board".COLUMNS
	#var square_height = $"../Board".height/$"../Board".ROWS
	
	for item in matches:
		var delta = (location-item)*square_width
		
		var object = $"../Board"._get_foreground_square(item)
		tween.tween_property(object,"position",object.position+delta,0.2)
	
	await tween.finished
	if not disappear:
		return
	
	remove_duplicates(matches)
	
	for item in matches.slice(1):
		$"../Board"._get_foreground_square(item).hide()
	
	var item = matches[0]
	var shrink_object: Sprite2D = $"../Board"._get_foreground_square(item)
	shrink_object.align_for_animation()
	shrink_object.animation_player.play("vanish")
	
	await shrink_object.animation_player.animation_finished

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
