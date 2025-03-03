extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.AddScore.connect(add_score)
	_update()

func evaluate_next_level():
	if $"../../Board".score >= $"../../Board".goal:
		$"../../Board".next_level()

func add_score(score):
	var score_to_add = score*$"../../Board".level
	
	var final_score = score_to_add + $"../../Board".score
	const SCORE_TIME = 0.5
	var STEP = 3
	var sleep_time = SCORE_TIME/(float(score_to_add)/STEP)
	
	self_modulate = Color(300,300,300)
	while $"../../Board".score < final_score:
		$"../../Board".score += STEP
		$"../../Board".score = min($"../../Board".score,final_score)
		_update()
		await get_tree().create_timer(sleep_time).timeout
	_update()
	self_modulate = Color(1,1,1)
	
	evaluate_next_level()
	
func _update():
	add_theme_font_size_override("normal_font_size", _calculate_font_size($"../../Board".score))
	text = "[center]%s" % [$"../../Board".score]
	
	$"../Level".add_theme_font_size_override("normal_font_size", _calculate_font_size($"../../Board".level))
	$"../Level".text = "[center]%s" % [$"../../Board".level]
	
	$"../Goal".add_theme_font_size_override("normal_font_size", _calculate_font_size($"../../Board".goal))
	$"../Goal".text = "[center]%s" % [$"../../Board".goal]
	
	$"../Moves".add_theme_font_size_override("normal_font_size", _calculate_font_size($"../../Board".moves))
	$"../Moves".text = "[center]%s" % [$"../../Board".moves]

func _calculate_font_size(score) -> int:
	var font_size = 50
	var score_string = str(score)
	
	if len(score_string) < 3:
		return font_size
	
	font_size -= 10* (len(score_string) - 2)
	
	return font_size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
