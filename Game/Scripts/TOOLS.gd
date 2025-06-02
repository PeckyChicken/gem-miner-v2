extends Control

enum Tools {
	pickaxe,
	axe,
	jackhammer,
	star,
	bucket,
	dice,
	clock
}

var background_tiles: Array[Node2D] = []
var foreground_tiles: Array[Tool] = []

@onready var tool_scene: Resource = preload("res://Game/Scenes/tool.tscn")

const HEIGHT = 60

var active_tools: Array[Tools] = [Tools.pickaxe,Tools.axe,Tools.jackhammer,Tools.star,Tools.dice]
var tool_counts = [1,1,1,1,1]
var selected_tool = null

func _ready() -> void:
	Events.DeselectTools.connect(deselect)
	if Game.current_mode == Game.Mode.obstacles:
		tool_counts = [0,0,0,0,0]
	if Game.current_mode == Game.Mode.time_rush:
		active_tools = [Tools.pickaxe,Tools.axe,Tools.jackhammer,Tools.star,Tools.clock]
	draw_background()
	draw()

func _process(_delta: float) -> void:
	for index in range(len(active_tools)):
		foreground_tiles[index].count = tool_counts[index]

func deselect():
	selected_tool = null

func tool_clicked(tile: BackgroundTile):
	if tile.type == Events.Type.tool:
		pass

func draw_background():
	for tile in background_tiles:
		tile.queue_free()
	background_tiles.clear()
	var tile_sprite = $background_tile
	
	for __ in active_tools:
		var tile = tile_sprite.duplicate()
		tile.show()
		add_child(tile)
		
		background_tiles.append(tile)
		tile_sprite.position.y += HEIGHT
	
	tile_sprite.hide()

func get_tool(tool) -> Tool:
	assert (tool in active_tools)
	return foreground_tiles[active_tools.find(tool)]

func draw():
	assert (len(active_tools) == len(background_tiles))
	for tile in foreground_tiles:
		tile.queue_free()
	foreground_tiles.clear()
	
	var index = 0
	for bg_tile in background_tiles:
		var tool: Tool = tool_scene.instantiate()
		tool.show()
		tool.position = Vector2.ZERO
		bg_tile.add_child(tool)
		
		tool.image.frame = active_tools[index]
		tool.tool = active_tools[index]
		tool.count = tool_counts[index]
		
		foreground_tiles.append(tool)
		index += 1
	
