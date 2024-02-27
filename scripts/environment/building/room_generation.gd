extends GridMap

@export_category("Debug")
@export var b_debug_mode : bool = false

@export_category("Dungeon Generate Rooms")
@export var b_generate_rooms : bool = true
@export var b_generate_borders : bool = false
@export var b_fill_empty : bool = false
@export var b_fill_everything : bool = false


@export_category("Dungeon Properties")
@export var n_room_tile: PackedScene # The 3D model for the floor tile

# Dungeon variales
@export_range(1, 3, 1) var amount_grid_multiplier : int = 1
@export var v2_g_dungeon_size := Vector2(20, 20):
	get:
		if v2_g_dungeon_size.x != v2_g_dungeon_size.y:
			return Vector2(floor((v2_g_dungeon_size.x + v2_g_dungeon_size.y)/2), floor((v2_g_dungeon_size.x + v2_g_dungeon_size.y)/2))
		else:
			return v2_g_dungeon_size
var arr_dungeon_grid : Array = []
var arr_future_dead_end_directions : Array[Vector3]= []
var stg_dungeon_state : String = "fine"

# Rooms variables
@export var amount_g_max_steps : int = 10:
	get:
		#var amount_procentage = 1
		#if amount_g_max_steps > amount_procentage * v2_g_dungeon_size.x * 2:
			#return floor(amount_procentage * v2_g_dungeon_size.x * 2)
		#else:
		return amount_g_max_steps
var amount_steps : int = 1
var v3_position := Vector3.ZERO

# Branches variables
@export var b_automatic_branch_number : bool = true
@export var amount_g_branch_max_steps : int = 0:
	get:
		if b_automatic_branch_number == true:
			return amount_g_max_steps * 2
		elif amount_g_branch_max_steps > amount_g_max_steps * 2.5:
			return amount_g_max_steps * 2
		else:
			return amount_g_branch_max_steps
var amount_branch_steps : int = 1

#variables for the generated "rooms"
var mat_material := StandardMaterial3D.new()
var mat_material_border := StandardMaterial3D.new()
var mat_material_empty := StandardMaterial3D.new()
@export var clr_color := Color(3, 0, 0, 0)

func _ready():
	if b_generate_borders:	do_borders()
	if b_fill_everything:	do_fill()
	else:
		if b_generate_rooms:	do_generate_dungeon()
		if b_fill_empty:		do_fill_empty()

func do_generate_dungeon():
	
	# Initialize the dungeon grid
	for _amount_x in range(v2_g_dungeon_size.x):
		arr_dungeon_grid.append([])
		for _amount_z in range(v2_g_dungeon_size.y):
			arr_dungeon_grid[_amount_x].append(false)
	
	# Initialization of the first room
	v3_position = Vector3(randi_range(floor(0.33 * v2_g_dungeon_size.x), floor(0.33 * v2_g_dungeon_size.x) * 2 ), 0, randi_range(floor(0.33 * v2_g_dungeon_size.y), floor(0.33 * v2_g_dungeon_size.y) * 2))	
	do_room()
	
	# Initialization of the rest of the rooms
	while amount_steps <= amount_g_max_steps:
		do_room_direction()

		#If the dungeon is impossible to generate
		if stg_dungeon_state == "impossible":
			if b_debug_mode: print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
			if b_debug_mode: print("The dungeon will be regenerated!")
			if b_debug_mode: print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
			while get_node('Rooms/Rooms').get_child_count() > 0:
				get_node('Rooms/Rooms').remove_child(get_node('Rooms/Rooms').get_child(0))
			for _amount_x in range(v2_g_dungeon_size.x):
				for _amount_z in range(v2_g_dungeon_size.y):
					arr_dungeon_grid[_amount_x][_amount_z] = false
			amount_steps = 1
			arr_future_dead_end_directions.clear()
			v3_position = Vector3(randi() % (v2_g_dungeon_size.x as int), 0, randi() % (v2_g_dungeon_size.y as int))
			do_room()
			stg_dungeon_state = "not fine"
			continue
		#If no issue occurs
		elif stg_dungeon_state == "fine":
			do_room()
	
	
	# Initialization of the branches
	arr_future_dead_end_directions.clear()
	while amount_branch_steps <= amount_g_branch_max_steps:
#		getrandom position from any room
		if get_node('Rooms/Rooms/').get_child_count() > 0:	v3_position = get_node('Rooms/Rooms/').get_child(randi_range(0, get_node('Rooms/Rooms/').get_child_count() - 1)).transform.origin			
		else: if b_debug_mode: print('Found no child'); 	break
		
		do_branch_direction()
		if stg_dungeon_state == "branch dead end":
			v3_position = get_node('Rooms/Rooms/').get_child(randi_range(0, get_node('Rooms/Rooms/').get_child_count() - 1)).transform.origin
			stg_dungeon_state = "fine"
			continue
		elif stg_dungeon_state == "fine":	
			do_branch_room()

func do_room_direction():
	if b_debug_mode: print(amount_steps, ' step-----------------------------------------------')
	var _arr_possible_directions := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var _arr_available_directions := _arr_possible_directions
	while !_arr_available_directions.is_empty():
		var _amount_neighbors : int = 0
		var _v3_addition = _arr_available_directions[randi() % _arr_available_directions.size()]
		var _v3_future_position = v3_position + _v3_addition
		
		if b_debug_mode: print(v3_position, " current position")
		if b_debug_mode: print(_v3_addition, " addition")
		if b_debug_mode: print(_v3_future_position, " future position")
		
		# How many neighbors the space has?
		if _v3_future_position.x - 1 < 0 or _v3_future_position.z >= v2_g_dungeon_size.y: pass
		elif arr_dungeon_grid[_v3_future_position.x - 1][_v3_future_position.z] == true:	_amount_neighbors += 1
		if _v3_future_position.x + 1 >= v2_g_dungeon_size.x or _v3_future_position.z >= v2_g_dungeon_size.y: pass
		elif arr_dungeon_grid[_v3_future_position.x + 1][_v3_future_position.z] == true:	_amount_neighbors += 1
		if _v3_future_position.z - 1 < 0 or _v3_future_position.x >= v2_g_dungeon_size.x: pass
		elif arr_dungeon_grid[_v3_future_position.x][_v3_future_position.z - 1] == true:	_amount_neighbors += 1
		if _v3_future_position.z + 1 >= v2_g_dungeon_size.y or _v3_future_position.x >= v2_g_dungeon_size.x: pass
		elif arr_dungeon_grid[_v3_future_position.x][_v3_future_position.z + 1] == true:	_amount_neighbors += 1
		
		if (_v3_future_position.x <= 0 or _v3_future_position.x >= v2_g_dungeon_size.x or _v3_future_position.z <= 0 or _v3_future_position.z >= v2_g_dungeon_size.y):
			if b_debug_mode: print(_v3_future_position, " out of bounds")
			_arr_available_directions.remove_at(_arr_available_directions.find(_v3_addition))
			continue
		elif (arr_dungeon_grid[_v3_future_position.x][_v3_future_position.z] == true):
			if b_debug_mode: print(_v3_future_position, " aready true")
			_arr_available_directions.remove_at(_arr_available_directions.find(_v3_addition))
			continue
		elif (_amount_neighbors != 1):
			if b_debug_mode: print(_v3_future_position, " too many naighbours")
			_arr_available_directions.remove_at(_arr_available_directions.find(_v3_addition))
			continue
		elif (arr_future_dead_end_directions.find(_v3_future_position) != -1):
			if b_debug_mode: print(_v3_future_position, " future dead end")
			_arr_available_directions.remove_at(_arr_available_directions.find(_v3_addition))
			continue
		else:
			v3_position = _v3_future_position
			if b_debug_mode: print(_v3_future_position, " position accsepted")
			stg_dungeon_state = "fine"
			arr_dungeon_grid[v3_position.x][v3_position.z] = true
			_arr_available_directions = _arr_possible_directions
			break
	
		#There are no available directions anymore. Return to the previous used space and note this current space as a dead end one
	if _arr_available_directions.is_empty():
		#add the future dead end space
		if b_debug_mode: print(" rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr")
		if b_debug_mode: print(v3_position, " added as a future dead end")
		arr_future_dead_end_directions.append(v3_position)
		
		if amount_steps - 2 <= 1:
			stg_dungeon_state = "impossible"
			return
			
		#remove current room
		arr_dungeon_grid[v3_position.x][v3_position.z] = false
		var n_current_room = get_node("Rooms/Rooms/" + str(amount_steps - 1))
		if b_debug_mode: print(n_current_room, "current room removed at ", n_current_room.position)
		get_node("Rooms/Rooms").remove_child(n_current_room)
		n_current_room.queue_free()
		
		#return to previous room
		var _n_previous_room = get_node("Rooms/Rooms/" + str(amount_steps - 2))
		if b_debug_mode: print(_n_previous_room, " returned to previous pos ", _n_previous_room.position)
		v3_position = _n_previous_room.position
		if b_debug_mode: print(v3_position, " position after returning")
		
		#return logic
		stg_dungeon_state = "not fine"
		amount_steps -= 1

func do_branch_direction():
	if b_debug_mode: print(amount_branch_steps, ' branch step-----------------------------------------------')
	var _arr_possible_directions := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var _arr_available_directions := _arr_possible_directions
	while !_arr_available_directions.is_empty():
		var _amount_neighbors : int = 0
		var _v3_addition = _arr_available_directions[randi() % _arr_available_directions.size()]
		var _v3_future_position = v3_position + _v3_addition
		
		# How many neighbors the space has?
		if _v3_future_position.x - 1 < 0 or _v3_future_position.z >= v2_g_dungeon_size.y: pass
		elif arr_dungeon_grid[_v3_future_position.x - 1][_v3_future_position.z] == true:	_amount_neighbors += 1
		if _v3_future_position.x + 1 >= v2_g_dungeon_size.x or _v3_future_position.z >= v2_g_dungeon_size.y: pass
		elif arr_dungeon_grid[_v3_future_position.x + 1][_v3_future_position.z] == true:	_amount_neighbors += 1
		if _v3_future_position.z - 1 < 0 or _v3_future_position.x >= v2_g_dungeon_size.x: pass
		elif arr_dungeon_grid[_v3_future_position.x][_v3_future_position.z - 1] == true:	_amount_neighbors += 1
		if _v3_future_position.z + 1 >= v2_g_dungeon_size.y or _v3_future_position.x >= v2_g_dungeon_size.x: pass
		elif arr_dungeon_grid[_v3_future_position.x][_v3_future_position.z + 1] == true:	_amount_neighbors += 1
		
		if (_v3_future_position.x <= 0 or _v3_future_position.x >= v2_g_dungeon_size.x or _v3_future_position.z <= 0 or _v3_future_position.z >= v2_g_dungeon_size.y) or (arr_dungeon_grid[_v3_future_position.x][_v3_future_position.z] == true) or (_amount_neighbors != 1) or (arr_future_dead_end_directions.find(_v3_future_position) != -1):
			if b_debug_mode: print(_v3_future_position, " invalid")
			_arr_available_directions.remove_at(_arr_available_directions.find(_v3_addition))
			continue
		#Else the space is valid
		else:
			v3_position += _v3_addition
			if b_debug_mode: print(v3_position, " accsepted")
			arr_dungeon_grid[v3_position.x][v3_position.z] = true
			_arr_available_directions = _arr_possible_directions
			break
	#There are no available directions anymore. Return to the previous used space and note this current space as a dead end one
	if _arr_available_directions.is_empty():
		stg_dungeon_state = "branch dead end"

func do_room():
	if b_debug_mode: print(amount_steps, ' step-----------------------------------------------')	
	arr_dungeon_grid[v3_position.x][v3_position.z] = true
	var _n_instance = n_room_tile.instantiate()
	set_cell_item(Vector3(v3_position.x, 0, v3_position.z), 0)
	mat_material.albedo_color = clr_color
	_n_instance.transform.origin = Vector3(v3_position.x, 0, v3_position.z)
	_n_instance.name = str(amount_steps)
	_n_instance.get_node('Floor').material_override = mat_material.duplicate()
	_n_instance.get_node('Floor').material_override.albedo_color = clr_color
	_n_instance.get_node('Count').text = str(amount_steps)
	_n_instance.get_node('Coordinates').text = str(v3_position)
	clr_color.h += 0.05
	get_node("Rooms/Rooms/").add_child(_n_instance)
	amount_steps += 1	
	if b_debug_mode: print("===================================")
	if b_debug_mode: print(_n_instance, " room added at ", v3_position)

func do_branch_room():
	arr_dungeon_grid[v3_position.x][v3_position.z] = true
	var _n_instance = n_room_tile.instantiate()
	mat_material.albedo_color = clr_color
	_n_instance.transform.origin = Vector3(v3_position.x, 0, v3_position.z)
	_n_instance.name = str('B', amount_branch_steps)
	_n_instance.get_node('Floor').material_override = mat_material.duplicate()
	_n_instance.get_node('Floor').material_override.albedo_color = clr_color
	_n_instance.get_node('Count').text = str('B', amount_branch_steps)
	_n_instance.get_node('Coordinates').text = str(v3_position)
	clr_color.h += 0.05
	amount_branch_steps += 1	
	get_node("Rooms/Rooms/").add_child(_n_instance)
	if b_debug_mode: print("===================================")
	if b_debug_mode: print(_n_instance, " branch added at ", v3_position)

func do_fill():
	for _amount_x in range(v2_g_dungeon_size.x):
		for _amount_z in range(v2_g_dungeon_size.y):
			var _v3_position = Vector3(_amount_x, 0, _amount_z)
			var _n_instance = n_room_tile.instantiate()
			mat_material.albedo_color = clr_color
			_n_instance.transform.origin = _v3_position
			_n_instance.get_node('Count').text = "Filled"
			_n_instance.get_node('Coordinates').text = str(_v3_position)
			_n_instance.get_node('Floor').material_override = mat_material.duplicate()
			_n_instance.get_node('Floor').material_override.albedo_color = clr_color
			clr_color.h += 0.05
			get_node("Rooms/Rooms").add_child(_n_instance)

func do_fill_empty():
	mat_material_empty.albedo_color = Color(1, 1, 1, 0.01)
	mat_material_empty.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	for _amount_x in range(v2_g_dungeon_size.x):
		for _amount_z in range(v2_g_dungeon_size.y):
			if arr_dungeon_grid[_amount_x][_amount_z] == false:
				var _v3_position = Vector3(_amount_x, 0, _amount_z)
				var _n_instance = n_room_tile.instantiate()
				_n_instance.transform.origin = _v3_position
				_n_instance.name = "Empty"
				_n_instance.get_node('Count').font_size /= 2
				_n_instance.get_node('Count').text = "Empty"
				_n_instance.get_node('Coordinates').text = str(_v3_position)
				_n_instance.get_node('Floor').material_override = mat_material_empty
				get_node("Empty").add_child(_n_instance)

func do_borders():
	mat_material_border.albedo_color = Color(0.2, 0.2, 0.2, 0)
	for _amount_x in range(v2_g_dungeon_size.x + 2):
		for _amount_z in range(v2_g_dungeon_size.y + 2):
			if _amount_x - 1 < 0 or _amount_z - 1 < 0 or _amount_x == v2_g_dungeon_size.x + 1 or _amount_z == v2_g_dungeon_size.y + 1:
				var _v3_position = Vector3(_amount_x-1, 0, _amount_z-1)
				var _n_instance = n_room_tile.instantiate()
				_n_instance.transform.origin = _v3_position
				_n_instance.get_node('Count').font_size /= 2
				_n_instance.get_node('Count').text = "Border"
				_n_instance.get_node('Coordinates').text = str(_v3_position)
				_n_instance.get_node('Floor').material_override = mat_material_border
				get_node("Borders").add_child(_n_instance)

