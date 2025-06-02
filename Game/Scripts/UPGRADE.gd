extends Node
class_name upgrade_class

const UPGRADE_COUNT = 4
const ORE_DESCRIPTION = preload("res://Game/Scenes/ores/ore_description.tscn")

var upgraded_gems: Array[Game.Item] = [Game.Item.TOPAZ]

func create_description(title,desc):
	var description = ORE_DESCRIPTION.instantiate()
	description.title_tag = title
	description.description_tag = desc
	description.position = Vector2(100,200)
	add_child(description)

func _ready() -> void:
	pass
	#create_description("ore_ruby","ore_ruby_desc")
