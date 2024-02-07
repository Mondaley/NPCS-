extends Node

@onready var pgb_sprint : ProgressBar = $Control/sprint_bar

var d_decrease = {
	"sprint" : 0.5
}

var func_sprint_bar = func():
	if Input.is_action_pressed("move_sprint") and pgb_sprint.value == 0:
		owner.amount_external_sprint_speed = 0.5
	elif Input.is_action_pressed("move_sprint"):
		owner.amount_external_sprint_speed = 1.4
		pgb_sprint.value -= d_decrease["sprint"]
	elif !Input.is_action_pressed("move_sprint") and pgb_sprint.value < pgb_sprint.max_value:
		owner.amount_external_sprint_speed = 1.0
		pgb_sprint.value += d_decrease["sprint"] / 4

func _physics_process(_delta):
	func_sprint_bar.call()
	
