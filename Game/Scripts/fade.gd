extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func fade_in(time):
	show()
	modulate.a = 0
	var tween = get_tree().create_tween()
	tween.tween_property(self,"modulate:a",1,time)
	await tween.finished
	hide()

func fade_out(time):
	show()
	modulate.a = 1
	var tween = get_tree().create_tween()
	tween.tween_property(self,"modulate:a",0,time)
	await tween.finished
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
