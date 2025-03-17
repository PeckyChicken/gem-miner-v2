extends Node2D
class_name Tool

@onready var image: Sprite2D = $Image
@onready var value: RichTextLabel = $Value

var tool
var count: int
var selected = false

func _ready() -> void:
	show()
	Events.DeselectTools.connect(deselect)

func deselect():
	selected = false

func _process(_delta):
	image.visible = count > 0
	value.visible = count > 1
	value.text = str(count)
