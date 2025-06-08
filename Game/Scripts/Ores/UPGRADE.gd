extends Node
class_name upgrade_class

const UPGRADE_COUNT = 5
const ORE = preload("res://Game/Scenes/ores/ore.tscn")

var upgraded_gems: Array[Game.Item] = [Game.Item.TOPAZ]
var ore_cache: Dictionary = {}

func create_ore(data):
	print("Ore data: ",data)
	var ore: Ore = ORE.instantiate()
	ore.data = data
	ore.position = Vector2(-125,25)
	add_child(ore)

func load_ore_data(file_name) -> Dictionary:
	if file_name in ore_cache:
		return ore_cache[file_name]
	
	var file_data = load("res://Upgrades/%s.json" % [file_name])
	var data = file_data.data
	ore_cache[file_name] = data
	
	return data

func _ready() -> void:
	pass

	create_ore(load_ore_data("diamond_ore"))
