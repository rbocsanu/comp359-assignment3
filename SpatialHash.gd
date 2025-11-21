extends Node3D
class_name SpatialHash

var size: float
var cells := {}

# Can create instances with different sizes
func _init(_size: float = 5.0) -> void:
	size = _size

# Associates a position with a key
# Converts x,y,z coords to its associated cell
func getKey(pos: Vector3) -> Vector3i:
	return Vector3i(
		floor(pos.x / size),
		floor(pos.y / size),
		floor(pos.z / size)
	)

# Adds an object to the SpatialTable
func add(obj: Node3D) -> void:
	var key = getKey(obj.global_position)
	if not cells.has(key):
		cells[key] = []
	cells[key].append(obj)

# Removes an object from a SpatialTable
func remove(obj: Node3D) -> void:
	var key = getKey(obj.global_position)
	if cells.has(key):
		cells[key].erase(obj)
	# If that was the last object in the cell
	# Erase the key
	if cells[key].is_empty():
		cells.erase(key)

# Updates an object in the SpatialTable
func update(obj: Node3D, old_pos: Vector3) -> void:
	var old_key = getKey(old_pos)
	var new_key = getKey(obj.global_position)
	
	# If its in the same cell, return
	if old_key == new_key:
		return
	# Object has moved cell
	# Remove object from old key
	if cells.has(old_key):
		cells[old_key].erase(obj)
		if cells[old_key].is_empty():
			cells.erase(old_key)
	# Add object to new key
	if not cells.has(new_key):
		cells[new_key] = []
	cells[new_key].append(obj)

# Returns an array
# of all of the objects
# in the 3x3x3 grid of pos
func query(pos: Vector3) -> Array:
	var key = getKey(pos)
	var result: Array = []
	for x in range(-1,2):
		for y in range(-1,2):
			for z in range(-1,2):
				var neighbor = key + Vector3i(x,y,z)
				if cells.has(neighbor):
					result.append_array(cells[neighbor])
	return result
