extends Node

@export var n_player : Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	rescure_player()

func rescure_player():
	if n_player.position.y < -50:
		n_player.position = Vector3(0,0,0)
