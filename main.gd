extends Node3D

# Setup 'player' and 'ball' scene
var player_scene = preload("res://player_fish.tscn")
var ball_scene = preload("res://ball.tscn")
var eaten_screen_scene = load("res://EatenScreen.tscn")

var balls: Array[Ball] = []
var player: Player
var eaten_screen: EatenScreen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	handle_spawn()

func handle_spawn():
	var spatial_hash = SpatialHash.new()
	add_child(spatial_hash)
	
	# Create instance of player
	player = player_scene.instantiate()
	player.environment = $WorldEnvironment
	add_child(player)
	player.spatial_hash = spatial_hash
	player.size = int(spatial_hash.size)
	
	player.eaten.connect(handle_game_over)
	player.size_changed.connect(_on_player_size_changed)
	
	# Creates fish
	for i in range(1000):
		spawn_ball(Vector3(
		randf_range(-25,25),
		randf_range(-25,25),
		randf_range(-25,25)),
		spatial_hash)
	
	_on_player_size_changed(player.current_size)

# Function for creating an instance of ball
func spawn_ball(pos: Vector3, spatial_hash: SpatialHash) -> void:
	var ball = ball_scene.instantiate()
	ball.spatial_hash = spatial_hash
	ball.position = pos
	ball.set_fish_size(int(pow(randf(), 4) * 4) + 1)
	add_child(ball)
	balls.append(ball)
	
func handle_game_over():
	player.queue_free()
	player = null
	
	eaten_screen = eaten_screen_scene.instantiate()
	add_child(eaten_screen)
	if not eaten_screen.is_node_ready(): await eaten_screen.ready
	
	for ball in balls:
		if is_instance_valid(ball): ball.queue_free()
	balls = []
	eaten_screen.button.button_down.connect(_respawn)
	
func _respawn():
	if eaten_screen:
		eaten_screen.button.button_down.disconnect(_respawn)
		eaten_screen.queue_free()
		eaten_screen = null
	
	handle_spawn()

func _on_player_size_changed(new_size):
	print("IM WORKING")
	for ball in balls:
		if is_instance_valid(ball):
			if ball.fish_size <= new_size:
				ball.glow.set_color(Color.GREEN)
			else:
				ball.glow.set_color(Color.RED)
