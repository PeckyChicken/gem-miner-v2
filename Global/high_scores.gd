extends CanvasLayer

class_name HighScores

const CLICK = preload("res://assets/Sounds/Gameplay/click.wav")
var audio_player = AudioStreamPlayer.new()

func _ready() -> void:
	audio_player.stream = CLICK
	add_child(audio_player)
	
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()
	
	for mode in Game.high_scores.keys():
		var score_element: RichTextLabel = $score_element.duplicate()
		
		var title: String = Game.Mode.keys()[mode]
		title = TranslationServer.translate(title)
		
		var score: int = Game.high_scores[mode]
		
		score_element.text = "%s: %s" % [title,score]
		
		$score_holders.add_child(score_element)
		score_element.show()
		
		$score_holders.add_child(HSeparator.new())
	
	$Return.reparent($score_holders)

func _on_return_pressed() -> void:
	audio_player.volume_db = linear_to_db(Music.sfx_volume)
	audio_player.play()
	hide()
	get_tree().paused = false
	await audio_player.finished
	queue_free()
