extends Node
class_name Ores

const UPGRADE_COUNT = 5
const ORE = preload("res://Game/Scenes/ores/ore.tscn")

var ores: Array[Ore] = []

enum Event {
	gem_line,
	gem_break,
	gem_place,
	tool_create,
}

enum In {
	event,
	tile_pos,
	tile,
	count
}

enum Out {
	score
}

var ore_cache: Dictionary = {}

func evaluate_ores(context):
	var return_data = {Out.score:0}
	for ore in ores:
		if context[In.event] in [Event.gem_line,Event.gem_break]:
			if ore.data["ability"] == "extra_points_for_gem" and ore.extra["gem_type"] == context[In.tile]:
				var bonus = ore.extra["bonus"] * context[In.count]
				#return_data[Out.score] += bonus
				Events.AddScore.emit(bonus)
				ore.trigger(true,"+"+str(bonus))
	
	return return_data

func create_ore(data):
	var ore: Ore = ORE.instantiate()
	ores.append(ore)
	ore.data = data
	$HolderImage/Holder.add_child(ore)

func load_ore_data(file_name) -> Dictionary:
	if file_name in ore_cache:
		return ore_cache[file_name]
	
	var file_data = load("res://Upgrades/%s.json" % [file_name])
	var data: Dictionary = file_data.data
	
	for datum in data.keys():
		if data[datum] is float:
			var _temp_data: float = data[datum]
			if _temp_data == floor(_temp_data):
				data[datum] = int(_temp_data)
			else:
				data[datum] = float(_temp_data)
	
	if "extra" in data:
		for datum in data["extra"].keys():
			if data["extra"][datum] is float:
				var _temp_data: float = data["extra"][datum]
				if _temp_data == floor(_temp_data):
					data["extra"][datum] = int(_temp_data)
				else:
					data["extra"][datum] = float(_temp_data)
	
	ore_cache[file_name] = data
	
	return data

func _ready() -> void:
	pass

	create_ore(load_ore_data("sapphire_ore"))
