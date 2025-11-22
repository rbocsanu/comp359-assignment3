extends Node3D

# Colors for close or far
@export var close_color: Color = Color.GREEN
@export var close_color_ball: Color = Color.WEB_PURPLE
@export var far_color: Color = Color.RED

# Flocking parameters
@export var neighbor_radius: float = 4.0
@export var separation_radius: float = 1.5
@export var max_speed: float = 6.0
@export var max_force: float = 4.0
@export var max_flee_force: float = 4.5

@export var weight_separation: float = 1.8
@export var weight_alignment: float = 1.0
@export var weight_cohesion: float = 0.8

# Declare some variables
var sphere = MeshInstance3D.new()
var spatial_hash = SpatialHash
var near_balls: Array = []
var last_pos: Vector3
var velocity: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO

@export var bounds_min: Vector3 = Vector3(-30, -30, -30)
@export var bounds_max: Vector3 = Vector3( 30,  30,  30)
@export var boundary_push_strength: float = 8.0
@export var boundary_distance: float = 8.0   # start steering before reaching wall

@export var bubble_scene: PackedScene = preload("res://Bubble.tscn")

func set_hash(_spatial_hash: SpatialHash) -> void:
	spatial_hash = _spatial_hash


func _ready():
	# Creates visual for ball
	sphere.mesh = SphereMesh.new()
	sphere.scale = Vector3(0.3,0.3, 0.3)
	var mat = StandardMaterial3D.new()
	sphere.material_override = mat
	add_child(sphere)
	set_color(far_color)
	
	last_pos = global_position
	
	# Add ball to the SpatialHash table
	spatial_hash.add(self)
	
	# Random starting direction
	direction = Vector3(
		randf_range(-1,1),
		randf_range(-1,1),
		randf_range(-1,1)
	).normalized()

	velocity = direction * max_speed * 0.5



func _process(delta):
	# ---------------------------------------------------------
	# QUERIED NEIGHBORS (Broad phase)
	# ---------------------------------------------------------
	var neighbors = spatial_hash.query(global_position)

	# ---------------------------------------------------------
	# FLOCKING FORCES
	# ---------------------------------------------------------
	var sep = Vector3.ZERO
	var ali = Vector3.ZERO
	var coh = Vector3.ZERO
	var count = 0

	for other in neighbors:
		if other == self:
			continue

		var d = global_position.distance_to(other.global_position)
		if d < neighbor_radius:
			count += 1

			# --- SEPARATION --------------------
			if d < separation_radius and d > 0:
				sep += (global_position - other.global_position).normalized() / d

			# --- ALIGNMENT ---------------------
			ali += other.velocity

			# --- COHESION ----------------------
			coh += other.global_position

	if count > 0:
		# --- Alignment ---
		ali = (ali / count).normalized() * max_speed - velocity

		# --- Cohesion ---
		var center = coh / count
		coh = (center - global_position).normalized() * max_speed - velocity

		# Clamp cohesion force
		coh = coh.limit_length(max_force)

		# --- Separation ---
		sep = sep.normalized() * max_speed - velocity
		sep = sep.limit_length(max_force)

	# Combine forces
	var acceleration = Vector3.ZERO
	acceleration += sep * weight_separation
	acceleration += ali * weight_alignment
	acceleration += coh * weight_cohesion
	# ---------------------------------------------------------
	# BOUNDARY STEERING
	# ---------------------------------------------------------
	var boundary_force := Vector3.ZERO
	if global_position.x < bounds_min.x + boundary_distance:
		boundary_force.x += boundary_push_strength
	elif global_position.x > bounds_max.x - boundary_distance:
		boundary_force.x -= boundary_push_strength
	if global_position.y < bounds_min.y + boundary_distance:
		boundary_force.y += boundary_push_strength
	elif global_position.y > bounds_max.y - boundary_distance:
		boundary_force.y -= boundary_push_strength
	if global_position.z < bounds_min.z + boundary_distance:
		boundary_force.z += boundary_push_strength
	elif global_position.z > bounds_max.z - boundary_distance:
		boundary_force.z -= boundary_push_strength

	# Add this to total acceleration
	acceleration += boundary_force

	# ---------------------------------------------------------
	# MOVE THE BOID
	# ---------------------------------------------------------
	velocity += acceleration * delta
	velocity = velocity.limit_length(max_speed)

	global_position += velocity * delta
	look_at(-velocity + global_position)

	# Position changed → update spatial hash
	if global_position != last_pos:
		spatial_hash.update(self, last_pos)
		last_pos = global_position

	# ---------------------------------------------------------
	# COLOR DEBUGGING (your existing logic)
	# ---------------------------------------------------------
	#for ball in near_balls:
		#ball.set_close_ball(false)
#
	#for ball in neighbors:
		#if ball.global_position.distance_to(global_position) < separation_radius:
			#ball.set_close_ball(true)
#
	near_balls = neighbors



# ---------------------------------------------------------
# Utility color functions
# ---------------------------------------------------------
func set_color(color: Color):
	var material = sphere.get_active_material(0)
	if material:
		material.albedo_color = color

func flee_from(predator_pos: Vector3):
	var desired = (global_position - predator_pos).normalized() * (max_speed * 1.1)
	var flee_force = (desired - velocity).limit_length(max_force)
	# LIMIT the force so they don’t blast away too fas
	flee_force = flee_force.limit_length(max_flee_force)
	velocity += flee_force
	
func set_close_scared(active: bool, predator_pos: Vector3):
	
	if active and predator_pos != Vector3.ZERO:
		flee_from(predator_pos)

func set_close(active: bool):
	
	set_color(close_color if active else far_color)
	if active:
		remove()

func set_close_ball(active: bool):
	set_color(close_color_ball if active else far_color)
	
func remove():
	scale *= 2
	# Optional: wait for 1 second before actually deleting
	if bubble_scene:
		var bubbles = bubble_scene.instantiate()
		bubbles.global_position = global_position
		get_parent().add_child(bubbles)
		
	spatial_hash.remove(self)
	
	# Remove from nearby tracking arrays
	for arr in [near_balls]:  # add any other arrays tracking this boid
		if self in arr:
			arr.erase(self)
	#await get_tree().create_timer(1.0).timeout
	queue_free()
	
