extends Area2D

@export_file("*.tscn") var next_level: String
@export var keys_required: int = 3

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.keys >= keys_required:
		get_tree().change_scene_to_file.call_deferred(next_level)
