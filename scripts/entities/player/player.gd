extends CharacterBody3D

class_name c_player

@onready var n_head = $Head

#	stats
var amount_jump_height = 1.0
var amount_movement_speed := 2.0
var amount_sprint_speed := 1.0

#	y-axis
var amount_gravity := 9.8
var amount_weight := 1.4


func _physics_process(_amount_delta):	
	do_movement(_amount_delta)

func do_movement(_amount_delta):
#	stats
	if Input.is_action_pressed("move_sprint"):
		amount_sprint_speed = 1.4
	elif Input.is_action_just_released("move_sprint"):
		amount_sprint_speed = 1
	
#	y-axis
	if Input.is_action_pressed("jump") && is_on_floor():
		velocity.y = sqrt(amount_jump_height * amount_gravity)
	if !is_on_floor():
		velocity.y -= amount_gravity * amount_weight * _amount_delta
	if is_on_floor():
		velocity.y = 0
	
#	x-,z-axis
	var _v2_input_dir = Input.get_vector("move_left", "move_right", "move_front", "move_back")
	var _v3_direction = (n_head.transform.basis * Vector3(_v2_input_dir.x, 0, _v2_input_dir.y)).normalized()
	if _v3_direction:
		velocity.x = _v3_direction.x * amount_movement_speed * amount_sprint_speed
		velocity.z = _v3_direction.z * amount_movement_speed * amount_sprint_speed
	else:
		velocity.x = move_toward(velocity.x, 0, amount_movement_speed)
		velocity.z = move_toward(velocity.z, 0, amount_movement_speed)
	
	move_and_slide()
	
	
	
