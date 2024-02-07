extends Node3D

@onready var n_neck = $Neck
@onready var n_camera = $Neck/Camera
@onready var n_mesh = owner.get_node("Mesh")

var _v3_initial_pos := position
var nr_angular_multiplier := 0.005
var b_mouse_captured := true

var in_event

func _ready():
	#Engine.max_fps = 10
	owner.connect("sg_crouch", do_camera_position)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	do_camera_mode(delta)

func _input(_in_event):
	if _in_event is InputEventMouseMotion:
		in_event = _in_event
	if Input.is_action_just_pressed("escape"):
		b_mouse_captured = !b_mouse_captured
		if b_mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func do_camera_mode(_delta):
	if in_event:
		basis *= Basis().rotated(Vector3(0,1,0), -in_event.relative.x * nr_angular_multiplier)
		n_camera.basis *= Basis().rotated(Vector3(1,0,0), -in_event.relative.y * nr_angular_multiplier)
		n_mesh.basis *= Basis().rotated(Vector3(0,1,0), -in_event.relative.y * nr_angular_multiplier)
		if n_camera.rotation.x < -1.5:	n_camera.rotation = Vector3(-1.5,0,0)
		if n_camera.rotation.x > 1.5:	n_camera.rotation = Vector3(1.5,0,0)
		in_event = null

func do_camera_position(_b_crauching : bool = false):
	if _b_crauching:
		create_tween().tween_property(self, "position", _v3_initial_pos / 2, 0.1)
	elif !_b_crauching:
		create_tween().tween_property(self, "position", _v3_initial_pos, 0.1)
		
