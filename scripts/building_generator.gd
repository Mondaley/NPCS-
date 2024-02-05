extends Node3D

const GRID_SIZE = 2.0

# TODO: load scene files representing rooms
# rooms will be able to be of different sizes, potentially grid-locked
# rooms will be able to specify where doors will be, and the generator will branch off of there
# probably best for the generator to recursively branch off rooms breadth-first (as opposed to depth-first)
func place_room(center_pos: Vector3):
	var body = StaticBody3D.new()
	body.position = center_pos
	
	# create mesh instance
	var mesh_instance = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size.x = GRID_SIZE
	mesh.size.y = GRID_SIZE
	mesh_instance.mesh = mesh
	
	# create collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(GRID_SIZE, 2.0, GRID_SIZE)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0.0, -1.0, 0.0)
	
	# add both to static body
	body.add_child(mesh_instance)
	body.add_child(collision_shape)
	
	add_child(body)
	return body

func delta_vector_from_side(side: int):
	return Vector3(
		cos(PI/2.0 * side),
		0.0,
		sin(PI/2.0 * side)
	)

func _ready():
	# could use a "hashset" for this, instead of an array
	var occupied: Array[Vector3] = []
	
	# where the next room will be placed
	var cursor = Vector3(0, 0, 0)
	var cursor_next = Vector3(0, 0, 0)
	
	for i in 500:
		place_room(cursor)
		
		var dir = randi_range(0, 3)
		cursor_next = cursor + delta_vector_from_side(dir) * GRID_SIZE
		for j in 5:
			if j == 5:
				print("Trapped!")
				return
			
			dir = (dir + 1) % 4
			cursor_next = cursor + delta_vector_from_side(dir) * GRID_SIZE
		
		occupied.push_back(cursor)
		cursor = cursor_next
