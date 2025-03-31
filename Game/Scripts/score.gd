extends RichTextLabel

@onready var board: brd = $"../../Board"

var high_score_beaten: bool = false
const HIGH_SCORE_COLOR = Color.CHARTREUSE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.AddScore.connect(add_score)
	_update()

func add_score(score):
	var score_to_add = score*board.level
	
	var final_score = score_to_add + board.score
	const SCORE_TIME = 0.5
	var STEP = max(3,board.level)
	var sleep_time = SCORE_TIME/(float(score_to_add)/STEP)
	
	self_modulate = Color(300,300,300)
	while board.score < final_score:
		board.score += STEP
		board.score = min(board.score,final_score)
		_update()
		await get_tree().create_timer(sleep_time).timeout
	_update()
	self_modulate = Color(1,1,1)
	
	if Game.current_mode != Game.Mode.obstacle:
		board.evaluate_next_level()
	Config.save_config()
	
func _update():
	add_theme_font_size_override("normal_font_size", _calculate_font_size(board.score))
	text = "[center]%s" % [board.score]
	
	$"../Level".add_theme_font_size_override("normal_font_size", _calculate_font_size(board.level))
	$"../Level".text = "[center]%s" % [board.level]
	
	$"../Goal".add_theme_font_size_override("normal_font_size", _calculate_font_size(board.goal))
	$"../Goal".text = "[center]%s" % [board.goal]
	
	$"../Moves".add_theme_font_size_override("normal_font_size", _calculate_font_size(board.moves))
	$"../Moves".text = "[center]%s" % [board.moves]
	
	if board.score > Game.high_scores[Game.current_mode]:
		$"../Best".modulate = HIGH_SCORE_COLOR
		$"../Best_Label".modulate = HIGH_SCORE_COLOR
		if not high_score_beaten:
			if Game.high_scores[Game.current_mode] > 0:
				Events.PlaySound.emit("Gameplay/highscore")
			high_score_beaten = true
		Game.high_scores[Game.current_mode] = board.score
	
	$"../Best".text = "[center]%s" % [Game.high_scores[Game.current_mode]]

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
