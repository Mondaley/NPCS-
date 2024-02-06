extends Node3D

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
@export var v2_dungeon_size := Vector2(20, 20)
var arr_dungeon_grid : Array = []
@export_range(1, 3, 1) var amount_grid_multiplier : int = 1
var arr_future_dead_end_directions := []

# Rooms variables
var v3_previous_direction : Vector3
var amount_max_spteps_rough : int = round(v2_dungeon_size.x/2) * v2_dungeon_size.x + (v2_dungeon_size.x - round(v2_dungeon_size.x/2))
@export var amount_max_steps : int = 10
var amount_steps : int = 1

# Branches variables
@export var b_automatic_branch_number : bool = true
@export var amount_branch_max_steps : int = 0:
	get:
		if b_automatic_branch_number == true:
			return amount_max_steps * 2
		else:
			return amount_branch_max_steps
var amount_branch_steps : int = 1

#variables for the generated "rooms"
var v3_coordinates : Vector3
var mat_material := StandardMaterial3D.new()
var mat_material_border := StandardMaterial3D.new()
var mat_material_empty := StandardMaterial3D.new()
@export var clr_color := Color(3, 0, 0, 0)

func _ready():
	if b_generate_borders:	do_generate_borders()
	if b_fill_everything:	do_fill()
	else:
		if b_generate_rooms:	do_generate_dungeon()
		if b_fill_empty:		do_fill_empty()

func do_generate_dungeon():
	var _v3_position : Vector3
	if v2_dungeon_size.x != v2_dungeon_size.y:
		var _amount_average = floor((v2_dungeon_size.y + v2_dungeon_size.x)/2)
		v2_dungeon_size.x = _amount_average
		v2_dungeon_size.y = _amount_average
	if v2_dungeon_size.x == v2_dungeon_size.y:
		_v3_position = Vector3(randi_range(floor((33/100.0) * v2_dungeon_size.x), floor((33/100.0) * v2_dungeon_size.x) * 2 ), 0, randi_range(floor((33/100.0) * v2_dungeon_size.y), floor((33/100.0) * v2_dungeon_size.y) * 2))
		if  amount_max_steps > (20/100.0) * amount_max_spteps_rough:
			amount_max_steps = floor((20/100.0) * amount_max_spteps_rough)
	
	# Initialize the dungeon grid
	for _amount_x in range(v2_dungeon_size.x):
		arr_dungeon_grid.append([])
		for _amount_z in range(v2_dungeon_size.y):
			arr_dungeon_grid[_amount_x].append(false)
	
	# Initialization of the first room
	if b_debug_mode: print(amount_steps, ' step-----------------------------------------------')
	if !_v3_position.x < 0 or !_v3_position.x >= v2_dungeon_size.x or !_v3_position.z < 0 or !_v3_position.z >= v2_dungeon_size.y:
		if b_debug_mode: print(_v3_position, " accepted")
		v3_coordinates = _v3_position
		arr_dungeon_grid[_v3_position.x][_v3_position.z] = true
		do_room(arr_dungeon_grid, _v3_position)
		amount_steps += 1
	else:
		if b_debug_mode: print(_v3_position, " first room passed the boundries")
		return
	
	# Initialization of the rest of the rooms
	while amount_steps <= amount_max_steps:
		if b_debug_mode: print(amount_steps, ' step-----------------------------------------------')
		_v3_position = do_room_direction(_v3_position, arr_dungeon_grid)
		
		#If there are no available directions
		if _v3_position == Vector3(-1, 0 ,0):
			_v3_position = v3_previous_direction
			amount_steps -= 1
			continue
		#If the dungeon is impossible to generate
		if _v3_position == Vector3(-2, 0, 0):
			if b_debug_mode: print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
			if b_debug_mode: print("The dungeon will be regenerated!")
			if b_debug_mode: print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
			while get_node('Rooms/Rooms').get_child_count() > 0:
				get_node('Rooms/Rooms').remove_child(get_node('Rooms/Rooms').get_child(0))
			for _amount_x in range(v2_dungeon_size.x):
				for _amount_y in range(v2_dungeon_size.y):
					arr_dungeon_grid[_amount_x][_amount_y] = false
			amount_steps = 1
			arr_future_dead_end_directions.clear()
			_v3_position = Vector3(randi() % (v2_dungeon_size.x as int), 0, randi() % (v2_dungeon_size.y as int))
			if b_debug_mode:print(amount_steps, ' step-----------------------------------------------')
			if !_v3_position.x < 0 or !_v3_position.x >= v2_dungeon_size.x or !_v3_position.z < 0 or !_v3_position.z >= v2_dungeon_size.y:
				if b_debug_mode:print(_v3_position, " accepted")
				v3_coordinates = _v3_position
				arr_dungeon_grid[_v3_position.x][_v3_position.z] = true
				do_room(arr_dungeon_grid, _v3_position)
				amount_steps += 1
			continue
		#If no issue occurs
		else:
			do_room(arr_dungeon_grid, _v3_position)
			amount_steps += 1
	
	# Initialization of the branches
	arr_future_dead_end_directions.clear()
	while amount_branch_steps <= amount_branch_max_steps:
		if get_node('Rooms/Rooms/').get_child_count() > 0:
			_v3_position = get_node('Rooms/Rooms/').get_child(randi_range(0, get_node('Rooms/Rooms/').get_child_count() - 1)).transform.origin			
		else:
			if b_debug_mode: print('Found no child')
			break
		
		if b_debug_mode: print(amount_branch_steps, ' branch step-----------------------------------------------')
		_v3_position = do_branch_direction(_v3_position, arr_dungeon_grid)
		
		if _v3_position == Vector3(-1, 0, 0):
			_v3_position = get_node('Rooms/Rooms/').get_child(randi_range(0, get_node('Rooms/Rooms/').get_child_count() - 1)).transform.origin
			continue
		else:
			do_branch_room(arr_dungeon_grid, _v3_position)
			amount_branch_steps += 1
				
func do_room_direction(_v3_position : Vector3, _arr_dungeon_grid : Array, _amount_grid_multiplier : int = amount_grid_multiplier) -> Vector3:
	var _arr_possible_directions := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var _arr_available_directions := _arr_possible_directions
	while !_arr_available_directions.is_empty():
		var _amount_neighbors : int = 0
		var _v3_addition = _arr_available_directions[randi() % _arr_available_directions.size()]
		_v3_position += _v3_addition * _amount_grid_multiplier
		if b_debug_mode: print(_v3_addition, " addition vector")
		
		# How many neighbors the space has?
		if _v3_position.x - amount_grid_multiplier < 0 or _v3_position.z >= v2_dungeon_size.y: pass
		elif _arr_dungeon_grid[_v3_position.x - amount_grid_multiplier][_v3_position.z] == true:	_amount_neighbors += 1
		if _v3_position.x + amount_grid_multiplier >= v2_dungeon_size.x or _v3_position.z >= v2_dungeon_size.y: pass
		elif _arr_dungeon_grid[_v3_position.x + amount_grid_multiplier][_v3_position.z] == true:	_amount_neighbors += 1
		if _v3_position.z - amount_grid_multiplier < 0 or _v3_position.x >= v2_dungeon_size.x: pass
		elif _arr_dungeon_grid[_v3_position.x][_v3_position.z - amount_grid_multiplier] == true:	_amount_neighbors += 1
		if _v3_position.z + amount_grid_multiplier >= v2_dungeon_size.y or _v3_position.x >= v2_dungeon_size.x: pass
		elif _arr_dungeon_grid[_v3_position.x][_v3_position.z + amount_grid_multiplier] == true:	_amount_neighbors += 1
		
		#Is the space out of bounds?
		if _v3_position.x < 0 or _v3_position.x >= v2_dungeon_size.x or _v3_position.z < 0 or _v3_position.z >= v2_dungeon_size.y:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Is the space aleardy used? (true)
		elif _arr_dungeon_grid[_v3_position.x][_v3_position.z] == true:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Is the space having too many or too little neighbours?
		elif _amount_neighbors != 1:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Is the space a future dead end?
		elif arr_future_dead_end_directions.find(_v3_position) != -1:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Else the space is valid
		else:
			if b_debug_mode: print(_v3_position, " accsepted")
			_arr_dungeon_grid[_v3_position.x][_v3_position.z] = true
			_arr_available_directions 		= 		_arr_possible_directions
			break
	
		#There are no available directions anymore. Return to the previous used space and note this current space as a dead end one
	if _arr_available_directions.is_empty():
		#add the future dead end space
		if b_debug_mode: print(_v3_position, " added as a future dead end")
		arr_future_dead_end_directions.append(_v3_position)
		#retuen to previous used space (true)
		
		if amount_steps - 2 <= 1:
			return Vector3(-2, 0, 0)
			
		var _n_previous_room = get_node("Rooms/Rooms/" + str(amount_steps - 1))
		_arr_dungeon_grid[_n_previous_room.transform.origin.x][_n_previous_room.transform.origin.z]= false
		if b_debug_mode: print(_n_previous_room, " room removed at ", _n_previous_room.transform.origin)
		get_node("Rooms/Rooms").remove_child(_n_previous_room)
		#----------------------------------------------------
		
		v3_previous_direction = _n_previous_room.transform.origin
		return Vector3(-1, 0, 0)
	return _v3_position

func do_branch_direction(_v3_position : Vector3, _arr_dungeon_grid : Array, _amount_grid_multiplier : int = amount_grid_multiplier) -> Vector3:
	var _arr_possible_directions := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var _arr_available_directions := _arr_possible_directions
	while !_arr_available_directions.is_empty():
		var _amount_neighbors : int = 0
		var _v3_addition = _arr_available_directions[randi() % _arr_available_directions.size()]
		_v3_position += _v3_addition * _amount_grid_multiplier
		if b_debug_mode: print(_v3_addition, " addition vector")
		
		# How many neighbors the space has?
		if _v3_position.x - amount_grid_multiplier < 0 or _v3_position.z >= v2_dungeon_size.y: pass
		elif _arr_dungeon_grid[_v3_position.x - amount_grid_multiplier][_v3_position.z] == true:	_amount_neighbors += 1
		if _v3_position.x + amount_grid_multiplier >= v2_dungeon_size.x or _v3_position.z >= v2_dungeon_size.y: pass
		elif _arr_dungeon_grid[_v3_position.x + amount_grid_multiplier][_v3_position.z] == true:	_amount_neighbors += 1
		if _v3_position.z - amount_grid_multiplier < 0 or _v3_position.x >= v2_dungeon_size.x: pass
		elif _arr_dungeon_grid[_v3_position.x][_v3_position.z - amount_grid_multiplier] == true:	_amount_neighbors += 1
		if _v3_position.z + amount_grid_multiplier >= v2_dungeon_size.y or _v3_position.x >= v2_dungeon_size.x: pass
		elif _arr_dungeon_grid[_v3_position.x][_v3_position.z + amount_grid_multiplier] == true:	_amount_neighbors += 1
		
		#Is the space out of bounds?
		if _v3_position.x < 0 or _v3_position.x >= v2_dungeon_size.x or _v3_position.z < 0 or _v3_position.z >= v2_dungeon_size.y:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Is the space aleardy used? (true)
		elif _arr_dungeon_grid[_v3_position.x][_v3_position.z] == true:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Is the space having too many or too little neighbours?
		elif _amount_neighbors != 1:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Is the space a future dead end?
		elif arr_future_dead_end_directions.find(_v3_position) != -1:
			if b_debug_mode: print(_v3_position, " passed the boundries")
			_v3_position 					-= 		_v3_addition * _amount_grid_multiplier
			var _amount_failed_value_index 	= 		_arr_available_directions.find(_v3_addition)
			if _amount_failed_value_index 	!= -1: 	_arr_available_directions.remove_at(_amount_failed_value_index)
		#Else the space is valid
		else:
			if b_debug_mode: print(_v3_position, " accsepted")
			_arr_dungeon_grid[_v3_position.x][_v3_position.z] = true
			_arr_available_directions 		= 		_arr_possible_directions
			break
			
	#There are no available directions anymore. Return to the previous used space and note this current space as a dead end one
	if _arr_available_directions.is_empty():
		return Vector3(-1, 0, 0)
	return _v3_position

func do_room(_arr_dungeon_grid : Array, _v3_position : Vector3):
	if _arr_dungeon_grid[_v3_position.x][_v3_position.z]:
		var _n_instance = n_room_tile.instantiate()
		mat_material.albedo_color = clr_color
		_n_instance.transform.origin = Vector3(_v3_position.x, 0, _v3_position.z)
		v3_coordinates = _n_instance.transform.origin 
		_n_instance.name = str(amount_steps)
		_n_instance.get_node('Floor').material_override = mat_material.duplicate()
		_n_instance.get_node('Floor').material_override.albedo_color = clr_color
		_n_instance.get_node('Count').text = str(amount_steps)
		_n_instance.get_node('Coordinates').text = str(v3_coordinates)
		clr_color.h += 0.05
		get_node("Rooms/Rooms/").add_child(_n_instance)
		if b_debug_mode: print("===================================")
		if b_debug_mode: print(_n_instance, " room added")

func do_branch_room(_arr_dungeon_grid : Array, _v3_position : Vector3):
	if _arr_dungeon_grid[_v3_position.x][_v3_position.z]:
		var _n_instance = n_room_tile.instantiate()
		mat_material.albedo_color = clr_color
		_n_instance.transform.origin = Vector3(_v3_position.x, 0, _v3_position.z)
		v3_coordinates = _n_instance.transform.origin 
		_n_instance.name = str('B', amount_branch_steps)
		_n_instance.get_node('Floor').material_override = mat_material.duplicate()
		_n_instance.get_node('Floor').material_override.albedo_color = clr_color
		_n_instance.get_node('Count').text = str('B', amount_branch_steps)
		_n_instance.get_node('Coordinates').text = str(v3_coordinates)
		clr_color.h += 0.05
		get_node("Rooms/Rooms/").add_child(_n_instance)
		if b_debug_mode: print("===================================")
		if b_debug_mode: print(_n_instance, " branch added")

func do_fill():
	for _amount_x in range(v2_dungeon_size.x):
		for _amount_z in range(v2_dungeon_size.y):
			var _v3_position = Vector3(_amount_x, 0,_amount_z) * amount_grid_multiplier
			
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
	for _amount_x in range(v2_dungeon_size.x):
		for _amount_z in range(v2_dungeon_size.y):
			if arr_dungeon_grid[_amount_x][_amount_z] == false:
				var _v3_position = Vector3(_amount_x, 0, _amount_z) * amount_grid_multiplier
				var _n_instance = n_room_tile.instantiate()
				_n_instance.transform.origin = _v3_position
				_n_instance.get_node('Count').font_size /= 2
				_n_instance.get_node('Count').text = "Empty"
				_n_instance.get_node('Coordinates').text = str(_v3_position)
				_n_instance.get_node('Floor').material_override = mat_material_empty
				get_node("Rooms/Empty").add_child(_n_instance)

func do_generate_borders():
	mat_material_border.albedo_color = Color(0.2, 0.2, 0.2, 0)
	for _amount_x in range(v2_dungeon_size.x + 2):
		for _amount_z in range(v2_dungeon_size.y + 2):
			if !_amount_x - 1 >= 0 or !_amount_z - 1 >= 0 or _amount_x == v2_dungeon_size.x + 1 or _amount_z == v2_dungeon_size.y + 1:
				var _v3_position = Vector3(_amount_x - 1, 0, _amount_z - 1) * amount_grid_multiplier
				var _n_instance = n_room_tile.instantiate()
				_n_instance.transform.origin = _v3_position
				_n_instance.get_node('Count').font_size /= 2
				_n_instance.get_node('Count').text = "Border"
				_n_instance.get_node('Coordinates').text = str(_v3_position)
				_n_instance.get_node('Floor').material_override = mat_material_border
				get_node("Rooms/Borders").add_child(_n_instance)

