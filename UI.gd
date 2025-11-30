extends MarginContainer

@onready var shield_bar = $Container/ScoreBar
@onready var energy_bar = $Container/EnergyBar
var player: Player

func _ready():
	await get_tree().process_frame  # Wait one frame so Player loads

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_error("UI.gd: Could not find any node in group 'player'!")
		return

	player = players[0]
	print(player)
	if player: _init_new_player()
	
	get_tree().node_added.connect(_node_added)
	
func _node_added(node: Node):
	if node is not Player or player: return
	player = node
	
	_init_new_player()
	
func _init_new_player():
	player.shield_changed.connect(_on_player_shield_changed)
	_on_player_shield_changed(player.max_shield, player.shield)
	player.sprinting.connect(_on_player_sprint)

func _on_player_shield_changed(max_value, value):
	shield_bar.max_value = max_value
	shield_bar.value = value

func _on_player_sprint(energy: float):
	energy_bar.value = energy * 100
