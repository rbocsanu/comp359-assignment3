extends Node3D

# Setup 'player' and 'ball' scene
var player_scene = preload("res://player_fish.tscn")
var ball_scene = preload("res://ball.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create instance of a SpatialHash table
	var spatial_hash = SpatialHash.new()
	add_child(spatial_hash)
	
	# Create instance of player
	var player = player_scene.instantiate()
	add_child(player)
	player.spatial_hash = spatial_hash
	player.size = int(spatial_hash.size)
	
	# Creates 10 balls
	for i in range(2000):
		spawn_ball(Vector3(
		randf_range(-25,25),
		randf_range(-25,25),
		randf_range(-25,25)),
		spatial_hash)

# Function for creating an instance of ball
func spawn_ball(pos: Vector3, spatial_hash: SpatialHash) -> void:
	var ball = ball_scene.instantiate()
	ball.spatial_hash = spatial_hash
	ball.position = pos
	add_child(ball)
