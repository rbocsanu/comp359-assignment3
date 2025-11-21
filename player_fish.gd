extends CharacterBody3D

@onready var camera_pivot = $CameraPivot
@onready var fish = $Fish

@export var move_speed = 5

var mouse_pressed = false
var camera_direction = Vector3.ZERO
var spatial_hash: SpatialHash
var near_balls: Array = []
var distance = 3.0

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
	# Checks neighboring cells for balls in radius
	var balls = spatial_hash.query(global_position)
	for ball in near_balls:
		ball.set_close(false)
	for ball in balls:
		if ball.global_position.distance_to(global_position) < distance:
			ball.set_close(true)
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
