extends Node2D

const PAUSE_MENU_SCENE = preload("res://Global/pause_menu.tscn")
var pause_menu: Control

func _ready():
	Events.Pause.connect(pause)
	Events.Resume.connect(resume)

func pause():
	Events.PlaySound.emit("Gameplay/click")
	if pause_menu:
		var player: AnimationPlayer = pause_menu.get_node("AnimationPlayer")
		if player.is_playing():
			await player.animation_finished
	get_tree().paused = true
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_sibling(pause_menu)
	

func resume():
	var player: AnimationPlayer = pause_menu.get_node("AnimationPlayer")
	if player.is_playing():
		await player.animation_finished
	
	get_tree().paused = false
	
	player.play("unpause")
	await player.animation_finished
	pause_menu.queue_free()
