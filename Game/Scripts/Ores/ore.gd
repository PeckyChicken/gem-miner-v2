extends Node2D
class_name Ore

const ORE_DESCRIPTION = preload("res://Game/Scenes/ores/ore_description.tscn")

var data: Dictionary
var extra: Dictionary

var hovered: bool = false
var clicked: bool = false
var description: OreDescription

func _ready() -> void:
	Events.MouseClicked.connect(_on_mouse_clicked)
	Events.MouseReleased.connect(_on_mouse_released)
	
	$Frame.frame = data["rarity"]
	$Frame/Image.frame_coords = Vector2(data["x"],data["y"])
	
	extra = data.get("extra",{})

func create_description():
	var _desc: OreDescription
	_desc = ORE_DESCRIPTION.instantiate()
	_desc.title_tag = data["name"]
	_desc.description_tag = data["description"]
	_desc.ore_data = data["extra"]
	_desc.position = Vector2.ZERO
	add_child(_desc)
	return _desc

func trigger(status=false,message=""):
	Events.PlaySound.emit("Upgrades/activate")
	$AnimationPlayer.play("activate_%s" % randi_range(0,3))
	if status:
		$Status.text=OreDescription.new().format_description(message)
		$StatusPlayer.play("status_activate")
		

func _on_mouse_clicked(__,___):
	await get_tree().process_frame
	if hovered:
		clicked = true

func _on_mouse_released(__,___):
	await get_tree().process_frame
	
	clicked = false

func _on_mouse_entered() -> void:
	hovered = true
	if description:
		description.queue_free()
	description = create_description()

func _on_mouse_exited() -> void:
	hovered = false
	clicked = false
	if description:
		description.queue_free()
