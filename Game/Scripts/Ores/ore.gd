extends Node2D
class_name Ore

const ORE_DESCRIPTION = preload("res://Game/Scenes/ores/ore_description.tscn")

var data: Dictionary
var hovered: bool = false
var clicked: bool = false
var description: OreDescription

func _ready() -> void:
	Events.MouseClicked.connect(_on_mouse_clicked)
	Events.MouseReleased.connect(_on_mouse_released)
	
	$Frame.frame = data["rarity"]
	$Frame/Image.frame_coords = Vector2(data["x"],data["y"])

func create_description():
	
	if description:
		description.queue_free()
	description = ORE_DESCRIPTION.instantiate()
	description.title_tag = data["name"]
	description.description_tag = data["description"]
	description.ore_data = data["extra"]
	description.position = Vector2.ZERO
	add_child(description)

func trigger(status=false):
	Events.PlaySound.emit("Upgrades/activate")
	$AnimationPlayer.play("activate_%s" % randi_range(0,3))
	if status:
		$StatusPlayer.play("status_activate")
		

func _on_mouse_clicked(__,___):
	await get_tree().process_frame
	if hovered:
		trigger(true)
		clicked = true

func _on_mouse_released(__,___):
	await get_tree().process_frame
	
	clicked = false

func _on_mouse_entered() -> void:
	hovered = true
	create_description()

func _on_mouse_exited() -> void:
	hovered = false
	clicked = false
	if description:
		description.queue_free()
