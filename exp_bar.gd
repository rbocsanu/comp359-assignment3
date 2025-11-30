extends Control

class_name ExpBar

@onready var progress_bar = $TextureProgressBar
@onready var label = $Label

var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.exp_changed.connect(_exp_changed)
		player.size_changed.connect(_size_changed)
		
		_size_changed(player.current_size)
		
	var player_get_connection: Signal = get_tree().node_added
	player_get_connection.connect(_node_added)

func _node_added(node: Node):
	if node is not Player or player: return
	player = node
	
	print("added")
	
	player.exp_changed.connect(_exp_changed)
	player.size_changed.connect(_size_changed)
	
	_size_changed(player.current_size)
	
	#get_tree().node_added.disconnect(_node_added)

func _exp_changed(current_exp: float, current_size: int):
	if current_size == 4:
		progress_bar.value = 100
		return
	progress_bar.value = (current_exp / player.size_exp_requirements[current_size]) * 100
	
func _size_changed(current_size: int):
	label.text = "Size: " + str(current_size)
	pass
