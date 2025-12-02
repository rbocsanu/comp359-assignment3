extends CharacterBody3D

class_name Player

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var fish: Node3D = $Fish
@onready var environment: WorldEnvironment

@export var base_move_speed = 7 # Move speed when not sprinting
@export var max_sprint_time = 3 # In seconds
@export var energy_regeneration_time = 8 # In seconds
@export var sprint_speed_boost = 4 # Added to base_move_speed when sprinting
@export var sprint_increased_camera_FOV = 100

const size_exp_requirements: Array[float] = [0.0, 10.0, 25.0, 50.0]

var base_camera_FOV = 75
var move_speed = base_move_speed
var mouse_pressed = false
var camera_direction = Vector3.ZERO
var spatial_hash: SpatialHash
var near_balls: Array = []
var distance = 1.0
var scared_distance = 3.0
var wire := ImmediateMesh.new()
var wire_instance: MeshInstance3D
var key: Vector3i
var size: int
var one = Vector3i(1, 1, 1)
#var UI = MarginContainer
var growth_rate = 0.04
var is_sprinting = false
var energy = 1.0


signal shield_changed
signal sprinting(energy: float)
signal exp_changed(current_exp: float, current_size: int)
signal size_changed(level: int)
signal eaten

@export var max_shield = 100
var shield = 0:
	set = set_shield
	
func set_shield(value):
	shield = clamp(value, 0, max_shield)
	shield_changed.emit(max_shield, shield)
	if shield <= 0:
		print("low shield")


var current_size: int = 1
var current_exp: float = 0.0:
	set(value):
		current_exp = value
		if current_size < 4 and current_exp >= size_exp_requirements[current_size]:
			current_exp -= size_exp_requirements[current_size]
			current_size += 1
			size_changed.emit(current_size)
		
		exp_changed.emit(current_exp, current_size)


func _ready() -> void:
	wire_instance = MeshInstance3D.new()
	wire_instance.mesh = wire
	var mat = StandardMaterial3D.new()
	wire_instance.material_override = mat
	mat.albedo_color = Color.WHITE
	get_parent().add_child(wire_instance)
	add_to_group("player")
	
	current_exp = 0.0
	current_size = 1
	energy = 1.0
	#var UI = get_parent().get_node("UI")

# Draws debug cells
func _debug_cells():
	wire.clear_surfaces()
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1 ,2):
				var cell = key + Vector3i(x, y, z)
				wire.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
				wire.surface_add_vertex(cell)
				wire.surface_add_vertex(cell + size * Vector3i(1, 0, 0))
				wire.surface_add_vertex(cell + size * Vector3i(1, 1, 0))
				wire.surface_add_vertex(cell + size * Vector3i(0, 1, 0))
				wire.surface_add_vertex(cell)
				wire.surface_add_vertex(cell + size * Vector3i(0, 0, 1))
				wire.surface_add_vertex(cell + size * Vector3i(0, 1, 1))
				wire.surface_add_vertex(cell + size * Vector3i(0, 1, 0))
				wire.surface_add_vertex(cell)
				wire.surface_add_vertex(cell + size * Vector3i(0, 0, 1))
				wire.surface_add_vertex(cell + size * Vector3i(1, 0, 1))
				wire.surface_add_vertex(cell + size * Vector3i(1, 0, 0))
				wire.surface_add_vertex(cell)
				
				wire.surface_end()
				
				wire.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
				
				wire.surface_add_vertex(cell + size * (one))
				wire.surface_add_vertex(cell + size * (one - Vector3i(1, 0, 0)))
				wire.surface_add_vertex(cell + size * (one - Vector3i(1, 1, 0)))
				wire.surface_add_vertex(cell + size * (one - Vector3i(0, 1, 0)))
				wire.surface_add_vertex(cell + size * (one))
				wire.surface_add_vertex(cell + size * (one - Vector3i(0, 0, 1)))
				wire.surface_add_vertex(cell + size * (one - Vector3i(0, 1, 1)))
				wire.surface_add_vertex(cell + size * (one - Vector3i(0, 1, 0)))
				wire.surface_add_vertex(cell + size * (one))
				wire.surface_add_vertex(cell + size * (one - Vector3i(0, 0, 1)))
				wire.surface_add_vertex(cell + size * (one - Vector3i(1, 0, 1)))
				wire.surface_add_vertex(cell + size * (one - Vector3i(1, 0, 0)))
				wire.surface_add_vertex(cell + size * (one))
				
				wire.surface_end()

func _unhandled_input(event: InputEvent) -> void:
	
	# Mouse movement (camera rotation)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_pressed = true
			else:
				mouse_pressed = false
	
	if (event is InputEventMouseMotion) and (mouse_pressed):
		camera_direction = event.screen_relative
		
	if not mouse_pressed:
		camera_direction = Vector3.ZERO
		
		
func _physics_process(delta: float) -> void:
	key = spatial_hash.getKey(global_position) * size
	#_debug_cells()
	# Checks neighboring cells for balls in radius
	var balls = spatial_hash.query(global_position, scared_distance).filter(func(b): return is_instance_valid(b))
	near_balls = near_balls.filter(func(b): return is_instance_valid(b))
	for ball in near_balls:
		ball.set_close(false)
	
	for ball: Ball in balls:
		if not ball is Ball: continue
		
		if ball.global_position.distance_to(global_position) < distance:
			#for arr in [near_balls]:  # add any other arrays tracking this boid
				#if self in arr:
					#arr.erase(ball)
			_eat_fish(ball)
			
		if ball.global_position.distance_to(global_position) < scared_distance:
			if ball.fish_size <= current_size:
				ball.set_close_scared(true, global_position)
			else: 
				ball.set_close_hungry(true, global_position)
		
			
		near_balls = balls
	
	camera_pivot.rotation.x += (camera_direction.y * delta)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2, PI / 2)
	
	camera_pivot.rotation.y += (-camera_direction.x * delta)
	
	fish.rotation.x = camera_pivot.rotation.x
	fish.rotation.y = camera_pivot.rotation.y
	
	camera_direction = Vector3.ZERO
	
	var forward = int(Input.is_action_pressed("move_forward"))
	var left = int(Input.is_action_pressed("move_left")) - int(Input.is_action_pressed("move_right"))
	
	#var direction = Vector3(int(Input.is_action_pressed("move_left")) - int(Input.is_action_pressed("move_right")), 0, Input.is_action_pressed("move_forward"))
	var direction = fish.global_basis.z * forward + fish.global_basis.x * left
	direction = direction.normalized()
	
	velocity = velocity.move_toward(direction * move_speed, delta * move_speed * 5)
	move_and_slide()
	
	if Input.is_action_pressed("sprint"):
		_sprinting(delta)
	else:
		_sprint_ended()
		energy = clamp(energy + delta / energy_regeneration_time, 0.0, 1.0)
		
	sprinting.emit(energy)
	
func _sprinting(delta: float) -> void:
	if energy == 0.0:
		if is_sprinting:
			_sprint_ended()
			return
		else:
			return
	
	if !is_sprinting:
		is_sprinting = true
		camera.fov = sprint_increased_camera_FOV
	
	energy = clamp(energy - delta / max_sprint_time, 0.0, 1.0)
	
	move_speed = base_move_speed + sprint_speed_boost
		
func _sprint_ended() -> void:
	if is_sprinting:
		camera.fov = base_camera_FOV
		move_speed = base_move_speed
	
	is_sprinting = false
	
func _eat_fish(ball: Ball) -> void:
	if ball.fish_size <= current_size:
		ball.set_close(true)
		scale += one * growth_rate
		distance += growth_rate * 1.001
		environment.environment.volumetric_fog_density *= 0.99
		shield += (max_shield * 0.05) # * delta
		current_exp += ball.fish_size
	else:
		eaten.emit()

#func update_shield(max_value, value):
	#UI.update_shield(max_value, value)


func _on_shield_changed(_max_value, _value) -> void:
	pass # Replace with function body.
