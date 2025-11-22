extends CharacterBody3D

@onready var camera_pivot = $CameraPivot
@onready var fish = $Fish

@export var move_speed = 7

var mouse_pressed = false
var camera_direction = Vector3.ZERO
var spatial_hash: SpatialHash
var near_balls: Array = []
var distance = 2.0
var scared_distance = 4.5
var wire := ImmediateMesh.new()
var wire_instance: MeshInstance3D
var key: Vector3i
var size: int
var one = Vector3i(1, 1, 1)

func _ready() -> void:
	wire_instance = MeshInstance3D.new()
	wire_instance.mesh = wire
	var mat = StandardMaterial3D.new()
	wire_instance.material_override = mat
	mat.albedo_color = Color.WHITE
	get_parent().add_child(wire_instance)

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
	var balls = spatial_hash.query(global_position).filter(func(b): return is_instance_valid(b))
	near_balls = near_balls.filter(func(b): return is_instance_valid(b))
	for ball in near_balls:
		print(balls.size())
		ball.set_close(false)
	
	for ball in balls:
		if ball.global_position.distance_to(global_position) < distance:
			#for arr in [near_balls]:  # add any other arrays tracking this boid
				#if self in arr:
					#arr.erase(ball)
			ball.set_close(true)
			# TODO not a perfect solution as camera angle gets kinda wonky
			fish.scale *= 1.00075
			
		if ball.global_position.distance_to(global_position) < scared_distance:
			ball.set_close_scared(true, global_position)
		
			
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
