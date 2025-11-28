extends MarginContainer

@onready var shield_bar = $HBoxContainer/ScoreBar
var player

func _ready():
	await get_tree().process_frame  # Wait one frame so Player loads

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_error("UI.gd: Could not find any node in group 'player'!")
		return

	player = players[0]

	player.shield_changed.connect(_on_player_shield_changed)
	_on_player_shield_changed(player.max_shield, player.shield)


func _on_player_shield_changed(max_value, value):
	shield_bar.max_value = max_value
	shield_bar.value = value
