extends Area2D

@export_file("*.tscn") var next_level: String
@export var keys_required: int = 3

var is_open := false
var is_entering := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("closed")
	body_entered.connect(_on_body_entered)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.keys_changed.connect(_on_keys_changed)
		_on_keys_changed(player.keys)

func _on_keys_changed(count: int) -> void:
	if count >= keys_required and not is_open:
		is_open = true
		sprite.play("open")
		for body in get_overlapping_bodies():
			_on_body_entered(body)

func _on_body_entered(body: Node) -> void:
	if is_open and not is_entering and body.is_in_group("player"):
		is_entering = true
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(next_level)
