extends Node

@onready var overlay = $overlays/overlay


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	random_brightness()

func random_brightness():
	var value = randf_range(0.8, 0.85)
	overlay.self_modulate = Color(value, value, value, value)
