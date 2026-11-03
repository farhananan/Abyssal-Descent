extends Label

@export var keys_required: int = 3

func _ready() -> void:
	text = "Keys: 0/%d" % keys_required
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("KeyLabel: no node in group 'player' found")
		return
	text = "Keys: %d/%d" % [player.keys, keys_required]
	player.keys_changed.connect(_on_keys_changed)

func _on_keys_changed(count: int) -> void:
	text = "Keys: %d/%d" % [count, keys_required]
