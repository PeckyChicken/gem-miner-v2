extends Node2D

func _ready() -> void:
	await $"Fade".fade_out(0.5)
	Music.play("title")
	
