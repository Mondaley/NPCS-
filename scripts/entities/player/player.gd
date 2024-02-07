extends CharacterBody3D

class_name c_player

@onready var n_head = $Head

@export_category("Debug")
@export var b_debug_mode : bool = false

#	stats
@export_category("Attributes")
@export_group("Movement")
@export var amount_movement_speed := 2.0
@export var amount_sprint_speed := 1.2

#	y-axis
@export_group("Y-axis")
@export var amount_jump_height = 2.0
@export var amount_gravity := 9.8
@export var amount_weight := 1.4


func _physics_process(_amount_delta):	
	do_movement(_amount_delta)

func do_movement(_amount_delta):
#	stats
	if Input.is_action_pressed("move_sprint"):
		amount_sprint_speed = 1.4
	elif Input.is_action_just_released("move_sprint"):
		amount_sprint_speed = 2
	
#	y-axis
	if b_debug_mode:
		var _amount_y_dir = Input.get_axis("move_down", "move_up")
		if _amount_y_dir:
			velocity.y = _amount_y_dir * amount_movement_speed * amount_sprint_speed
		else:
			velocity.y = move_toward(velocity.y, 0, amount_movement_speed)
	else:
		if Input.is_action_pressed("jump") && is_on_floor():
			velocity.y = sqrt(amount_jump_height * amount_gravity)
		if !is_on_floor():
			velocity.y -= amount_gravity * amount_weight * _amount_delta

#	x-,z-axis
	var _v2_xz_dir = Input.get_vector("move_left", "move_right", "move_front", "move_back")
	var _v3_direction = (n_head.transform.basis * Vector3(_v2_xz_dir.x, 0, _v2_xz_dir.y)).normalized()
	if _v3_direction:
		velocity.x = _v3_direction.x * amount_movement_speed * amount_sprint_speed
		velocity.z = _v3_direction.z * amount_movement_speed * amount_sprint_speed
	else:
		velocity.x = move_toward(velocity.x, 0, amount_movement_speed)
		velocity.z = move_toward(velocity.z, 0, amount_movement_speed)
			
	move_and_slide()
	
	
	
