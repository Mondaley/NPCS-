extends CharacterBody3D

class_name c_player

#	@export var invd_inventory_data : C_InventoryData

#	signals
signal sg_select
signal sg_break
signal sg_camera_mode

#	stats
var amount_jump_height = 1
var amount_movement_speed := 2.0
var amount_sprint_speed : float
var is_sprinting := true

#	y-axis
var amount_gravity := 9.8
var amount_weight := 1.4

var n_previous_collider
var n_current_collider

#	camera
var is_holding_screen_first := true
var is_holding_screen_third := false
var v2_previous_mouse_position : Vector2
var v3_previous_mesh_rotation : Vector3
var amount_camera_mode := 0

#	input
var is_select_approving := false
var is_input_approving := false
var in_event

#	raycast
var is_break_delay_approving := false
var ph_reach_range_1 : PhysicsRayQueryParameters3D
var d_raycast_result = {}

#	nodes
@onready var n_mesh := $Mesh
@onready var n_head := $Head
@onready var n_neck := $Head/Neck
@onready var n_camera := $Head/Neck/Camera
@onready var n_reach_range_0 := $Head/Neck/Camera/Ray
@onready var n_time_break_delay = $T_Break_Delay
@onready var n_canvas := $CanvasLayer
#@onready var n_inventory := owner.get_node("CanvasLayer/Inventory")

class c_ui:	
#	static func do_progress_bar(_n_current_collider, _n_previous_collider, _n_canvas):
#		if _n_current_collider and _n_previous_collider and _n_current_collider != null:
#			_n_canvas.get_node('ProgressBar').visible = true
#			_n_canvas.get_node('ProgressBar').max_value = _n_current_collider.amount_initial_life
#			_n_canvas.get_node('ProgressBar').value = _n_current_collider.amount_current_life
#		else:
#			_n_canvas.get_node('ProgressBar').visible = false
#	static func do_inventory(_n_inventory,_invd_inventory_data : C_InventoryData):
#		if Input.is_action_just_pressed('ui_inventory'):
#			_n_inventory.visible = !_n_inventory.visible
#		_n_inventory.do_inventory_data(_invd_inventory_data)
	static func do_cursor(_is_first_frame : bool, _in_event : InputEvent, _n_canvas : CanvasLayer, _amount_camera_mode : int, _v2_viewport : Vector2):
		if _is_first_frame:
			if _amount_camera_mode == 0:	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			elif  _amount_camera_mode == 1:	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		if _in_event is InputEventMouseButton:
#			if _amount_camera_mode == 0:
#				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if _amount_camera_mode == 1:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		elif _in_event is InputEventMouseMotion:
			if _amount_camera_mode == 1:
				_n_canvas.get_node('Cursor').position = _v2_viewport
		elif _in_event is InputEventKey:
			if Input.is_action_just_pressed('ui_cancel') and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			elif Input.is_action_just_pressed('ui_cancel') and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if Input.is_action_just_pressed('camera_mode_0'):
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			elif Input.is_action_just_pressed('camera_mode_1'):
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _ready():
#	initiate signals
	connect('sg_camera_mode', Callable(self, 'do_camera_mode'))
	emit_signal('sg_camera_mode', 0)
	
#	initiate ui
#	c_ui.do_inventory(n_inventory, invd_inventory_data)
	c_ui.do_cursor(true, in_event, n_canvas, amount_camera_mode, get_viewport().get_mouse_position())

func _input(_in_event):
#	c_ui.do_inventory(n_inventory, invd_inventory_data)
	c_ui.do_cursor(false, _in_event, n_canvas, amount_camera_mode, get_viewport().get_mouse_position())
	if _in_event is InputEventMouseButton:
		if amount_camera_mode == 0:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				is_holding_screen_first = false
			if _in_event.is_action_pressed("left_click") and is_select_approving:
				n_time_break_delay.start()
				is_input_approving = true
				is_break_delay_approving = true
				connect('sg_break', Callable(self, 'do_break'))
				emit_signal('sg_break')
			elif _in_event.is_action_released("left_click"):
				n_time_break_delay.stop()
				is_input_approving = false
				is_break_delay_approving = false
				if !is_connected('sg_break', Callable(self, 'do_break')):	pass
				else: disconnect('sg_break', Callable(self, 'do_break'))
		elif amount_camera_mode == 1:
			if _in_event.is_action_pressed("right_click"):
				is_holding_screen_third = true
				v2_previous_mouse_position = get_viewport().get_mouse_position()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			elif _in_event.is_action_released("right_click"):
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				get_viewport().warp_mouse(v2_previous_mouse_position)
				is_holding_screen_third = false
			if _in_event.is_action_pressed("left_click") and is_select_approving:
				n_time_break_delay.start()
				is_input_approving = true
				is_break_delay_approving = true
				connect('sg_break', Callable(self, 'do_break'))
				emit_signal('sg_break')
			elif _in_event.is_action_released("left_click"):
				n_time_break_delay.stop()
				is_input_approving = false
				is_break_delay_approving = false
				if !is_connected('sg_break', Callable(self, 'do_break')):	pass
				else: disconnect('sg_break', Callable(self, 'do_break'))
	elif _in_event is InputEventMouseMotion:
		if amount_camera_mode == 0:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				is_holding_screen_first = true
			in_event = _in_event
			emit_signal('sg_camera_mode', amount_camera_mode)
		elif amount_camera_mode == 1:
			in_event = _in_event
			emit_signal('sg_camera_mode', amount_camera_mode)
	elif _in_event is InputEventKey:
		if _in_event.is_action_pressed('camera_mode_0'):
			if amount_camera_mode == 0:	return
			is_holding_screen_first = true
			amount_camera_mode = 0
			n_mesh.rotation.y = n_head.rotation.y
			n_neck.rotation = Vector3.ZERO
			n_camera.global_transform.origin = n_neck.global_transform.origin
			n_canvas.get_node('Cursor').position = get_viewport().get_mouse_position()
			emit_signal('sg_camera_mode', amount_camera_mode)
			print('camera mode switched:		', amount_camera_mode)
		elif _in_event.is_action_pressed('camera_mode_1'):
			if amount_camera_mode == 1:	return
			amount_camera_mode = 1
			n_camera.transform.origin += Vector3(0,0.7,3)
			n_camera.look_at(self.global_transform.origin)
			emit_signal('sg_camera_mode', amount_camera_mode)
			print('camera mode switched:		', amount_camera_mode)
		elif _in_event.is_action_pressed('ui_cancel'):
			if amount_camera_mode == 0:
				is_holding_screen_first = false

func _physics_process(_amount_delta):	
	print(velocity)
	do_movement(_amount_delta)
	move_and_slide()
	do_select()
#	c_ui.do_progress_bar(n_current_collider, n_previous_collider, n_canvas)
	do_cursor_raycast()
	do_rotation_for_third_person()

func do_movement(_amount_delta):
#	stats
	if Input.is_action_pressed("move_sprint"):
		if is_sprinting:
			amount_sprint_speed = amount_movement_speed * 1.4
			amount_movement_speed += amount_sprint_speed
		is_sprinting = false
	elif !Input.is_action_pressed("move_sprint"):
		if !is_sprinting:
			amount_movement_speed -= amount_sprint_speed
		is_sprinting = true
	
#	y-axis
	if is_on_floor():
		velocity.y = 0
	if Input.is_action_pressed("jump") && is_on_floor():
		velocity.y = sqrt(amount_jump_height * amount_gravity)
	if not is_on_floor():
		velocity.y -= amount_gravity * _amount_delta * amount_weight
	
#	x-,z-axis
	var _v2_input_dir = Input.get_vector("move_left", "move_right", "move_front", "move_back")
	var _v3_direction = (n_head.transform.basis * Vector3(_v2_input_dir.x, 0, _v2_input_dir.y)).normalized()
	if _v3_direction:
		velocity.x = _v3_direction.x * amount_movement_speed
		velocity.z = _v3_direction.z * amount_movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, amount_movement_speed)
		velocity.z = move_toward(velocity.z, 0, amount_movement_speed)

func do_select():
	if amount_camera_mode == 0:
		if n_reach_range_0.is_colliding():
			n_current_collider = n_reach_range_0.get_collider()
		elif n_reach_range_0.is_colliding() == false:
			n_current_collider = null
		if n_previous_collider == null:
			n_previous_collider = n_current_collider
		elif n_previous_collider != n_current_collider:
			emit_signal('sg_select', false)
			if !is_connected('sg_select', Callable(n_previous_collider, 'do_outline')):	pass
			elif is_connected('sg_select', Callable(n_previous_collider, 'do_outline')):
				disconnect('sg_select', Callable(n_previous_collider, 'do_outline'))
			n_previous_collider = n_current_collider
			is_select_approving = false
		elif n_previous_collider == n_current_collider:
			if !sg_select.is_connected(Callable(n_current_collider, 'do_outline')):
				connect('sg_select', Callable(n_current_collider, 'do_outline'))
				emit_signal('sg_select', true)
				is_select_approving = true
				is_break_delay_approving = true
				if n_current_collider is CharacterBody3D:
					n_current_collider.n_player = self
					n_current_collider.n_ray = n_reach_range_0
				emit_signal('sg_break')
	if amount_camera_mode == 1:
		if d_raycast_result.has('collider'):
			n_current_collider = d_raycast_result.get('collider')
		elif d_raycast_result.has('collider') == false:
			n_current_collider = null
		if n_previous_collider == null:
			n_previous_collider = n_current_collider
		elif n_previous_collider != n_current_collider:
			emit_signal('sg_select', false)
			if !is_connected('sg_select', Callable(n_previous_collider, 'do_outline')):	pass
			elif is_connected('sg_select', Callable(n_previous_collider, 'do_outline')):
				disconnect('sg_select', Callable(n_previous_collider, 'do_outline'))
			n_previous_collider = n_current_collider
			is_select_approving = false
		elif n_previous_collider == n_current_collider:
			if !sg_select.is_connected(Callable(n_current_collider, 'do_outline')):
				connect('sg_select', Callable(n_current_collider, 'do_outline'))
				emit_signal('sg_select', true)
				is_select_approving = true
				is_break_delay_approving = true
				n_current_collider.n_player = self
				n_current_collider.n_ray = ph_reach_range_1
				emit_signal('sg_break')

func do_break():
	if n_current_collider != null:
		n_current_collider.do_breaking(25.0, 0.01)
	
func do_camera_mode(_amount_camera_mode):
	if _amount_camera_mode == 0:
		if in_event != null:
			if is_holding_screen_first:
				n_neck.global_transform.origin = self.global_transform.origin + Vector3(0,.35,0)
				n_head.basis *= Basis().rotated(Vector3(0,1,0), -in_event.relative.x * 0.005)
				n_camera.basis *= Basis().rotated(Vector3(1,0,0), -in_event.relative.y * 0.005)
				n_mesh.basis *= Basis().rotated(Vector3(0,1,0), -in_event.relative.x * 0.005)
				if n_camera.rotation.x < -1.5:	n_camera.rotation = Vector3(-1.5,0,0)
				if n_camera.rotation.x > 1.5:	n_camera.rotation = Vector3(1.5,0,0)
	elif _amount_camera_mode == 1:
		if in_event != null:
			if is_holding_screen_third:
				n_canvas.get_node('Cursor').position = v2_previous_mouse_position
				n_head.basis *= Basis().rotated(Vector3(0,1,0), -in_event.relative.x * 0.005)
				n_neck.basis *= Basis().rotated(Vector3(1,0,0), -in_event.relative.y * 0.005)
				if n_neck.rotation.x < -1:	n_neck.rotation = Vector3(-1,0,0)
				if n_neck.rotation.x > 1.2:	n_neck.rotation = Vector3(1.2,0,0)
			pass
	else:
		print('camera mode out of range')

func _on_t_break_delay_timeout():
	is_break_delay_approving = true

func do_cursor_raycast():
	var _amount_ray_length = 5
	if amount_camera_mode == 0:
		n_reach_range_0.enabled = true
		n_reach_range_0.target_position.z = _amount_ray_length
	if amount_camera_mode == 1:
		n_reach_range_0.enabled = false
		var _d_space = get_world_3d().direct_space_state
		ph_reach_range_1 = PhysicsRayQueryParameters3D.create(n_camera.project_ray_origin(n_canvas.get_node('Cursor').position), n_camera.project_ray_origin(n_canvas.get_node('Cursor').position) + n_camera.project_ray_normal(n_canvas.get_node('Cursor').position) * _amount_ray_length)
		ph_reach_range_1.collision_mask = 2
		ph_reach_range_1.collide_with_bodies = true
		d_raycast_result = _d_space.intersect_ray(ph_reach_range_1)

func do_rotation_for_third_person():
	if amount_camera_mode == 1:
		if velocity.x != 0 or velocity.z != 0:
			n_mesh.basis = Basis(Quaternion(n_mesh.basis).slerp(Quaternion(Basis.looking_at(velocity.normalized(), Vector3.UP)), 0.3))
			n_mesh.rotation.x = 0
			n_mesh.rotation.z = 0
			v3_previous_mesh_rotation = velocity
		else:
			if v3_previous_mesh_rotation != Vector3.ZERO:
				n_mesh.basis = Basis(Quaternion(n_mesh.basis).slerp(Quaternion(Basis.looking_at(v3_previous_mesh_rotation, Vector3.UP)), 0.3))
				n_mesh.rotation.x = 0
				n_mesh.rotation.z = 0
