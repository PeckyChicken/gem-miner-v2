extends RichTextLabel

@onready var board: brd = $"../../Board"

var high_score_beaten: bool = false


var current_score: float
var starting_score: float

const SCORE_TIME = 0.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.AddScore.connect(add_score)
	_update()

func add_score(score):
	board.score += score
	starting_score = float(text)
	current_score = float(text)
	
	
	if Game.current_mode != Game.Mode.obstacles:
		board.evaluate_next_level()
	Config.save_config()
	
func _update():
	add_theme_font_size_override("normal_font_size", _calculate_font_size(floori(board.score)))
	text = str(floori(board.score))
	
	$"../Level".add_theme_font_size_override("normal_font_size", _calculate_font_size(board.level))
	$"../Level".text = str(board.level)
	
	$"../Goal".add_theme_font_size_override("normal_font_size", _calculate_font_size(board.goal))
	$"../Goal".text = str(board.goal)
	
	$"../Moves".add_theme_font_size_override("normal_font_size", _calculate_font_size(board.moves))
	$"../Moves".text = str(board.moves)
	
	if board.score > Game.high_scores[Game.current_mode]:
		if not high_score_beaten:
			if Game.high_scores[Game.current_mode] > 0:
				Events.PlaySound.emit("Gameplay/highscore")
			high_score_beaten = true
		Game.high_scores[Game.current_mode] = board.score

func _calculate_font_size(score) -> int:
	var font_size = 50
	var score_string = str(score)
	
	if len(score_string) < 3:
		return font_size
	
	font_size -= 10* (len(score_string) - 2)
	
	return font_size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var distance = floorf(board.score) - starting_score
	current_score += distance * delta / SCORE_TIME
	text = str(ceili(current_score))
	
	if floorf(current_score) >= floorf(board.score):
		starting_score = floorf(board.score)
		_update()
	
	add_theme_font_size_override("normal_font_size", _calculate_font_size(floori(current_score)))
