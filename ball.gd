extends Node3D

# Colors for close or far
@export var close_color: Color = Color.GREEN
@export var far_color: Color = Color.RED

# Declare some variables
var sphere = MeshInstance3D.new()
var spatial_hash = SpatialHash
var last_pos: Vector3
var velocity: Vector3
var direction: Vector3

func set_hash(_spatial_hash: SpatialHash) -> void:
	spatial_hash = _spatial_hash

func _ready():
	# Creates visual for ball
	sphere.mesh = SphereMesh.new()
	sphere.scale = Vector3(0.5, 0.5, 0.5)
	var mat = StandardMaterial3D.new()
	sphere.material_override = mat
	add_child(sphere)
	set_color(far_color)
	
	last_pos = global_position
	
	# Add ball to the SpatialHash table
	spatial_hash.add(self)
	
	direction = Vector3(
		randf_range(-1,1),
		randf_range(-1,1),
		randf_range(-1,1)
	)


func _process(delta):
	# If position changes
	# update it with table
	var drift = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)).normalized()
	
	direction = direction.lerp(direction + drift, 1).normalized() * 3
	velocity = direction
	global_position += velocity * delta
	look_at(-velocity + global_position)
	if global_position != last_pos:
		spatial_hash.update(self, last_pos)
		last_pos = global_position

# Function for setting color
func set_color(color: Color):
	var material = sphere.get_active_material(0)
	if material:
		material.albedo_color = color

# Function for setting a ball to 'close'
func set_close(active: bool):
	set_color(close_color if active else far_color)

# A function for removing a ball
func remove():
	spatial_hash.remove(self)
